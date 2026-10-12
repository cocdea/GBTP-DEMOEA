function ok = fetchParksData(city)
%FETCHPARKSDATA Download real park coordinates from OpenStreetMap.
%   fetchParksData('shenzhen')   % paper city, 659 parks (recommended)
%   fetchParksData('chongqing')
%   fetchParksData('guangzhou')
%
% Requires Python 3. Requires network.

if nargin < 1
    city = 'shenzhen';
end

rootDir = fileparts(fileparts(mfilename('fullpath')));
script = fullfile(rootDir, 'Application', 'fetch_osm_parks.py');
cmd = sprintf('python "%s" %s 441', script, city);
fprintf('Running: %s\n', cmd);
status = system(cmd);
ok = (status == 0);
if ok
    fprintf('Saved: Application/data/%s_parks_real.csv\n', city);
else
    warning('fetchParksData:Failed', 'Download failed. Use bundled shenzhen_parks_real.csv.');
end

end
