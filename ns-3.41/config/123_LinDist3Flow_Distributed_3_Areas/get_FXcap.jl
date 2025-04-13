function get_FXcap(EXCELSHEET)

    params = get_params(EXCELSHEET)
    sbase = params["sbase"]

    Qcap = Dict()

    for k in 1:size(EXCELSHEET["FXcaps"],1)
        bus = Int(EXCELSHEET["FXcaps"][k,1])

        Qcap[bus,:a] = EXCELSHEET["FXcaps"][k,2]/(1e3*sbase)
        Qcap[bus,:b] = EXCELSHEET["FXcaps"][k,3]/(1e3*sbase)
        Qcap[bus,:c] = EXCELSHEET["FXcaps"][k,4]/(1e3*sbase)
        
    end

    for bus in BUS_SET["area_0"]
        if !(bus in EXCELSHEET["FXcaps"][:,1])

        Qcap[bus,:a] = 0.0
        Qcap[bus,:b] = 0.0
        Qcap[bus,:c] = 0.0

        end
    end

    return Qcap

end
