clear, clc
load('branch_org.mat')
bus_temp = unique( union( unique(branch_org(:,1)), unique(branch_org(:,2))) );


busidx=[];
for i=1:130
    busidx(i) = find(bus_temp == bus_temp(i));
end

fbus_new=[];
tbus_new=[];
for i=1:129
    fbus_new(i) = find( bus_temp == branch_org(i,1));
    tbus_new(i) = find( bus_temp == branch_org(i,2));
end

branchnew = [fbus_new', tbus_new'];

branch_org_new = [branch_org, branchnew];
save('branch_org_new.mat', 'branch_org_new');

busidx=busidx';
bus_org_new = [bus_temp, busidx];
save('bus_org_new.mat', 'bus_org_new');