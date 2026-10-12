function targetPopX = bestSolutionSelection(C_HCMset,Problem,t,K)
%BESTSOLUTIONSELECTION 从聚类结果中挑选用于初始化的优选解
%   此处显示详细说明
d = size(Problem.XLow,1);
targetPopX = zeros(d,K);

for i=1:K
        min_c = Inf;
        min_cid = -1;
        for j=1:size(C_HCMset{i},2)
            [objectives, ~] = Problem.FObj(C_HCMset{i}(:,j)',t);
            convergence = sum(objectives);
            if convergence < min_c
               min_c = convergence;
               min_cid = j;
            end
        end
        targetPopX(:,i) =  C_HCMset{i}(:,min_cid);
end

end

