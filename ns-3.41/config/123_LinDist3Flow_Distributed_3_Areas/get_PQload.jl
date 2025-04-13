function get_PQload(EXCELSHEET)

    params = get_params(EXCELSHEET)
    sbase = params["sbase"]

    _SUBSET = make_subsets(EXCELSHEET)
    _BUS_SET = _SUBSET["DG_SET"]

    Pload = Dict()
    Qload = Dict()

    for k in 1:size(EXCELSHEET["Loads"],1)

        bus = Int( EXCELSHEET["Loads"][k,1] )

        Pload[bus,:a] = EXCELSHEET["Loads"][k,3]/(1e3*sbase)
        Pload[bus,:b] = EXCELSHEET["Loads"][k,4]/(1e3*sbase)
        Pload[bus,:c] = EXCELSHEET["Loads"][k,5]/(1e3*sbase)

        Qload[bus,:a] = EXCELSHEET["Loads"][k,6]/(1e3*sbase)
        Qload[bus,:b] = EXCELSHEET["Loads"][k,7]/(1e3*sbase)
        Qload[bus,:c] = EXCELSHEET["Loads"][k,8]/(1e3*sbase)

    end


    for bus in BUS_SET["area_0"]

        if !(bus in EXCELSHEET["Loads"][:,1])

        Pload[bus,:a] = 0.0
        Pload[bus,:b] = 0.0
        Pload[bus,:c] = 0.0

        Qload[bus,:a] = 0.0
        Qload[bus,:b] = 0.0
        Qload[bus,:c] = 0.0

        end

    end

return Pload, Qload

end
