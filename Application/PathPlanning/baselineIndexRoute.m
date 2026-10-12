function route = baselineIndexRoute(env, cfg)
%BASELINEINDEXROUTE Reference route: visit tasks in index order 1..N.

if nargin < 2
    cfg = struct();
end

x = (1:env.nTasks)' / max(env.nTasks, 1);
order = decodePathPlanning(x, env.nTasks);
coords = env.allCoords(order, :);

f1 = tourLength(coords, env.depot);
f2 = maxSegmentLength(coords, env.depot);

route = struct();
route.x = x;
route.order = order;
route.coords = coords;
route.depot = env.depot;
route.f1 = f1;
route.f2 = f2;
route.total = f1 + f2;
route.label = 'Original (index order)';

end
