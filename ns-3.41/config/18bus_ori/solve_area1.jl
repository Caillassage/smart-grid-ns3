## Centralized solution
using Ipopt
using JuMP

include("Cent-revised.jl")

function solve_area1(lambda=zeros(24), z=zeros(24), rho=0)
area = "area_1"

opf1 = Model(Ipopt.Optimizer)
set_optimizer_attribute(opf1, "print_level", 0)
#set_optimizer_attribute(opf1, "OutputFlag", 0)

#Branch variables def
@variable(opf1, Pbranch[(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]])
@variable(opf1, Qbranch[(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]])

#Bus variables def
@variable(opf1, v[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])
@variable(opf1, Pgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
@variable(opf1, Qgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
@variable(opf1, Qdg[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])

## slackbus constraint
@constraint(opf1, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
                Pgen[i,phs] == sum(Pbranch[(i,j),phs] for j in BUS_SET_ex[area] if (i,j) in BRANCH_SET_ex[area]) )
@constraint(opf1, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
                Qgen[i,phs] == sum(Qbranch[(i,j),phs] for j in BUS_SET_ex[area] if (i,j) in BRANCH_SET_ex[area]) )


#Power balance
@constraint(opf1, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                sum(Pbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                == Pload[j,phs] - PDGmax[j,phs] + sum(Pbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))

@constraint(opf1, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                sum(Qbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                == Qload[j,phs] - Qcap[j,phs] - Qdg[j,phs] + sum(Qbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))

#Voltage drop
@constraint(opf1, [(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]],
                        v[i,phs] == v[j,phs] - sum( M_P[(i,j),(phs,gmm)]*Pbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] )
                                             - sum( M_Q[(i,j),(phs,gmm)]*Qbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] ) )

#DG constraint
@constraint(opf1, [ i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i] ], -QDGmax[i,phs] <= Qdg[i,phs] <= QDGmax[i,phs])

#Voltage limits
@constraint(opf1, [i=slack_bus, phs=BUS_PHS_SET[area][slack_bus]], v[i,phs] == 1.0*1.0)
@constraint(opf1, [i in setdiff(BUS_SET_ex[area],slack_bus), phs=BUS_PHS_SET[area][i]], 0.95^2 <= v[i,phs] <= 1.05^2)
#=
x = [PDGmax[3,:a]-Pload[3,:a], Qdg[3,:a]-Qload[3,:a], v[3,:a], v[4,:a], Pbranch[(3,4),:a], Qbranch[(3,4),:a],PDGmax[4,:a]-Pload[4,:a], Qdg[4,:a]-Qload[4,:a],
     PDGmax[3,:b]-Pload[3,:b], Qdg[3,:b]-Qload[3,:b], v[3,:b], v[4,:b], Pbranch[(3,4),:b], Qbranch[(3,4),:b], PDGmax[4,:b]-Pload[4,:b], Qdg[4,:b]-Qload[4,:b],
     PDGmax[3,:c]-Pload[3,:c], Qdg[3,:c]-Qload[3,:c], v[3,:c], v[4,:c], Pbranch[(3,4),:c], Qbranch[(3,4),:c], PDGmax[4,:c]-Pload[4,:c], Qdg[4,:c]-Qload[4,:c]]
=#
     x = [PDGmax[3,:a]-Pload[3,:a], Qdg[3,:a], v[3,:a], v[4,:a], Pbranch[(3,4),:a], Qbranch[(3,4),:a],PDGmax[4,:a]-Pload[4,:a], Qdg[4,:a],
          PDGmax[3,:b]-Pload[3,:b], Qdg[3,:b], v[3,:b], v[4,:b], Pbranch[(3,4),:b], Qbranch[(3,4),:b], PDGmax[4,:b]-Pload[4,:b], Qdg[4,:b],
          PDGmax[3,:c]-Pload[3,:c], Qdg[3,:c], v[3,:c], v[4,:c], Pbranch[(3,4),:c], Qbranch[(3,4),:c], PDGmax[4,:c]-Pload[4,:c], Qdg[4,:c] ]

@expression(opf1, Total_gen, sum(Pgen[i,phs] for i = slack_bus, phs=BUS_PHS_SET[area][i]))

# Voltage Deviation w/ absolute value
Vpos = 1.0
@variable(opf1, aux[i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ] >= 0)
@constraint(opf1, [i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= v[i,phs] - Vpos )
@constraint(opf1, [i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= Vpos - v[i,phs] )
@expression(opf1, Total_vdev, sum(aux[i, phs] for i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i]) )

@objective(opf1, Min, Total_vdev
                        + lambda'*(x-z)
                        + rho/2*(x-z)'*(x-z))

optimize!(opf1)
#=
return[ value(PDGmax[3,:a])-Pload[3,:a], value(Qdg[3,:a])-Qload[3,:a], value(v[3,:a]), value(v[4,:a]), value(Pbranch[(3,4),:a]), value(Qbranch[(3,4),:a]),value(PDGmax[4,:a])-Pload[4,:a], value(Qdg[4,:a])-Qload[4,:a],
        value(PDGmax[3,:b])-Pload[3,:b], value(Qdg[3,:b])-Qload[3,:b], value(v[3,:b]), value(v[4,:b]), value(Pbranch[(3,4),:b]), value(Qbranch[(3,4),:b]),value(PDGmax[4,:b])-Pload[4,:b], value(Qdg[4,:b])-Qload[4,:b],
        value(PDGmax[3,:c])-Pload[3,:c], value(Qdg[3,:c])-Qload[3,:c], value(v[3,:c]), value(v[4,:c]), value(Pbranch[(3,4),:c]), value(Qbranch[(3,4),:c]), value(PDGmax[4,:c])-Pload[4,:c], value(Qdg[4,:c])-Qload[4,:c] ], value.(v), opf1
=#

return[ value(PDGmax[3,:a])-Pload[3,:a], value(Qdg[3,:a]), value(v[3,:a]), value(v[4,:a]), value(Pbranch[(3,4),:a]), value(Qbranch[(3,4),:a]),value(PDGmax[4,:a])-Pload[4,:a], value(Qdg[4,:a]),
        value(PDGmax[3,:b])-Pload[3,:b], value(Qdg[3,:b]), value(v[3,:b]), value(v[4,:b]), value(Pbranch[(3,4),:b]), value(Qbranch[(3,4),:b]),value(PDGmax[4,:b])-Pload[4,:b], value(Qdg[4,:b]),
        value(PDGmax[3,:c])-Pload[3,:c], value(Qdg[3,:c]), value(v[3,:c]), value(v[4,:c]), value(Pbranch[(3,4),:c]), value(Qbranch[(3,4),:c]), value(PDGmax[4,:c])-Pload[4,:c], value(Qdg[4,:c]) ], value.(v), opf1

end

if length(ARGS) > 0
     # The first argument is assumed to be the variable we want to use
     lambda = parse(Float64, ARGS[1])
     z = parse(Float64, ARGS[2])
     rho = parse(Float64, ARGS[3])
 
     start_time = time()
     println(solve_area1(lambda, rho, rho))
     end_time = time()
     
     time_taken = end_time - start_time
     println(time_taken)
 end
