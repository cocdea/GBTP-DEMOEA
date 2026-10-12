function plotPathPlanningOverlay(env, routes, routeNames, displayNames, cfg, savePath)
%PLOTPATHPLANNINGOVERLAY All routes on one map.

figure('Name', 'Route overlay', 'Color', 'w', 'Position', [100, 100, 560, 480]);
hold on;

plot(env.allCoords(:, 1), env.allCoords(:, 2), 'o', ...
    'Color', [0.85, 0.33, 0.10], 'MarkerSize', 6, 'DisplayName', 'Task points');
plot(env.depot(1), env.depot(2), 'ks', 'MarkerFaceColor', 'y', ...
    'MarkerSize', 8, 'DisplayName', 'Depot');

styles = {'-+', '-s', '-o', '-d', '--'};
for k = 1:numel(routeNames)
    route = routes.(routeNames{k});
    if isempty(route.coords)
        continue;
    end
    pts = [env.depot; route.coords; env.depot];
    lbl = displayNames{k};
    if isnan(route.total)
        leg = lbl;
    else
        leg = sprintf('%s (f1+f2=%.1f)', lbl, route.total);
    end
    plot(pts(:, 1), pts(:, 2), styles{min(k, numel(styles))}, ...
        'LineWidth', 1.5, 'DisplayName', leg);
end

axis equal;
pad = 5;
xlim([0 - pad, cfg.mapSize + pad]);
ylim([0 - pad, cfg.mapSize + pad]);
grid on;
legend('Location', 'best');
title('Route overlay (final environment)');
xlabel('x');
ylabel('y');
hold off;

if nargin >= 6 && ~isempty(savePath)
    saveas(gcf, savePath);
end

end
