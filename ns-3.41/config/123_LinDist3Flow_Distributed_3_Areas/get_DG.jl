function get_DG(EXCELSHEET)

    _SUBSET = make_subsets(EXCELSHEET)
    _DG_SET = _SUBSET["DG_SET"]

    params = get_params(EXCELSHEET)
    sbase = params["sbase"]

    PDGmax = Dict()
    QDGmax = Dict()
    SDGmax = Dict()

    Srated(P)=1.1*P

    for k in 1:size(EXCELSHEET["DG"],1)
        bus = Int(EXCELSHEET["DG"][k,1])

        PDGmax[bus,:a] = EXCELSHEET["DG"][k,2]/(1e3*sbase)
        PDGmax[bus,:b] = EXCELSHEET["DG"][k,3]/(1e3*sbase)
        PDGmax[bus,:c] = EXCELSHEET["DG"][k,4]/(1e3*sbase)

        QDGmax[bus,:a] = sqrt( Srated(PDGmax[bus,:a])^2 - PDGmax[bus,:a]^2 )
        QDGmax[bus,:b] = sqrt( Srated(PDGmax[bus,:b])^2 - PDGmax[bus,:b]^2 )
        QDGmax[bus,:c] = sqrt( Srated(PDGmax[bus,:c])^2 - PDGmax[bus,:c]^2 )

        SDGmax[bus,:a] = Srated(PDGmax[bus,:a])
        SDGmax[bus,:b] = Srated(PDGmax[bus,:b])
        SDGmax[bus,:c] = Srated(PDGmax[bus,:c])

    end

    for bus in BUS_SET["area_0"]

        if !(bus in EXCELSHEET["DG"][:,1])

            PDGmax[bus,:a] = 0.0
            PDGmax[bus,:b] = 0.0
            PDGmax[bus,:c] = 0.0

            QDGmax[bus,:a] = 0.0
            QDGmax[bus,:b] = 0.0
            QDGmax[bus,:c] = 0.0

            SDGmax[bus,:a] = 0.0
            SDGmax[bus,:b] = 0.0
            SDGmax[bus,:c] = 0.0

        end

    end

    return PDGmax, QDGmax, SDGmax

end
