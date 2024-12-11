function make_subsets(EXCELSHEET)

    line = EXCELSHEET["Lines"]
    reg = EXCELSHEET["Regulators"]
    xfmr = EXCELSHEET["Transformers"]
    switch = EXCELSHEET["Switches"]
    load = EXCELSHEET["Loads"]
    fxcap = EXCELSHEET["FXcaps"]
    gen = EXCELSHEET["Generators"]
    dg = EXCELSHEET["DG"]


    # Constructing the sets
    _SUBSET = Dict()
    _SUBSET["LINE_SET"] = sort([(Int64(line[k,1]),Int64(line[k,2])) for k in 1:size(line,1)])
    _SUBSET["REG_SET"] = sort([(Int64(reg[k,1]),Int64(reg[k,2])) for k in 1:size(reg,1)])
    _SUBSET["XFMR_SET"] = sort([(Int64(xfmr[k,1]),Int64(xfmr[k,2])) for k in 1:size(xfmr,1)])
    _SUBSET["SWITCH_SET"] = sort([(Int64(switch[k,1]),Int64(switch[k,2])) for k in 1:size(switch,1)])
    _SUBSET["LOAD_SET"] = sort([Int64(load[k,1]) for k in 1:size(load,1)])
    _SUBSET["FXCAP_SET"] = sort([Int64(fxcap[k,1]) for k in 1:size(fxcap,1)])
    _SUBSET["GEN_SET"] = sort([Int64(gen[k,1]) for k in 1:size(gen,1)])
    _SUBSET["DG_SET"] = sort([Int64(dg[k,1]) for k in 1:size(dg,1)])

    return _SUBSET

end
