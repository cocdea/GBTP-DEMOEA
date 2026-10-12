function metrics = computeEnvRoutingMetrics(res, Problem, T_parameter, group)
%COMPUTEENVROUTINGMETRICS Best compromise (min f1+f2) per environment.

global APP_TASK_ENVS
if isempty(APP_TASK_ENVS)
    error('computeEnvRoutingMetrics:NoEnv', ...
        'APP_TASK_ENVS is empty. Call setPathPlanningEnv(envs) before computing metrics.');
end

if ~iscell(res)
    error('computeEnvRoutingMetrics:InvalidRes', 'res must be a cell array, got %s.', class(res));
end

nObj = 2;
if isfield(Problem, 'NObj')
    nObj = Problem.NObj;
end

nEnv = numel(res);
metrics.f1 = nan(nEnv, 1);
metrics.f2 = nan(nEnv, 1);
metrics.total = nan(nEnv, 1);
metrics.initQ = nan(nEnv, 1);

for T = 1:nEnv
    if isempty(res{T}) || ~isstruct(res{T})
        continue;
    end

    t = 1 / T_parameter(group, 1) * (T - 1);
    best = bestFromEnvResult(res{T}, Problem, t, nObj);

    if ~isempty(best)
        metrics.f1(T) = best(1);
        metrics.f2(T) = best(2);
        metrics.total(T) = best(1) + best(2);
    end

    if isfield(res{T}, 'initPopMeanSum') && ~isnan(res{T}.initPopMeanSum)
        metrics.initQ(T) = res{T}.initPopMeanSum;
    end
end

metrics.meanTotal = mean(metrics.total, 'omitnan');
metrics.meanInitQ = mean(metrics.initQ(2:end), 'omitnan');

end

function best = bestFromEnvResult(resT, Problem, t, nObj)
best = [];
candidates = collectObjectiveSets(resT, Problem, t, nObj);

for c = 1:numel(candidates)
    F = candidates{c};
    if isempty(F) || all(isnan(F(:)))
        continue;
    end
    [~, idx] = min(sum(F, 1));
    pick = F(:, idx);
    if isempty(best) || sum(pick) < sum(best)
        best = pick;
    end
end
end

function sets = collectObjectiveSets(resT, Problem, t, nObj)
sets = {};

if isfield(resT, 'PopX') && ~isempty(resT.PopX)
    sets{end + 1} = evalPopX(resT.PopX, Problem, t, nObj); %#ok<AGROW>
end

if isfield(resT, 'Pareto') && isstruct(resT.Pareto)
    F = parseObjectiveMatrix(resT.Pareto.F, nObj);
    if isempty(F) && isfield(resT.Pareto, 'X') && ~isempty(resT.Pareto.X)
        F = evalPopX(resT.Pareto.X, Problem, t, nObj);
    end
    if ~isempty(F)
        sets{end + 1} = F; %#ok<AGROW>
    end
end

if isfield(resT, 'POF_iter') && ~isempty(resT.POF_iter)
    F = parseObjectiveMatrix(resT.POF_iter{end}, nObj);
    if ~isempty(F)
        sets{end + 1} = F; %#ok<AGROW>
    end
end
end

function F = evalPopX(X, Problem, t, nObj)
X = double(X);
if isempty(X)
    F = [];
    return;
end
if size(X, 1) < size(X, 2)
    X = X';
end
nSol = size(X, 2);
F = nan(nObj, nSol);
for i = 1:nSol
    f = Problem.FObj(X(:, i), t);
    F(:, i) = f(:);
end
F = F(:, all(~isnan(F), 1));
end

function F = parseObjectiveMatrix(F, nObj)
F = double(F);
if isempty(F)
    return;
end
if size(F, 1) == nObj && size(F, 2) ~= nObj
    return;
end
if size(F, 2) == nObj && size(F, 1) ~= nObj
    F = F';
    return;
end
if mod(numel(F), nObj) ~= 0
    F = [];
    return;
end
F = reshape(F(:)', nObj, []);
end
