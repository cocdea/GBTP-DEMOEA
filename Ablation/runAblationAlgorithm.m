function res = runAblationAlgorithm(algName, Problem, popSize, MaxIt, T_parameter, group)
%RUNABLATIONALGORITHM Dispatch one ablation algorithm by name.
%   Supported names:
%     'MOEA/D'      - random restart baseline
%     'GBS-MOEA/D'  - granular-ball selection only
%     'GBT-MOEA/D'  - GBSVM transfer only
%     'GBCT-DMOEA'  - full method

switch algName
    case 'MOEA/D'
        res = MOEAD_DMOEA(Problem, popSize, MaxIt, T_parameter, group);
    case 'GBS-MOEA/D'
        res = GBS_MOEA_D(Problem, popSize, MaxIt, T_parameter, group);
    case 'GBT-MOEA/D'
        res = GBT_MOEA_D(Problem, popSize, MaxIt, T_parameter, group);
    case 'GBCT-DMOEA'
        res = GBCT_DMOEA(Problem, popSize, MaxIt, T_parameter, group);
    otherwise
        error('runAblationAlgorithm:UnknownAlg', ...
            'Unknown algorithm: %s', algName);
end

end
