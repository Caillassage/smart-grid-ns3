clear, close all, clc
vcent = readmatrix("vprof_cent.csv");
vcent_noVVO = readmatrix("vprof_cent_noVVO.csv");


fontsize = 13;
linewidth = 1.2;

figure
subplot(3,1,1)

plot(vcent(:,1), 'ro', 'LineWidth',1.5),hold on
plot(vcent_noVVO(:,1), 'b+', 'LineWidth',1.5)

%ylim([0.95 1.05])
xlim([0 131])

ylabel('Voltage (p.u.)','FontSize',15,'FontWeight','bold')
xlabel('Bus','FontSize',15,'FontWeight','bold')
title('(a)')
lgd = legend('With VVO','Without VVO','Interpreter','latex');
lgd.FontName = 'Times';
lgd.FontSize = fontsize;
%lgd.Location = 'North'; % <-- Legend placement with tiled layout
lgd.Position = [0.469408595567495,0.95289063088297,0.110529688400568,0.0382572606985];
lgd.NumColumns = 5;
set(gca, 'Linewidth', linewidth)
set(gca, 'FontName', 'Times')
set(gca, 'FontSize', fontsize)

subplot(3,1,2)

plot(vcent(:,2), 'ro', 'LineWidth',1.5),hold on
plot(vcent_noVVO(:,2), 'b+', 'LineWidth',1.5)


%ylim([0.95 1.05])
xlim([0 131])

ylabel('Voltage (p.u.)','FontSize',15,'FontWeight','bold')
xlabel('Bus','FontSize',15,'FontWeight','bold')
title('(b)')
set(gca, 'Linewidth', linewidth)
set(gca, 'FontName', 'Times')
set(gca, 'FontSize', fontsize)


subplot(3,1,3)

plot(vcent(:,3), 'ro', 'LineWidth',1.5),hold on
plot(vcent_noVVO(:,3), 'b+', 'LineWidth',1.5)

%ylim([0.95 1.05])
xlim([0 131])

ylabel('Voltage (p.u.)','FontSize',15,'FontWeight','bold')
xlabel('Bus','FontSize',15,'FontWeight','bold')
title('(c)')

set(gca, 'Linewidth', linewidth)
set(gca, 'FontName', 'Times')
set(gca, 'FontSize', fontsize)
set(gcf, 'Position', [883,134,1378,1205] );
