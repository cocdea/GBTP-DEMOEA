function writePathPlanningRoutes(rootDir, routes, routeNames, displayNames, envIdx)
%WRITEPATHPLANNINGROUTES Export visit order and coordinates to text files.

outDir = fullfile(rootDir, 'pathplan_routes');
if ~isfolder(outDir)
    mkdir(outDir);
end

summaryFile = fullfile(outDir, sprintf('routes_env%d_summary.txt', envIdx));
fid = fopen(summaryFile, 'w');
fprintf(fid, '# Route export (environment %d)\n', envIdx);
fprintf(fid, '# Algorithm\tf1\tf2\ttotal\tvisit_order\n');

for k = 1:numel(routeNames)
    name = routeNames{k};
    route = routes.(name);
    label = displayNames{k};
    if isfield(route, 'label')
        label = route.label;
    end

    writeOneRoute(fullfile(outDir, sprintf('route_%s_env%d.txt', name, envIdx)), ...
        label, route, envIdx);
    fprintf(fid, '%s\t%.4f\t%.4f\t%.4f\t', label, route.f1, route.f2, route.total);
    if isempty(route.order)
        fprintf(fid, 'N/A\n');
    else
        fprintf(fid, '%s\n', mat2str(route.order'));
    end
end

fclose(fid);
fprintf('  Route files saved to: %s\n', outDir);

end

function writeOneRoute(filePath, label, route, envIdx)
fid = fopen(filePath, 'w');
fprintf(fid, 'Algorithm: %s\n', label);
fprintf(fid, 'Environment: %d\n', envIdx);
fprintf(fid, 'f1 (total length): %.4f\n', route.f1);
fprintf(fid, 'f2 (max segment): %.4f\n', route.f2);
fprintf(fid, 'f1 + f2: %.4f\n\n', route.total);

if isempty(route.order)
    fprintf(fid, 'No valid route.\n');
    fclose(fid);
    return;
end

fprintf(fid, 'Visit order (task index):\n');
fprintf(fid, '%d ', route.order);
fprintf(fid, '\n\n');

fprintf(fid, 'Depot (x, y):\n');
fprintf(fid, '%.4f\t%.4f\n\n', route.depot(1), route.depot(2));

fprintf(fid, 'Route coordinates (x, y):\n');
fprintf(fid, 'idx\tx\ty\n');
for i = 1:size(route.coords, 1)
    fprintf(fid, '%d\t%.4f\t%.4f\n', route.order(i), ...
        route.coords(i, 1), route.coords(i, 2));
end

fclose(fid);
end
