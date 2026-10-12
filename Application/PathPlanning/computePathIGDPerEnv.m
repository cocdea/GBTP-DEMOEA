function IGD_T = computePathIGDPerEnv(res, Problem, cfg)
%COMPUTEPATHIGDPERENV Per-environment IGD using sampled reference front.

IGD_T = zeros(1, numel(res));
for T = 1:numel(res)
    t = T - 1;
    refPF = buildReferencePF(Problem, t, cfg);
    if isempty(refPF)
        IGD_T(T) = NaN;
        continue;
    end
    pof = res{T}.POF_iter{end};
    pof = normalizeParetoF(pof, 2);
    if isempty(pof)
        IGD_T(T) = NaN;
    else
        IGD_T(T) = IGD(pof', refPF');
    end
end

end

function F = normalizeParetoF(F, nObj)
F = double(F);
if size(F, 1) == nObj
    return;
end
if size(F, 2) == nObj
    F = F';
    return;
end
F = reshape(F(:)', nObj, []);
end
