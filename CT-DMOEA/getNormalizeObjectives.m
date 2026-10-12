function NormalizeObjectives = getNormalizeObjectives(Problem,t,popX)
%GETNORMALIZEOBJECTIVE 目标值归一化，便于跨目标比较与角度计算
%   此处显示详细说明
m = Problem.NObj;
xSize = size(popX, 2);

NormalizeObjectives = zeros(xSize,m);

for i=1:xSize
    [NormalizeObjectives(i,:), ~] = Problem.FObj(popX(:,i)',t);
end

[max_eachcol,~] = max(NormalizeObjectives,[],1);
[min_eachcol,~] = min(NormalizeObjectives,[],1);

for i=1:xSize
    for j=1:m
        NormalizeObjectives(i,j) = (NormalizeObjectives(i,j)-min_eachcol(j))/(max_eachcol(j)-min_eachcol(j));
    end
end

end

