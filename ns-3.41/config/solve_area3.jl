using Ipopt, Gurobi, JuMP

include("123_LinDist3Flow_Distributed_3_Areas/Cent-revised.jl")

function parse_float_vector(arg::String)
    # Remove brackets if present, then split by comma
    clean_arg = replace(arg, ['[', ']'] => "")
    return parse.(Float64, split(clean_arg, ","))
end


function solve_area3(lambda, z, rho)
area = "area_3"

opf3 = Model(Gurobi.Optimizer)
#set_optimizer_attribute(opf3, "print_level", 0)
set_optimizer_attribute(opf3, "OutputFlag", 0)

#Branch variables def
@variable(opf3, Pbranch[(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]])
@variable(opf3, Qbranch[(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]])

#Bus variables def
@variable(opf3, v[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])
#@variable(opf3, Pgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
#@variable(opf3, Qgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
@variable(opf3, Qdg[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])
@variable(opf3, Pdg[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])

## slackbus constraint
#@constraint(opf3, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
#                Pgen[i,phs] == sum(Pbranch[(i,j),phs] for j in BUS_SET_ex[area] if (i,j) in BRANCH_SET_ex[area]) )
#@constraint(opf3, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
#                Qgen[i,phs] == sum(Qbranch[(i,j),phs] for j in BUS_SET_ex[area] if (i,j) in BRANCH_SET_ex[area]) )


#Power balance
@constraint(opf3, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                sum(Pbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                == Pload[j,phs] - Pdg[j,phs] + sum(Pbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))

@constraint(opf3, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                sum(Qbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                == Qload[j,phs] - Qcap[j,phs] - Qdg[j,phs] + sum(Qbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))



#Voltage drop
@constraint(opf3, [(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]],
                        v[i,phs] == v[j,phs] - sum( M_P[(i,j),(phs,gmm)]*Pbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] )
                                             - sum( M_Q[(i,j),(phs,gmm)]*Qbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] ) )

#PV modelling as a linear constraint
 k = 16
 phi=180/k
 @constraint(opf3, [l=1:k, i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]], -SDGmax[i,phs] <=   cosd(l*phi)*Pdg[i,phs] + sind(l*phi)*Qdg[i,phs]  <= SDGmax[i,phs] )

 #DG constraint
@constraint(opf3, [ i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i] ], 0 <= Pdg[i,phs] <= PDGmax[i,phs]  )

@constraint(opf3, [ i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i] ], -QDGmax[i,phs] <= Qdg[i,phs] <= QDGmax[i,phs])


#Voltage limits
@constraint(opf3, [i in setdiff(BUS_SET_ex[area],slack_bus), phs=BUS_PHS_SET[area][i]], 0.95^2 <= v[i,phs] <= 1.05^2)

x = [ Pdg[31,:a]-Pload[31,:a], Qdg[31,:a]-Qload[31,:a], v[31,:a], v[94,:a], Pbranch[(31,94),:a], Qbranch[(31,94),:a], Pdg[94,:a]-Pload[94,:a], Qdg[94,:a]-Qload[94,:a],
     Pdg[31,:b]-Pload[31,:b], Qdg[31,:b]-Qload[31,:b], v[31,:b], v[94,:b], Pbranch[(31,94),:b], Qbranch[(31,94),:b], Pdg[94,:b]-Pload[94,:b], Qdg[94,:b]-Qload[94,:b],
     Pdg[31,:c]-Pload[31,:c], Qdg[31,:c]-Qload[31,:c], v[31,:c], v[94,:c], Pbranch[(31,94),:c], Qbranch[(31,94),:c], Pdg[94,:c]-Pload[94,:c], Qdg[94,:c]-Qload[94,:c] ]

@expression(opf3, Total_gen, sum(Pgen[i,phs] for i = slack_bus, phs=BUS_PHS_SET[area][i]))

# Voltage Deviation w/ absolute value
Vpos = 1.0
@variable(opf3, aux[i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ] >= 0)
@constraint(opf3, [i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= v[i,phs] - Vpos )
@constraint(opf3, [i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= Vpos - v[i,phs] )
@expression(opf3, Total_vdev, sum(aux[i, phs] for i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i]) )

@expression(opf3, Pdgtot, sum(Pdg[i,phs] for i = BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]) )
@expression(opf3, Qdgtot, sum(Qdg[i,phs] for i = BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]) )

@expression(opf3, PVHC, sum(PDGmax[i,phs]-Pdg[i,phs] for i = BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]))

@objective(opf3, Min, Total_vdev
                        + lambda'*(x-z)
                        + rho/2*(x-z)'*(x-z))

solvetime = @elapsed optimize!(opf3)

return[value(Pdg[31,:a])-Pload[31,:a], value(Qdg[31,:a])-Qload[31,:a], value(v[31,:a]), value(v[94,:a]), value(Pbranch[(31,94),:a]), value(Qbranch[(31,94),:a]),value(Pdg[94,:a])-Pload[94,:a], value(Qdg[94,:a])-Qload[94,:a],
        value(Pdg[31,:b])-Pload[31,:b], value(Qdg[31,:b])-Qload[31,:b], value(v[31,:b]), value(v[94,:b]), value(Pbranch[(31,94),:b]), value(Qbranch[(31,94),:b]),value(Pdg[94,:b])-Pload[94,:b], value(Qdg[94,:b])-Qload[94,:b],
        value(Pdg[31,:c])-Pload[31,:c], value(Qdg[31,:c])-Qload[31,:c], value(v[31,:c]), value(v[94,:c]), value(Pbranch[(31,94),:c]), value(Qbranch[(31,94),:c]), value(Pdg[94,:c])-Pload[94,:c], value(Qdg[94,:c])-Qload[94,:c] ],
        value.(v),solvetime, opf3, JuMP.objective_value(opf3),  value(Pload[31,:a] - Pdg[31,:a]), value.(Pdg), value.(Qdg)

end

lambda_133 = parse_float_vector(ARGS[1])
z13 = parse_float_vector(ARGS[2])
rho = parse(Float64, ARGS[3])

start_time = time()
x3, v3, t3, opf3, obj3, nl3, Pdg3, Qdg3 = solve_area3(lambda_133, z13, rho)
end_time = time()

# x1 24-element Vector{Float64}
# v3 JuMP.Containers.SparseAxisArray{Float64, 2, Tuple{Int64, Symbol}} with 106 entries
# t1 Float64
# obj1 Float64

time_taken = end_time - start_time
println(time_taken)
println(x3)
println(t3)
println(obj3)