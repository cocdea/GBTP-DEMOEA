function plotPathPlanning(env, x, cfg, titleStr)
%PLOTPATHPLANNING 2-D task points and routing path.

if nargin < 4
    titleStr = 'Dynamic Path Planning';
end

figure('Name', titleStr, 'Color', 'w');
hold on;
plot(env.allCoords(:, 1), env.allCoords(:, 2), 'o', ...
    'Color', [0.85, 0.33, 0.10], 'MarkerSize', 6, 'DisplayName', 'Task points');
plot(env.depot(1), env.depot(2), 'ks', 'MarkerFaceColor', 'y', ...
    'MarkerSize', 8, 'DisplayName', 'Depot');

if ~isempty(x)
    order = decodePathPlanning(x, env.nTasks);
    coords = env.allCoords(order, :);
    pts = [env.depot; coords; env.depot];
    plot(pts(:, 1), pts(:, 2), '-', 'Color', [0.00, 0.45, 0.74], ...
        'LineWidth', 1.8, 'DisplayName', 'Route');
end

axis equal;
pad = 5;
xlim([0 - pad, cfg.mapSize + pad]);
ylim([0 - pad, cfg.mapSize + pad]);
grid on;
legend('Location', 'best');
title(titleStr);
xlabel('x');
ylabel('y');
hold off;

end
