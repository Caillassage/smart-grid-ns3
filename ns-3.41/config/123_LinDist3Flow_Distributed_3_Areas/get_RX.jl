function get_RX(NETWORK)

    params = get_params(NETWORK)
    zbase = params["zbase"]

    CONFIG = get_line_configs(NETWORK)
#     REGCONFIG = get_reg_configs(NETWORK)
    R11=1; R12=2; R13=3; R22=4; R23=5; R33=6; # based on [R] array indexing
    X11=1; X12=2; X13=3; X22=4; X23=5; X33=6; # based on [R] array indexing

    R = Dict()
    X = Dict()
    BRANCH_PHS_SET = Dict()

    for k in 1:size(NETWORK["Lines_new"],1)

        fbus = NETWORK["Lines_new"][k,1]
        tbus = NETWORK["Lines_new"][k,2]
        len = NETWORK["Lines_new"][k,3]*0.000189394 # converted to miles
        cnfg = NETWORK["Lines_new"][k,4]


        R[(fbus,tbus),(:a,:a)] = CONFIG[cnfg]["R"][R11]*len/zbase
        R[(fbus,tbus),(:a,:b)] = CONFIG[cnfg]["R"][R12]*len/zbase
        R[(fbus,tbus),(:a,:c)] = CONFIG[cnfg]["R"][R13]*len/zbase
        R[(fbus,tbus),(:b,:b)] = CONFIG[cnfg]["R"][R22]*len/zbase
        R[(fbus,tbus),(:b,:c)] = CONFIG[cnfg]["R"][R23]*len/zbase
        R[(fbus,tbus),(:c,:c)] = CONFIG[cnfg]["R"][R33]*len/zbase

        X[(fbus,tbus),(:a,:a)] = CONFIG[cnfg]["X"][X11]*len/zbase
        X[(fbus,tbus),(:a,:b)] = CONFIG[cnfg]["X"][X12]*len/zbase
        X[(fbus,tbus),(:a,:c)] = CONFIG[cnfg]["X"][X13]*len/zbase
        X[(fbus,tbus),(:b,:b)] = CONFIG[cnfg]["X"][X22]*len/zbase
        X[(fbus,tbus),(:b,:c)] = CONFIG[cnfg]["X"][X23]*len/zbase
        X[(fbus,tbus),(:c,:c)] = CONFIG[cnfg]["X"][X33]*len/zbase


        BRANCH_PHS_SET[(fbus,tbus)] = CONFIG[cnfg]["phs"]


    end


    for k in 1:size(NETWORK["Transformers_new"],1)

        fbus = NETWORK["Transformers_new"][k,1]
        tbus = NETWORK["Transformers_new"][k,2]
        len = NETWORK["Transformers_new"][k,3]*0.000189394 # converted to miles
        cnfg = NETWORK["Transformers_new"][k,4]


        R[(fbus,tbus),(:a,:a)] = CONFIG[cnfg]["R"][R11]*len/zbase
        R[(fbus,tbus),(:a,:b)] = CONFIG[cnfg]["R"][R12]*len/zbase
        R[(fbus,tbus),(:a,:c)] = CONFIG[cnfg]["R"][R13]*len/zbase
        R[(fbus,tbus),(:b,:b)] = CONFIG[cnfg]["R"][R22]*len/zbase
        R[(fbus,tbus),(:b,:c)] = CONFIG[cnfg]["R"][R23]*len/zbase
        R[(fbus,tbus),(:c,:c)] = CONFIG[cnfg]["R"][R33]*len/zbase

        X[(fbus,tbus),(:a,:a)] = CONFIG[cnfg]["X"][X11]*len/zbase
        X[(fbus,tbus),(:a,:b)] = CONFIG[cnfg]["X"][X12]*len/zbase
        X[(fbus,tbus),(:a,:c)] = CONFIG[cnfg]["X"][X13]*len/zbase
        X[(fbus,tbus),(:b,:b)] = CONFIG[cnfg]["X"][X22]*len/zbase
        X[(fbus,tbus),(:b,:c)] = CONFIG[cnfg]["X"][X23]*len/zbase
        X[(fbus,tbus),(:c,:c)] = CONFIG[cnfg]["X"][X33]*len/zbase


        BRANCH_PHS_SET[(fbus,tbus)] = CONFIG[cnfg]["phs"]


    end


    for k in 1:size(NETWORK["Switches_new"],1)

        fbus = NETWORK["Switches_new"][k,1]
        tbus = NETWORK["Switches_new"][k,2]
        len = NETWORK["Switches_new"][k,3]*0.000189394 # converted to miles
        cnfg = NETWORK["Switches_new"][k,4]


        R[(fbus,tbus),(:a,:a)] = CONFIG[cnfg]["R"][R11]*len/zbase
        R[(fbus,tbus),(:a,:b)] = CONFIG[cnfg]["R"][R12]*len/zbase
        R[(fbus,tbus),(:a,:c)] = CONFIG[cnfg]["R"][R13]*len/zbase
        R[(fbus,tbus),(:b,:b)] = CONFIG[cnfg]["R"][R22]*len/zbase
        R[(fbus,tbus),(:b,:c)] = CONFIG[cnfg]["R"][R23]*len/zbase
        R[(fbus,tbus),(:c,:c)] = CONFIG[cnfg]["R"][R33]*len/zbase

        X[(fbus,tbus),(:a,:a)] = CONFIG[cnfg]["X"][X11]*len/zbase
        X[(fbus,tbus),(:a,:b)] = CONFIG[cnfg]["X"][X12]*len/zbase
        X[(fbus,tbus),(:a,:c)] = CONFIG[cnfg]["X"][X13]*len/zbase
        X[(fbus,tbus),(:b,:b)] = CONFIG[cnfg]["X"][X22]*len/zbase
        X[(fbus,tbus),(:b,:c)] = CONFIG[cnfg]["X"][X23]*len/zbase
        X[(fbus,tbus),(:c,:c)] = CONFIG[cnfg]["X"][X33]*len/zbase


        BRANCH_PHS_SET[(fbus,tbus)] = CONFIG[cnfg]["phs"]


    end



    for k in 1:size(NETWORK["Regulators_new"],1)

        fbus = NETWORK["Regulators_new"][k,1]
        tbus = NETWORK["Regulators_new"][k,2]
        len = NETWORK["Regulators_new"][k,3]*0.000189394 # converted to miles
        cnfg = NETWORK["Regulators_new"][k,4]


        R[(fbus,tbus),(:a,:a)] = CONFIG[cnfg]["R"][R11]*len/zbase
        R[(fbus,tbus),(:a,:b)] = CONFIG[cnfg]["R"][R12]*len/zbase
        R[(fbus,tbus),(:a,:c)] = CONFIG[cnfg]["R"][R13]*len/zbase
        R[(fbus,tbus),(:b,:b)] = CONFIG[cnfg]["R"][R22]*len/zbase
        R[(fbus,tbus),(:b,:c)] = CONFIG[cnfg]["R"][R23]*len/zbase
        R[(fbus,tbus),(:c,:c)] = CONFIG[cnfg]["R"][R33]*len/zbase

#         R[(fbus,tbus),(:a,:a)] = CONFIG[cnfg]["R"][R11]*len/zbase
#         R[(fbus,tbus),(:a,:b)] = CONFIG[cnfg]["R"][R12]*len/zbase
#         R[(fbus,tbus),(:a,:c)] = CONFIG[cnfg]["R"][R13]*len/zbase
#         R[(fbus,tbus),(:b,:a)] = CONFIG[cnfg]["R"][R12]*len/zbase
#         R[(fbus,tbus),(:b,:b)] = CONFIG[cnfg]["R"][R22]*len/zbase
#         R[(fbus,tbus),(:b,:c)] = CONFIG[cnfg]["R"][R23]*len/zbase
#         R[(fbus,tbus),(:c,:a)] = CONFIG[cnfg]["R"][R13]*len/zbase
#         R[(fbus,tbus),(:c,:b)] = CONFIG[cnfg]["R"][R23]*len/zbase
#         R[(fbus,tbus),(:c,:c)] = CONFIG[cnfg]["R"][R33]*len/zbase

        X[(fbus,tbus),(:a,:a)] = CONFIG[cnfg]["X"][X11]*len/zbase
        X[(fbus,tbus),(:a,:b)] = CONFIG[cnfg]["X"][X12]*len/zbase
        X[(fbus,tbus),(:a,:c)] = CONFIG[cnfg]["X"][X13]*len/zbase
        X[(fbus,tbus),(:b,:b)] = CONFIG[cnfg]["X"][X22]*len/zbase
        X[(fbus,tbus),(:b,:c)] = CONFIG[cnfg]["X"][X23]*len/zbase
        X[(fbus,tbus),(:c,:c)] = CONFIG[cnfg]["X"][X33]*len/zbase

#         X[(fbus,tbus),(:a,:a)] = CONFIG[cnfg]["X"][X11]*len/zbase
#         X[(fbus,tbus),(:a,:b)] = CONFIG[cnfg]["X"][X12]*len/zbase
#         X[(fbus,tbus),(:a,:c)] = CONFIG[cnfg]["X"][X13]*len/zbase
#         X[(fbus,tbus),(:b,:a)] = CONFIG[cnfg]["X"][X12]*len/zbase
#         X[(fbus,tbus),(:b,:b)] = CONFIG[cnfg]["X"][X22]*len/zbase
#         X[(fbus,tbus),(:b,:c)] = CONFIG[cnfg]["X"][X23]*len/zbase
#         X[(fbus,tbus),(:c,:a)] = CONFIG[cnfg]["X"][X13]*len/zbase
#         X[(fbus,tbus),(:c,:b)] = CONFIG[cnfg]["X"][X23]*len/zbase
#         X[(fbus,tbus),(:c,:c)] = CONFIG[cnfg]["X"][X33]*len/zbase


#         BRANCH_PHS_SET[(fbus,tbus)] = REGCONFIG[cnfg]["phs"]
        BRANCH_PHS_SET[(fbus,tbus)] = CONFIG[cnfg]["phs"]


    end

    return R,X

end
