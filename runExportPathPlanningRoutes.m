%RUNEXPORTPATHPLANNINGROUTES Re-export route figures and txt from saved experiment.
clc;
rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));

matFile = fullfile(rootDir, 'PathPlanning-results.mat');
if ~isfile(matFile)
    error('File not found: %s. Run runPathPlanningApp first.', matFile);
end

S = load(matFile);
need = {'envs', 'resRR', 'resDT', 'resCT', 'resGBCT', 'cfg'};
for i = 1:numel(need)
    if ~isfield(S, need{i})
        error('Missing %s in %s. Re-run runPathPlanningApp.', need{i}, matFile);
    end
end

cfg = S.cfg;
cfgGBCT = cfg;
cfgGBCT.useGBSVM = true;
cfgCT = cfg;
cfgCT.useGBSVM = false;
ProblemGBCT = createPathPlanningProblem(cfgGBCT);
ProblemCT = createPathPlanningProblem(cfgCT);
ProblemDT = createPathPlanningProblem(cfg);
T_parameter = [1, 1, cfg.nEnv];
group = 1;

exportPathPlanningRoutes(rootDir, S.envs, S.resRR, S.resDT, S.resCT, S.resGBCT, ...
    ProblemDT, ProblemCT, ProblemGBCT, cfg, T_parameter, group, cfg.nEnv);

fprintf('Done.\n');
