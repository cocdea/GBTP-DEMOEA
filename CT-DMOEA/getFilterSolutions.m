function NDS = getFilterSolutions(SolutionSet,Problem,t,K )
%GETFILTERSOLUTIONS 对候选解过滤，保留更优或更具有代表性的解
%   此处显示详细说明
    if size(SolutionSet,1) < K
        NDS = SolutionSet;  
    else
       PopF = zeros(size(SolutionSet,1), Problem.NObj);
       for i=1:size(SolutionSet,1)
         [PopF(i,:),~] = Problem.FObj(SolutionSet(i,:),t);
       end
       [Rank,~,~] = fastNonDominatedSort(PopF);
       front = 1;
       index = 1;
       NDS = [];
       while size(NDS,1) < K
           for j=1:size(SolutionSet,1)
              if Rank(j)==front
                 NDS(index,:) = SolutionSet(j,:);
                 index = index + 1;
              end
           end
           front = front + 1;
       end      
    end

end

