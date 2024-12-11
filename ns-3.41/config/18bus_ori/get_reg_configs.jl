function get_reg_configs(EXCELSHEET)

R_range = 2:10
X_range = 11:19
B_range = []
R11=2; R22=6; R33=10;

regconfig = Dict()

for (k,label) in enumerate(EXCELSHEET["RegConfig"][:,1])

    case1 = (EXCELSHEET["RegConfig"][k,R11]!=0.0) & (EXCELSHEET["Config"][k,R22]!=0.0) & (EXCELSHEET["Config"][k,R33]!=0.0)
    case2 = (EXCELSHEET["RegConfig"][k,R11]!=0.0) & (EXCELSHEET["Config"][k,R22]!=0.0) & (EXCELSHEET["Config"][k,R33]==0.0)
    case3 = (EXCELSHEET["RegConfig"][k,R11]!=0.0) & (EXCELSHEET["Config"][k,R22]==0.0) & (EXCELSHEET["Config"][k,R33]!=0.0)
    case4 = (EXCELSHEET["RegConfig"][k,R11]==0.0) & (EXCELSHEET["Config"][k,R22]!=0.0) & (EXCELSHEET["Config"][k,R33]!=0.0)
    case5 = (EXCELSHEET["RegConfig"][k,R11]!=0.0) & (EXCELSHEET["Config"][k,R22]==0.0) & (EXCELSHEET["Config"][k,R33]==0.0)
    case6 = (EXCELSHEET["RegConfig"][k,R11]==0.0) & (EXCELSHEET["Config"][k,R22]!=0.0) & (EXCELSHEET["Config"][k,R33]==0.0)
    case7 = (EXCELSHEET["RegConfig"][k,R11]==0.0) & (EXCELSHEET["Config"][k,R22]==0.0) & (EXCELSHEET["Config"][k,R33]!=0.0)

phasing = Set()

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

regconfig[label] = Dict( "R"=> EXCELSHEET["RegConfig"][k,R_range],
                      "X"=> EXCELSHEET["RegConfig"][k,X_range],
                      "phs"=> phasing)
end

return regconfig

end
