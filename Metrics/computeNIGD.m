function nigd = computeNIGD(IGD_tr, IGD_rnd, startT)
%COMPUTENIGD Negative transfer IGD (paper Eq. 16).
% NIGD = sum over t of (IGD_tr - IGD_rnd) when IGD_tr > IGD_rnd.

if nargin < 3
    startT = 2;
end

nigd = 0;
n = min(numel(IGD_tr), numel(IGD_rnd));
for T = startT:n
    if IGD_tr(T) > IGD_rnd(T)
        nigd = nigd + (IGD_tr(T) - IGD_rnd(T));
    end
end

end
