function read_network_file(filename)
    cd("/Users/samirsim/Desktop/Smart-Grid-Project/smart-grid-ns3/ns-3.41/config/18bus_ori")
    # Open file to be read
    xf = XLSX.readxlsx(filename)

    EXCELSHEET = Dict()

    # Read series component data
    EXCELSHEET["Parameters"] = xf["Parameters"][:][1:end,:];
    EXCELSHEET["Lines"] = xf["Lines"][:][2:end,:];
    EXCELSHEET["Regulators"] = xf["Regulators"][:][2:end,:];
    EXCELSHEET["Transformers"] = xf["Transformers"][:][2:end,:];
    EXCELSHEET["Switches"] = xf["Switches"][:][2:end,:];
    EXCELSHEET["Config"] = xf["Config"][:][2:end,:];

    # Read shunt component data
    EXCELSHEET["Loads"] = xf["Loads"][:][2:end,:];
    EXCELSHEET["FXcaps"] = xf["FXcaps"][:][2:end,:];
    EXCELSHEET["Generators"] = xf["Generators"][:][2:end,:];
    EXCELSHEET["DG"] = xf["DG"][:][2:end,:];

    EXCELSHEET["area_0"] = xf["area_0"][:][2:end,:];
    EXCELSHEET["area_1"] = xf["area_1"][:][2:end,:];
    EXCELSHEET["area_2"] = xf["area_2"][:][2:end,:];
    

   return EXCELSHEET

end
