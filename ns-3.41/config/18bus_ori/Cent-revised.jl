using Ipopt, JuMP,  XLSX, Plots, DataFrames, CSV, JLD2
include("read_network_file.jl")
include("get_params.jl")
include("get_DG.jl")
include("get_FXcap.jl")
include("get_line_configs.jl")
include("get_MPMQ.jl")
include("get_PQload.jl")
include("get_reg_configs.jl")
include("get_RX.jl")
include("make_branch_phs_set.jl")
include("make_bus_phs_set.jl")
include("make_subsets.jl")
include("make_supersets.jl")
include("make_bounding_branch_set.jl")
include("make_BRANCH_SET.jl")

#compiling the data extracted from the excel file to be sent to each raspberry pi
filename = "networkfile.xlsx"
EXCELSHEET = read_network_file(filename)
params = get_params(EXCELSHEET)
slack_bus = params["slackbus_idx"]
sbase = params["sbase"]

##make SETS
SUBSET = make_subsets(EXCELSHEET)
SUPER_SET = make_supersets(SUBSET)


AREA_SET = ["area_0", "area_1", "area_2"]

BRANCH_SET,BUS_SET,FBUS_SET,TBUS_SET = make_BRANCH_SET(AREA_SET)

INBRANCH_SET = Dict()
OUTBRANCH_SET = Dict()
# Extended bus set
BUS_SET_ex = Dict()
BUS_SET_ex["area_1"] = sort(unique(union(BUS_SET["area_1"],[4])))
BUS_SET_ex_ONE = BUS_SET_ex["area_1"]
BUS_SET_ex["area_2"] = sort(unique(union(BUS_SET["area_2"],[3])))
BUS_SET_ex_TWO = BUS_SET_ex["area_2"]

OBRANCH_SET = Dict()
OBRANCH_SET["area_1"] = [(3,4)]
OBRANCH_SET["area_2"] = [(3,4)]


# Extended branch set
BRANCH_SET_ex = Dict()
BRANCH_SET_ex["area_1"] = sort(union(BRANCH_SET["area_1"],OBRANCH_SET["area_1"]))
BRANCH_SET_ex_ONE = BRANCH_SET_ex["area_1"]
BRANCH_SET_ex["area_2"] = sort(union(BRANCH_SET["area_2"],OBRANCH_SET["area_2"]))
BRANCH_SET_ex_TWO = BRANCH_SET_ex["area_2"]

TBUS_SET_ONE = TBUS_SET["area_1"]
TBUS_SET["area_2"] = union(TBUS_SET["area_2"],4)
TBUS_SET_TWO = TBUS_SET["area_2"]



BRANCH_PHS_SET = Dict()
BRANCH_PHS_SET["area_0"] = make_branch_phs_set(EXCELSHEET)
BRANCH_PHS_SET["area_1"] = BRANCH_PHS_SET["area_0"]
BRANCH_PHS_SET_ONE = BRANCH_PHS_SET["area_1"]
BRANCH_PHS_SET["area_2"] = BRANCH_PHS_SET["area_0"]
BRANCH_PHS_SET_TWO = BRANCH_PHS_SET["area_2"]

BUS_PHS_SET = Dict()
BUS_PHS_SET["area_0"] = make_bus_phs_set(EXCELSHEET)
BUS_PHS_SET["area_1"] = BUS_PHS_SET["area_0"]
BUS_PHS_SET_ONE = BUS_PHS_SET["area_1"]
BUS_PHS_SET["area_2"] = BUS_PHS_SET["area_0"]
BUS_PHS_SET_TWO = BUS_PHS_SET["area_2"]

INBRANCH_SET["area_0"], OUTBRANCH_SET["area_0"] = make_bounding_branch_set(SUPER_SET)
INBRANCH_SET["area_1"] = INBRANCH_SET["area_0"]
INBRANCH_SET_ONE = INBRANCH_SET["area_1"]
INBRANCH_SET["area_2"] = INBRANCH_SET["area_0"]
INBRANCH_SET_TWO = INBRANCH_SET["area_2"]
OUTBRANCH_SET["area_1"] = OUTBRANCH_SET["area_0"]
OUTBRANCH_SET_ONE = OUTBRANCH_SET["area_1"]
OUTBRANCH_SET["area_2"] = OUTBRANCH_SET["area_0"]
OUTBRANCH_SET_TWO = OUTBRANCH_SET["area_2"]


## Get DATA
R,X = get_RX(EXCELSHEET)
Pload,Qload = get_PQload(EXCELSHEET)
Qcap = get_FXcap(EXCELSHEET)
PDGmax, QDGmax = get_DG(EXCELSHEET)
M_P, M_Q = get_MPMQ(R,X,BRANCH_SET["area_0"])
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
