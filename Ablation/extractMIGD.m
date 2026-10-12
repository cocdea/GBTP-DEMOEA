function migd = extractMIGD(res)
%EXTRACTMIGD Mean IGD over all environments (MIGD).

numEnv = numel(res);
igdEnv = zeros(1, numEnv);

for T = 1:numEnv
    POFIter = res{T}.POF_iter;
    POFbenchmark = res{T}.turePOF;
    pof = POFIter{end};
    pof(imag(pof) ~= 0) = abs(pof(imag(pof) ~= 0));
    igdEnv(T) = IGD(pof', POFbenchmark);
end

migd = mean(igdEnv);

end
