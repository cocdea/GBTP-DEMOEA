function data = generateParkData(cfg, seed)
%GENERATEPARKDATA Create simulated park coordinates for UGV and UAV.

if nargin > 1
    rng(seed);
end

nTotal = cfg.nUGV + cfg.nUAVPool;
data.allCoords = cfg.mapSize * rand(nTotal, 2);
data.ugvIdx = (1:cfg.nUGV)';
data.uavPoolIdx = (cfg.nUGV + 1:nTotal)';
data.depot = mean(data.allCoords, 1);

end
