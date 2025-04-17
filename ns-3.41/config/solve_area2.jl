using Ipopt, Gurobi, JuMP

include("123_LinDist3Flow_Distributed_3_Areas/Cent-revised.jl")

function parse_float_vector(arg::String)
    # Remove brackets if present, then split by comma
    clean_arg = replace(arg, ['[', ']'] => "")
    return parse.(Float64, split(clean_arg, ","))
end

function solve_area2(lambda, z, rho)
area = "area_2"

opf2 = Model(Gurobi.Optimizer)
#set_optimizer_attribute(opf2, "print_level", 0)
set_optimizer_attribute(opf2, "OutputFlag", 0)

#Branch variables def
@variable(opf2, Pbranch[(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]])
@variable(opf2, Qbranch[(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]])

#Bus variables def
@variable(opf2, v[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])
#@variable(opf2, Pgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
#@variable(opf2, Qgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
@variable(opf2, Qdg[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])
@variable(opf2, Pdg[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])

## slackbus constraint
#@constraint(opf2, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
#                Pgen[i,phs] == sum(Pbranch[(i,j),phs] for j in BUS_SET_ex[area] if (i,j) in BRANCH_SET_ex[area]) )
#@constraint(opf2, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
#                Qgen[i,phs] == sum(Qbranch[(i,j),phs] for j in BUS_SET_ex[area] if (i,j) in BRANCH_SET_ex[area]) )


#Power balance
@constraint(opf2, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                sum(Pbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                == Pload[j,phs] - Pdg[j,phs] + sum(Pbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))

@constraint(opf2, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                sum(Qbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                == Qload[j,phs] - Qcap[j,phs] - Qdg[j,phs] + sum(Qbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))



#Voltage drop
@constraint(opf2, [(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]],
                        v[i,phs] == v[j,phs] - sum( M_P[(i,j),(phs,gmm)]*Pbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] )
                                             - sum( M_Q[(i,j),(phs,gmm)]*Qbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] ) )

#PV modelling as a linear constraint
 k = 16
 phi=180/k
 @constraint(opf2, [l=1:k, i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]], -SDGmax[i,phs] <=   cosd(l*phi)*Pdg[i,phs] + sind(l*phi)*Qdg[i,phs]  <= SDGmax[i,phs] )

 #DG constraint
@constraint(opf2, [ i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i] ], 0 <= Pdg[i,phs] <= PDGmax[i,phs]  )

@constraint(opf2, [ i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i] ], -QDGmax[i,phs] <= Qdg[i,phs] <= QDGmax[i,phs])


#Voltage limits
@constraint(opf2, [i in setdiff(BUS_SET_ex[area],slack_bus), phs=BUS_PHS_SET[area][i]], 0.95^2 <= v[i,phs] <= 1.05^2)

x = [ Pdg[21,:a]-Pload[21,:a], Qdg[21,:a]-Qload[21,:a], v[21,:a], v[56,:a], Pbranch[(21,56),:a], Qbranch[(21,56),:a], Pdg[56,:a]-Pload[56,:a], Qdg[56,:a]-Qload[56,:a],
     Pdg[21,:b]-Pload[21,:b], Qdg[21,:b]-Qload[21,:b], v[21,:b], v[56,:b], Pbranch[(21,56),:b], Qbranch[(21,56),:b], Pdg[56,:b]-Pload[56,:b], Qdg[56,:b]-Qload[56,:b],
     Pdg[21,:c]-Pload[21,:c], Qdg[21,:c]-Qload[21,:c], v[21,:c], v[56,:c], Pbranch[(21,56),:c], Qbranch[(21,56),:c], Pdg[56,:c]-Pload[56,:c], Qdg[56,:c]-Qload[56,:c] ]

@expression(opf2, Total_gen, sum(Pgen[i,phs] for i = slack_bus, phs=BUS_PHS_SET[area][i]))

# Voltage Deviation w/ absolute value
Vpos = 1.0
@variable(opf2, aux[i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ] >= 0)
@constraint(opf2, [i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= v[i,phs] - Vpos )
@constraint(opf2, [i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= Vpos - v[i,phs] )
@expression(opf2, Total_vdev, sum(aux[i, phs] for i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i]) )

@expression(opf2, Pdgtot, sum(Pdg[i,phs] for i = BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]) )
@expression(opf2, Qdgtot, sum(Qdg[i,phs] for i = BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]) )

@expression(opf2, PVHC, sum(PDGmax[i,phs]-Pdg[i,phs] for i = BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]))

@objective(opf2, Min, Total_vdev
                        + lambda'*(x-z)
                        + rho/2*(x-z)'*(x-z))

solvetime = @elapsed optimize!(opf2)

return[value(Pdg[21,:a])-Pload[21,:a], value(Qdg[21,:a])-Qload[21,:a], value(v[21,:a]), value(v[56,:a]), value(Pbranch[(21,56),:a]), value(Qbranch[(21,56),:a]),value(Pdg[56,:a])-Pload[56,:a], value(Qdg[56,:a])-Qload[56,:a],
        value(Pdg[21,:b])-Pload[21,:b], value(Qdg[21,:b])-Qload[21,:b], value(v[21,:b]), value(v[56,:b]), value(Pbranch[(21,56),:b]), value(Qbranch[(21,56),:b]),value(Pdg[56,:b])-Pload[56,:b], value(Qdg[56,:b])-Qload[56,:b],
        value(Pdg[21,:c])-Pload[21,:c], value(Qdg[21,:c])-Qload[21,:c], value(v[21,:c]), value(v[56,:c]), value(Pbranch[(21,56),:c]), value(Qbranch[(21,56),:c]), value(Pdg[56,:c])-Pload[56,:c], value(Qdg[56,:c])-Qload[56,:c] ],
        value.(v),solvetime, opf2, JuMP.objective_value(opf2),  value(Pload[21,:a] - Pdg[21,:a]), value.(Pdg), value.(Qdg)

end

lambda_122 = parse_float_vector(ARGS[1])
z12 = parse_float_vector(ARGS[2])
rho = parse(Float64, ARGS[3])

start_time = time()
x2,v2,t2, opf2,obj2, nl2, Pdg2, Qdg2= solve_area2(lambda_122, z12, rho)
end_time = time()

# x1 24-element Vector{Float64}
# v2 JuMP.Containers.SparseAxisArray{Float64, 2, Tuple{Int64, Symbol}} with 42 entries:
# t1 Float64
# obj1 Float64

time_taken = end_time - start_time
println(time_taken)
println(x2)
println(t2)
println(obj2)