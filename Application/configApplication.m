function cfg = configApplication()
%CONFIGAPPLICATION UAV/UGV application (uses CT_DMOEA; default = fast real data).
% Paper Table III + Fig.5: run runTable3Application (see getTable3Config there).

cfg.useRealData  = true;
cfg.paperSplit   = true;
cfg.paperPreset  = false;
cfg.quickMode    = false;

if cfg.paperPreset
    cfg.cityName       = 'Shenzhen';
    cfg.dataFile       = fullfile('Application', 'data', 'shenzhen_parks_real.csv');
    cfg.nUGV           = 41;
    cfg.nUAVPool       = 400;
    cfg.nUAVVisit      = 300;
    cfg.nEnv           = 5;
    cfg.changeRatio    = 0.10;
    cfg.realDataJitter = 0.15;
    cfg.popSize        = 100;
    cfg.maxIt          = 80;
    cfg.repeatMax      = 5;
elseif cfg.quickMode
    cfg.cityName       = 'Shenzhen';
    cfg.dataFile       = fullfile('Application', 'data', 'shenzhen_parks_fast.csv');
    cfg.nUGV           = 3;
    cfg.nUAVPool       = 8;
    cfg.nUAVVisit      = 5;
    cfg.nEnv           = 2;
    cfg.changeRatio    = 0.10;
    cfg.realDataJitter = 0.15;
    cfg.popSize        = 20;
    cfg.maxIt          = 10;
    cfg.repeatMax      = 1;
    cfg.testPopMult    = 15;
else
    %% Default FAST preset (recommended): 14 real parks, ~10-30 min typical
    cfg.cityName       = 'Shenzhen';
    cfg.dataFile       = fullfile('Application', 'data', 'shenzhen_parks_fast.csv');
    cfg.nUGV           = 4;     % rows 1-4 in CSV -> UGV
    cfg.nUAVPool       = 10;    % rows 5-14 -> UAV pool
    cfg.nUAVVisit      = 6;     % UAV visits per run
    cfg.nEnv           = 3;
    cfg.changeRatio    = 0.10;
    cfg.realDataJitter = 0.15;
    cfg.popSize        = 25;
    cfg.maxIt          = 15;
    cfg.repeatMax      = 2;
    cfg.testPopMult    = 25;   % default CT_DMOEA uses 90; smaller = faster GBSVM
end

cfg.mapSize = 100;

if ~cfg.useRealData
    cfg.nUGV        = 4;
    cfg.nUAVPool    = 10;
    cfg.nUAVVisit   = 6;
    cfg.nEnv        = 3;
    cfg.changeRatio = 0.10;
    cfg.popSize     = 25;
    cfg.maxIt       = 15;
    cfg.repeatMax   = 2;
    cfg.paperSplit  = true;
    cfg.testPopMult = 25;
end

end
