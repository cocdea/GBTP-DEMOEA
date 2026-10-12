function envs = buildDynamicEnvironment(baseData, cfg)
%BUILDDYNAMICENVIRONMENT Build a sequence of environments with changing UAV parks.

envs = cell(cfg.nEnv, 1);
envs{1} = baseData;

for e = 2:cfg.nEnv
    envs{e} = applyParkChange(envs{e - 1}, cfg);
end

end

function newData = applyParkChange(data, cfg)
newData = data;
pool = data.uavPoolIdx;
nChange = max(1, round(numel(pool) * cfg.changeRatio));
replaceIdx = pool(randperm(numel(pool), nChange));

if isfield(data, 'isReal') && data.isReal
    jitter = 0.25;
    if isfield(cfg, 'realDataJitter')
        jitter = cfg.realDataJitter;
    end
    newData.allCoords(replaceIdx, :) = newData.allCoords(replaceIdx, :) ...
        + jitter * randn(nChange, 2);
else
    newData.allCoords(replaceIdx, :) = cfg.mapSize * rand(nChange, 2);
end
newData.envChangeRatio = cfg.changeRatio;
end
