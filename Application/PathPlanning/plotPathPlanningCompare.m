function plotPathPlanningCompare(env, routes, routeNames, cfg, savePath)
%PLOTPATHPLANNINGCOMPARE Side-by-side route comparison (incl. original baseline).

nPlot = numel(routeNames);
nCol = min(3, nPlot);
nRow = ceil(nPlot / nCol);

figure('Name', 'Route comparison', 'Color', 'w', ...
    'Position', [80, 80, 320 * nCol, 280 * nRow]);

colors = [0.47, 0.67, 0.19; 0.85, 0.33, 0.10; 0.55, 0.55, 0.55; ...
          0.85, 0.10, 0.10; 0.00, 0.45, 0.74];

for k = 1:nPlot
    subplot(nRow, nCol, k);
    hold on;
    name = routeNames{k};
    route = routes.(name);

    plot(env.allCoords(:, 1), env.allCoords(:, 2), 'o', ...
        'Color', [0.85, 0.33, 0.10], 'MarkerSize', 5);
    plot(env.depot(1), env.depot(2), 'ks', 'MarkerFaceColor', 'y', 'MarkerSize', 7);

    if ~isempty(route.coords)
        pts = [env.depot; route.coords; env.depot];
        c = colors(min(k, size(colors, 1)), :);
        plot(pts(:, 1), pts(:, 2), '-', 'Color', c, 'LineWidth', 1.6);
    end

    axis equal;
    pad = 5;
    xlim([0 - pad, cfg.mapSize + pad]);
    ylim([0 - pad, cfg.mapSize + pad]);
    grid on;

    if isfield(route, 'label')
        algLabel = route.label;
    else
        algLabel = name;
    end
    title(sprintf('%s\nf1+f2=%.1f', algLabel, route.total));
    xlabel('x');
    ylabel('y');
    hold off;
end

sgtitle('Route comparison (final environment)');

if nargin >= 5 && ~isempty(savePath)
    saveas(gcf, savePath);
end

end
