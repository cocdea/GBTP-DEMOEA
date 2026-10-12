function plotPathPlanningInitQ(results, algNames, algFields, cfg, savePath)
%PLOTPATHPLANNINGINITQ Initial population quality after each environment change.

nEnv = cfg.nEnv;
if isfield(results, algFields{1})
    nEnv = size(results.(algFields{1}).envInitQ, 2);
end
nTrans = max(nEnv - 1, 0);
if nTrans < 1
    return;
end

curve = nan(numel(algFields), nTrans);
for k = 1:numel(algFields)
    q = results.(algFields{k}).envInitQ;
    if isempty(q) || size(q, 2) < 2
        continue;
    end
    qTrans = q(:, 2:min(nEnv, size(q, 2)));
    if size(qTrans, 2) > nTrans
        qTrans = qTrans(:, 1:nTrans);
    end
    curve(k, 1:size(qTrans, 2)) = mean(qTrans, 1, 'omitnan');
end

figure('Name', 'Initial population quality', 'Color', 'w', ...
    'Position', [120, 120, 720, 420]);
hold on;

colors = [0.85, 0.33, 0.10; 0.55, 0.55, 0.55; 0.85, 0.10, 0.10];
for k = 1:numel(algFields)
    if all(isnan(curve(k, :)))
        continue;
    end
    plot(2:(1 + nTrans), curve(k, :), '-o', 'LineWidth', 1.4, ...
        'Color', colors(min(k, size(colors, 1)), :), 'DisplayName', algNames{k});
end

grid on;
box on;
xlabel('Environment index (after change)');
ylabel('Initial population quality (\Sigma f_i, mean)');
title('Transferred initialization quality over environments');
legend('Location', 'best');
hold off;

if nargin >= 5 && ~isempty(savePath)
    saveas(gcf, savePath);
end

end
