function clusterIndex = ClusterSelection(TargetPopX,SourcePopXset,sourceFlag,Problem,t)
%CLUSTERSELECTION 在多个候选簇中选择与目标环境更匹配的簇
%   此处显示详细说明
L = length(SourcePopXset);

num = 0;
for i=1:L
    if sourceFlag(i) == 0
        index = i;
        num = num + 1; 
    end   
end
if num == 1
   clusterIndex = index;
   return;
end

%{
m = Problem.NObj;
objectivesTarget = zeros(size(TargetPopX,2),m);
for i=1:size(TargetPopX,2)
    [objectivesTarget(i,:), ~] = Problem.FObj(TargetPopX(:,i)',t);
end
%}
angles = ones(1,L)*Inf;
for i=1:L
    if sourceFlag(i) == 0
        %{
        objectivesSource = zeros(size(SourcePopXset{i},2),m);
        for j=1:size(SourcePopXset{i},2)
            [objectivesSource(j,:), ~] = Problem.FObj(SourcePopXset{i}(:,j)',t);
        end
        [max_objectives,~] = max([objectivesTarget; objectivesSource],[],1);
        [min_objectives,~] = min([objectivesTarget; objectivesSource],[],1);
        angles(i) = computeAngle(TargetPopX,SourcePopXset{i},Problem,t,max_objectives,min_objectives);
        %}
        angles(i) = computeAngle(TargetPopX,SourcePopXset{i},Problem,t);
    end 
end

num = 0;
for i=1:size(angles,2)
      if angles(i) ~= Inf
         num = num + 1; 
      end
end

probs_indexs = zeros(2,num);
it_ = 1;
for i=1:size(angles,2)
   if angles(i) ~= Inf
       probs_indexs(1,it_) = angles(i);
       probs_indexs(2,it_) = i;
       it_ = it_ + 1;
   end
end

total_angles = 0;
for i=1:num
    total_angles = total_angles + probs_indexs(1,i);
end
%normalize
for i=1:num
   probs_indexs(1,i) = probs_indexs(1,i)/total_angles; 
end

%model -log(x)
for i=1:num
    if probs_indexs(1,i) <= 0
        probs_indexs(1,i) = 1e5;
    else
        probs_indexs(1,i) = -log(probs_indexs(1,i)); 
    end
end
total = 0;
for i=1:num
    total = total +  probs_indexs(1,i);
end
%compute probability
for i=1:num
    probs_indexs(1,i) = probs_indexs(1,i)/total;
end

ran  = rand (1, 1);
right = 0;
for i=1:num
    left = right;
    right = right + probs_indexs(1,i);
    if ran >= left && ran <= right
       clusterIndex = probs_indexs(2,i);
       break;   
    end
end

end

