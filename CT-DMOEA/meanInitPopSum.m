function v = meanInitPopSum(initPop, Problem, t)
%MEANINITPOPSUM Mean of (f1+f2+...) over initial population rows.

if isempty(initPop)
    v = NaN;
    return;
end

s = zeros(size(initPop, 1), 1);
for ii = 1:size(initPop, 1)
    s(ii) = sum(Problem.FObj(initPop(ii, :)', t));
end
v = mean(s);

end
