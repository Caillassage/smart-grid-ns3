function make_bounding_branch_set( SUPER_SET )

    _BRANCH_SET = SUPER_SET["BRANCH_SET"]
    _BUS_SET = SUPER_SET["BUS_SET"]
    _TBUS_SET = SUPER_SET["TBUS_SET"]

    _INBRANCH_SET = Dict()
    _OUTBRANCH_SET = Dict()

    for j in _TBUS_SET

        _INBRANCH_SET[j] = [(i,j) for i in _BUS_SET if (i,j) in _BRANCH_SET]
        _OUTBRANCH_SET[j] = [(j,k) for k in _BUS_SET if (j,k) in _BRANCH_SET]

    end

    return _INBRANCH_SET, _OUTBRANCH_SET

end
