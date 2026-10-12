function [objs, extra] = evaluatePathPlanning(x, t, cfg)
%EVALUATEPATHPLANNING Minimize total length (f1) and max segment (f2).

global APP_TASK_ENVS

if isempty(APP_TASK_ENVS)
    error('APP_TASK_ENVS not set. Call setPathPlanningEnv first.');
end

envIdx = timeToEnvIndex(t, numel(APP_TASK_ENVS));
env = APP_TASK_ENVS{envIdx};

order = decodePathPlanning(x, env.nTasks);
coords = env.allCoords(order, :);

f1 = tourLength(coords, env.depot);
f2 = maxSegmentLength(coords, env.depot);
objs = [f1; f2];

if nargout > 1
    extra.order = order;
    extra.coords = coords;
    extra.envIdx = envIdx;
end

end
function idx = timeToEnvIndex(t, nEnv)
idx = round(t) + 1;
idx = min(max(idx, 1), nEnv);
end
