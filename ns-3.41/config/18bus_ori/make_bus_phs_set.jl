function make_bus_phs_set( EXCELSHEET )

    _BUS_PHS_SET = Dict()

    _SUBSET = make_subsets(EXCELSHEET)
    _SUPER_SET = make_supersets(_SUBSET)
    _BRANCH_SET = _SUPER_SET["BRANCH_SET"]
    _BUS_SET = _SUPER_SET["BUS_SET"]
    _BRANCH_PHS_SET = make_branch_phs_set( EXCELSHEET )


    for bus in _BUS_SET

        inbound_branch = [ (i,j) for (i,j) in _BRANCH_SET if j==bus ]
        outbound_branch = [ (i,j) for (i,j) in _BRANCH_SET if i==bus ]

        brn = [ _BRANCH_PHS_SET[branch] for branch in union(inbound_branch,outbound_branch)]
        _BUS_PHS_SET[bus] = union(brn...)
    end

    return _BUS_PHS_SET

end
