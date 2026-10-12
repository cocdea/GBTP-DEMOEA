function res = RR_DMOEA(Problem, popSize, MaxIt, T_parameter, group)
%RR_DMOEA Random restart MOEA/D at every environment (no transfer).

numEnv = floor(T_parameter(group, 3) / T_parameter(group, 2));
res = cell(1, numEnv);

for T = 1:numEnv
    t = 1 / T_parameter(group, 1) * (T - 1);
    fprintf(' %d', T);
    [PopX, Pareto, POF_iter] = moead(Problem, popSize, MaxIt, t);
    res{T}.PopX = PopX;
    res{T}.turePOF = getBenchmarkPOF(Problem.Name, group, T, T_parameter);
    res{T}.POF_iter = POF_iter;
    res{T}.Pareto = Pareto;
end

end
