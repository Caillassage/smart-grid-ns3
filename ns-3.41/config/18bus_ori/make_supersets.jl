function make_supersets( _SUBSET )

    _BRANCH_SET = union(SUBSET["LINE_SET"],SUBSET["REG_SET"], SUBSET["XFMR_SET"],SUBSET["SWITCH_SET"])

    _FBUS_LIST = [ i for (i,j) in _BRANCH_SET]
    _TBUS_LIST = [ j for (i,j) in _BRANCH_SET]

    _BUS_SET = union(_FBUS_LIST,_TBUS_LIST)

    _SUPER_SET = Dict()
    _SUPER_SET["BRANCH_SET"] = _BRANCH_SET
    _SUPER_SET["BUS_SET"] = _BUS_SET
    _SUPER_SET["FBUS_SET"] = unique(_FBUS_LIST)
    _SUPER_SET["TBUS_SET"] = unique(_TBUS_LIST)

    return _SUPER_SET

end
