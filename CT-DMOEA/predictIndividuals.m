
function [initPopulation] = predictIndividuals(tdX,tdY,tsX,tsY,testX,popSize,M,Problem,pt)
% GBSVM classifier for CBT:
% 1) build granular balls
% 2) optimize alpha with PSO under GBSVM objective
% 3) recover w,b and classify test candidates

tX = [tdX; tsX];
tY = [tdY; tsY];
tY(tY >= 0) = 1;
tY(tY < 0) = -1;

[ballC, ballR, ballY] = buildGranularBalls(tX, tY, Problem, pt);

% Fallback when granularized data collapses to one class
if isempty(ballC) || numel(unique(ballY)) < 2
    ballC = tX;
    ballR = zeros(size(tX,1),1);
    ballY = tY;
end

qmax = getQmax(Problem);
[w, b] = trainGBSVM(ballC, ballR, ballY, qmax);
PredictVec = sign(testX * w + b);
PredictVec(PredictVec == 0) = 1;

initPopulation = [];
j = 0;
for i = 1:size(PredictVec,1)
    if PredictVec(i) == 1
        j = j + 1;
        initPopulation(j,:) = testX(i,:); %#ok<AGROW>
    end
end

initPopulation = initPopulation';
Length = floor(popSize / M);
if size(initPopulation,2) > Length
    initPopulation = initPopulation(:,1:Length);
    initPopulation = initPopulation';
elseif size(initPopulation,2) == 0
    maxIndex = min([size(tdX,1), Length]);
    initPopulation = tdX(1:maxIndex,:);
else
    initPopulation = initPopulation';
end
end

function [w, b] = trainGBSVM(ballC, ballR, ballY, qmax)
% MATLAB implementation of GBSVM.py core equations.
nBall = size(ballC,1);
d = size(ballC,2);
C = 255;

if nBall < 2 || numel(unique(ballY)) < 2
    w = zeros(d,1);
    b = 0;
    return;
end

[alphaBest, ~] = psoOptimizeAlpha(ballC, ballR, ballY, C, qmax);
[w, b] = recoverWb(alphaBest, ballC, ballR, ballY, C);
end

function [bestX, bestF] = psoOptimizeAlpha(ballC, ballR, ballY, C, qmax)
dim = size(ballC,1);
pop = min(max(40, 5 * dim), 160);
maxIter = qmax;
wInertia = 0.5;
c1 = 1.6;
c2 = 1.6;

X = C * rand(pop, dim);
V = zeros(pop, dim);
P = X;
PF = inf(pop,1);

for i = 1:pop
    PF(i) = gbsvmObjective(X(i,:)', ballC, ballR, ballY);
end
[bestF, gIdx] = min(PF);
bestX = P(gIdx,:)';

for iter = 1:maxIter
    for i = 1:pop
        r1 = rand(1,dim);
        r2 = rand(1,dim);
        V(i,:) = wInertia * V(i,:) + c1 * r1 .* (P(i,:) - X(i,:)) + c2 * r2 .* (bestX' - X(i,:));
        X(i,:) = X(i,:) + V(i,:);
        X(i,:) = min(max(X(i,:), 0), C);

        f = gbsvmObjective(X(i,:)', ballC, ballR, ballY);
        if f < PF(i)
            PF(i) = f;
            P(i,:) = X(i,:);
        end
        if f < bestF
            bestF = f;
            bestX = X(i,:)';
        end
    end
end
end

function f = gbsvmObjective(alpha, ballC, ballR, ballY)
A = (alpha .* ballY)' * ballC;
B = alpha' * ballR;
wl = norm(A) - B;
f = 0.5 * (wl ^ 2) - sum(alpha);
end

function [w, b] = recoverWb(alpha, ballC, ballR, ballY, C)
A = (alpha .* ballY)' * ballC;
B = alpha' * ballR;
wl = norm(A) - B;
den = wl + B;
if abs(den) < 1e-12
    den = sign(den + eps) * 1e-12;
end
w = (wl / den) * A';

supportMask = alpha > max(1e-6, 0.01 * C);
supportIdx = find(supportMask);
if isempty(supportIdx)
    [~, idx] = max(alpha);
    supportIdx = idx;
end

bVals = zeros(numel(supportIdx),1);
for k = 1:numel(supportIdx)
    i = supportIdx(k);
    yi = ballY(i);
    if abs(yi) < 1e-12
        yi = 1;
    end
    b1 = (1 + wl * ballR(i)) / yi;
    bVals(k) = b1 - ballC(i,:) * w;
end
b = mean(bVals);
end

function [ballC, ballR, ballY] = buildGranularBalls(X, Y, Problem, pt)
% Build class-aware balls to preserve label purity.
posIdx = find(Y == 1);
negIdx = find(Y == -1);

[cPos, rPos] = buildBallsForClass(X(posIdx,:), Problem, pt);
[cNeg, rNeg] = buildBallsForClass(X(negIdx,:), Problem, pt);

ballC = [cPos; cNeg];
ballR = [rPos; rNeg];
ballY = [ones(size(cPos,1),1); -ones(size(cNeg,1),1)];
end

function [centers, radii] = buildBallsForClass(Xc, Problem, pt)
n = size(Xc,1);
if n == 0
    centers = zeros(0, size(Xc,2));
    radii = zeros(0,1);
    return;
elseif n == 1
    centers = Xc;
    radii = 0;
    return;
end

Kc = max(1, min(n, round(sqrt(n))));
[~, idxCells] = HierarchicalClustering(Xc', Problem, pt, Kc);
centers = zeros(numel(idxCells), size(Xc,2));
radii = zeros(numel(idxCells), 1);

for i = 1:numel(idxCells)
    idx = idxCells{i};
    Xi = Xc(idx,:);
    ci = mean(Xi,1);
    centers(i,:) = ci;
    d = sqrt(sum((Xi - ci).^2, 2));
    radii(i) = mean(d);
end
end

function qmax = getQmax(Problem)
% Paper setting: Q_max = 6 PSO iterations for GBSVM alpha optimization.
qmax = 6;
if nargin >= 1 && isstruct(Problem) && isfield(Problem, 'AppConfig') ...
        && isfield(Problem.AppConfig, 'Qmax')
    qmax = Problem.AppConfig.Qmax;
end
qmax = max(1, round(qmax));
end


