function get_RX(EXCELSHEET)

    params = get_params(EXCELSHEET)
    zbase = params["zbase"]

    CONFIG = get_line_configs(EXCELSHEET)

    R11=1; R12=2; R13=3; R22=4; R23=5; R33=6;
    X11=1; X12=2; X13=3; X22=4; X23=5; X33=6;

    R = Dict()
    X = Dict()
    _BRANCH_PHS_SET = Dict()

    for k in 1:size(EXCELSHEET["Lines"],1)

        fbus = Int(EXCELSHEET["Lines"][k,1])
        tbus = Int(EXCELSHEET["Lines"][k,2])
        len = EXCELSHEET["Lines"][k,3]*0.000189394 #converting to miles
        cnfg = EXCELSHEET["Lines"][k,4]

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

        _BRANCH_PHS_SET[(fbus,tbus)] = CONFIG[cnfg]["phs"]

    end


    for k in 1:size(EXCELSHEET["Regulators"],1)

        fbus = Int(EXCELSHEET["Regulators"][k,1])
        tbus = Int(EXCELSHEET["Regulators"][k,2])
        len = EXCELSHEET["Regulators"][k,3]*0.000189394 #converting to miles
        cnfg = EXCELSHEET["Regulators"][k,4]

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

        _BRANCH_PHS_SET[(fbus,tbus)] = CONFIG[cnfg]["phs"]

    end

    return R,X
end
