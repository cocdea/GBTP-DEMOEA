function Problem = createPathPlanningProblem(cfg)
%CREATEPATHPLANNINGPROBLEM Problem struct for CT_DMOEA / MOEA/D.

Problem.Name  = 'PathPlan';
Problem.NObj  = 2;
Problem.XLow  = zeros(cfg.nTasks, 1);
Problem.XUpp  = ones(cfg.nTasks, 1);
Problem.AppConfig = cfg;
if isfield(cfg, 'testPopMult')
    Problem.AppConfig.testPopMult = cfg.testPopMult;
end
if isfield(cfg, 'useGBSVM')
    Problem.AppConfig.useGBSVM = cfg.useGBSVM;
else
    Problem.AppConfig.useGBSVM = true;
end
Problem.FObj  = @(x, t) evaluatePathPlanning(x, t, cfg);

end
