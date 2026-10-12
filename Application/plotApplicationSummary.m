function plotApplicationSummary(results, algNames)
%PLOTAPPLICATIONSUMMARY Bar chart of mean total path length across runs.

meanTotal = [mean(results.ct.total, 'omitnan'), mean(results.np.total, 'omitnan')];
stdTotal = [std(results.ct.total, 0, 'omitnan'), std(results.np.total, 0, 'omitnan')];

figure('Name', 'Application Summary', 'Color', 'w');
b = bar(meanTotal);
b.FaceColor = 'flat';
b.CData = [0.20, 0.45, 0.75; 0.85, 0.33, 0.10];
hold on;
errorbar(1:2, meanTotal, stdTotal, 'k.', 'LineWidth', 1.2, 'CapSize', 12);
set(gca, 'XTickLabel', algNames);
ylabel('Total path length (UGV + UAV)');
title('Simplified UAV/UGV Application (mean over runs)');
grid on;
hold off;

saveas(gcf, 'app_summary_distance.png');

end
