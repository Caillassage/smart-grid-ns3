clear, close all, clc

vcent = readmatrix("vprof_cent.csv");
vpt1 = readmatrix("vprof_rho_0.1.csv");
v1 = readmatrix("vprof_rho_1.csv");
v10 = readmatrix("vprof_rho_10.csv");
v30 = readmatrix("vprof_rho_30.csv");
v50 = readmatrix("vprof_rho_50.csv");
v100 = readmatrix("vprof_rho_100.csv");

fontsize = 20;
linewidth = 1.2;

figure
subplot(3,1,1)

plot(vcent(:,1), 'ro', 'LineWidth',1.5),hold on
plot(vpt1(:,1), 'ks', 'LineWidth',1.5)
plot(v1(:,1), 'b+', 'LineWidth',1.5)
plot(v10(:,1), 'g+', 'LineWidth',1.5)
plot(v30(:,1), 'c+', 'LineWidth',1.5)
plot(v50(:,1), 'k+', 'LineWidth',1.5)
plot(v100(:,1), 'md', 'LineWidth',1.5)

%ylim([0.95 1.05])
xlim([0 131])

ylabel('$|V_i^a|$','FontSize',fontsize,'Interpreter','latex')
xlabel('Bus','FontSize',fontsize)
title('(a) Phase a')
lgd = legend('Centralized' ,'Distributed $\rho=0.1$','Distributed $\rho=1$','Distributed $\rho=10$','Distributed $\rho=30$','Distributed $\rho=50$','Distributed $\rho=100$','Interpreter','latex')
lgd.FontName = 'Times';
lgd.FontSize = fontsize;
%lgd.Location = 'North'; % <-- Legend placement with tiled layout
%lgd.Position = [0.469408595567495,0.95289063088297,0.110529688400568,0.0382572606985];
lgd.NumColumns = 4;
set(gca, 'Linewidth', linewidth)
set(gca, 'FontName', 'Times')
set(gca, 'FontSize', fontsize)

subplot(3,1,2)

plot(vcent(:,2), 'ro', 'LineWidth',1.5),hold on
plot(vpt1(:,2), 'ks', 'LineWidth',1.5)
plot(v1(:,2), 'b+', 'LineWidth',1.5)
plot(v10(:,2), 'g+', 'LineWidth',1.5)
plot(v30(:,2), 'c+', 'LineWidth',1.5)
plot(v50(:,2), 'k+', 'LineWidth',1.5)
plot(v100(:,2), 'md', 'LineWidth',1.5)

%ylim([0.95 1.05])
xlim([0 131])

ylabel('$|V_i^b|$','FontSize',fontsize,'Interpreter','latex')
xlabel('Bus','FontSize',fontsize)
title('(b) Phase b')
set(gca, 'Linewidth', linewidth)
set(gca, 'FontName', 'Times')
set(gca, 'FontSize', fontsize)


subplot(3,1,3)

plot(vcent(:,3), 'ro', 'LineWidth',1.5),hold on
plot(vpt1(:,3), 'ks', 'LineWidth',1.5)
plot(v1(:,3), 'b+', 'LineWidth',1.5)
plot(v10(:,3), 'g+', 'LineWidth',1.5)
plot(v30(:,3), 'c+', 'LineWidth',1.5)
plot(v50(:,3), 'k+', 'LineWidth',1.5)
plot(v100(:,3), 'md', 'LineWidth',1.5)

%ylim([0.95 1.05])
xlim([0 131])

ylabel('$|V_i^c|$','FontSize',fontsize,'Interpreter','latex')
xlabel('Bus','FontSize',fontsize)
title('(c) Phase c')

set(gca, 'Linewidth', linewidth)
set(gca, 'FontName', 'Times')
set(gca, 'FontSize', fontsize)
set(gcf, 'Position', [883,134,1378,1205] );


%% error
max(max((abs(vcent-v10)./vcent)*100))