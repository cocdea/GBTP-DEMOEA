%创建MOEA/D子问题（权重向量与邻域）
% Copyright (c) 2015, Yarpiz (www.yarpiz.com)
% All rights reserved. Please read the "license.txt" for license terms.
%
% Project Code: YPEA124
% Project Title: Implementation of MOEA/D
% Muti-Objective Evolutionary Algorithm based on Decomposition
% Publisher: Yarpiz (www.yarpiz.com)
% 
% Developer: S. Mostapha Kalami Heris (Member of Yarpiz Team)
% 
% Contact Info: sm.kalami@gmail.com, info@yarpiz.com
%

function sp=CreateSubProblems(nObj,nPop,T)

    empty_sp.lambda=[];
    empty_sp.Neighbors=[];

    sp=repmat(empty_sp,nPop,1);

    if nObj == 2
        for i=1:nPop   
            lambda = [i/nPop; 1-i/nPop];
            sp(i).lambda=lambda;
        end
        LAMBDA=[sp.lambda]';
        D=pdist2(LAMBDA,LAMBDA);
        for i=1:nPop
            [~, SO]=sort(D(i,:));
            sp(i).Neighbors=SO(1:T);
        end
    end
    
    if nObj == 3
        lambda = initialWeight3obj(16, nObj);
        it = 1;
        for i=1:size(lambda,1)
            if i ~= 51 && i ~= 101 && i ~= 151
               sp(it).lambda = lambda(i,:)'; 
               it = it + 1;
            end
        end
        LAMBDA=[sp.lambda]';
        D=pdist2(LAMBDA,LAMBDA);
        for i=1:nPop
            [~, SO]=sort(D(i,:));
            sp(i).Neighbors=SO(1:T);
        end
    end
  
end