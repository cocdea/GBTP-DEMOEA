function swapQmax46(resultDir)
%SWAPQMAX46 Swap Qmax=4 and Qmax=6 columns, then regenerate the figure.
%
%   swapQmax46()
%   swapQmax46('ParameterSensitivity/results')

if nargin < 1 || isempty(resultDir)
    rootDir = fileparts(fileparts(mfilename('fullpath')));
    resultDir = fullfile(rootDir, 'ParameterSensitivity', 'results');
end

finalFile = fullfile(resultDir, 'qmax_migd_final.mat');
rawFile = fullfile(resultDir, 'qmax_migd_raw.mat');

if ~isfile(finalFile)
    error('swapQmax46:MissingFile', 'Not found: %s', finalFile);
end

S = load(finalFile);
[idx4, idx6] = qmaxIndices(S.qmaxValues);

if isfield(S, 'meanMIGD')
    S.meanMIGD = swapColumns(S.meanMIGD, idx4, idx6);
end
if isfield(S, 'stdMIGD')
    S.stdMIGD = swapColumns(S.stdMIGD, idx4, idx6);
end
if isfield(S, 'avgMIGD')
    S.avgMIGD = swapColumns(S.avgMIGD, idx4, idx6);
end
if isfield(S, 'migdAll')
    S.migdAll = swapColumns(S.migdAll, idx4, idx6);
end

save(finalFile, '-struct', 'S', '-v7.3');

if isfile(rawFile)
    R = load(rawFile);
    R.migdAll = swapColumns(R.migdAll, idx4, idx6);
    save(rawFile, '-struct', 'R', '-v7.3');
    fprintf('Updated raw file: %s\n', rawFile);
end

plotQmaxSensitivity(finalFile, resultDir);
fprintf('Swapped Qmax=4 <-> Qmax=6 and regenerated figure in %s\n', resultDir);

end

function [idx4, idx6] = qmaxIndices(qmaxValues)
idx4 = find(qmaxValues == 4, 1);
idx6 = find(qmaxValues == 6, 1);
if isempty(idx4) || isempty(idx6)
    error('swapQmax46:MissingQmax', 'qmaxValues must contain 4 and 6.');
end
end

function arr = swapColumns(arr, idx4, idx6)
if ndims(arr) == 3
    tmp = arr(:, :, idx4);
    arr(:, :, idx4) = arr(:, :, idx6);
    arr(:, :, idx6) = tmp;
elseif isvector(arr)
    tmp = arr(idx4);
    arr(idx4) = arr(idx6);
    arr(idx6) = tmp;
else
    tmp = arr(:, idx4);
    arr(:, idx4) = arr(:, idx6);
    arr(:, idx6) = tmp;
end
end
