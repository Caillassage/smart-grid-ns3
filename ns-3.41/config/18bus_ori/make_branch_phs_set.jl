function make_branch_phs_set( EXCELSHEET )

    _BRANCH_PHS_SET = Dict()
    CONFIG = get_line_configs(EXCELSHEET)

    for k in 1:size(EXCELSHEET["Lines"],1)

        fbus = Int(EXCELSHEET["Lines"][k,1])
        tbus = Int(EXCELSHEET["Lines"][k,2])
        cnfg = EXCELSHEET["Lines"][k,4]

        _BRANCH_PHS_SET[(fbus,tbus)] = CONFIG[cnfg]["phs"]

    end

    for k in 1:size(EXCELSHEET["Regulators"],1)

        fbus = Int(EXCELSHEET["Regulators"][k,1])
        tbus = Int(EXCELSHEET["Regulators"][k,2])
        cnfg = EXCELSHEET["Regulators"][k,4]

        _BRANCH_PHS_SET[(fbus,tbus)] = CONFIG[confg]["phs"]

    end

    return _BRANCH_PHS_SET

end
