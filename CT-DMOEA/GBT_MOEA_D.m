function res = GBT_MOEA_D(Problem, popSize, MaxIt, T_parameter, group)
%GBT_MOEA_D GBSVM-based Transfer + MOEA/D (CBT-MOEA/D ablation variant).
%
%   After an environment change:
%     1) construct target-domain training data by simple selection
%        (getStSolutionSet only, NO granular-ball clustering selection);
%     2) GBSVM classifies promising / non-promising candidates;
%     3) promising solutions initialize the new population (random padding if needed);
%     4) run MOEA/D.
%
%   Does NOT use granular-ball-based clustering selection (GBS module).

res = CT_DMOEA_ablation(Problem, popSize, MaxIt, T_parameter, group, 'GBT');

end
