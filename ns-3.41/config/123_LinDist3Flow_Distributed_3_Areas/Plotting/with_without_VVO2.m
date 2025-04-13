clear, close all, clc
vcent = readmatrix("vprof_cent.csv");
vcent_noVVO = readmatrix("vprof_cent_noVVO.csv");


fontsize = 20;
linewidth = 1.2;

figure
subplot(2,1,1)


plot(vcent_noVVO(:,1), 'ro', 'LineWidth',1.5) ,hold on
plot(vcent_noVVO(:,2), 'b+', 'LineWidth',1.5) 
plot(vcent_noVVO(:,3), 'gd', 'LineWidth',1.5) 
plot(1.05*ones(130,1), 'k--', 'LineWidth',1.5) 
ylim([0.96 1.07])
xlim([0 131])

ylabel('$|V_i^\psi|$ (p.u.)','FontSize',fontsize,'Interpreter','latex')
xlabel('Bus','FontSize',fontsize)
title('(a) Voltage magnitudes without VVO')
lgd = legend('$|V_i^a|$','$|V_i^b|$', '$|V_i^c|$', '$\overline{V}$','Interpreter','latex');
lgd.FontName = 'Times';
lgd.FontSize = fontsize;
%lgd.Location = 'North'; % <-- Legend placement with tiled layout
lgd.Position = [0.469408595567495,0.95289063088297,0.110529688400568,0.0382572606985];
lgd.NumColumns = 4;
set(gca, 'Linewidth', linewidth)
set(gca, 'FontName', 'Times')
set(gca, 'FontSize', fontsize)

subplot(2,1,2)

plot(vcent(:,1), 'ro', 'LineWidth',1.5) ,hold on
plot(vcent(:,2), 'b+', 'LineWidth',1.5) 
plot(vcent(:,3), 'gd', 'LineWidth',1.5) 
plot(1.05*ones(130,1), 'k--', 'LineWidth',1.5) 

ylim([0.96 1.07])
xlim([0 131])

ylabel('$|V_i^\psi|$ (p.u.)','FontSize',50,'Interpreter','latex')
xlabel('Bus','FontSize',fontsize)
title('(b) Voltage magnitudes with VVO')
set(gca, 'Linewidth', linewidth)
set(gca, 'FontName', 'Times')
set(gca, 'FontSize', fontsize)

set(gcf, 'Position', [883,134,1378,1205] );
