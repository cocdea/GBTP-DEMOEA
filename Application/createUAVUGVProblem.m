function Problem = createUAVUGVProblem(cfg)
%CREATEUAVUGVPROBLEM Build Problem struct compatible with CT_DMOEA / MOEA/D.

nVar = cfg.nUGV + cfg.nUAVPool;

Problem.Name  = 'UAVUGV';
Problem.NObj  = 2;
Problem.XLow  = zeros(nVar, 1);
Problem.XUpp  = ones(nVar, 1);
Problem.AppConfig = cfg;
if isfield(cfg, 'testPopMult')
    Problem.AppConfig.testPopMult = cfg.testPopMult;
end
Problem.FObj  = @(x, t) evaluateUAVUGV(x, t, cfg);

end
