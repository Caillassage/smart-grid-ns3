## Centralized solution
#Run MAIN0.jl
using Ipopt
area = "area_0"

opf = Model(Ipopt.Optimizer)

#Branch variables def
@variable(opf, Pbranch[(i,j)=BRANCH_SET[area], phs=BRANCH_PHS_SET[area][(i,j)]])
@variable(opf, Qbranch[(i,j)=BRANCH_SET[area], phs=BRANCH_PHS_SET[area][(i,j)]])

#Bus variables def
@variable(opf, v[i=BUS_SET[area], phs=BUS_PHS_SET[area][i]])
@variable(opf, Pgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
@variable(opf, Qgen[i=slack_bus, phs=BUS_PHS_SET[area][i]])
@variable(opf, Qdg[i=BUS_SET[area], phs=BUS_PHS_SET[area][i]])

## slackbus constraint
@constraint(opf, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
                Pgen[i,phs] == sum(Pbranch[(i,j),phs] for j in BUS_SET[area] if (i,j) in BRANCH_SET[area]) )
@constraint(opf, [ i=slack_bus, phs=BUS_PHS_SET[area][i] ],
                Qgen[i,phs] == sum(Qbranch[(i,j),phs] for j in BUS_SET[area] if (i,j) in BRANCH_SET[area]) )


#Power balance
@constraint(opf, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                sum(Pbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                == Pload[j,phs] - PDGmax[j,phs]  + sum(Pbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))

@constraint(opf, [ j=TBUS_SET[area], phs=BUS_PHS_SET[area][j] ],
                sum(Qbranch[(i,j),phs] for (i,j) in INBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(i,j)] )
                == Qload[j,phs] - Qcap[j,phs] - Qdg[j,phs] + sum(Qbranch[(j,k),phs] for (j,k) in OUTBRANCH_SET[area][j] if phs in BRANCH_PHS_SET[area][(j,k)] ))

#Voltage drop
@constraint(opf, [(i,j)=BRANCH_SET[area], phs=BRANCH_PHS_SET[area][(i,j)]],
                        v[i,phs] == v[j,phs] - sum( M_P[(i,j),(phs,gmm)]*Pbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] )
                                             - sum( M_Q[(i,j),(phs,gmm)]*Qbranch[(i,j),gmm] for gmm in BRANCH_PHS_SET[area][(i,j)] ) )

#Voltage limits
@constraint(opf, [i=slack_bus, phs=BUS_PHS_SET[area][slack_bus]], v[i,phs] == 1.0*1.0)
@constraint(opf, [i in setdiff(BUS_SET[area],slack_bus), phs=BUS_PHS_SET[area][i]], 0.95^2 <= v[i,phs] <= 1.05^2)

#DG constraint
@constraint(opf, [ i=BUS_SET[area], phs=BUS_PHS_SET[area][i] ], -QDGmax[i,phs] <= Qdg[i,phs] <= QDGmax[i,phs])

@expression(opf, Total_gen, sum(Pgen[i,phs] for i = slack_bus, phs=BUS_PHS_SET[area][i]))
#@objective(opf, Min, Total_gen)

# Voltage Deviation w/ absolute value
Vpos = 1.0
@variable(opf, aux[i=BUS_SET[area],phs=BUS_PHS_SET[area][i] ] >= 0)
@constraint(opf, [i=BUS_SET[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= v[i,phs] - Vpos )
@constraint(opf, [i=BUS_SET[area],phs=BUS_PHS_SET[area][i] ], aux[i,phs] .>= Vpos - v[i,phs] )
@expression(opf, Total_vdev, sum(aux[i, phs] for i=BUS_SET[area],phs=BUS_PHS_SET[area][i]) )

@objective(opf, Min, Total_vdev)

optimize!(opf)

V = Dict( (i,phs) => sqrt( value(v[i,phs])) for i in BUS_SET[area] for phs in BUS_PHS_SET[area][i])
Pgen = Dict( (i,phs) => ( value(Pgen[i,phs])) for i in slack_bus for phs in BUS_PHS_SET[area][i])
Qgen = Dict( (i,phs) => ( value(Qgen[i,phs])) for i in slack_bus for phs in BUS_PHS_SET[area][i])
Pbranch = Dict( ((i,j),phs) => ( value(Pbranch[(i,j),phs])) for (i,j) in BRANCH_SET[area] for phs in BRANCH_PHS_SET[area][(i,j)])
Qbranch = Dict( ((i,j),phs) => ( value(Qbranch[(i,j),phs])) for (i,j) in BRANCH_SET[area] for phs in BRANCH_PHS_SET[area][(i,j)])
Qdg = Dict( (i,phs) => ( value(Qdg[i,phs])) for i in BUS_SET[area]  for phs in BUS_PHS_SET[area][i])

Qdg_a = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Qdg_b = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)
Qdg_c = Array{Float64,2}(undef,length(BUS_SET["area_0"]),1)

for bus in BUS_SET[area]
        Qdg_a[bus] = :a in BUS_PHS_SET[area][bus] ? value(Qdg[bus,:a]) : NaN
        Qdg_b[bus] = :b in BUS_PHS_SET[area][bus] ? value(Qdg[bus,:b])  : NaN
        Qdg_c[bus] = :c in BUS_PHS_SET[area][bus] ? value(Qdg[bus,:c])  : NaN
end

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
p1 = scatter( Vcent_a, marker = (:hexagon, 5, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-A")
p2 = scatter( Vcent_b, marker = (:hexagon, 5, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-B")
p3 = scatter( Vcent_c, marker = (:hexagon, 5, 0.6, :red, stroke(1,0.1,:red,:dot)), label="centralized", title="Phs-C")

plot(p1,p2,p3,
        layout=(3,1),
        size=(600,500),
        xlabel="bus",
        ylabel="voltage(p.u.)",
        xlims=(0,19),
        xticks=0:1:19)
