function plotPathPlanningDynamicCurve(results, algNames, algFields, cfg, savePath)
%PLOTPLANNINGDYNAMICCURVE Environment index vs mean routing quality (f1+f2).

nEnv = size(results.(algFields{1}).envTotal, 2);
curve = zeros(numel(algFields), nEnv);

for k = 1:numel(algFields)
    curve(k, :) = mean(results.(algFields{k}).envTotal, 1, 'omitnan');
end

figure('Name', 'Routing quality over dynamic environments', 'Color', 'w', ...
    'Position', [100, 100, 720, 420]);
hold on;

colors = [0.47, 0.67, 0.19; 0.85, 0.33, 0.10; 0.55, 0.55, 0.55; 0.85, 0.10, 0.10];
markers = {'+', 's', 'o', 'd'};
for k = 1:numel(algFields)
    plot(1:nEnv, curve(k, :), ['-' markers{k}], 'LineWidth', 1.4, ...
        'Color', colors(k, :), 'MarkerSize', 6, 'DisplayName', algNames{k});
end

grid on;
box on;
xlabel('Environment index');
ylabel('Routing quality (f_1 + f_2)');
title('Routing quality over dynamic environments');
legend('Location', 'best');
xlim([1, nEnv]);
hold off;

if nargin >= 5 && ~isempty(savePath)
    saveas(gcf, savePath);
end

end
