function [ugvOrder, uavOrder, ugvCoords, uavCoords] = decodeUAVUGV(x, env, cfg)
%DECODEUAVUGV Random-key decoding to UGV/UAV visit orders and coordinates.

nUGV = cfg.nUGV;
poolSize = cfg.nUAVPool;
nVisit = min(cfg.nUAVVisit, poolSize);

x = x(:)';
if numel(x) < nUGV + poolSize
    x = [x, rand(1, nUGV + poolSize - numel(x))];
end

[~, ugvOrder] = sort(x(1:nUGV), 'ascend');
ugvGlobal = env.ugvIdx(ugvOrder);
ugvCoords = env.allCoords(ugvGlobal, :);

[~, rankInPool] = sort(x(nUGV + 1:nUGV + poolSize), 'ascend');
selected = rankInPool(1:nVisit);
uavGlobal = env.uavPoolIdx(selected);
uavOrder = selected;
uavCoords = env.allCoords(uavGlobal, :);

end
