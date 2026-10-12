function refPF = buildReferencePF(Problem, t, cfg)
%BUILDREFERENCEPF Approximate reference PF by random-key sampling.

nObj = Problem.NObj;
F = zeros(nObj, cfg.refSampleSize);

for i = 1:cfg.refSampleSize
    x = rand(cfg.nTasks, 1);
    F(:, i) = Problem.FObj(x', t)';
end

refPF = getNonDominatedSet(F);

end

function nd = getNonDominatedSet(F)
%F is nObj x n
n = size(F, 2);
keep = true(1, n);
for i = 1:n
    if ~keep(i)
        continue;
    end
    for j = 1:n
        if i == j || ~keep(j)
            continue;
        end
        if dominates(F(:, j), F(:, i))
            keep(i) = false;
            break;
        end
    end
end
nd = F(:, keep);
end

function flag = dominates(a, b)
flag = all(a <= b) && any(a < b);
end
