clc
clear
close all
warning('off')

rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));
cd(rootDir);

cfg = getTable3Config();
algNames = {'EEMTA', 'C-MOEA/D', 'CT-DMOEA'};
algFields = {'eemta', 'np', 'ct'};
changeRatios = cfg.changeRatios;
T_parameter = [1, 1, cfg.nEnv];
group = 1;

Problem = createUAVUGVProblem(cfg);
resultFile = fullfile(rootDir, 'Table3-results.mat');

tableData.changeRatios = changeRatios;
tableData.rows = cell(numel(changeRatios), 1);

raw = struct();
for fi = 1:numel(algFields)
    raw.(algFields{fi}) = struct( ...
        'ugv', nan(cfg.repeatMax, numel(changeRatios)), ...
        'uav', nan(cfg.repeatMax, numel(changeRatios)), ...
        'total', nan(cfg.repeatMax, numel(changeRatios)));
end

fig5CT = [];
fig5NP = [];
fig5Ratio = changeRatios(1);

fprintf('=== Table III + Fig.5 (UAV/UGV path planning) ===\n');
fprintf('Data: %s (%s)\n', cfg.dataFile, cfg.cityName);
fprintf('UGV=%d, UAV pool=%d, UAV visit=%d, dim=%d\n', ...
    cfg.nUGV, cfg.nUAVPool, cfg.nUAVVisit, cfg.nUGV + cfg.nUAVPool);
fprintf('envs=%d, reps=%d, pop=%d, maxIt=%d\n', ...
    cfg.nEnv, cfg.repeatMax, cfg.popSize, cfg.maxIt);
fprintf('Change ratios: %s\n', sprintf('%.0f%% ', changeRatios * 100));
fprintf('Algorithms: CT-DMOEA, C-MOEA/D (EEMTA row shown as "-" — not implemented)\n');
if cfg.usePaperScale
    fprintf('Warning: paper scale (441-dim) — expect long runtime.\n');
end

for ri = 1:numel(changeRatios)
    cfg.changeRatio = changeRatios(ri);
    fprintf('\n--- Change ratio %.0f%% ---\n', cfg.changeRatio * 100);

    for rep = 1:cfg.repeatMax
        baseData = loadParkData(cfg, rep + ri * 100);
        envs = buildDynamicEnvironment(baseData, cfg);
        setApplicationEnv(envs);

        fprintf('[cr=%.0f%%, rep %d/%d] CT-DMOEA ...\n', ...
            cfg.changeRatio * 100, rep, cfg.repeatMax);
        resCT = CT_DMOEA(Problem, cfg.popSize, cfg.maxIt, T_parameter, group);
        bestCT = extractBestSolution(resCT, cfg);
        raw.ct.ugv(rep, ri) = bestCT.f1;
        raw.ct.uav(rep, ri) = bestCT.f2;
        raw.ct.total(rep, ri) = bestCT.total;

        fprintf('[cr=%.0f%%, rep %d/%d] C-MOEA/D ...\n', ...
            cfg.changeRatio * 100, rep, cfg.repeatMax);
        resNP = CT_DMOEA_np(Problem, cfg.popSize, cfg.maxIt, T_parameter, group);
        bestNP = extractBestSolution(resNP, cfg);
        raw.np.ugv(rep, ri) = bestNP.f1;
        raw.np.uav(rep, ri) = bestNP.f2;
        raw.np.total(rep, ri) = bestNP.total;

        if ri == 1 && rep == cfg.repeatMax
            fig5CT = bestCT.pof;
            fig5NP = bestNP.pof;
            fig5Ratio = cfg.changeRatio;
            lastEnv = envs{end};
            lastBestCT = bestCT;
            lastBestNP = bestNP;
        end

        save(resultFile, 'raw', 'cfg', 'tableData', 'algNames', 'rep', 'ri', '-v7.3');
    end

    row.eemta = struct('uav', NaN, 'ugv', NaN, 'total', NaN);
    row.np = aggRow(raw.np, ri);
    row.ct = aggRow(raw.ct, ri);
    tableData.rows{ri} = row;
end

printTable3Console(tableData, algNames, algFields);
writeTable3Results(rootDir, tableData, algNames, algFields);

plotApplicationFig5(fig5CT, fig5NP, fig5Ratio, ...
    fullfile(rootDir, 'Fig5_POS_compare.png'));

plotApplicationPaths(lastEnv, lastBestCT.x, cfg, ...
    sprintf('CT-DMOEA paths (change %.0f%%)', fig5Ratio * 100));
saveas(gcf, 'Table3_paths_CT-DMOEA.png');

plotApplicationPaths(lastEnv, lastBestNP.x, cfg, ...
    sprintf('C-MOEA/D paths (change %.0f%%)', fig5Ratio * 100));
saveas(gcf, 'Table3_paths_C-MOEA-D.png');

save(resultFile, 'raw', 'tableData', 'cfg', 'algNames', 'fig5CT', 'fig5NP', '-v7.3');

fprintf('\nDone.\n');
fprintf('  Table3-results.mat\n');
fprintf('  Table3-results.txt\n');
fprintf('  Fig5_POS_compare.png\n');
fprintf('  Table3_paths_CT-DMOEA.png, Table3_paths_C-MOEA-D.png\n');

function row = aggRow(r, col)
row.ugv = mean(r.ugv(:, col), 'omitnan');
row.uav = mean(r.uav(:, col), 'omitnan');
row.total = mean(r.total(:, col), 'omitnan');
end

function cfg = getTable3Config()
%GETTABLE3CONFIG Settings for paper Table III + Fig.5 style experiments.

cfg.useRealData = true;
cfg.paperSplit = true;
cfg.cityName = 'Shenzhen';
cfg.dataFile = fullfile('Application', 'data', 'shenzhen_parks_real.csv');
cfg.realDataJitter = 0.15;
cfg.nEnv = 5;
cfg.changeRatios = [0.10, 0.20, 0.30];
cfg.mapSize = 100;

%% Scale: set usePaperScale=true for full paper (441-dim, very slow)
cfg.usePaperScale = false;

if cfg.usePaperScale
    cfg.nUGV = 41;
    cfg.nUAVPool = 400;
    cfg.nUAVVisit = 300;
    cfg.popSize = 100;
    cfg.maxIt = 80;
    cfg.repeatMax = 5;
    cfg.testPopMult = 90;
else
    %% Balanced preset: real Shenzhen parks, ~30–90 min depending on machine
    cfg.nUGV = 10;
    cfg.nUAVPool = 100;
    cfg.nUAVVisit = 50;
    cfg.popSize = 40;
    cfg.maxIt = 25;
    cfg.repeatMax = 1;
    cfg.testPopMult = 25;
end

cfg.changeRatio = cfg.changeRatios(1);

end
