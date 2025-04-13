
using JuMP,  XLSX, Plots, DataFrames, CSV, JLD2
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

filename = "123bus_W_LTC_3_Areas.xlsx"

EXCELSHEET = read_network_file(filename)
params = get_params(EXCELSHEET)
slack_bus = params["slackbus_idx"]
sbase = params["sbase"]

##make SETS
SUBSET = make_subsets(EXCELSHEET)
SUPER_SET = make_supersets(SUBSET)

AREA_SET = ["area_0", "area_1", "area_2", "area_3"]

BRANCH_SET,BUS_SET,FBUS_SET,TBUS_SET = make_BRANCH_SET(AREA_SET)

# Extended bus set
BUS_SET_ex = Dict()
BUS_SET_ex["area_1"] = sort(unique(union(BUS_SET["area_1"],[56, 94])))
BUS_SET_ex["area_2"] = sort(unique(union(BUS_SET["area_2"],[21])))
BUS_SET_ex["area_3"] = sort(unique(union(BUS_SET["area_3"],[31])))

OBRANCH_SET = Dict()
OBRANCH_SET["area_1"] = [(21,56), (31,94)]

#,(31,94)
OBRANCH_SET["area_2"] = [(21,56)]
OBRANCH_SET["area_3"] = [(31,94)]


# Extended branch set
BRANCH_SET_ex = Dict()
BRANCH_SET_ex["area_1"] = sort(union(BRANCH_SET["area_1"],OBRANCH_SET["area_1"]))
BRANCH_SET_ex["area_2"] = sort(union(BRANCH_SET["area_2"],OBRANCH_SET["area_2"]))
BRANCH_SET_ex["area_3"] = sort(union(BRANCH_SET["area_3"],OBRANCH_SET["area_3"]))

TBUS_SET["area_1"] = setdiff(TBUS_SET["area_1"],56,94)
TBUS_SET["area_2"] = union(TBUS_SET["area_2"],56)
TBUS_SET["area_3"] = union(TBUS_SET["area_3"],94)

REG_SET = Dict()
REG_SET["area_0"] = SUBSET["REG_SET"]

DG_SET = Dict()
DG_SET["area_0"] = SUBSET["DG_SET"]


BRANCH_PHS_SET = Dict()
BRANCH_PHS_SET["area_0"] = make_branch_phs_set(EXCELSHEET)
BRANCH_PHS_SET["area_1"] = BRANCH_PHS_SET["area_0"]
BRANCH_PHS_SET["area_2"] = BRANCH_PHS_SET["area_0"]
BRANCH_PHS_SET["area_3"] = BRANCH_PHS_SET["area_0"]

BUS_PHS_SET = Dict()
BUS_PHS_SET["area_0"] = make_bus_phs_set(EXCELSHEET)
BUS_PHS_SET["area_1"] = BUS_PHS_SET["area_0"]
BUS_PHS_SET["area_2"] = BUS_PHS_SET["area_0"]
BUS_PHS_SET["area_3"] = BUS_PHS_SET["area_0"]

INBRANCH_SET = Dict()
OUTBRANCH_SET = Dict()

INBRANCH_SET["area_0"], OUTBRANCH_SET["area_0"] = make_bounding_branch_set(SUPER_SET)
INBRANCH_SET["area_1"] = INBRANCH_SET["area_0"]
INBRANCH_SET["area_2"] = INBRANCH_SET["area_0"]
INBRANCH_SET["area_3"] = INBRANCH_SET["area_0"]
OUTBRANCH_SET["area_1"] = OUTBRANCH_SET["area_0"]
OUTBRANCH_SET["area_2"] = OUTBRANCH_SET["area_0"]
OUTBRANCH_SET["area_3"] = OUTBRANCH_SET["area_0"]


## Get DATA
R,X = get_RX(EXCELSHEET)
Pload,Qload = get_PQload(EXCELSHEET)
Qcap = get_FXcap(EXCELSHEET)
PDGmax, QDGmax, SDGmax = get_DG(EXCELSHEET)
M_P, M_Q = get_MPMQ(R,X,BRANCH_SET["area_0"])
