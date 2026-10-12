function plotQmaxSensitivity(resultFile, outDir)
%PLOTQMAXSENSITIVITY Line plot of average MIGD vs Q_max for GBCT-DMOEA.
%   plotQmaxSensitivity()
%   plotQmaxSensitivity(resultMatFile, outputDir)

if nargin < 1 || isempty(resultFile)
    rootDir = fileparts(fileparts(mfilename('fullpath')));
    resultFile = fullfile(rootDir, 'ParameterSensitivity', 'results', 'qmax_migd_final.mat');
end
if nargin < 2 || isempty(outDir)
    outDir = fileparts(resultFile);
end

S = load(resultFile);
qmaxValues = S.qmaxValues;
avgMIGD = S.avgMIGD;

if isfield(S, 'meanMIGD')
    avgMIGD = mean(S.meanMIGD, 1, 'omitnan');
end

adoptedQmax = 6;
if isfield(S, 'adoptedQmax')
    adoptedQmax = S.adoptedQmax;
end

adoptedIdx = find(qmaxValues == adoptedQmax, 1);
if isempty(adoptedIdx)
    adoptedIdx = 1;
end

figure('Name', 'Qmax sensitivity', 'Color', 'w', 'Position', [120, 120, 640, 460]);
hold on;

plot(qmaxValues, avgMIGD, '-o', ...
    'Color', [0.12, 0.47, 0.71], ...
    'LineWidth', 1.8, ...
    'MarkerSize', 8, ...
    'MarkerFaceColor', [0.12, 0.47, 0.71], ...
    'DisplayName', 'Average MIGD');

plot(qmaxValues(adoptedIdx), avgMIGD(adoptedIdx), 'p', ...
    'Color', [0.84, 0.15, 0.16], ...
    'MarkerSize', 16, ...
    'LineWidth', 1.5, ...
    'DisplayName', 'Adopted setting');

text(qmaxValues(adoptedIdx), avgMIGD(adoptedIdx), ...
    sprintf('  Q_{max}=%g\n  Adopted setting', adoptedQmax), ...
    'Color', [0.84, 0.15, 0.16], ...
    'FontSize', 10, ...
    'VerticalAlignment', 'bottom');

grid on;
box on;
xlim([min(qmaxValues) - 0.5, max(qmaxValues) + 0.5]);
xticks(qmaxValues);
xlabel('Q_{max}');
ylabel('Average MIGD');
title('Average MIGD values of GBCT-DMOEA with different Q_{max} values');
legend('Location', 'best');
hold off;

pngFile = fullfile(outDir, 'qmax_sensitivity_migd.png');
figFile = fullfile(outDir, 'qmax_sensitivity_migd.fig');
saveas(gcf, pngFile);
savefig(gcf, figFile);

end
