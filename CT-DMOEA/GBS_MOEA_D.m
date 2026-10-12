function res = GBS_MOEA_D(Problem, popSize, MaxIt, T_parameter, group)
%GBS_MOEA_D Granular-Ball Selection + MOEA/D (CBS-MOEA/D ablation variant).
%
%   After an environment change:
%     1) build target candidate pool (one-generation MOEA/D + noise);
%     2) granular-ball clustering selection (getStSolutionSet ->
%        HierarchicalClustering -> bestSolutionSelection);
%     3) use selected representatives as part of the initial population;
%     4) fill the rest with random individuals;
%     5) run MOEA/D.
%
%   Does NOT use GBSVM / clustering transfer (CBT).

res = CT_DMOEA_ablation(Problem, popSize, MaxIt, T_parameter, group, 'GBS');

end
