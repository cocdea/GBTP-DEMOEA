%TESTPATHPLANNINGSMOKE Quick sanity check for path planning metrics (run in MATLAB).
clc;
rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));

cfg = configPathPlanning();
cfg.quickMode = true;
cfg.repeatMax = 1;

base = generateTaskPoints(cfg, 1);
envs = buildDynamicTaskEnvironment(base, cfg);
setPathPlanningEnv(envs);

Problem = createPathPlanningProblem(cfg);
t = 0;
[PopX, Pareto, POF_iter] = moead(Problem, cfg.popSize, cfg.maxIt, t);

fprintf('--- moead smoke test ---\n');
fprintf('Pareto.F size: %s\n', mat2str(size(Pareto.F)));
fprintf('Pareto.X size: %s\n', mat2str(size(Pareto.X)));
if isfield(Pareto, 'F') && ~isempty(Pareto.F)
    fprintf('Pareto.F sample: [%.2f, %.2f]\n', Pareto.F(1, 1), Pareto.F(2, 1));
end
if ~isempty(POF_iter)
    fprintf('POF_iter{end} size: %s\n', mat2str(size(POF_iter{end})));
end

res = cell(1, 1);
res{1}.PopX = PopX;
res{1}.Pareto = Pareto;
res{1}.POF_iter = POF_iter;
m = computeEnvRoutingMetrics(res, Problem, [1, 1, cfg.nEnv], 1);
fprintf('computeEnvRoutingMetrics total(1): %.4f\n', m.total(1));
if isnan(m.total(1))
    error('testPathPlanningSmoke:FAILED', 'Metrics still NaN — check moead / evaluatePathPlanning.');
end
fprintf('OK: path planning metrics pipeline works.\n');
