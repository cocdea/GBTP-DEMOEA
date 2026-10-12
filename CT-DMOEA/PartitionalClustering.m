function SolutionSet = PartitionalClustering(Problem,t,popX)
%P 基于划分思想对解集聚类并组织结构信息
%   此处显示详细说明
m_Clu = Problem.NObj;
xSize = size(popX, 2);
cs = floor(xSize/m_Clu);
SolutionSet = cell(1, m_Clu);

NormalizeObjectives = getNormalizeObjectives(Problem,t,popX);

isAssociated = zeros(1,xSize);
permutation = randperm(m_Clu);

for i = 1:m_Clu
    n = permutation(i);
    if i == m_Clu
        num = 0;
        for j=1:xSize
            if isAssociated(j) == 0
                num = num + 1;
            end
        end
        pop_tmp = zeros(size(popX, 1),num);
        index = 1;
        for j=1:xSize
            if isAssociated(j) == 0
                pop_tmp(:,index) = popX(:,j);
                index = index + 1;
            end
        end
        SolutionSet{n} = pop_tmp;
        break;
    end
    currentSize = xSize;
    for j = 1:xSize
        if isAssociated(j) == 1
            currentSize = currentSize - 1;
        end
    end
    X_tmp = zeros(currentSize,2);
    index = 1;
    for j = 1:xSize
        if isAssociated(j) == 0
            molecule = NormalizeObjectives(j,n);
            denominator = 0;
            for k=1:m_Clu
                denominator = denominator + NormalizeObjectives(j,k)^2;
            end
            denominator = sqrt(denominator);
            X_tmp(index,1) = acos(abs(molecule/denominator));
            X_tmp(index,2) = j;
            index = index + 1;
        end
    end  
    
    [X_tmp,~] = sortrows(X_tmp,1);
    for j=1:cs
        isAssociated(X_tmp(j,2))=1;
    end
    
    pop_tmp = zeros(size(popX, 1),cs);
    for j=1:cs
        pop_tmp(:,j) = popX(:,X_tmp(j,2));
    end
    SolutionSet{n} = pop_tmp;
    
end

end

