function metrics = extractPerEnvMetrics(res, nObj, Problem, T_parameter, group)
%EXTRACTPERENVMETRICS Compromise solution quality at every environment.

if nargin < 3
    Problem = [];
end
if nargin < 4
    T_parameter = [];
    group = 1;
end

nEnv = numel(res);
metrics.f1 = nan(nEnv, 1);
metrics.f2 = nan(nEnv, 1);
metrics.total = nan(nEnv, 1);
metrics.initQ = nan(nEnv, 1);

for T = 1:nEnv
    t = envIndexToTime(T, T_parameter, group);
    F = extractEnvParetoF(res{T}, nObj, Problem, t);

    if ~isempty(F) && ~all(isnan(F(:)))
        [~, idx] = min(sum(F, 1));
        metrics.f1(T) = F(1, idx);
        metrics.f2(T) = F(2, idx);
        metrics.total(T) = F(1, idx) + F(2, idx);
    end

    if isfield(res{T}, 'initPopMeanSum') && ~isnan(res{T}.initPopMeanSum)
        metrics.initQ(T) = res{T}.initPopMeanSum;
    end
end

metrics.meanTotal = mean(metrics.total, 'omitnan');
metrics.meanInitQ = mean(metrics.initQ(2:end), 'omitnan');

end

function t = envIndexToTime(T, T_parameter, group)
if nargin >= 2 && ~isempty(T_parameter)
    t = 1 / T_parameter(group, 1) * (T - 1);
else
    t = T - 1;
end
end

function F = extractEnvParetoF(resT, nObj, Problem, t)
F = [];

if isfield(resT, 'Pareto')
    F = paretoToMatrix(resT.Pareto, nObj, Problem, t);
end

if (isempty(F) || all(isnan(F(:)))) && isfield(resT, 'POF_iter') && ~isempty(resT.POF_iter)
    pofEnd = resT.POF_iter{end};
    if ~isempty(pofEnd)
        F = normalizeParetoF(pofEnd, nObj);
    end
end

if (isempty(F) || all(isnan(F(:)))) && isfield(resT, 'PopX') && ~isempty(resT.PopX) ...
        && ~isempty(Problem)
    F = objectivesFromX(resT.PopX, Problem, t, nObj);
end
end

function F = paretoToMatrix(Pareto, nObj, Problem, t)
F = [];
if isfield(Pareto, 'F') && ~isempty(Pareto.F)
    F = normalizeParetoF(Pareto.F, nObj);
end

if (isempty(F) || all(isnan(F(:)))) && isfield(Pareto, 'X') && ~isempty(Pareto.X) ...
        && ~isempty(Problem)
    F = objectivesFromX(Pareto.X, Problem, t, nObj);
end
end

function F = objectivesFromX(X, Problem, t, nObj)
X = normalizePopX(X);
if isempty(X)
    F = [];
    return;
end
nSol = size(X, 2);
F = nan(nObj, nSol);
for i = 1:nSol
    f = Problem.FObj(X(:, i), t);
    F(:, i) = f(:);
end
F = F(:, all(~isnan(F), 1));
end

function X = normalizePopX(X)
X = double(X);
if isempty(X)
    return;
end
if size(X, 1) < size(X, 2)
    X = X';
end
end

function F = normalizeParetoF(F, nObj)
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

nVal = numel(F);
if mod(nVal, nObj) ~= 0
    return;
end
F = reshape(F(:)', nObj, []);
end
