function res = CT_DMOEA_np(Problem, popSize, MaxIt, T_parameter, group)
%CT_DMOEA_NP CT-DMOEAnp: direct POS transfer without CBS/CBT (paper Fig.2).
% When T>1, the previous environment Pareto set initializes MOEA/D directly.

d = size(Problem.XLow, 1);
numEnv = floor(T_parameter(group, 3) / T_parameter(group, 2));
res = cell(1, numEnv);

for T = 1:numEnv
    t = 1 / T_parameter(group, 1) * (T - 1);
    fprintf(' %d', T);

    if T == 1
        [PopX, Pareto, POF_iter] = moead(Problem, popSize, MaxIt, t);
    else
        initPop = LastPareto';
        if size(initPop, 1) > popSize
            initPop = initPop(1:popSize, :);
        end
        res{T}.initPopMeanSum = meanInitPopSum(initPop, Problem, t);
        [PopX, Pareto, POF_iter] = moead(Problem, popSize, MaxIt, t, initPop');
    end

    res{T}.PopX = PopX;
    LastPareto = Pareto.X;
    res{T}.turePOF = getBenchmarkPOF(Problem.Name, group, T, T_parameter);
    res{T}.POF_iter = POF_iter;
    res{T}.Pareto = Pareto;
end

end
