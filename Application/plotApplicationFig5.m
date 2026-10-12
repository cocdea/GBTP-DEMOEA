function plotApplicationFig5(pofCT, pofNP, changeRatio, savePath)
%PLOTAPPLICATIONFIG5 Paper Fig.5 style: UAV (x) vs UGV (y) final POS.

if nargin < 3 || isempty(changeRatio)
    changeRatio = 0.10;
end

figure('Name', 'Fig.5 Application POS', 'Color', 'w', 'Position', [120, 120, 560, 420]);
hold on;

if ~isempty(pofCT)
    scatter(pofCT(2, :), pofCT(1, :), 28, 'r', 'filled', 'DisplayName', 'CT-DMOEA');
end
if ~isempty(pofNP)
    scatter(pofNP(2, :), pofNP(1, :), 36, 's', ...
        'MarkerEdgeColor', [0.15, 0.35, 0.75], ...
        'MarkerFaceColor', [0.55, 0.70, 0.95], ...
        'LineWidth', 0.8, 'DisplayName', 'C-MOEA/D');
end

grid on;
box on;
xlabel('UAV');
ylabel('UGV');
title(sprintf('Final POSs (change ratio = %.0f%%)', changeRatio * 100));
legend('Location', 'northeast');
hold off;

if nargin >= 4 && ~isempty(savePath)
    saveas(gcf, savePath);
end

end
