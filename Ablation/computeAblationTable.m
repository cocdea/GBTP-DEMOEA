function stats = computeAblationTable(meanMIGD, algNames, tol)
%COMPUTEABLATIONTABLE Build best/all and +/- rows for ablation table.
%   meanMIGD: nCase x nAlg matrix (smaller is better).
%   algNames: cell array of algorithm labels.
%   tol: equality threshold for +/- = comparison.

if nargin < 3 || isempty(tol)
    tol = 1e-4;
end

nCase = size(meanMIGD, 1);
nAlg = size(meanMIGD, 2);
if numel(algNames) ~= nAlg
    error('computeAblationTable:SizeMismatch', ...
        'algNames length must match number of algorithm columns.');
end

stats = struct();
stats.algNames = algNames(:)';
stats.nCase = nCase;
stats.bestCount = zeros(1, nAlg);
stats.vsMOEAD = repmat(struct('plus', 0, 'minus', 0, 'equal', 0), 1, nAlg);
stats.vsGBCT = repmat(struct('plus', 0, 'minus', 0, 'equal', 0), 1, nAlg);

gbctIdx = find(strcmp(algNames, 'GBCT-DMOEA'), 1);
moeadIdx = find(strcmp(algNames, 'MOEA/D'), 1);
if isempty(gbctIdx)
    gbctIdx = nAlg;
end
if isempty(moeadIdx)
    moeadIdx = 1;
end

[~, bestIdx] = min(meanMIGD, [], 2);
for c = 1:nCase
    stats.bestCount(bestIdx(c)) = stats.bestCount(bestIdx(c)) + 1;
end

for a = 1:nAlg
    for c = 1:nCase
        diffMOEAD = meanMIGD(c, a) - meanMIGD(c, moeadIdx);
        if abs(diffMOEAD) <= tol
            stats.vsMOEAD(a).equal = stats.vsMOEAD(a).equal + 1;
        elseif diffMOEAD < 0
            stats.vsMOEAD(a).plus = stats.vsMOEAD(a).plus + 1;
        else
            stats.vsMOEAD(a).minus = stats.vsMOEAD(a).minus + 1;
        end

        diffGBCT = meanMIGD(c, a) - meanMIGD(c, gbctIdx);
        if abs(diffGBCT) <= tol
            stats.vsGBCT(a).equal = stats.vsGBCT(a).equal + 1;
        elseif diffGBCT < 0
            stats.vsGBCT(a).plus = stats.vsGBCT(a).plus + 1;
        else
            stats.vsGBCT(a).minus = stats.vsGBCT(a).minus + 1;
        end
    end
end

end
