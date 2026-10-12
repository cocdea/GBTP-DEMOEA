function writePathPlanningApplicationTable(rootDir, results, algNames, algFields)
%WRITEPATHPLANNINGAPPLICATIONTABLE Mean routing quality over all environments.

outFile = fullfile(rootDir, 'pathplan_table_application.txt');
fid = fopen(outFile, 'w');

fprintf(fid, 'Algorithm\tMean(f1+f2)\tStd\tRank\n');

nAlg = numel(algFields);
means = zeros(nAlg, 1);
stds = zeros(nAlg, 1);
for k = 1:nAlg
    means(k) = mean(results.(algFields{k}).meanAllEnv, 'omitnan');
    stds(k) = std(results.(algFields{k}).meanAllEnv, 0, 'omitnan');
end

rank = nan(nAlg, 1);
valid = ~isnan(means);
if any(valid)
    [~, order] = sort(means(valid));
    validIdx = find(valid);
    for r = 1:numel(order)
        rank(validIdx(order(r))) = r;
    end
end

for k = 1:nAlg
    if isnan(rank(k))
        fprintf(fid, '%s\t%.4f\t%.4f\t%s\n', algNames{k}, means(k), stds(k), 'NaN');
    else
        fprintf(fid, '%s\t%.4f\t%.4f\t%d\n', algNames{k}, means(k), stds(k), rank(k));
    end
end

fclose(fid);

fprintf('\n=== Application results (mean over ALL environments) ===\n');
if ~any(valid)
    fprintf('ERROR: All algorithms NaN. Did you run runPathPlanningApp to completion?\n');
    fprintf('       Try: testPathPlanningSmoke  then  runPathPlanningApp with cfg.quickMode=true\n\n');
end
fprintf('%-14s %12s %10s %6s\n', 'Algorithm', 'Mean(f1+f2)', 'Std', 'Rank');
for k = 1:nAlg
    if isnan(rank(k))
        fprintf('%-14s %12.4f %10.4f %6s\n', algNames{k}, means(k), stds(k), 'NaN');
    else
        fprintf('%-14s %12.4f %10.4f %6d\n', algNames{k}, means(k), stds(k), rank(k));
    end
end
fprintf('\n');

end
