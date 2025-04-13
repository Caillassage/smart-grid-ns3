function make_branch_phs_set(NETWORK)

    BRANCH_PHS_SET = Dict()
    CONFIG = get_line_configs(NETWORK)

    for k in 1:size(NETWORK["Lines_new"],1)

        fbus = NETWORK["Lines_new"][k,1]
        tbus = NETWORK["Lines_new"][k,2]
        cnfg = NETWORK["Lines_new"][k,4]

        BRANCH_PHS_SET[(fbus,tbus)] = CONFIG[cnfg]["phs"]


    end

    for k in 1:size(NETWORK["Regulators_new"],1)

        fbus = NETWORK["Regulators_new"][k,1]
        tbus = NETWORK["Regulators_new"][k,2]
        cnfg = NETWORK["Regulators_new"][k,4]

        BRANCH_PHS_SET[(fbus,tbus)] = CONFIG[cnfg]["phs"]


    end


    for k in 1:size(NETWORK["Transformers_new"],1)

        fbus = NETWORK["Transformers_new"][k,1]
        tbus = NETWORK["Transformers_new"][k,2]
        cnfg = NETWORK["Transformers_new"][k,4]

        BRANCH_PHS_SET[(fbus,tbus)] = CONFIG[cnfg]["phs"]


    end


    for k in 1:size(NETWORK["Switches_new"],1)

        fbus = NETWORK["Switches_new"][k,1]
        tbus = NETWORK["Switches_new"][k,2]
        cnfg = NETWORK["Switches_new"][k,4]

        BRANCH_PHS_SET[(fbus,tbus)] = CONFIG[cnfg]["phs"]


    end


    return BRANCH_PHS_SET

end
