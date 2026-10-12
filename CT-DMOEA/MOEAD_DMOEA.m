function res = MOEAD_DMOEA(Problem, popSize, MaxIt, T_parameter, group)
%MOEAD_DMOEA Baseline: random restart MOEA/D at every environment (no transfer).
%   Ablation counterpart of MOEA/D in the original CT-DMOEA paper.

res = RR_DMOEA(Problem, popSize, MaxIt, T_parameter, group);

end
