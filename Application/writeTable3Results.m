function writeTable3Results(rootDir, tableData, algNames, algFields)
%WRITETABLE3RESULTS Write paper Table III style text file.

outFile = fullfile(rootDir, 'Table3-results.txt');
fid = fopen(outFile, 'w');

fprintf(fid, 'TABLE III\n');
fprintf(fid, 'RESULTS OF COMPARED ALGORITHMS FOR PATH PLANNING\n');
fprintf(fid, '(UAV/UGV km; compromise solution on final environment, mean over reps)\n\n');
fprintf(fid, '%-14s %-12s %10s %10s %10s\n', ...
    'Change ratio', 'Algorithms', 'UAV(km)', 'UGV(km)', 'Total(km)');

ratios = tableData.changeRatios;
for ri = 1:numel(ratios)
    cr = ratios(ri);
    row = tableData.rows{ri};
    crStr = sprintf('%.0f%%', cr * 100);

    for ai = 1:numel(algNames)
        v = row.(algFields{ai});
        if ai == 1
            fprintf(fid, '%-14s %-12s %10s %10s %10s\n', ...
                crStr, algNames{ai}, fmtKm(v.uav), fmtKm(v.ugv), fmtKm(v.total));
        else
            fprintf(fid, '%-14s %-12s %10s %10s %10s\n', ...
                '', algNames{ai}, fmtKm(v.uav), fmtKm(v.ugv), fmtKm(v.total));
        end
        crStr = '';
    end
    fprintf(fid, '\n');
end

fclose(fid);

end

function s = fmtKm(x)
if isnan(x)
    s = '-';
else
    s = sprintf('%.2f', x);
end
end
