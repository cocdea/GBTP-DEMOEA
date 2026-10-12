function writeAblationTable(stats, algNames, outDir)
%WRITEABLATIONTABLE Save ablation statistics to txt and tex files.

if nargin < 3 || isempty(outDir)
    outDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'Ablation', 'results');
end
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

txtFile = fullfile(outDir, 'ablation_migd_table.txt');
texFile = fullfile(outDir, 'ablation_migd_table.tex');

writeTxt(txtFile, stats, algNames);
writeTex(texFile, stats, algNames);

fprintf('Ablation table saved:\n  %s\n  %s\n', txtFile, texFile);

end

function writeTxt(outFile, stats, algNames)
fid = fopen(outFile, 'w');
fprintf(fid, '# Ablation study on MIGD (DF1--DF14, 4 dynamic settings, %d cases)\n', stats.nCase);
fprintf(fid, '# Columns: %s\n', strjoin(algNames, ', '));
fprintf(fid, 'Row\t%s\n', strjoin(algNames, '\t'));

bestStr = strings(1, numel(algNames));
for a = 1:numel(algNames)
    bestStr(a) = sprintf('%d/%d', stats.bestCount(a), stats.nCase);
end
fprintf(fid, 'best/all\t%s\n', strjoin(cellstr(bestStr), '\t'));

vsMOEADStr = strings(1, numel(algNames));
for a = 1:numel(algNames)
    vsMOEADStr(a) = sprintf('%d/%d/%d', ...
        stats.vsMOEAD(a).plus, stats.vsMOEAD(a).minus, stats.vsMOEAD(a).equal);
end
fprintf(fid, '+/-/= (VS MOEA/D)\t%s\n', strjoin(cellstr(vsMOEADStr), '\t'));

vsGBCTStr = strings(1, numel(algNames));
for a = 1:numel(algNames)
    vsGBCTStr(a) = sprintf('%d/%d/%d', ...
        stats.vsGBCT(a).plus, stats.vsGBCT(a).minus, stats.vsGBCT(a).equal);
end
fprintf(fid, '+/-/= (VS GBCT-DMOEA)\t%s\n', strjoin(cellstr(vsGBCTStr), '\t'));
fclose(fid);
end

function writeTex(outFile, stats, algNames)
fid = fopen(outFile, 'w');
fprintf(fid, '%% Auto-generated ablation table\n');
fprintf(fid, '\\begin{table}[t]\n');
fprintf(fid, '\\centering\n');
fprintf(fid, '\\caption{Results of MIGD metric obtained by four ablation algorithms.}\n');
fprintf(fid, '\\label{tab:ablation_migd}\n');
fprintf(fid, '\\footnotesize\n');
fprintf(fid, '\\begin{tabular}{l%s}\n', repmat('c', 1, numel(algNames)));
fprintf(fid, '\\hline\n');
fprintf(fid, 'Problems (DF1--DF14) & %s \\\\\n', strjoin(algNames, ' & '));
fprintf(fid, '\\hline\n');

bestCells = arrayfun(@(a) sprintf('%d/%d', stats.bestCount(a), stats.nCase), ...
    1:numel(algNames), 'UniformOutput', false);
fprintf(fid, 'best/all & %s \\\\\n', strjoin(bestCells, ' & '));

vsMOEADCells = arrayfun(@(a) sprintf('%d/%d/%d', ...
    stats.vsMOEAD(a).plus, stats.vsMOEAD(a).minus, stats.vsMOEAD(a).equal), ...
    1:numel(algNames), 'UniformOutput', false);
fprintf(fid, '$+/-/=$ (VS MOEA/D) & %s \\\\\n', strjoin(vsMOEADCells, ' & '));

vsGBCTCells = arrayfun(@(a) sprintf('%d/%d/%d', ...
    stats.vsGBCT(a).plus, stats.vsGBCT(a).minus, stats.vsGBCT(a).equal), ...
    1:numel(algNames), 'UniformOutput', false);
fprintf(fid, '$+/-/=$ (VS GBCT-DMOEA) & %s \\\\\n', strjoin(vsGBCTCells, ' & '));

fprintf(fid, '\\hline\n');
fprintf(fid, '\\end{tabular}\n');
fprintf(fid, '\\end{table}\n');
fclose(fid);
end
