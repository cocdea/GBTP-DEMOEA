clc
clearvars
close all
warning('off')

rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));
cd(rootDir);
rehash path

cfg = configPathPlanning();
algNames = {'RR', 'DT', 'CT-DMOEA', 'GBCT-DMOEA'};
algFields = {'rr', 'dt', 'ct', 'gbct'};
T_parameter = [1, 1, cfg.nEnv];
group = 1;
nRunEnv = floor(T_parameter(group, 3) / T_parameter(group, 2));
if nRunEnv ~= cfg.nEnv
    warning('runPathPlanningApp:EnvCount', ...
        'Adjusting cfg.nEnv from %d to %d to match T_parameter.', cfg.nEnv, nRunEnv);
    cfg.nEnv = nRunEnv;
end

cfgGBCT = cfg;
cfgGBCT.useGBSVM = true;
cfgCT = cfg;
cfgCT.useGBSVM = false;

ProblemGBCT = createPathPlanningProblem(cfgGBCT);
ProblemCT = createPathPlanningProblem(cfgCT);
ProblemDT = createPathPlanningProblem(cfg);

resultFile = fullfile(rootDir, 'PathPlanning-results.mat');
results = initPathResults(cfg, algFields);

fprintf('=== GBCT-DMOEA Dynamic Path Planning Application ===\n');
fprintf('Tasks=%d, envs=%d, pop=%d, maxIt=%d, reps=%d\n', ...
    cfg.nTasks, cfg.nEnv, cfg.popSize, cfg.maxIt, cfg.repeatMax);
fprintf('Change: perturb %.0f%%, replace %.0f%% (local, similar envs)\n', ...
    cfg.perturbRatio * 100, cfg.replaceRatio * 100);
fprintf('Objectives: f1=total length, f2=max segment length\n');
fprintf('Primary comparison: GBCT-DMOEA (GBSVM) vs CT-DMOEA (SVM)\n');
fprintf('Baselines: DT (direct transfer), RR (MOEA/D random restart)\n');
fprintf('Metric: mean(f1+f2) over ALL %d environments per run\n', cfg.nEnv);
if cfg.nEnv >= 20 && cfg.repeatMax >= 10
    fprintf('Note: full-scale run may take hours. Set cfg.quickMode=true in configPathPlanning for a quick test.\n');
end
fprintf('Tip: run testPathPlanningSmoke first; use cfg.quickMode=true to verify quickly.\n');
fprintf('\n');

for rep = 1:cfg.repeatMax
    base = generateTaskPoints(cfg, rep);
    envs = buildDynamicTaskEnvironment(base, cfg);
    setPathPlanningEnv(envs);

    fprintf('\n[rep %d/%d] GBCT-DMOEA ...\n', rep, cfg.repeatMax);
    resGBCT = CT_DMOEA(ProblemGBCT, cfg.popSize, cfg.maxIt, T_parameter, group);
    results = storePathMetrics(results, 'gbct', rep, resGBCT, ProblemGBCT, T_parameter, group, envs);
    bestGBCT = extractPathResult(resGBCT, cfg, ProblemGBCT);

    fprintf('[rep %d/%d] CT-DMOEA ...\n', rep, cfg.repeatMax);
    resCT = CT_DMOEA(ProblemCT, cfg.popSize, cfg.maxIt, T_parameter, group);
    results = storePathMetrics(results, 'ct', rep, resCT, ProblemCT, T_parameter, group, envs);

    fprintf('[rep %d/%d] DT ...\n', rep, cfg.repeatMax);
    resDT = CT_DMOEA_np(ProblemDT, cfg.popSize, cfg.maxIt, T_parameter, group);
    results = storePathMetrics(results, 'dt', rep, resDT, ProblemDT, T_parameter, group, envs);

    fprintf('[rep %d/%d] RR ...\n', rep, cfg.repeatMax);
    resRR = RR_DMOEA(ProblemDT, cfg.popSize, cfg.maxIt, T_parameter, group);
    results = storePathMetrics(results, 'rr', rep, resRR, ProblemDT, T_parameter, group, envs);
    bestRR = extractPathResult(resRR, cfg, ProblemDT);

    save(resultFile, 'results', 'cfg', 'algNames', 'envs', 'rep', '-v7.3');
end

writePathPlanningApplicationTable(rootDir, results, algNames, algFields);
writePathPlanningDetailTables(rootDir, results, algNames, algFields, cfg);

plotPathPlanningDynamicCurve(results, algNames, algFields, cfg, ...
    fullfile(rootDir, 'pathplan_dynamic_curve.png'));

initNames = {'DT', 'CT-DMOEA', 'GBCT-DMOEA'};
initFields = {'dt', 'ct', 'gbct'};
plotPathPlanningInitQ(results, initNames, initFields, cfg, ...
    fullfile(rootDir, 'pathplan_initQ_curve.png'));

plotPathPlanningMeanBar(results, algNames, algFields);

setPathPlanningEnv(envs);
exportPathPlanningRoutes(rootDir, envs, resRR, resDT, resCT, resGBCT, ...
    ProblemDT, ProblemCT, ProblemGBCT, cfg, T_parameter, group, cfg.nEnv);

lastEnv = envs{end};
plotPathPlanning(lastEnv, bestGBCT.x, cfg, 'GBCT-DMOEA final route (visualization)');
saveas(gcf, 'pathplan_route_GBCT.png');

plotPathPlanningPOF(bestGBCT.pof, extractPathResult(resCT, cfg, ProblemCT).pof, bestRR.pof, ...
    {'GBCT-DMOEA', 'CT-DMOEA', 'RR'});
saveas(gcf, 'pathplan_pof_final_env.png');

save(resultFile, 'results', 'cfg', 'algNames', 'envs', 'rep', ...
    'resRR', 'resDT', 'resCT', 'resGBCT', 'T_parameter', 'group', '-v7.3');

fprintf('\nDone.\n');
fprintf('  pathplan_table_application.txt   (main result: mean over all envs)\n');
fprintf('  pathplan_dynamic_curve.png       (env index vs routing quality)\n');
fprintf('  pathplan_initQ_curve.png         (initial population quality)\n');
fprintf('  pathplan_route_GBCT.png          (final route visualization)\n');
fprintf('  pathplan_routes_compare.png      (all routes side-by-side)\n');
fprintf('  pathplan_routes_overlay.png      (all routes on one map)\n');
fprintf('  pathplan_route_original_env1.png (original index-order route)\n');
fprintf('  pathplan_routes/                 (route coordinates txt)\n');

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

if ~iscell(res) || numel(res) < 1
    error('runPathPlanningApp:BadRes', '%s rep %d: invalid res (type=%s, n=%d).', ...
        field, rep, class(res), numel(res));
end

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

if all(isnan(m.total))
    debugResFields(res);
    error('runPathPlanningApp:NoMetrics', ...
        '%s rep %d: all %d environments returned NaN. See debug info above.', field, rep, nRes);
end
fprintf('  -> %s rep %d: mean(f1+f2) over envs = %.2f\n', field, rep, m.meanTotal);
end

function debugResFields(res)
fprintf('  [debug] res has %d environments\n', numel(res));
for T = 1:min(3, numel(res))
    if isempty(res{T}) || ~isstruct(res{T})
        fprintf('  [debug] env %d: empty\n', T);
        continue;
    end
    fn = fieldnames(res{T});
    fprintf('  [debug] env %d fields: %s\n', T, strjoin(fn', ', '));
    if isfield(res{T}, 'PopX')
        fprintf('  [debug] env %d PopX size: %s\n', T, mat2str(size(res{T}.PopX)));
    end
    if isfield(res{T}, 'Pareto')
        pf = res{T}.Pareto.F;
        fprintf('  [debug] env %d Pareto.F size: %s\n', T, mat2str(size(pf)));
    end
end
end

function writePathPlanningDetailTables(rootDir, results, algNames, algFields, cfg)
fid = fopen(fullfile(rootDir, 'PathPlanning-summary.txt'), 'w');
fprintf(fid, '# Dynamic path planning — mean over ALL environments\n');
fprintf(fid, '# nTasks=%d nEnv=%d pop=%d maxIt=%d reps=%d perturb=%.2f replace=%.2f\n', ...
    cfg.nTasks, cfg.nEnv, cfg.popSize, cfg.maxIt, cfg.repeatMax, ...
    cfg.perturbRatio, cfg.replaceRatio);
fprintf(fid, '# Algorithm mean_allEnv std_allEnv mean_initQ\n');
for k = 1:numel(algFields)
    r = results.(algFields{k});
    fprintf(fid, '%s %.4f %.4f %.4f\n', algNames{k}, ...
        mean(r.meanAllEnv, 'omitnan'), std(r.meanAllEnv, 0, 'omitnan'), ...
        mean(r.initQ, 'omitnan'));
end
fclose(fid);

fid = fopen(fullfile(rootDir, 'pathplan_table_initQ.txt'), 'w');
fprintf(fid, 'Algorithm\tQ_init (mean+-std)\n');
for k = 1:numel(algFields)
    r = results.(algFields{k});
    if all(isnan(r.initQ))
        fprintf(fid, '%s\tN/A\n', algNames{k});
    else
        fprintf(fid, '%s\t%.4f+-%.4f\n', algNames{k}, ...
            mean(r.initQ, 'omitnan'), std(r.initQ, 0, 'omitnan'));
    end
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

function plotPathPlanningPOF(pof1, pof2, pof3, names)
if nargin < 4
    names = {'GBCT-DMOEA', 'CT-DMOEA', 'RR'};
end
figure('Name', 'Final environment POF', 'Color', 'w');
hold on;
styles = {struct('c', [0.85, 0.10, 0.10], 'm', 'filled'), ...
          struct('c', [0.55, 0.55, 0.55], 'm', 'o'), ...
          struct('c', [0.47, 0.67, 0.19], 'm', '+')};
pofs = {pof1, pof2, pof3};
for i = 1:3
    if ~isempty(pofs{i})
        scatter(pofs{i}(1, :), pofs{i}(2, :), 36, styles{i}.c, styles{i}.m, ...
            'DisplayName', names{i});
    end
end
grid on;
xlabel('f_1 total path length');
ylabel('f_2 max segment length');
title('Final environment POF (visualization only)');
legend('Location', 'best');
hold off;
end
