## Centralized solution
#Run MAIN.jl
# using Ipopt, Gurobi
using Gurobi
area = "area_0"

# opf = Model(Ipopt.Optimizer)
opf = Model(Gurobi.Optimizer)

#Branch variables def
@variable(opf, Pbranch[(i,j)=BRANCH_SET[area], phs=BRANCH_PHS_SET[area][(i,j)]])
@variable(opf, Qbranch[(i,j)=BRANCH_SET[area], phs=BRANCH_PHS_SET[area][(i,j)]])

#Bus variables def
@variable(opf, v[i=BUS_SET[area], phs=BUS_PHS_SET[area][i]])
@variable(opf, Pgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
@variable(opf, Qgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
@variable(opf, Qdg[i=BUS_SET[area], phs=BUS_PHS_SET[area][i]])
@variable(opf, Pdg[i=BUS_SET[area], phs=BUS_PHS_SET[area][i]])
## slackbus constraint
@constraint(opf, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
                Pgen[i,phs] == sum(Pbranch[(i,j),phs] for j in BUS_SET[area] if (i,j) in BRANCH_SET[area]) )
@constraint(opf, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
                Qgen[i,phs] == sum(Qbranch[(i,j),phs] for j in BUS_SET[area] if (i,j) in BRANCH_SET[area]) )


#Power balance
@constraint(opf, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                sum(Pbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                == Pload[j,phs] - Pdg[j,phs] + sum(Pbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))
#Pload[21,:a] - Pdg[21,:a]
@constraint(opf, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                sum(Qbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                == Qload[j,phs] - Qcap[j,phs] - Qdg[j,phs]   + sum(Qbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))

#Voltage drop
@constraint(opf, [(i,j)=BRANCH_SET[area], phs=BRANCH_PHS_SET[area][(i,j)]],
                        v[i,phs] == v[j,phs] - sum( M_P[(i,j),(phs,gmm)]*Pbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] )
                                             - sum( M_Q[(i,j),(phs,gmm)]*Qbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] ) )


#PV modelling as a linear constraint
   k = 16
   phi=180/k
   @constraint(opf, [l=1:k, i=BUS_SET[area], phs=BUS_PHS_SET[area][i]], -SDGmax[i,phs] <=   cosd(l*phi)*Pdg[i,phs] + sind(l*phi)*Qdg[i,phs]  <= SDGmax[i,phs] )

#DG constraint
@constraint(opf, [ i=BUS_SET[area], phs=BUS_PHS_SET[area][i] ], 0 <= Pdg[i,phs] <= PDGmax[i,phs]  )
@constraint(opf, [ i=BUS_SET[area], phs=BUS_PHS_SET[area][i] ], -QDGmax[i,phs] <= Qdg[i,phs] <= QDGmax[i,phs])

#Voltage limits
@constraint(opf, [i=slack_bus, phs=BUS_PHS_SET[area][slack_bus]], v[i,phs] == 1.0*1.0)
@constraint(opf, [i in setdiff(BUS_SET[area],slack_bus), phs=BUS_PHS_SET[area][i]], 0.95^2 <= v[i,phs] <= 1.05^2)


@expression(opf, Total_gen, sum(Pgen[i,phs] for i = slack_bus, phs=BUS_PHS_SET[area][i]))
#@objective(opf, Min, Total_gen)

@expression(opf, PVHC, sum(PDGmax[i,phs]-Pdg[i,phs] for i = BUS_SET[area], phs=BUS_PHS_SET[area][i]))

# Voltage Deviation w/ absolute value
Vpos = 1.0
@variable(opf, aux[i=BUS_SET[area],phs=BUS_PHS_SET[area][i] ] >= 0)
@constraint(opf, [i=BUS_SET[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= v[i,phs] - Vpos )
@constraint(opf, [i=BUS_SET[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= Vpos - v[i,phs] )
@expression(opf, Total_vdev, sum(aux[i, phs] for i=BUS_SET[area],phs=BUS_PHS_SET[area][i]) )

#@expression(opf, Total_loss, sum( R[(i,j),(phs,gmm)]*(Pbranch[(i,j),phs]^2 + Qbranch[(i,j),phs]^2)/(v[slack_bus]^2)
                #for (i,j) in BRANCH_SET[area], phs in BRANCH_PHS_SET[area][(i,j)], gmm in BRANCH_PHS_SET[area][(i,j)]  ) )

@objective(opf, Min, Total_vdev)
#@objective(opf, Min, Total_gen)
#@objective(opf, Min, Total_loss)
#@objective(opf, Min, PVHC)

solvetime_cent = @elapsed optimize!(opf)
obj_cent = JuMP.objective_value(opf)

V = Dict( (i,phs) => sqrt( value(v[i,phs])) for i in BUS_SET[area] for phs in BUS_PHS_SET[area][i])
Pgen = Dict( (i,phs) => ( value(Pgen[i,phs])) for i in slack_bus for phs in BUS_PHS_SET[area][i])
Qgen = Dict( (i,phs) => ( value(Qgen[i,phs])) for i in slack_bus for phs in BUS_PHS_SET[area][i])
Pbranch = Dict( ((i,j),phs) => ( value(Pbranch[(i,j),phs])) for (i,j) in BRANCH_SET[area] for phs in BRANCH_PHS_SET[area][(i,j)])
Qbranch = Dict( ((i,j),phs) => ( value(Qbranch[(i,j),phs])) for (i,j) in BRANCH_SET[area] for phs in BRANCH_PHS_SET[area][(i,j)])
Qdg = Dict( (i,phs) => ( value(Qdg[i,phs])) for i in BUS_SET[area] for phs in BUS_PHS_SET[area][i])
Pdg = Dict( (i,phs) => ( value(Pdg[i,phs])) for i in BUS_SET[area] for phs in BUS_PHS_SET[area][i])
Psub_cent = (Pgen[(25, :a)] + Pgen[(25, :b)] + Pgen[(25, :c)])*(1e3*sbase) #kW
Qsub_cent = (Qgen[(25, :a)] + Qgen[(25, :b)] + Qgen[(25, :c)])*(1e3*sbase) #kW
#=
df = DataFrame( Psub =Psub_cent,  Qsub =Qsub_cent, objective = obj_cent, Pdg_21 = Pdg[(21, :a)]*(1e3*sbase), Qdg_21 = Qdg[(21, :a)]*(1e3*sbase) )
CSV.write("Plotting\\results_cent.csv",df)
## Pdg plot
Pdg_a = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Pdg_b = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Pdg_c = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)

for bus in BUS_SET[area]
        Pdg_a[bus] = :a in BUS_PHS_SET[area][bus] ? value(Pdg[bus,:a]) : NaN
        Pdg_b[bus] = :b in BUS_PHS_SET[area][bus] ? value(Pdg[bus,:b])  : NaN
        Pdg_c[bus] = :c in BUS_PHS_SET[area][bus] ? value(Pdg[bus,:c])  : NaN
end

Pdg_a_new = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Pdg_b_new = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Pdg_c_new = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
for bus in BUS_SET[area]
        Pdg_a_new[bus] =  :a in BUS_PHS_SET[area][bus] ? value(Pdg[bus,:a]) : 0
        Pdg_b_new[bus] =  :b in BUS_PHS_SET[area][bus] ? value(Pdg[bus,:b]) : 0
        Pdg_c_new[bus] =  :c in BUS_PHS_SET[area][bus] ? value(Pdg[bus,:c]) : 0
end
Pdg_total = sum(Pdg_a_new + Pdg_b_new + Pdg_c_new)*(1e3*sbase)

p1 = scatter( Pdg_a, marker = (:hexagon, 2, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-A")
p2 = scatter( Pdg_b, marker = (:hexagon, 2, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-B")
p3 = scatter( Pdg_c, marker = (:hexagon, 2, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-C")

plot(p1,p2,p3,
        layout=(3,1),
        size=(600,500),
        xlabel="bus",
        ylabel="voltage(p.u.)",
        xlims=(0,130),
        xticks=0:1:130)


## Qdg plot
        Qdg_a = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
        Qdg_b = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
        Qdg_c = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)

        for bus in BUS_SET[area]
                Qdg_a[bus] = :a in BUS_PHS_SET[area][bus] ? value(Qdg[bus,:a]) : NaN
                Qdg_b[bus] = :b in BUS_PHS_SET[area][bus] ? value(Qdg[bus,:b])  : NaN
                Qdg_c[bus] = :c in BUS_PHS_SET[area][bus] ? value(Qdg[bus,:c])  : NaN
        end

        p1 = scatter( Qdg_a, marker = (:hexagon, 2, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-A")
        p2 = scatter( Qdg_b, marker = (:hexagon, 2, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-B")
        p3 = scatter( Qdg_c, marker = (:hexagon, 2, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-C")

        plot(p1,p2,p3,
                layout=(3,1),
                size=(600,500),
                xlabel="bus",
                ylabel="voltage(p.u.)",
                xlims=(0,130),
                xticks=0:1:130)


Qdg_a_new = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Qdg_b_new = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Qdg_c_new = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
for bus in BUS_SET[area]
        Qdg_a_new[bus] =  :a in BUS_PHS_SET[area][bus] ? value(Qdg[bus,:a]) : 0
        Qdg_b_new[bus] =  :b in BUS_PHS_SET[area][bus] ? value(Qdg[bus,:b]) : 0
        Qdg_c_new[bus] =  :c in BUS_PHS_SET[area][bus] ? value(Qdg[bus,:c]) : 0
end
Qdg_total = sum(Qdg_a_new + Qdg_b_new + Qdg_c_new)*(1e3*sbase)

##
#=
Pbranch_a = Array{Tuple{Int64, Int64},2}(undef,length(BRANCH_SET["area_0"]),1)
Pbranch_b = Array{Tuple{Int64, Int64},2}(undef,length(BRANCH_SET["area_0"]),1)
Pbranch_c = Array{Tuple{Int64, Int64},2}(undef,length(BRANCH_SET["area_0"]),1)
for (i,j) in BRANCH_SET[area]
        Pbranch_a[(i,j)] = :a in BRANCH_PHS_SET[area][(i,j)] ? Pbranch[(i,j),:a] : NaN
        Pbranch_b[(i,j)] = :b in BRANCH_PHS_SET[area][(i,j)] ? Pbranch[(i,j),:b]  : NaN
        Pbranch_c[(i,j)] = :c in BRANCH_PHS_SET[area][(i,j)] ? Pbranch[(i,j),:c]  : NaN
end
=#
=#
## Getting voltages
Vcent_a = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Vcent_b = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Vcent_c = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)


for bus in BUS_SET[area]
        Vcent_a[bus] = :a in BUS_PHS_SET[area][bus] ? V[(bus,:a)] : NaN
        Vcent_b[bus] = :b in BUS_PHS_SET[area][bus] ? V[(bus,:b)] : NaN
        Vcent_c[bus] = :c in BUS_PHS_SET[area][bus] ? V[(bus,:c)] : NaN
end


##Plotting
p1 = scatter( Vcent_a, marker = (:hexagon, 2, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-A")
p2 = scatter( Vcent_b, marker = (:hexagon, 2, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-B")
p3 = scatter( Vcent_c, marker = (:hexagon, 2, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-C")

plot(p1,p2,p3,
        layout=(3,1),
        size=(600,500),
        xlabel="bus",
        ylabel="voltage(p.u.)",
        xlims=(0,130),
        xticks=0:1:130)
