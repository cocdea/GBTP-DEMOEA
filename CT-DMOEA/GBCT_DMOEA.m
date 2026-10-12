function res = GBCT_DMOEA(Problem, popSize, MaxIt, T_parameter, group)
%GBCT_DMOEA Full method: granular-ball selection + GBSVM transfer + MOEA/D.
%   Equivalent to CT_DMOEA with useGBSVM = true.

if ~isfield(Problem, 'AppConfig')
    Problem.AppConfig = struct();
end
Problem.AppConfig.useGBSVM = true;

res = CT_DMOEA_ablation(Problem, popSize, MaxIt, T_parameter, group, 'GBCT');

end
