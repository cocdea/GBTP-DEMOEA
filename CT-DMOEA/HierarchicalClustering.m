function [C_HCMset, C_HCMindex] = HierarchicalClustering(st,Problem,t,K)
%HIERARCHICALCLUSTERING 层次聚类，将李世杰按结构相似性分簇
st_size = size(st,2);
if st_size == 0
    error('HierarchicalClustering:EmptyInput', 'Input st is empty.');
end
K = min(K, st_size);

m = Problem.NObj;
Objectives = zeros(st_size,m);
for i=1:st_size
    [Objectives(i,:), ~] = Problem.FObj(st(:,i)',t);
end
%{
[max_objectives,~] = max(Objectives,[],1);
[min_objectives,~] = min(Objectives,[],1);
%}
minAngle = Inf;
minAngles = ones(1,st_size)*Inf;
minIndexs = ones(1,st_size)*(-1);
flag = zeros(1,st_size);
list_ = cell(1, st_size);
list_index = cell(1, st_size);
index = ones(1,4)*(-1);

for i=1:st_size
   list_{i} = st(:,i); 
end

for i=1:st_size
   list_index{i} = i; 
end

for i=1:st_size
    min_ = Inf;
    for j=1:st_size
        if i ~= j
            % compute the angle of cluster_i'centroid and cluster_j'centroid
            total_i = zeros(1,m);
            for ii=1:size(list_index{i},2)
                total_i = total_i + Objectives(list_index{i}(ii),:);
            end
            centroid_i = total_i/size(list_index{i},2);
            total_j = zeros(1,m);
            for jj=1:size(list_index{j},2)
               total_j  = total_j + Objectives(list_index{j}(jj),:);
            end
            centroid_j = total_j/size(list_index{j},2);
            top = abs(centroid_i*centroid_j');
            bottom = norm(centroid_i')*norm(centroid_j');
            res = top/bottom;
            if res >= 1
               res = 1;
            end
            angle = acos(res);
            if angle<min_
                min_ = angle;
                index(1) = i;
                index(2) = j;
            end
        end
    end
    minAngles(i) = min_;
    minIndexs(i) = index(2);
    if min_<minAngle
        minAngle = min_;
        index(3) = index(1);
        index(4) = index(2);
    end    
end

while st_size > K
    union_ = [list_{index(3)} list_{index(4)}];
    union_index = [list_index{index(3)} list_index{index(4)}];
    flag(index(3)) = 1;
    list_{index(4)} = union_;
    list_index{index(4)} = union_index;
    
    for i=1:size(st,2)
        if minIndexs(i) == index(3) && flag(i) == 0
            min_ = Inf;
            sb = -1;
            for j=1:size(st,2)
                if i ~= j && flag(j) == 0
                    total_i = zeros(1,m);
                    for ii=1:size(list_index{i},2)
                        total_i = total_i + Objectives(list_index{i}(ii),:);
                    end
                    centroid_i = total_i/size(list_index{i},2);
                    total_j = zeros(1,m);
                    for jj=1:size(list_index{j},2)
                        total_j  = total_j + Objectives(list_index{j}(jj),:);
                    end
                    centroid_j = total_j/size(list_index{j},2);
                    top = abs(centroid_i*centroid_j');
                    bottom = norm(centroid_i')*norm(centroid_j');
                    res = top/bottom;
                    if res >= 1
                        res = 1;
                    end
                    ss = acos(res);
                    if ss < min_
                       min_ = ss;
                       sb = j;
                    end
                end
            end
            minAngles(i) = min_;
            minIndexs(i) = sb; 
        end
    end
    
    for i=1:size(st,2)
        if minIndexs(i)==index(4) && flag(i)==0
            min_ = Inf;
            sb = -1;
            for j=1:size(st,2)
               if i ~= j && flag(j) == 0
                   total_i = zeros(1,m);
                   for ii=1:size(list_index{i},2)
                         total_i = total_i + Objectives(list_index{i}(ii),:);
                   end
                   centroid_i = total_i/size(list_index{i},2);
                   total_j = zeros(1,m);
                   for jj=1:size(list_index{j},2)
                        total_j  = total_j + Objectives(list_index{j}(jj),:);
                   end
                   centroid_j = total_j/size(list_index{j},2);
                   top = abs(centroid_i*centroid_j');
                   bottom = norm(centroid_i')*norm(centroid_j');
                   res = top/bottom;
                   if res >= 1
                        res = 1;
                   end
                   ss = acos(res);
                   if ss < min_
                      min_ = ss;
                      sb = j;
                   end
               end
            end
            minAngles(i) = min_;
            minIndexs(i) = sb;
        end  
    end
    
    sAngle = Inf;
    for p=1:size(st,2)
        if flag(p)==0
            if minAngles(p)<sAngle
               sAngle = minAngles(p);
               index(3) = p;
               index(4) = minIndexs(p);
            end
        end
    end
    st_size = st_size-1;

end

num = 0;
C_HCMset = cell(1, K);
C_HCMindex = cell(1,K);
it_ = 1;
for i=1:size(st,2)
   if flag(i) == 0
       C_HCMset{it_} = list_{i};
       C_HCMindex{it_} = list_index{i};
       it_ = it_ + 1;
       num = num + 1;
   end
end

if num ~= K
   disp("E");
   error("E");
end

end

