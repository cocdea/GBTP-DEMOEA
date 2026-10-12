clc
clear
close all
warning('off')

rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));
cd(rootDir);

cfg = configApplication();
algNames = {'CT-DMOEA', 'C-MOEA/D'};
T_parameter = [1, 1, cfg.nEnv];
group = 1;

results.ct = struct('f1', nan(cfg.repeatMax, 1), ...
    'f2', nan(cfg.repeatMax, 1), 'total', nan(cfg.repeatMax, 1));
results.np = struct('f1', nan(cfg.repeatMax, 1), ...
    'f2', nan(cfg.repeatMax, 1), 'total', nan(cfg.repeatMax, 1));

Problem = createUAVUGVProblem(cfg);
resultFile = fullfile(rootDir, 'Application-results.mat');

fprintf('=== UAV/UGV Application ===\n');
if cfg.useRealData
    fprintf('Data: REAL %s, file: %s\n', cfg.cityName, cfg.dataFile);
else
    fprintf('Data: synthetic random points\n');
end
fprintf('UGV=%d, UAV pool=%d, UAV visit=%d, decision dim=%d\n', ...
    cfg.nUGV, cfg.nUAVPool, cfg.nUAVVisit, cfg.nUGV + cfg.nUAVPool);
fprintf('envs=%d, reps=%d, popSize=%d, maxIt=%d, changeRatio=%.0f%%\n', ...
    cfg.nEnv, cfg.repeatMax, cfg.popSize, cfg.maxIt, cfg.changeRatio * 100);
nTasks = cfg.repeatMax * 2;
fprintf('Algorithms: CT-DMOEA + C-MOEA/D (np), %d runs total. Engine: CT_DMOEA.m\n', nTasks);
if cfg.paperPreset
    fprintf('Warning: paperPreset is slow; keep paperPreset=false for fast results.\n');
end

for rep = 1:cfg.repeatMax
    baseData = loadParkData(cfg, rep);
    envs = buildDynamicEnvironment(baseData, cfg);
    setApplicationEnv(envs);

    fprintf('\n[rep %d/%d] CT-DMOEA ...\n', rep, cfg.repeatMax);
    resCT = CT_DMOEA(Problem, cfg.popSize, cfg.maxIt, T_parameter, group);
    bestCT = extractBestSolution(resCT, cfg);
    results.ct.f1(rep) = bestCT.f1;
    results.ct.f2(rep) = bestCT.f2;
    results.ct.total(rep) = bestCT.total;

    fprintf('[rep %d/%d] C-MOEA/D (no transfer) ...\n', rep, cfg.repeatMax);
    resNP = CT_DMOEA_np(Problem, cfg.popSize, cfg.maxIt, T_parameter, group);
    bestNP = extractBestSolution(resNP, cfg);
    results.np.f1(rep) = bestNP.f1;
    results.np.f2(rep) = bestNP.f2;
    results.np.total(rep) = bestNP.total;

    save(resultFile, 'results', 'cfg', 'algNames', 'envs', 'rep', '-v7.3');
end

fprintf('\n=== Results (total path length = UGV + UAV) ===\n');
fprintf('%-14s  mean±std\n', algNames{1});
fprintf('  %.2f ± %.2f\n', mean(results.ct.total), std(results.ct.total));
fprintf('%-14s\n', algNames{2});
fprintf('  %.2f ± %.2f\n', mean(results.np.total), std(results.np.total));

writeApplicationSummary(rootDir, results, algNames, cfg);
plotApplicationSummary(results, algNames);

lastEnv = envs{end};
plotApplicationPaths(lastEnv, bestCT.x, cfg, ...
    sprintf('CT-DMOEA paths (rep %d, final env)', cfg.repeatMax));
saveas(gcf, 'app_paths_CT-DMOEA.png');

plotApplicationPaths(lastEnv, bestNP.x, cfg, ...
    sprintf('C-MOEA/D paths (rep %d, final env)', cfg.repeatMax));
saveas(gcf, 'app_paths_C-MOEA-D.png');

plotApplicationPOF(bestCT.pof, bestNP.pof);
saveas(gcf, 'app_pof_compare.png');

fprintf('\nDone.\n');
fprintf('  Application-results.mat\n');
fprintf('  Application-summary.txt\n');
fprintf('  app_summary_distance.png, app_paths_*.png, app_pof_compare.png\n');

function writeApplicationSummary(rootDir, results, algNames, cfg)
fid = fopen(fullfile(rootDir, 'Application-summary.txt'), 'w');
fprintf(fid, '# Simplified UAV/UGV path planning application\n');
fprintf(fid, '# UGV=%d UAV_pool=%d UAV_visit=%d nEnv=%d changeRatio=%.2f\n', ...
    cfg.nUGV, cfg.nUAVPool, cfg.nUAVVisit, cfg.nEnv, cfg.changeRatio);
fprintf(fid, '# Algorithm mean_f1 mean_f2 mean_total std_total\n');

for i = 1:numel(algNames)
    if i == 1
        r = results.ct;
    else
        r = results.np;
    end
    fprintf(fid, '%s %.4f %.4f %.4f %.4f\n', algNames{i}, ...
        mean(r.f1, 'omitnan'), mean(r.f2, 'omitnan'), ...
        mean(r.total, 'omitnan'), std(r.total, 0, 'omitnan'));
end
fclose(fid);
end
