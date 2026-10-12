function st = getStSolutionSet(SolutionSet, Problem, t, K)
%GETSTSOLUTIONSET Select up to K solutions by non-dominated sorting; pad if needed.

n = size(SolutionSet, 2);
if n == 0
    error('getStSolutionSet:EmptyInput', 'SolutionSet is empty.');
end

PopF = zeros(Problem.NObj, n);
for i = 1:n
    PopF(:, i) = Problem.FObj(SolutionSet(:, i)', t)';
end

[Rank, ~, ~] = fastNonDominatedSort(PopF');
front = 1;
st = [];

while size(st, 2) < K && front <= max(Rank)
    for j = 1:n
        if Rank(j) == front
            st(:, end + 1) = SolutionSet(:, j); %#ok<AGROW>
            if size(st, 2) >= K
                break;
            end
        end
    end
    front = front + 1;
end

if size(st, 2) < K
    need = K - size(st, 2);
    pick = randi(n, 1, need);
    st = [st, SolutionSet(:, pick)];
end

st = st(:, 1:K);
end
