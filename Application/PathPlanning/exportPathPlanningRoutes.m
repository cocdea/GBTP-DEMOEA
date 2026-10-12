function exportPathPlanningRoutes(rootDir, envs, resRR, resDT, resCT, resGBCT, ...
    ProblemDT, ProblemCT, ProblemGBCT, cfg, T_parameter, group, envIdx)
%EXPORTPATHPLANNINGROUTES Plot and save routes for comparison.

if nargin < 13 || isempty(envIdx)
    envIdx = cfg.nEnv;
end

setPathPlanningEnv(envs);
lastEnv = envs{envIdx};
firstEnv = envs{1};

routes = struct();
routes.baseline = baselineIndexRoute(lastEnv, cfg);
routes.baseline_env1 = baselineIndexRoute(firstEnv, cfg);
routes.rr = extractPathRoute(resRR, ProblemDT, T_parameter, group, envIdx);
routes.dt = extractPathRoute(resDT, ProblemDT, T_parameter, group, envIdx);
routes.ct = extractPathRoute(resCT, ProblemCT, T_parameter, group, envIdx);
routes.gbct = extractPathRoute(resGBCT, ProblemGBCT, T_parameter, group, envIdx);

routeFields = {'baseline', 'rr', 'dt', 'ct', 'gbct'};
displayNames = {'Original (index order)', 'RR', 'DT', 'CT-DMOEA', 'GBCT-DMOEA'};

plotPathPlanningCompare(lastEnv, routes, routeFields, cfg, ...
    fullfile(rootDir, 'pathplan_routes_compare.png'));
plotPathPlanningOverlay(lastEnv, routes, routeFields, displayNames, cfg, ...
    fullfile(rootDir, 'pathplan_routes_overlay.png'));

plotPathPlanning(firstEnv, [], cfg, 'Original task points (environment 1)');
saveas(gcf, fullfile(rootDir, 'pathplan_tasks_env1.png'));

plotPathPlanning(firstEnv, routes.baseline_env1.x, cfg, ...
    'Original route: index order (environment 1)');
saveas(gcf, fullfile(rootDir, 'pathplan_route_original_env1.png'));

writePathPlanningRoutes(rootDir, routes, routeFields, displayNames, envIdx);

fprintf('  pathplan_routes_compare.png, pathplan_routes_overlay.png\n');
fprintf('  pathplan_route_original_env1.png, pathplan_routes/ (txt)\n');

end
