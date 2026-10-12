%REBUILDPATHPLANNINGRESULTS Recompute tables/plots from saved res (no re-run algorithms).
% Use when algorithms finished but results struct was not saved (MATLAB pass-by-value bug).
clc;
rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));
cd(rootDir);

matFile = fullfile(rootDir, 'PathPlanning-results.mat');
if ~isfile(matFile)
    error('File not found: %s', matFile);
end

S = load(matFile);
if ~isfield(S, 'cfg')
    error('Missing cfg in %s', matFile);
end
cfg = S.cfg;
algNames = {'RR', 'DT', 'CT-DMOEA', 'GBCT-DMOEA'};
algFields = {'rr', 'dt', 'ct', 'gbct'};
T_parameter = [1, 1, cfg.nEnv];
group = 1;

if isfield(S, 'results') && isfield(S.results, 'gbct') ...
        && any(~isnan(S.results.gbct.meanAllEnv))
    fprintf('results already populated; rebuilding tables/plots only.\n');
    results = S.results;
else
    if ~all(isfield(S, {'resRR', 'resDT', 'resCT', 'resGBCT', 'envs'}))
        error(['Missing resRR/resDT/resCT/resGBCT/envs in mat file.\n' ...
            'Need to re-run runPathPlanningApp once with the fixed script.']);
    end
    fprintf('Recomputing results from saved algorithm outputs...\n');
    cfgGBCT = cfg;
    cfgGBCT.useGBSVM = true;
    cfgCT = cfg;
    cfgCT.useGBSVM = false;
    ProblemGBCT = createPathPlanningProblem(cfgGBCT);
    ProblemCT = createPathPlanningProblem(cfgCT);
    ProblemDT = createPathPlanningProblem(cfg);

    results = initPathResults(cfg, algFields);
    rep = 1;
    results = storePathMetrics(results, 'gbct', rep, S.resGBCT, ProblemGBCT, T_parameter, group, S.envs);
    results = storePathMetrics(results, 'ct', rep, S.resCT, ProblemCT, T_parameter, group, S.envs);
    results = storePathMetrics(results, 'dt', rep, S.resDT, ProblemDT, T_parameter, group, S.envs);
    results = storePathMetrics(results, 'rr', rep, S.resRR, ProblemDT, T_parameter, group, S.envs);
end

writePathPlanningApplicationTable(rootDir, results, algNames, algFields);
writePathPlanningDetailTables(rootDir, results, algNames, algFields, cfg);
plotPathPlanningDynamicCurve(results, algNames, algFields, cfg, ...
    fullfile(rootDir, 'pathplan_dynamic_curve.png'));
plotPathPlanningInitQ(results, {'DT', 'CT-DMOEA', 'GBCT-DMOEA'}, {'dt', 'ct', 'gbct'}, cfg, ...
    fullfile(rootDir, 'pathplan_initQ_curve.png'));
plotPathPlanningMeanBar(results, algNames, algFields);

if isfield(S, 'resGBCT')
    cfgGBCT = cfg;
    cfgGBCT.useGBSVM = true;
    cfgCT = cfg;
    cfgCT.useGBSVM = false;
    exportPathPlanningRoutes(rootDir, S.envs, S.resRR, S.resDT, S.resCT, S.resGBCT, ...
        createPathPlanningProblem(cfg), createPathPlanningProblem(cfgCT), ...
        createPathPlanningProblem(cfgGBCT), cfg, T_parameter, group, cfg.nEnv);
end

save(matFile, '-append', 'results');
fprintf('Done. See pathplan_table_application.txt and pathplan_dynamic_curve.png\n');

function results = initPathResults(cfg, algFields)
for k = 1:numel(algFields)
    results.(algFields{k}) = struct( ...
        'envF1', nan(cfg.repeatMax, cfg.nEnv), ...
        'envF2', nan(cfg.repeatMax, cfg.nEnv), ...
        'envTotal', nan(cfg.repeatMax, cfg.nEnv), ...
        'envInitQ', nan(cfg.repeatMax, cfg.nEnv), ...
        'meanAllEnv', nan(cfg.repeatMax, 1), ...
        'initQ', nan(cfg.repeatMax, 1));
end
end

function results = storePathMetrics(results, field, rep, res, Problem, T_parameter, group, envs)
setPathPlanningEnv(envs);
m = computeEnvRoutingMetrics(res, Problem, T_parameter, group);
nStore = size(results.(field).envTotal, 2);
nRes = numel(m.total);
n = min(nStore, nRes);
results.(field).envF1(rep, 1:n) = m.f1(1:n)';
results.(field).envF2(rep, 1:n) = m.f2(1:n)';
results.(field).envTotal(rep, 1:n) = m.total(1:n)';
nInit = min(size(results.(field).envInitQ, 2), numel(m.initQ));
results.(field).envInitQ(rep, 1:nInit) = m.initQ(1:nInit)';
results.(field).meanAllEnv(rep) = mean(m.total(1:n), 'omitnan');
results.(field).initQ(rep) = m.meanInitQ;
fprintf('  -> %s rep %d: mean(f1+f2) over envs = %.2f\n', field, rep, m.meanTotal);
end

function writePathPlanningDetailTables(rootDir, results, algNames, algFields, cfg)
fid = fopen(fullfile(rootDir, 'PathPlanning-summary.txt'), 'w');
fprintf(fid, '# Dynamic path planning — mean over ALL environments\n');
fprintf(fid, '# nTasks=%d nEnv=%d pop=%d maxIt=%d reps=%d\n', ...
    cfg.nTasks, cfg.nEnv, cfg.popSize, cfg.maxIt, cfg.repeatMax);
fprintf(fid, '# Algorithm mean_allEnv std_allEnv mean_initQ\n');
for k = 1:numel(algFields)
    r = results.(algFields{k});
    fprintf(fid, '%s %.4f %.4f %.4f\n', algNames{k}, ...
        mean(r.meanAllEnv, 'omitnan'), std(r.meanAllEnv, 0, 'omitnan'), ...
        mean(r.initQ, 'omitnan'));
end
fclose(fid);
end

function plotPathPlanningMeanBar(results, algNames, algFields)
meanTotal = zeros(1, numel(algFields));
stdTotal = zeros(1, numel(algFields));
for k = 1:numel(algFields)
    meanTotal(k) = mean(results.(algFields{k}).meanAllEnv, 'omitnan');
    stdTotal(k) = std(results.(algFields{k}).meanAllEnv, 0, 'omitnan');
end
figure('Name', 'Mean routing quality', 'Color', 'w');
bar(meanTotal);
hold on;
errorbar(1:numel(algFields), meanTotal, stdTotal, 'k.', 'LineWidth', 1.2, 'CapSize', 12);
set(gca, 'XTickLabel', algNames);
ylabel('Mean (f_1 + f_2) over all environments');
title('Average routing quality over dynamic process');
xtickangle(20);
grid on;
hold off;
saveas(gcf, 'pathplan_summary.png');
end
