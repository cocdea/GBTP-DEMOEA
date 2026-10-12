clc
clear
close all
warning('off')

rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));
cd(rootDir);

%% Ablation study: MOEA/D, GBS-MOEA/D, GBT-MOEA/D, GBCT-DMOEA
% Mapping to original paper:
%   MOEA/D       - no transfer
%   GBS-MOEA/D   - CBS (granular-ball selection only)
%   GBT-MOEA/D   - CBT (GBSVM transfer only)
%   GBCT-DMOEA   - CT-DMOEA (full method)

cfg = configure();
functions = cfg.TestFunctions;
T_parameter = cfg.T_parameter;
popSizeDefault = cfg.popSize;

algNames = {'MOEA/D', 'GBS-MOEA/D', 'GBT-MOEA/D', 'GBCT-DMOEA'};
nAlg = numel(algNames);
nFunc = numel(functions);
nGroup = size(T_parameter, 1);
nCase = nFunc * nGroup;

quickMode = false;   % true: DF1--DF2, 1 group, 2 reps (smoke test)
repeatMax = 6;      % paper setting
eqTol = 1e-4;

if quickMode
    functions = functions(1:2);
    T_parameter = T_parameter(1, :);
    repeatMax = 2;
    nFunc = numel(functions);
    nGroup = 1;
    nCase = nFunc * nGroup;
    fprintf('quickMode ON: %d functions, %d groups, %d repeats\n', nFunc, nGroup, repeatMax);
end

outDir = fullfile(rootDir, 'Ablation', 'results');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

resultFile = fullfile(outDir, 'ablation_migd_raw.mat');
if isfile(resultFile)
    S = load(resultFile);
    migdAll = S.migdAll;
    if isfield(S, 'functions')
        functions = S.functions;
        nFunc = numel(functions);
    end
    if isfield(S, 'T_parameter')
        T_parameter = S.T_parameter;
        nGroup = size(T_parameter, 1);
        nCase = nFunc * nGroup;
    end
    if isfield(S, 'repeatMax')
        repeatMax = S.repeatMax;
    end
    fprintf('Loaded cached raw results from %s\n', resultFile);
else
    migdAll = nan(repeatMax, nCase, nAlg);
end

for rep = 1:repeatMax
    for fIdx = 1:nFunc
        Problem = TestFunctions(functions{fIdx});
        popSize = popSizeDefault;
        if Problem.NObj == 3
            popSize = 150;
        end

        for group = 1:nGroup
            caseIdx = (fIdx - 1) * nGroup + group;
            MaxIt = T_parameter(group, 2);

            for algIdx = 1:nAlg
                if ~isnan(migdAll(rep, caseIdx, algIdx))
                    continue;
                end

                fprintf('\n[rep %d/%d] %s | %s | group %d (nt=%g, tau=%g)\n', ...
                    rep, repeatMax, algNames{algIdx}, Problem.Name, group, ...
                    T_parameter(group, 1), T_parameter(group, 2));

                res = runAblationAlgorithm(algNames{algIdx}, Problem, popSize, MaxIt, T_parameter, group);
                migdAll(rep, caseIdx, algIdx) = extractMIGD(res);

                save(resultFile, 'migdAll', 'functions', 'T_parameter', ...
                    'algNames', 'repeatMax', '-v7.3');
                fprintf('  MIGD = %.6f\n', migdAll(rep, caseIdx, algIdx));
            end
        end
    end
end

meanMIGD = squeeze(mean(migdAll, 1, 'omitnan'));
stdMIGD = squeeze(std(migdAll, 0, 1, 'omitnan'));

summaryFile = fullfile(outDir, 'ablation_migd_summary.txt');
fid = fopen(summaryFile, 'w');
fprintf(fid, '# Function Group MeanMIGD StdMIGD | algorithms: %s\n', strjoin(algNames, ', '));
for fIdx = 1:nFunc
    for group = 1:nGroup
        caseIdx = (fIdx - 1) * nGroup + group;
        fprintf(fid, '%s %d', functions{fIdx}, group);
        for algIdx = 1:nAlg
            fprintf(fid, ' %.10f %.10f', meanMIGD(caseIdx, algIdx), stdMIGD(caseIdx, algIdx));
        end
        fprintf(fid, '\n');
    end
end
fclose(fid);

stats = computeAblationTable(meanMIGD, algNames, eqTol);
writeAblationTable(stats, algNames, outDir);

save(fullfile(outDir, 'ablation_migd_final.mat'), ...
    'migdAll', 'meanMIGD', 'stdMIGD', 'stats', 'functions', ...
    'T_parameter', 'algNames', 'repeatMax', 'eqTol', '-v7.3');

fprintf('\n=== Ablation summary (%d cases, %d repeats) ===\n', nCase, repeatMax);
for a = 1:nAlg
    fprintf('%s  best/all = %d/%d\n', algNames{a}, stats.bestCount(a), stats.nCase);
    fprintf('  vs MOEA/D     +/-/= = %d/%d/%d\n', ...
        stats.vsMOEAD(a).plus, stats.vsMOEAD(a).minus, stats.vsMOEAD(a).equal);
    fprintf('  vs GBCT-DMOEA +/-/= = %d/%d/%d\n', ...
        stats.vsGBCT(a).plus, stats.vsGBCT(a).minus, stats.vsGBCT(a).equal);
end

fprintf('\nDone.\n');
fprintf('Raw runs : %s\n', resultFile);
fprintf('Summary  : %s\n', summaryFile);
fprintf('Table    : %s\n', fullfile(outDir, 'ablation_migd_table.txt'));
