function make_BRANCH_SET(AREA_SET)


    # Make branch set
    BRANCH_SET = Dict()
    FBUS_SET = Dict()
    TBUS_SET = Dict()
    BUS_SET = Dict()

    for area in AREA_SET

        fbus = Int.(EXCELSHEET[area][:,1])
        tbus = Int.(EXCELSHEET[area][:,2])

        nbranch = length(fbus)

        # branch set
        BRANCH_SET[area] = sort([(fbus[i],tbus[i]) for i in 1:nbranch])

        # bus set
        FBUS_SET[area] = sort(unique(fbus))
        TBUS_SET[area] = sort(unique(tbus))
        BUS_SET[area] = sort(union(FBUS_SET[area],TBUS_SET[area]))


    end

    return BRANCH_SET,BUS_SET,FBUS_SET,TBUS_SET # sort(collect(BRANCH_SET), by = x->x[1])

end
