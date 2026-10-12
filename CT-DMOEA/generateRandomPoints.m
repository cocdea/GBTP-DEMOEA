%生成随机候选点（用于补充初始化种群）
function resPop=generateRandomPoints(Pop, Problem)

VarMin=Problem.XLow;
VarMax=Problem.XUpp;
resPop=Pop;
for j=1:size(Pop,2)
    mutIndex=randperm(ceil(size(Pop,1)));
    mutIndex = mutIndex(1:5);
    for i=1:5
        id = mutIndex(i);
        %temp=cauchyrnd(Pop(id,j),1);
        temp = rand;
        resPop(id,j)= resPop(id,j) + temp;
    end
end

d = size(Pop,1);
for j=1:size(resPop,2)
    for i=1:d
        resPop(i,j) = min(max(resPop(i,j),VarMin(i)), VarMax(i));
    end
end

end