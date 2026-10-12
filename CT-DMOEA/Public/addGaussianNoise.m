function newPopulation = addGaussianNoise(init_population, Nini, n, Problem)
%ADDGAUSSIANNOISE 此处显示有关此函数的摘要
%   此处显示详细说明
if Nini > size(init_population, 2)
    error("Nini is large");
end
VarMin=Problem.XLow;
VarMax=Problem.XUpp;

newPopulation = zeros(n,Nini);
Indexs = randperm(size(init_population, 2), Nini);
for i=1:Nini
     newPopulation(:,i) = init_population(:,Indexs(i));
end
samples = zeros(1,n*Nini);
Ind = 1;
for j=1:Nini
    for i=1:n
        samples(Ind) = newPopulation(i, j);
        Ind = Ind + 1;
    end 
end
mean_value = mean(samples);
variance_value = var(samples);
std_value = std(samples);

for i=1:Nini
    % flag = (-1)^i;
    % noise = mean_value + variance_value .* randn(n,1);
    %noise = randn(n,1);
    noise = std_value .* randn(n,1);
    newPopulation(:,i) = newPopulation(:,i) + noise;
end

for j=1:Nini
    for i=1:n
        newPopulation(i,j) = min(max(newPopulation(i,j),VarMin(i)), VarMax(i));
    end
end

end

