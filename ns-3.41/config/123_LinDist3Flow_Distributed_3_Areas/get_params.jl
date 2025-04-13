function get_params(EXCELSHEET)

    # Read shunt component data
    params = Dict()

    params["slackbus_idx"] = Int(EXCELSHEET["Parameters"][1,2])
    params["sbase"] = EXCELSHEET["Parameters"][2,2]
    params["vbase"] = EXCELSHEET["Parameters"][3,2]
    params["zbase"] = EXCELSHEET["Parameters"][4,2]
    return params

end
