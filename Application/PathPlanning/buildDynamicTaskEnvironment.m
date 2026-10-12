function envs = buildDynamicTaskEnvironment(baseData, cfg)
%BUILDDYNAMICTASKENVIRONMENT Sequential environments with moderate, similar changes.

envs = cell(cfg.nEnv, 1);
envs{1} = baseData;

for e = 2:cfg.nEnv
    envs{e} = applyTaskChange(envs{e - 1}, cfg, e);
end

end

function newData = applyTaskChange(data, cfg, envIdx)
newData = data;
N = data.nTasks;
coords = data.allCoords;

nPerturb = max(1, round(cfg.perturbRatio * N));
idxP = randperm(N, nPerturb);

sigma = cfg.perturbSigma;
if isfield(cfg, 'useSmoothDrift') && cfg.useSmoothDrift
    phase = sin((envIdx - 1) / max(cfg.nEnv - 1, 1) * pi);
    sigma = cfg.perturbSigma * (0.4 + 0.6 * abs(phase));
end

coords(idxP, :) = coords(idxP, :) + sigma * randn(nPerturb, 2);

nReplace = max(1, round(cfg.replaceRatio * N));
idxR = randperm(N, nReplace);
if isfield(cfg, 'localReplace') && cfg.localReplace
    coords(idxR, :) = coords(idxR, :) + sigma * randn(nReplace, 2);
else
    coords(idxR, :) = cfg.mapSize * rand(nReplace, 2);
end

coords(:, 1) = min(max(coords(:, 1), 0), cfg.mapSize);
coords(:, 2) = min(max(coords(:, 2), 0), cfg.mapSize);

newData.allCoords = coords;
newData.depot = mean(coords, 1);
newData.envIdx = envIdx;
end
