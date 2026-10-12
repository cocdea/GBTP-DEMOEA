function [objs, extra] = evaluateUAVUGV(x, t, cfg)
%EVALUATEUAVUGV Two objectives: UGV path length and UAV path length.

global APP_UAVUGV_ENVS

if isempty(APP_UAVUGV_ENVS)
    error('APP_UAVUGV_ENVS not set. Call setApplicationEnv before running CT_DMOEA.');
end

envIdx = timeToEnvIndex(t, numel(APP_UAVUGV_ENVS));
env = APP_UAVUGV_ENVS{envIdx};

[ugvOrder, uavOrder, ugvCoords, uavCoords] = decodeUAVUGV(x, env, cfg);

f1 = tourLength(ugvCoords, env.depot);
f2 = tourLength(uavCoords, env.depot);
objs = [f1, f2];

if nargout > 1
    extra.ugvOrder = ugvOrder;
    extra.uavOrder = uavOrder;
    extra.ugvCoords = ugvCoords;
    extra.uavCoords = uavCoords;
    extra.envIdx = envIdx;
end

end

function idx = timeToEnvIndex(t, nEnv)
idx = round(t) + 1;
idx = min(max(idx, 1), nEnv);
end
