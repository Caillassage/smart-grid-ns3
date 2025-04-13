clear, clc, close all

load('branch_org_new.mat')
load('bus_org_new')
node_connection = str2double(branch_org_new(:,3:4));
G= digraph(node_connection(:,1),node_connection(:,2));


%% Plotting

screen = get(0,'screensize');

h{1} = plot(G,'Layout','force');
text(-8.136331831140547,0.622178717475555,'sourcebus')
set(gcf,'Position',[screen(3)-screen(3)/3.5 screen(4)-screen(4)/2 560 420])

figure
h{2} = plot(G,'Layout','layered');
text(48.1005345283065,294.8320912539195,'sourcebus')
set(gcf,'Position',[screen(3)-screen(3)/3.5 screen(4)-screen(4)/1.15 560 420])

% intermediate node curation
n1 = [25; sort(nearest(G,25, Inf, 'Method', 'unweighted'))]; % from substation
n2 = sort(nearest(G,21, Inf, 'Method', 'unweighted')); % from switch node 135 --> 35

%original bus numbering of n2
for i=1:size(n2,1)
    a(i) = find(bus_org_new(:,2) == string(n2(i)));
    t=bus_org_new(:,1);
    org(i)=t(a(i));
end
n2_org_new=[org', n2]
%n3 = sort(nearest(G,557, Inf, 'Method', 'unweighted')); % from VR node 557 --> 564
%n4 = sort(nearest(G,1062, Inf, 'Method', 'unweighted')); % from VR node 1062 --> 1065


for i=1:2
    
    highlight(h{i},n1,'NodeColor','b')
    highlight(h{i},25,'MarkerSize',10,'NodeColor','b')

    highlight(h{i},n2,'NodeColor','r')

      
end

%% Area connections - Overlapping branches
%  area 1 - 2 => 18-135 : original node numbering : changed
%  area 1 - 2 => 33-21 : my node numbering : changed
%overlaping_branch = [1,2,33,21 ]; 

%  area 1 - 2 => 135-35 : original node numbering
%  area 1 - 2 => 21-56 : my node numbering
overlaping_branch = [1,2,21,56 ]; 

% main node curation for each area
nodes1 = setdiff(n1,n2);
nodes2 = n2;


frombuslist = node_connection(:,1);
tobuslist = node_connection(:,2);

%% AREA - 1
branch1=[];


for i = 1:length(nodes1)
    
    idx = find( nodes1(i) == frombuslist );
    branch1 = [branch1; [frombuslist(idx) tobuslist(idx)] ];
    
end

% cleaning the inter area connections
idx = find(and( 21 == branch1(:,1), 56 == branch1(:,2) ));
branch1(idx,:) = [];


%% AREA - 2
branch2 = [];

for i = 1:length(nodes2)
    
    idx = find( nodes2(i) == frombuslist );
    branch2 = [branch2; [frombuslist(idx) tobuslist(idx)] ];
    
end

%% mapping branches of subsystems to their original node numbering
branch1_str = string(branch1);
branch2_str = string(branch2);

for i = 1:size(branch1,1)
    br(i) = branch1_str(i,1); 
    bus_new(i) = find(bus_org_new(:,2) == br(i));
    org_bus = bus_org_new(:,1);
    t_fr(i) = org_bus(bus_new(i),1);
end

for i = 1:size(branch1,1)
    br(i) = branch1_str(i,2); 
    bus_new(i) = find(bus_org_new(:,2) == br(i));
    org_bus = bus_org_new(:,1);
    t_to(i) = org_bus(bus_new(i),1);
end

area1_org_new = [ t_fr', t_to', branch1_str];

t_fr=[];
t_to=[];
for i = 1:size(branch2,1)
    br(i) = branch2_str(i,1); 
    bus_new(i) = find(bus_org_new(:,2) == br(i));
    org_bus = bus_org_new(:,1);
    t_fr(i) = org_bus(bus_new(i),1);
end

for i = 1:size(branch2,1)
    br(i) = branch2_str(i,2); 
    bus_new(i) = find(bus_org_new(:,2) == br(i));
    org_bus = bus_org_new(:,1);
    t_to(i) = org_bus(bus_new(i),1);
end

area2_org_new = [ t_fr', t_to', branch2_str];
%}
%% make sub-GRAPHS

g1 = digraph(string(branch1(:,1)),string(branch1(:,2)));
g2 = digraph(string(branch2(:,1)),string(branch2(:,2)));

