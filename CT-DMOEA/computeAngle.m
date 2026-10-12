function angle = computeAngle(HCM_set1,HCM_set2,Problem,t,max_objectives,min_objectives)
%COMPUTEANGLE ����ػ��������ļнǣ����ڴ�ƥ��/�������ж�
%   �˴���ʾ��ϸ˵��
size_1 = size(HCM_set1,2);
size_2 = size(HCM_set2,2);
m = Problem.NObj;
objectives_1 = zeros(size_1,m);
objectives_2 = zeros(size_2,m);
for i=1:size_1
    [objectives_1(i,:), ~] = Problem.FObj(HCM_set1(:,i)',t);
end
for i=1:size_2
    [objectives_2(i,:), ~] = Problem.FObj(HCM_set2(:,i)',t);
end

centroids_1 = sum(objectives_1,1)/size_1;
centroids_2 = sum(objectives_2,1)/size_2;

if nargin == 6
    normalize_centroids_1 = (centroids_1 - min_objectives)./(max_objectives - min_objectives);
    normalize_centroids_2 = (centroids_2 - min_objectives)./(max_objectives - min_objectives);
end

if nargin == 4
    normalize_centroids_1 = centroids_1;
    normalize_centroids_2 = centroids_2;
end

top = 0;
bottom1 = 0;
bottom2 = 0;
for i=1:m
    top = top + normalize_centroids_1(i)*normalize_centroids_2(i);
    bottom1 = bottom1 + normalize_centroids_1(i)^2;
    bottom2 = bottom2 + normalize_centroids_2(i)^2;
end
bottom = sqrt(bottom1)*sqrt(bottom2);
if bottom < 1e-12
    angle = pi/2;
    return;
end
ratio = top / bottom;
ratio = max(-1, min(1, ratio));
angle = acos(ratio);
end

