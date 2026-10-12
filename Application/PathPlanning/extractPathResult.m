function best = extractPathResult(res, cfg, Problem)
%EXTRACTPATHRESULT Best compromise solution from last environment.

if nargin < 3
    Problem = [];
end

lastT = res{end};
nEnv = numel(res);
t = nEnv - 1;

F = [];
if isfield(lastT, 'Pareto')
    F = paretoFromStruct(lastT.Pareto, Problem, t);
end
if (isempty(F) || all(isnan(F(:)))) && isfield(lastT, 'POF_iter') && ~isempty(lastT.POF_iter)
    F = normalizeParetoF(lastT.POF_iter{end}, 2);
end

if isempty(F) || all(isnan(F(:)))
    best = emptyBest();
    return;
end

[~, idx] = min(sum(F, 1));
best.f1 = F(1, idx);
best.f2 = F(2, idx);
best.total = best.f1 + best.f2;
best.pof = F;
if isfield(lastT, 'Pareto') && isfield(lastT.Pareto, 'X') && ~isempty(lastT.Pareto.X)
    X = lastT.Pareto.X;
    if size(X, 2) >= idx
        best.x = X(:, idx);
    elseif size(X, 1) >= idx
        best.x = X(idx, :)';
    else
        best.x = [];
    end
else
    best.x = [];
end

best.initQ = meanInitQuality(res);

end

function best = emptyBest()
best.f1 = NaN;
best.f2 = NaN;
best.total = NaN;
best.x = [];
best.pof = [];
best.initQ = NaN;
end
function q = meanInitQuality(res)
vals = [];
for T = 2:numel(res)
    if isfield(res{T}, 'initPopMeanSum') && ~isnan(res{T}.initPopMeanSum)
        vals(end + 1) = res{T}.initPopMeanSum; %#ok<AGROW>
    end
end
if isempty(vals)
    q = NaN;
else
    q = mean(vals);
end
end

function F = paretoFromStruct(Pareto, Problem, t)
F = [];
if isfield(Pareto, 'F') && ~isempty(Pareto.F)
    F = normalizeParetoF(Pareto.F, 2);
end
if (isempty(F) || all(isnan(F(:)))) && isfield(Pareto, 'X') && ~isempty(Pareto.X) && ~isempty(Problem)
    X = Pareto.X;
    if size(X, 1) < size(X, 2)
        X = X';
    end
    nSol = size(X, 2);
    F = nan(2, nSol);
    for i = 1:nSol
        f = Problem.FObj(X(:, i), t);
        F(:, i) = f(:);
    end
    F = F(:, all(~isnan(F), 1));
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
