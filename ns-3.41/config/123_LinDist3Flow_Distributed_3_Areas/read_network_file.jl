function read_network_file(filename)
    cd("./config/123_LinDist3Flow_Distributed_3_Areas")
    # Open file to be read
    xf = XLSX.readxlsx(filename)

    EXCELSHEET = Dict()

    # Read series component data
    EXCELSHEET["Parameters"] = xf["Parameters"][:][1:end,:];
    EXCELSHEET["Lines_new"] = xf["Lines_new"][:][2:end,:];
    EXCELSHEET["Regulators_new"] = xf["Regulators_new"][:][2:end,:];
    EXCELSHEET["Transformers_new"] = xf["Transformers_new"][:][2:end,:];
    EXCELSHEET["Switches_new"] = xf["Switches_new"][:][2:end,:];
    EXCELSHEET["Config"] = xf["Config"][:][2:end,:];

    # Read shunt component data
    EXCELSHEET["Loads"] = xf["Loads"][:][2:end,:];
    EXCELSHEET["FXcaps"] = xf["FXcaps"][:][2:end,:];
    EXCELSHEET["DG"] = xf["DG"][:][2:end,:];

    EXCELSHEET["area_0"] = xf["area_0"][:][2:end,:];
    EXCELSHEET["area_1"] = xf["area_1"][:][2:end,:];
    EXCELSHEET["area_2"] = xf["area_2"][:][2:end,:];
    EXCELSHEET["area_3"] = xf["area_3"][:][2:end,:];

    # Read overlapping branches
    EXCELSHEET["overlapping"] = xf["overlapping"][:][2:end,:];

   return EXCELSHEET

end
