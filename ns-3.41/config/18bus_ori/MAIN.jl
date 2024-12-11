#clearconsole()
using JuMP,  XLSX, Plots, DataFrames, CSV
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

#filename = "Distributed OPF/Three_phase/networkfile.xlsx"
filename = "networkfile.xlsx"
EXCELSHEET = read_network_file(filename)
params = get_params(EXCELSHEET)
slack_bus = params["slackbus_idx"]
sbase = params["sbase"]

##make SETS
SUBSET = make_subsets(EXCELSHEET)
SUPER_SET = make_supersets(SUBSET)

BRANCH_SET = Dict()
BUS_SET = Dict()

BRANCH_PHS_SET = Dict()
BUS_PHS_SET = Dict()

INBRANCH_SET = Dict()
OUTBRANCH_SET = Dict()

TBUS_SET = Dict()

BUS_SET_ex = Dict()
BRANCH_SET_ex = Dict()

BUS_SET["area_0"] = SUPER_SET["BUS_SET"]
BUS_SET["area_1"] = [1,2,3]
BUS_SET["area_2"] = [4,5,6,7,8,9,10,11,12,13,14,15,16,17,18]

BUS_SET_ex["area_1"] = [1,2,3,4]
BUS_SET_ex["area_2"] = [3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18]

TBUS_SET["area_0"] = SUPER_SET["TBUS_SET"]
TBUS_SET["area_1"] = [2,3]
TBUS_SET["area_2"] = [4,5,6,7,8,9,10,11,12,13,14,15,16,17,18]

BRANCH_SET["area_0"] = SUPER_SET["BRANCH_SET"]
BRANCH_SET["area_1"] = SUPER_SET["BRANCH_SET"][1:2]
BRANCH_SET["area_2"] = SUPER_SET["BRANCH_SET"][3:end]

OBRANCH_SET = [(3,4)] #overlapping branch set

BRANCH_SET_ex["area_1"] = sort(union(SUPER_SET["BRANCH_SET"][1:2],OBRANCH_SET))
BRANCH_SET_ex["area_2"] = sort(union(SUPER_SET["BRANCH_SET"][3:end],OBRANCH_SET))

BRANCH_PHS_SET["area_0"] = make_branch_phs_set(EXCELSHEET)
BRANCH_PHS_SET["area_1"] = BRANCH_PHS_SET["area_0"]
BRANCH_PHS_SET["area_2"] = BRANCH_PHS_SET["area_0"]

BUS_PHS_SET["area_0"] = make_bus_phs_set(EXCELSHEET)
BUS_PHS_SET["area_1"] = BUS_PHS_SET["area_0"]
BUS_PHS_SET["area_2"] = BUS_PHS_SET["area_0"]

INBRANCH_SET["area_0"], OUTBRANCH_SET["area_0"] = make_bounding_branch_set(SUPER_SET)
INBRANCH_SET["area_1"] = INBRANCH_SET["area_0"]
INBRANCH_SET["area_2"] = INBRANCH_SET["area_0"]
OUTBRANCH_SET["area_1"] = OUTBRANCH_SET["area_0"]
OUTBRANCH_SET["area_2"] = OUTBRANCH_SET["area_0"]

## Get DATA
R,X = get_RX(EXCELSHEET)
Pload,Qload = get_PQload(EXCELSHEET)
Qcap = get_FXcap(EXCELSHEET)
PDGmax, QDGmax = get_DG(EXCELSHEET)
M_P, M_Q = get_MPMQ(R,X,BRANCH_SET["area_0"])
