function get_line_configs(EXCELSHEET)

R_range = 2:7
X_range = 8:13
B_range = 14:19
R11=2; R22=5; R33=7

config = Dict()
linelength = Dict()

for (k,label) in enumerate(EXCELSHEET["Config"][:,1])

    case1 = (EXCELSHEET["Config"][k,R11]!=0.0) & (EXCELSHEET["Config"][k,R22]!=0.0) & (EXCELSHEET["Config"][k,R33]!=0.0)
    case2 = (EXCELSHEET["Config"][k,R11]!=0.0) & (EXCELSHEET["Config"][k,R22]!=0.0) & (EXCELSHEET["Config"][k,R33]==0.0)
    case3 = (EXCELSHEET["Config"][k,R11]!=0.0) & (EXCELSHEET["Config"][k,R22]==0.0) & (EXCELSHEET["Config"][k,R33]!=0.0)
    case4 = (EXCELSHEET["Config"][k,R11]==0.0) & (EXCELSHEET["Config"][k,R22]!=0.0) & (EXCELSHEET["Config"][k,R33]!=0.0)
    case5 = (EXCELSHEET["Config"][k,R11]!=0.0) & (EXCELSHEET["Config"][k,R22]==0.0) & (EXCELSHEET["Config"][k,R33]==0.0)
    case6 = (EXCELSHEET["Config"][k,R11]==0.0) & (EXCELSHEET["Config"][k,R22]!=0.0) & (EXCELSHEET["Config"][k,R33]==0.0)
    case7 = (EXCELSHEET["Config"][k,R11]==0.0) & (EXCELSHEET["Config"][k,R22]==0.0) & (EXCELSHEET["Config"][k,R33]!=0.0)

if case1
   phasing = Set([:a,:b,:c])
elseif case2
   phasing = Set([:a,:b])
elseif case3
   phasing = Set([:a,:c])
elseif case4
   phasing = Set([:b,:c])
elseif case5
   phasing = Set([:a])
elseif case6
   phasing = Set([:b])
elseif case7
   phasing = Set([:c])
else
   phasing = "N/A"
end

config[label] = Dict( "R"=> EXCELSHEET["Config"][k,R_range],
                      "X"=> EXCELSHEET["Config"][k,X_range],
                      "phs"=> phasing)
end

return config

end
