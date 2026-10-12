function route = extractPathRoute(res, Problem, T_parameter, group, envIdx)
%EXTRACTPATHROUTE Best compromise route at one environment.

global APP_TASK_ENVS
if isempty(APP_TASK_ENVS)
    error('extractPathRoute:NoEnv', 'Call setPathPlanningEnv(envs) first.');
end

envIdx = min(max(envIdx, 1), numel(res));
t = 1 / T_parameter(group, 1) * (envIdx - 1);
nObj = 2;
if isfield(Problem, 'NObj')
    nObj = Problem.NObj;
end

route = emptyRoute();
if isempty(res{envIdx}) || ~isstruct(res{envIdx})
    return;
end

[bestX, bestF] = pickBestSolution(res{envIdx}, Problem, t, nObj);
if isempty(bestX)
    return;
end

env = APP_TASK_ENVS{envIdx};
route = buildRouteStruct(bestX, bestF, env);

end

function route = buildRouteStruct(x, f, env)
route = struct();
route.x = x(:);
route.order = decodePathPlanning(route.x, env.nTasks);
route.coords = env.allCoords(route.order, :);
route.depot = env.depot;
route.f1 = f(1);
route.f2 = f(2);
route.total = f(1) + f(2);

end

function [bestX, bestF] = pickBestSolution(resT, Problem, t, nObj)
bestX = [];
bestF = [];
bestSum = inf;

if isfield(resT, 'PopX') && ~isempty(resT.PopX)
    [x, f] = pickFromPop(resT.PopX, Problem, t, nObj);
    if ~isempty(x) && sum(f) < bestSum
        bestSum = sum(f);
        bestX = x;
        bestF = f;
    end
end

if isfield(resT, 'Pareto') && isstruct(resT.Pareto) && isfield(resT.Pareto, 'X') ...
        && ~isempty(resT.Pareto.X)
    [x, f] = pickFromPop(resT.Pareto.X, Problem, t, nObj);
    if ~isempty(x) && sum(f) < bestSum
        bestSum = sum(f);
        bestX = x;
        bestF = f;
    end
end
end

function [bestX, bestF] = pickFromPop(X, Problem, t, nObj)
bestX = [];
bestF = [];
X = double(X);
if isempty(X)
    return;
end
if size(X, 1) < size(X, 2)
    X = X';
end
nSol = size(X, 2);
sums = inf(1, nSol);
F = nan(nObj, nSol);
for i = 1:nSol
    f = Problem.FObj(X(:, i), t);
    F(:, i) = f(:);
    sums(i) = sum(F(:, i));
end
[bestSum, idx] = min(sums);
bestX = X(:, idx);
bestF = F(:, idx);

end

function route = emptyRoute()
route = struct('x', [], 'order', [], 'coords', [], 'depot', [], ...
    'f1', NaN, 'f2', NaN, 'total', NaN);

end
