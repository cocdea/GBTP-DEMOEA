function data = loadRealParkData(cfg, seed)
%LOADREALPARKDATA Load real park lon/lat and project to local km coordinates.
% paperSplit=true: rows 1..nUGV -> UGV, rows nUGV+1..nUGV+nUAVPool -> UAV pool

if nargin > 1 && ~(isfield(cfg, 'paperSplit') && cfg.paperSplit)
    rng(seed);
end

csvPath = cfg.dataFile;
if ~isfile(csvPath)
    error('loadRealParkData:FileNotFound', 'Park data file not found: %s', csvPath);
end

tbl = readtable(csvPath, 'TextType', 'string');
nNeed = cfg.nUGV + cfg.nUAVPool;
if height(tbl) < nNeed
    error('loadRealParkData:NotEnoughParks', ...
        ['CSV has %d parks but need %d (nUGV=%d + nUAVPool=%d).\n' ...
         'Run: fetchParksData(''shenzhen'')  or  python Application/fetch_osm_parks.py shenzhen 441'], ...
        height(tbl), nNeed, cfg.nUGV, cfg.nUAVPool);
end

if isfield(cfg, 'paperSplit') && cfg.paperSplit
    sub = tbl(1:nNeed, :);
else
    pick = randperm(height(tbl), nNeed);
    sub = tbl(pick, :);
end

lon = sub.lon;
lat = sub.lat;
lon0 = mean(lon);
lat0 = mean(lat);

xy = zeros(nNeed, 2);
for i = 1:nNeed
    xy(i, :) = lonLatToLocalKm(lon(i), lat(i), lon0, lat0);
end

data.allCoords = xy;
data.ugvIdx = (1:cfg.nUGV)';
data.uavPoolIdx = (cfg.nUGV + 1:nNeed)';
data.depot = mean(data.allCoords, 1);
data.isReal = true;
data.parkNames = sub.name;
data.lonLat = [lon, lat];
data.lonLat0 = [lon0, lat0];
data.cityName = cfg.cityName;

margin = 1.2;
data.mapSize = max(max(abs(data.allCoords)) + margin, 10);

end

function xy = lonLatToLocalKm(lon, lat, lon0, lat0)
deg2kmLon = 111.32 * cosd(lat0);
deg2kmLat = 110.54;
xy = [(lon - lon0) * deg2kmLon, (lat - lat0) * deg2kmLat];
end
