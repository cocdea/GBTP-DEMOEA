function plotApplicationPOF(pofCT, pofNP, titleStr)
%PLOTAPPLICATIONPOF Compare final POF approximations (paper Fig.5 style).

if nargin < 3
    titleStr = 'Final POF: CT-DMOEA vs C-MOEA/D (no transfer)';
end

figure('Name', 'Application POF', 'Color', 'w');
hold on;

if ~isempty(pofCT)
    scatter(pofCT(2, :), pofCT(1, :), 36, 'r', 'filled', 'DisplayName', 'CT-DMOEA');
end
if ~isempty(pofNP)
    scatter(pofNP(2, :), pofNP(1, :), 36, 's', ...
        'MarkerEdgeColor', [0.15, 0.35, 0.75], ...
        'MarkerFaceColor', [0.55, 0.70, 0.95], ...
        'LineWidth', 0.8, 'DisplayName', 'C-MOEA/D (np)');
end

grid on;
box on;
xlabel('UAV');
ylabel('UGV');
title(titleStr);
legend('Location', 'best');
hold off;

end
