function plotApplicationPaths(env, bestX, cfg, titleStr)
%PLOTAPPLICATIONPATHS Draw park map and UGV/UAV routes (paper Fig.6 style).

if nargin < 4
    titleStr = 'UAV/UGV Path Planning';
end

[~, ~, ugvCoords, uavCoords] = decodeUAVUGV(bestX, env, cfg);

figure('Name', titleStr, 'Color', 'w');
hold on;

allCoords = env.allCoords;
plot(allCoords(env.uavPoolIdx, 1), allCoords(env.uavPoolIdx, 2), ...
    'o', 'Color', [0.85, 0.33, 0.10], 'MarkerSize', 5, 'DisplayName', 'UAV parks');
plot(allCoords(env.ugvIdx, 1), allCoords(env.ugvIdx, 2), ...
    'o', 'Color', [0.00, 0.65, 0.65], 'MarkerSize', 7, 'DisplayName', 'UGV parks');
plot(env.depot(1), env.depot(2), 'ks', 'MarkerFaceColor', 'y', 'MarkerSize', 8, 'DisplayName', 'Depot');

drawRoute([env.depot; ugvCoords; env.depot], [0.00, 0.45, 0.74], 'UGV route');
drawRoute([env.depot; uavCoords; env.depot], [0.47, 0.67, 0.19], 'UAV route');

axis equal;
pad = 1.5;
xlim([min(allCoords(:, 1)) - pad, max(allCoords(:, 1)) + pad]);
ylim([min(allCoords(:, 2)) - pad, max(allCoords(:, 2)) + pad]);
grid on;
legend('Location', 'bestoutside');
title(titleStr);
xlabel('x (km, local)');
ylabel('y (km, local)');
hold off;

end

function drawRoute(pts, color, label)
plot(pts(:, 1), pts(:, 2), '-', 'Color', color, 'LineWidth', 1.8, 'DisplayName', label);
end
