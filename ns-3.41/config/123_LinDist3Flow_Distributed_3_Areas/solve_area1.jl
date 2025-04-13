using Ipopt, Gurobi

function solve_area1(lambda=zeros(24), z=zeros(24), rho=0)
area = "area_1"

opf1 = Model(Gurobi.Optimizer)
#set_optimizer_attribute(opf1, "print_level", 0)
set_optimizer_attribute(opf1, "OutputFlag", 0)

#Branch variables def
@variable(opf1, Pbranch[(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]])
@variable(opf1, Qbranch[(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]])

#Bus variables def
@variable(opf1, v[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])
@variable(opf1, Pgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
@variable(opf1, Qgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
@variable(opf1, Qdg[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])
@variable(opf1, Pdg[i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]])

## slackbus constraint
@constraint(opf1, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
                Pgen[i,phs] == sum(Pbranch[(i,j),phs] for j in BUS_SET_ex[area] if (i,j) in BRANCH_SET_ex[area]) )
@constraint(opf1, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
                Qgen[i,phs] == sum(Qbranch[(i,j),phs] for j in BUS_SET_ex[area] if (i,j) in BRANCH_SET_ex[area]) )

                #Power balance
                @constraint(opf1, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                                sum(Pbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                                == Pload[j,phs] - Pdg[j,phs] + sum(Pbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))

                @constraint(opf1, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                                sum(Qbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                                == Qload[j,phs] - Qcap[j,phs] - Qdg[j,phs] + sum(Qbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))


#Voltage drop
@constraint(opf1, [(i,j)=BRANCH_SET_ex[area], phs=BRANCH_PHS_SET[area][(i,j)]],
                        v[i,phs] == v[j,phs] - sum( M_P[(i,j),(phs,gmm)]*Pbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] )
                                             - sum( M_Q[(i,j),(phs,gmm)]*Qbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] ) )

#PV modelling as a linear constraint
k = 16
phi=180/k
@constraint(opf1, [l=1:k, i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]], -SDGmax[i,phs] <=   cosd(l*phi)*Pdg[i,phs] + sind(l*phi)*Qdg[i,phs]  <= SDGmax[i,phs] )

#DG constraint
@constraint(opf1, [ i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i] ], 0 <= Pdg[i,phs] <= PDGmax[i,phs]  )

@constraint(opf1, [ i=BUS_SET_ex[area], phs=BUS_PHS_SET[area][i] ], -QDGmax[i,phs] <= Qdg[i,phs] <= QDGmax[i,phs])

#Voltage limits
@constraint(opf1, [i=slack_bus, phs=BUS_PHS_SET[area][slack_bus]], v[i,phs] == 1.0*1.0)
@constraint(opf1, [i in setdiff(BUS_SET_ex[area],slack_bus), phs=BUS_PHS_SET[area][i]], 0.95^2 <= v[i,phs] <= 1.05^2)
#=
x = [ Pdg[21,:a]-Pload[21,:a], Qdg[21,:a]-Qload[21,:a], v[21,:a], v[56,:a], Pbranch[(21,56),:a], Qbranch[(21,56),:a], Pdg[56,:a]-Pload[56,:a], Qdg[56,:a]-Qload[56,:a],
     Pdg[21,:b]-Pload[21,:b], Qdg[21,:b]-Qload[21,:b], v[21,:b], v[56,:b], Pbranch[(21,56),:b], Qbranch[(21,56),:b], Pdg[56,:b]-Pload[56,:b], Qdg[56,:b]-Qload[56,:b],
     Pdg[21,:c]-Pload[21,:c], Qdg[21,:c]-Qload[21,:c], v[21,:c], v[56,:c], Pbranch[(21,56),:c], Qbranch[(21,56),:c], Pdg[56,:c]-Pload[56,:c], Qdg[56,:c]-Qload[56,:c] ]
=#
x = [Pdg[21,:a]-Pload[21,:a], Qdg[21,:a]-Qload[21,:a], v[21,:a], v[56,:a], Pbranch[(21,56),:a], Qbranch[(21,56),:a],Pdg[56,:a]-Pload[56,:a], Qdg[56,:a]-Qload[56,:a],
Pdg[21,:b]-Pload[21,:b], Qdg[21,:b]-Qload[21,:b], v[21,:b], v[56,:b], Pbranch[(21,56),:b], Qbranch[(21,56),:b],Pdg[56,:b]-Pload[56,:b], Qdg[56,:b]-Qload[56,:b],
Pdg[21,:c]-Pload[21,:c], Qdg[21,:c]-Qload[21,:c], v[21,:c], v[56,:c], Pbranch[(21,56),:c], Qbranch[(21,56),:c],Pdg[56,:c]-Pload[56,:c], Qdg[56,:c]-Qload[56,:c],
Pdg[31,:a]-Pload[31,:a], Qdg[31,:a]-Qload[31,:a], v[31,:a], v[94,:a], Pbranch[(31,94),:a], Qbranch[(31,94),:a],Pdg[94,:a]-Pload[94,:a], Qdg[94,:a]-Qload[94,:a],
Pdg[31,:b]-Pload[31,:b], Qdg[31,:b]-Qload[31,:b], v[31,:b], v[94,:b], Pbranch[(31,94),:b], Qbranch[(31,94),:b],Pdg[94,:b]-Pload[94,:b], Qdg[94,:b]-Qload[94,:b],
Pdg[31,:c]-Pload[31,:c], Qdg[31,:c]-Qload[31,:c], v[31,:c], v[94,:c], Pbranch[(31,94),:c], Qbranch[(31,94),:c],Pdg[94,:c]-Pload[94,:c], Qdg[94,:c]-Qload[94,:c] ]

@expression(opf1, Total_gen, sum(Pgen[i,phs] for i = slack_bus, phs=BUS_PHS_SET[area][i]))

# Voltage Deviation w/ absolute value
Vpos = 1.0
@variable(opf1, aux[i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ] >= 0)
@constraint(opf1, [i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= v[i,phs] - Vpos )
@constraint(opf1, [i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= Vpos - v[i,phs] )
@expression(opf1, Total_vdev, sum(aux[i, phs] for i=BUS_SET_ex[area],phs=BUS_PHS_SET[area][i]) )

@expression(opf1, PVHC, sum(PDGmax[i,phs]-Pdg[i,phs] for i = BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]))

@expression(opf1, Pdgtot, sum(Pdg[i,phs] for i = BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]) )
@expression(opf1, Qdgtot, sum(Qdg[i,phs] for i = BUS_SET_ex[area], phs=BUS_PHS_SET[area][i]) )

@objective(opf1, Min, Total_vdev
                        + lambda'*(x-z)
                        + rho/2*(x-z)'*(x-z))

solvetime = @elapsed optimize!(opf1)

return[value(Pdg[21,:a])-Pload[21,:a], value(Qdg[21,:a])-Qload[21,:a], value(v[21,:a]), value(v[56,:a]), value(Pbranch[(21,56),:a]), value(Qbranch[(21,56),:a]),value(Pdg[56,:a])-Pload[56,:a], value(Qdg[56,:a])-Qload[56,:a],
        value(Pdg[21,:b])-Pload[21,:b], value(Qdg[21,:b])-Qload[21,:b], value(v[21,:b]), value(v[56,:b]), value(Pbranch[(21,56),:b]), value(Qbranch[(21,56),:b]),value(Pdg[56,:b])-Pload[56,:b], value(Qdg[56,:b])-Qload[56,:b],
        value(Pdg[21,:c])-Pload[21,:c], value(Qdg[21,:c])-Qload[21,:c], value(v[21,:c]), value(v[56,:c]), value(Pbranch[(21,56),:c]), value(Qbranch[(21,56),:c]), value(Pdg[56,:c])-Pload[56,:c], value(Qdg[56,:c])-Qload[56,:c],
        value(Pdg[31,:a])-Pload[31,:a], value(Qdg[31,:a])-Qload[31,:a], value(v[31,:a]), value(v[94,:a]), value(Pbranch[(31,94),:a]), value(Qbranch[(31,94),:a]),value(Pdg[94,:a])-Pload[94,:a], value(Qdg[94,:a])-Qload[94,:a],
        value(Pdg[31,:b])-Pload[31,:b], value(Qdg[31,:b])-Qload[31,:b], value(v[31,:b]), value(v[94,:b]), value(Pbranch[(31,94),:b]), value(Qbranch[(31,94),:b]),value(Pdg[94,:b])-Pload[94,:b], value(Qdg[94,:b])-Qload[94,:b],
        value(Pdg[31,:c])-Pload[31,:c], value(Qdg[31,:c])-Qload[31,:c], value(v[31,:c]), value(v[94,:c]), value(Pbranch[(31,94),:c]), value(Qbranch[(31,94),:c]), value(Pdg[94,:c])-Pload[94,:c], value(Qdg[94,:c])-Qload[94,:c] ],
        value.(v), solvetime, opf1, JuMP.objective_value(opf1), value(Pload[21,:a] - Pdg[21,:a]), value.(Pdg), value.(Qdg), value(Pbranch[(38,39),:b]) 

end

#=
return[value(Pdg[31,:a])-Pload[31,:a], value(Qdg[31,:a])-Qload[31,:a], value(v[31,:a]), value(v[94,:a]), value(Pbranch[(31,94),:a]), value(Qbranch[(31,94),:a]),value(Pdg[94,:a])-Pload[94,:a], value(Qdg[94,:a])-Qload[94,:a],
        value(Pdg[31,:b])-Pload[31,:b], value(Qdg[31,:b])-Qload[31,:b], value(v[31,:b]), value(v[94,:b]), value(Pbranch[(31,94),:b]), value(Qbranch[(31,94),:b]),value(Pdg[94,:b])-Pload[94,:b], value(Qdg[94,:b])-Qload[94,:b],
        value(Pdg[31,:c])-Pload[31,:c], value(Qdg[31,:c])-Qload[31,:c], value(v[31,:c]), value(v[94,:c]), value(Pbranch[(31,94),:c]), value(Qbranch[(31,94),:c]), value(Pdg[94,:c])-Pload[94,:c], value(Qdg[94,:c])-Qload[94,:c] ],
        value.(v),solvetime, opf3, JuMP.objective_value(opf3),  value(Pload[31,:a] - Pdg[31,:a]), value.(Pdg), value.(Qdg),value(Pbranch[(38,39),:b])

end
=#