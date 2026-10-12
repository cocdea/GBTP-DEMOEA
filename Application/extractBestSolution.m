function best = extractBestSolution(res, cfg)
%EXTRACTBESTSOLUTION Pick compromise solution (min sum of objectives) from last env.

lastT = res{end};
if ~isfield(lastT, 'Pareto') || isempty(lastT.Pareto) || isempty(lastT.Pareto.F)
    best.f1 = NaN;
    best.f2 = NaN;
    best.total = NaN;
    best.x = [];
    best.pof = [];
    return;
end

F = normalizeParetoF(lastT.Pareto.F, 2);
nSol = size(F, 2);

if nSol == 0
    best.f1 = NaN;
    best.f2 = NaN;
    best.total = NaN;
    best.x = [];
    best.pof = [];
    return;
end

[~, idx] = min(sum(F, 1));
idx = min(idx, nSol);

best.f1 = F(1, idx);
best.f2 = F(2, idx);
best.total = best.f1 + best.f2;
best.pof = F;

X = lastT.Pareto.X;
if isempty(X)
    best.x = [];
elseif size(X, 2) >= idx
    best.x = X(:, idx);
else
    best.x = X(:, min(idx, size(X, 2)));
end

end

function F = normalizeParetoF(F, nObj)
%MOEA/D stores Pareto.F as [EP.Cost], which may be 1x(2*n) or 2xn.

F = double(F);
if isempty(F)
    return;
end

if size(F, 1) == nObj
    return;
end

if size(F, 2) == nObj
    F = F';
    return;
end

F = F(:)';
if mod(numel(F), nObj) ~= 0
    error('extractBestSolution:InvalidParetoF', ...
        'Pareto.F length (%d) is not divisible by %d objectives.', numel(F), nObj);
end

F = reshape(F, nObj, []);

end
