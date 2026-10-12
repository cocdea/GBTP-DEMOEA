function [C_Kmeans_set,C_Kmeans_index] = KmeansClustering(pop,Problem,t,K)
%KMEANSCLUSTERING K-means聚类实现，用于分区或簇中心构建
%   此处显示详细说明

popsize = size(pop,2);
m = Problem.NObj;
Objectives = zeros(popsize,m);
Clusters_index = ones(1,popsize)*(-1);

for i=1:popsize
    [Objectives(i,:), ~] = Problem.FObj(pop(:,i)',t);
end
centroids = zeros(K,m);
init = randperm(popsize,K);
for i=1:K
   centroids(i,:) = Objectives(init(i),:);
end

while true
    flag = false;
    for i=1:K-1
        for j=i+1:K
           top = abs(centroids(i,:)*centroids(j,:)');
           bottom = norm(centroids(i,:)') * norm(centroids(j,:)');
           result = top/bottom;
           if result >= 1
               result = 1;
           end
           theta = acos(result);
           if theta < 1e-5
              flag = true; 
           end   
        end   
    end
    if flag
        init = randperm(popsize,K);
        for i=1:K
            centroids(i,:) = Objectives(init(i),:);
        end
    else
       break; 
    end
end

iterations = 100;

for i=1:iterations
    for j=1:popsize
        minAngle = Inf;
        clusterIndex = -1;
        for jj=1:K
            top = abs(centroids(jj,:)*Objectives(j,:)');
            bottom = norm(centroids(jj,:)') * norm(Objectives(j,:)');
            res = top/bottom;
            if res >= 1
               res = 1; 
            end
            angle = acos(res);
            if angle < minAngle
               clusterIndex = jj; 
               minAngle = angle;
            end
        end
        Clusters_index(j) = clusterIndex; 
    end
    for j=1:K
       temp = [];
       for jj=1:popsize
          if Clusters_index(jj) == j
             temp = [temp ; Objectives(jj,:)]; 
          end
       end
       if isempty(temp)
           C_Kmeans_set = [];
           C_Kmeans_index = [];
           return
       end
       try
       centroids(j,:) = sum(temp,1)./size(temp,1);
       catch ErrorInfo
          disp(ErrorInfo);
          error("E");
       end

    end   
end

C_Kmeans_set = cell(1,K);
C_Kmeans_index = cell(1,K);
for i=1:K
   temp1 = [];
   temp2 = [];
   for j=1:popsize
      if  Clusters_index(j) == i
          temp1 = [temp1 pop(:,j)];
          temp2 = [temp2 j];
      end  
   end
   C_Kmeans_set{i} = temp1; 
   C_Kmeans_index{i} = temp2;
end

end

