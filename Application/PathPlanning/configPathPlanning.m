function cfg = configPathPlanning()
%CONFIGPATHPLANNING Dynamic path planning for GBCT-DMOEA application study.
% Moderate environment changes preserve similarity across consecutive envs.

cfg.nTasks        = 30;
cfg.mapSize       = 100;
cfg.nEnv          = 30;
cfg.perturbRatio  = 0.10;   % fraction of points perturbed each change
cfg.replaceRatio  = 0.10;   % fraction of points locally shifted (not full reset)
cfg.perturbSigma  = 5.0;    % perturb magnitude on map [0,100]
cfg.useSmoothDrift = true;  % scale drift by sin(env) for gradual dynamics
cfg.localReplace  = true;   % replace = local shift, not random reset

cfg.popSize       = 30;
cfg.maxIt         = 20;
cfg.repeatMax     = 20;
cfg.testPopMult   = 20;
cfg.refSampleSize = 600;

cfg.quickMode     = false;
if cfg.quickMode
    cfg.nTasks      = 20;
    cfg.nEnv        = 5;
    cfg.popSize     = 20;
    cfg.maxIt       = 10;
    cfg.repeatMax   = 2;
    cfg.testPopMult = 15;
end

end
