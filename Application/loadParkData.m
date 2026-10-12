function data = loadParkData(cfg, seed)
%LOADPARKDATA Synthetic or real park coordinates based on cfg.useRealData.

if isfield(cfg, 'useRealData') && cfg.useRealData
    data = loadRealParkData(cfg, seed);
else
    data = generateParkData(cfg, seed);
    data.isReal = false;
end

end
