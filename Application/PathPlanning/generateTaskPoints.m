function data = generateTaskPoints(cfg, seed)
%GENERATETASKPOINTS Random 2-D task points in [0, mapSize]^2.

if nargin > 1
    rng(seed);
end

data.allCoords = cfg.mapSize * rand(cfg.nTasks, 2);
data.depot = mean(data.allCoords, 1);
data.nTasks = cfg.nTasks;
data.mapSize = cfg.mapSize;

end
