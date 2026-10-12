function printTable3Console(tableData, algNames, algFields)
%PRINTTABLE3CONSOLE Display Table III in command window.

fprintf('\n=== TABLE III: Path planning results ===\n');
fprintf('%-14s %-12s %10s %10s %10s\n', ...
    'Change ratio', 'Algorithms', 'UAV(km)', 'UGV(km)', 'Total(km)');

ratios = tableData.changeRatios;
for ri = 1:numel(ratios)
    row = tableData.rows{ri};
    crStr = sprintf('%.0f%%', ratios(ri) * 100);

    for ai = 1:numel(algNames)
        v = row.(algFields{ai});
        if ai == 1
            fprintf('%-14s %-12s %10s %10s %10s\n', ...
                crStr, algNames{ai}, fmtDash(v.uav), fmtDash(v.ugv), fmtDash(v.total));
        else
            fprintf('%-14s %-12s %10s %10s %10s\n', ...
                '', algNames{ai}, fmtDash(v.uav), fmtDash(v.ugv), fmtDash(v.total));
        end
        crStr = '';
    end
end
fprintf('\n');

end

function s = fmtDash(x)
if isnan(x)
    s = '-';
else
    s = sprintf('%.2f', x);
end
end
