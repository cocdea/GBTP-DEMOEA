function res = CT_DMOEA_ablation(Problem, popSize, MaxIt, T_parameter, group, mode)
%CT_DMOEA_ABLATION Ablation variants of GBCT-DMOEA.
%   mode:
%     'GBS'  - Granular-ball Selection only (CBS): ball clustering init, no GBSVM transfer
%     'GBT'  - Granular-ball Transfer only (CBT): GBSVM transfer, no ball clustering selection
%     'GBCT' - Full method: ball selection + GBSVM transfer (same as CT_DMOEA + useGBSVM)

validModes = {'GBS', 'GBT', 'GBCT'};
mode = upper(strtrim(mode));
if ~any(strcmp(validModes, mode))
    error('CT_DMOEA_ablation:InvalidMode', ...
        'mode must be one of: GBS, GBT, GBCT.');
end

d = size(Problem.XLow, 1);
numEnv = floor(T_parameter(group, 3) / T_parameter(group, 2));
res = cell(1, numEnv);

testPopMult = 90;
if isfield(Problem, 'AppConfig') && isfield(Problem.AppConfig, 'testPopMult')
    testPopMult = Problem.AppConfig.testPopMult;
end

for T = 1:numEnv
    t = 1 / T_parameter(group, 1) * (T - 1);
    fprintf(' %d', T);

    if T == 1
        [PopX, Pareto, POF_iter] = moead(Problem, popSize, MaxIt, t);
        PS = Pareto.X;
        random_PopX = sampleUniform(Problem, d, popSize);
        sourcePopX = [random_PopX, PS];
        LastPareto = PS;
        negtiveLabel = -1 * ones(1, size(sourcePopX, 2) - size(PS, 2));
        sourceRank = [negtiveLabel, ones(1, size(PS, 2))];
    else
        random_PopX = sampleUniform(Problem, d, popSize);
        [one_PopX, Pareto, ~] = moead(Problem, popSize, 1, t, LastPareto);
        randomPopX1 = addGaussianNoise_2(one_PopX, size(one_PopX, 2), size(one_PopX, 1), Problem);
        randomPopX2 = addGaussianNoise_2(Pareto.X, size(Pareto.X, 2), size(Pareto.X, 1), Problem);
        one_PopX = unique(one_PopX', 'rows')';
        union_PopX = [one_PopX, randomPopX1, randomPopX2];

        switch mode
            case 'GBS'
                [targetPopX, targetRank, targetNDS] = buildTargetByGranularBallSelection( ...
                    union_PopX, Problem, t, popSize);
                initPop = buildInitPopFromSelection(targetPopX, targetNDS, popSize, Problem, d);

            case 'GBT'
                [targetPopX, targetRank, targetNDS] = buildTargetBySimpleSelection( ...
                    union_PopX, Problem, t, popSize);
                initPop = buildInitPopByTransfer(targetPopX, targetRank, targetNDS, ...
                    sourcePopX, sourceRank, testPopMult, popSize, Problem, t, true, false);

            case 'GBCT'
                [targetPopX, targetRank, targetNDS] = buildTargetByGranularBallSelection( ...
                    union_PopX, Problem, t, popSize);
                initPop = buildInitPopByTransfer(targetPopX, targetRank, targetNDS, ...
                    sourcePopX, sourceRank, testPopMult, popSize, Problem, t, true, true);
        end

        res{T}.initPopMeanSum = meanInitPopSum(initPop, Problem, t);
        [PopX, Pareto, POF_iter] = moead(Problem, popSize, MaxIt, t, initPop');

        PS = Pareto.X;
        random_PopX = sampleUniform(Problem, d, popSize);
        sourcePopX = [random_PopX, PS];
        LastPareto = PS;
        negtiveLabel = -1 * ones(1, size(sourcePopX, 2) - size(PS, 2));
        sourceRank = [negtiveLabel, ones(1, size(PS, 2))];
    end

    res{T}.turePOF = getBenchmarkPOF(Problem.Name, group, T, T_parameter);
    res{T}.POF_iter = POF_iter;
    res{T}.Pareto = Pareto;
    if exist('PopX', 'var')
        res{T}.PopX = PopX;
    end
end

end

function X = sampleUniform(Problem, d, n)
X = zeros(d, n);
for i = 1:n
    X(:, i) = unifrnd(Problem.XLow, Problem.XUpp, [d, 1]);
end
end

function [targetPopX, targetRank, targetNDS] = buildTargetByGranularBallSelection(union_PopX, Problem, t, popSize)
% CBS / GBS: non-dominated pool -> hierarchical clustering -> per-ball best solution.
st = getStSolutionSet(union_PopX, Problem, t, popSize);
clusterK = min(popSize, size(st, 2));
[C_HCMset, ~] = HierarchicalClustering(st, Problem, t, clusterK);
targetPopX = bestSolutionSelection(C_HCMset, Problem, t, popSize);
[targetPopX, targetRank, targetNDS] = summarizeTarget(targetPopX, Problem, t);
end

function [targetPopX, targetRank, targetNDS] = buildTargetBySimpleSelection(union_PopX, Problem, t, popSize)
% CBT baseline target construction without granular-ball selection.
targetPopX = getStSolutionSet(union_PopX, Problem, t, popSize);
[targetPopX, targetRank, targetNDS] = summarizeTarget(targetPopX, Problem, t);
end

function [targetPopX, targetRank, targetNDS] = summarizeTarget(targetPopX, Problem, t)
targetRank = computeRank(targetPopX, Problem, t);
targetNDS = [];
for i = 1:size(targetRank, 2)
    if targetRank(i) == 1
        targetNDS = [targetNDS, targetPopX(:, i)]; %#ok<AGROW>
    end
end
end

function initPop = buildInitPopFromSelection(targetPopX, targetNDS, popSize, Problem, d)
% GBS-MOEA/D: selected representatives + random padding.
popRows = decisionRows(targetPopX, d);
if isempty(targetNDS)
    seeds = popRows;
else
    ndsRows = decisionRows(targetNDS, d);
    seeds = unique([ndsRows; popRows], 'rows', 'stable');
end
initPop = seeds;
if size(initPop, 1) > popSize
    initPop = initPop(1:popSize, :);
elseif size(initPop, 1) < popSize
    need = popSize - size(initPop, 1);
    initPop = [initPop; sampleUniform(Problem, d, need)']; %#ok<AGROW>
end
end

function rows = decisionRows(X, d)
if isempty(X)
    rows = zeros(0, d);
    return;
end
if size(X, 1) == d
    rows = X';
elseif size(X, 2) == d
    rows = X;
else
    error('CT_DMOEA_ablation:BadDecisionShape', ...
        'Decision matrix must be d-by-n or n-by-d.');
end
end

function initPop = buildInitPopByTransfer(targetPopX, targetRank, targetNDS, ...
    sourcePopX, sourceRank, testPopMult, popSize, Problem, t, useGBSVM, includeTargetNDS)

if nargin < 11
    includeTargetNDS = true;
end

M = Problem.NObj;
subSourcePopX = cell(1, M);
subSourceRank = cell(1, M);
subTargetPopX = cell(1, M);
subTargetRank = cell(1, M);

[subset1, subindex1] = HierarchicalClustering(sourcePopX, Problem, t, M);
[subset2, subindex2] = HierarchicalClustering(targetPopX, Problem, t, M);

for i = 1:M
    subSourcePopX{i} = subset1{i};
    subSourceRank{i} = sourceRank(subindex1{i});
    subTargetPopX{i} = subset2{i};
    subTargetRank{i} = targetRank(subindex2{i});
end

sourceFlag = zeros(1, M);
transferPop = [];
d = size(Problem.XLow, 1);

for i = 1:M
    testPopX = [];
    for j = 1:popSize * testPopMult
        testPopX(:, j) = unifrnd(Problem.XLow, Problem.XUpp, [d, 1]);
    end
    for j = 1:10
        testPopX = [addGaussianNoise_2(targetNDS, size(targetNDS, 2), size(targetNDS, 1), Problem), testPopX]; %#ok<AGROW>
    end

    clusterIndex = ClusterSelection(subTargetPopX{i}, subSourcePopX, sourceFlag, Problem, t);
    sourceFlag(clusterIndex) = 1;

    if useGBSVM
        tmpPop = predictIndividuals( ...
            subSourcePopX{clusterIndex}', subSourceRank{clusterIndex}', ...
            subTargetPopX{i}', subTargetRank{i}', testPopX', popSize, M, Problem, t);
    else
        tmpPop = predictIndividualsSVM( ...
            subSourcePopX{clusterIndex}', subSourceRank{clusterIndex}', ...
            subTargetPopX{i}', subTargetRank{i}', testPopX', popSize, M, Problem, t);
    end
    transferPop = [transferPop; tmpPop]; %#ok<AGROW>
end

if includeTargetNDS
    initPop = [decisionRows(targetNDS, d); transferPop];
else
    % GBT-MOEA/D: only GBSVM-predicted promising solutions.
    initPop = transferPop;
end

initPop = unique(initPop, 'rows', 'stable');
if size(initPop, 1) > popSize
    initPop = initPop(1:popSize, :);
elseif size(initPop, 1) < popSize
    need = popSize - size(initPop, 1);
    initPop = [initPop; sampleUniform(Problem, d, need)']; %#ok<AGROW>
end
end
