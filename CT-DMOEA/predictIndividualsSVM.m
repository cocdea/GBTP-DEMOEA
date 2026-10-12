function initPopulation = predictIndividualsSVM(tdX, tdY, tsX, tsY, testX, popSize, M, Problem, pt)
%PREDICTINDIVIDUALSSVM Standard SVM transfer (original CT-DMOEA, no granular balls).

tX = [tdX; tsX];
tY = [tdY; tsY];
tY(tY >= 0) = 1;
tY(tY < 0) = -1;

Length = floor(popSize / M);
if numel(unique(tY)) < 2
    initPopulation = fallbackPop(tdX, Length);
    return;
end

PredictVec = [];
try
    mdl = fitcsvm(tX, tY, 'KernelFunction', 'rbf', ...
        'BoxConstraint', 255, 'Standardize', true);
    PredictVec = predict(mdl, testX);
catch
    initPopulation = fallbackPop(tdX, Length);
    return;
end

initPopulation = selectPositive(testX, PredictVec, tdX, Length);

end

function initPopulation = selectPositive(testX, PredictVec, tdX, Length)
initPopulation = [];
j = 0;
for i = 1:numel(PredictVec)
    if PredictVec(i) == 1
        j = j + 1;
        initPopulation(j, :) = testX(i, :); %#ok<AGROW>
    end
end

initPopulation = initPopulation';
if size(initPopulation, 2) > Length
    initPopulation = initPopulation(:, 1:Length)';
elseif size(initPopulation, 2) == 0
    initPopulation = fallbackPop(tdX, Length);
else
    initPopulation = initPopulation';
end
end

function pop = fallbackPop(tdX, Length)
maxIndex = min(size(tdX, 1), Length);
pop = tdX(1:maxIndex, :);
end
