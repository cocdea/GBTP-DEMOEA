clc
clear
close all
warning('off')

rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));
cd(rootDir);

%% Parameter sensitivity: Q_max for GBSVM transfer in GBCT-DMOEA
% Vary only Q_max; all other settings follow configure() / paper benchmark.

cfg = configure();
functions = cfg.TestFunctions;
T_parameter = cfg.T_parameter;
popSizeDefault = cfg.popSize;

qmaxValues = [2, 4, 6, 8, 10];
adoptedQmax = 6;
nQmax = numel(qmaxValues);
nFunc = numel(functions);
nGroup = size(T_parameter, 1);
nCase = nFunc * nGroup;

quickMode = true;    % true: DF1--DF2, 1 group (smoke test)
repeatMax = 1;       % 1 = single run per case; use 20/30 for paper

if quickMode
    functions = functions(1:2);
    T_parameter = T_parameter(1, :);
    repeatMax = 2;
    nFunc = numel(functions);
    nGroup = 1;
    nCase = nFunc * nGroup;
    fprintf('quickMode ON: %d functions, %d groups, %d repeats\n', nFunc, nGroup, repeatMax);
end

outDir = fullfile(rootDir, 'ParameterSensitivity', 'results');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

resultFile = fullfile(outDir, 'qmax_migd_raw.mat');
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
    if isfield(S, 'qmaxValues')
        qmaxValues = S.qmaxValues;
        nQmax = numel(qmaxValues);
    end
    if isfield(S, 'repeatMax')
        repeatMax = S.repeatMax;
    end
    fprintf('Loaded cached raw results from %s\n', resultFile);
else
    migdAll = nan(repeatMax, nCase, nQmax);
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

            for qIdx = 1:nQmax
                if ~isnan(migdAll(rep, caseIdx, qIdx))
                    continue;
                end

                qmax = qmaxValues(qIdx);
                fprintf('\n[rep %d/%d] GBCT-DMOEA | Qmax=%g | %s | group %d (nt=%g, tau=%g)\n', ...
                    rep, repeatMax, qmax, Problem.Name, group, ...
                    T_parameter(group, 1), T_parameter(group, 2));

                if ~isfield(Problem, 'AppConfig')
                    Problem.AppConfig = struct();
                end
                Problem.AppConfig.useGBSVM = true;
                Problem.AppConfig.Qmax = qmax;

                res = GBCT_DMOEA(Problem, popSize, MaxIt, T_parameter, group);
                migdAll(rep, caseIdx, qIdx) = extractMIGD(res);

                save(resultFile, 'migdAll', 'functions', 'T_parameter', ...
                    'qmaxValues', 'adoptedQmax', 'repeatMax', '-v7.3');
                fprintf('  MIGD = %.6f\n', migdAll(rep, caseIdx, qIdx));
            end
        end
    end
end

meanMIGD = squeeze(mean(migdAll, 1, 'omitnan'));
stdMIGD = squeeze(std(migdAll, 0, 1, 'omitnan'));
avgMIGD = mean(meanMIGD, 1, 'omitnan');

summaryFile = fullfile(outDir, 'qmax_migd_summary.txt');
fid = fopen(summaryFile, 'w');
fprintf(fid, '# GBCT-DMOEA parameter sensitivity on Q_max\n');
fprintf(fid, '# Function Group');
for qIdx = 1:nQmax
    fprintf(fid, ' Qmax=%g_mean Qmax=%g_std', qmaxValues(qIdx), qmaxValues(qIdx));
end
fprintf(fid, '\n');
for fIdx = 1:nFunc
    for group = 1:nGroup
        caseIdx = (fIdx - 1) * nGroup + group;
        fprintf(fid, '%s %d', functions{fIdx}, group);
        for qIdx = 1:nQmax
            fprintf(fid, ' %.10f %.10f', meanMIGD(caseIdx, qIdx), stdMIGD(caseIdx, qIdx));
        end
        fprintf(fid, '\n');
    end
end
fclose(fid);

save(fullfile(outDir, 'qmax_migd_final.mat'), ...
    'migdAll', 'meanMIGD', 'stdMIGD', 'avgMIGD', 'functions', ...
    'T_parameter', 'qmaxValues', 'adoptedQmax', 'repeatMax', '-v7.3');

plotQmaxSensitivity(fullfile(outDir, 'qmax_migd_final.mat'), outDir);

fprintf('\n=== Q_max sensitivity (%d cases, %d repeats) ===\n', nCase, repeatMax);
for qIdx = 1:nQmax
    tag = '';
    if qmaxValues(qIdx) == adoptedQmax
        tag = '  <- adopted setting';
    end
    fprintf('Qmax=%g  average MIGD = %.6f%s\n', qmaxValues(qIdx), avgMIGD(qIdx), tag);
end

[~, bestIdx] = min(avgMIGD);
if bestIdx == find(qmaxValues == adoptedQmax, 1)
    fprintf('\nQmax=%g achieves the lowest average MIGD.\n', adoptedQmax);
else
    fprintf('\nQmax=%g achieves competitive average MIGD (best: Qmax=%g).\n', ...
        adoptedQmax, qmaxValues(bestIdx));
end

fprintf('\nDone.\n');
fprintf('Raw runs : %s\n', resultFile);
fprintf('Summary  : %s\n', summaryFile);
fprintf('Figure   : %s\n', fullfile(outDir, 'qmax_sensitivity_migd.png'));
