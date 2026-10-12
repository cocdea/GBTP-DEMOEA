function Model = LPCA( X, NClu, DLat, MaxIter )
countzero=(X==0);
if sum(countzero(:))>size(X,1)*size(X,2)/2
    for i=1:size(X,2)
        countzero=(X(:,i)==0);
        while sum(countzero(:))>size(X,1)/2
            index=ceil(unifrnd(1, size(X,1)));
            X(index,i)=unifrnd(0, 1);
            countzero=(X(:,i)==0);
        end
    end

end
% Model = LPCA( X, NClu, DLat ) partitions the set X into NClu clusters by
% Local PCA method 通过LPCA划分种群聚类
%
%   Please refer Nandakishore Kambhatla and Todd K. Leen. 'Dimension
%   Reduction by Local Principal Component Analysis' for more details.
%
%     Parameters:
%     X         - data set
%     NClu      - number of clusters
%     DLat      - dimension of latent sapce
%     MaxIter   - maximum iterations
%     Returns:
%     Model
%       - Model.Mean    mean vector of each cluster
%       - Model.PI      matrix PI to each cluster
%       - Model.Eve     eigenvectors 
%       - Model.Eva     eigenvaluse
%       - Model.PMin    min values in principal vectors
%       - Model.PMax    max values in principal vectors
%       - Model.Index   index to which cluster
%
%     Aimin Zhou
%     Department of Computer Science
%     University of Essex
%     Colchester, U.K, CO4 3SQ
%     amzhou@gmail.com
%
% History:
%     6/10/2006 create
%    27/10/2006 remove the part to optimize reference vector
%               the reference vector is set to be the mean of each cluster
%    10/11/2006 optimize the codes


%% Step 1: define and set algorithm parameters
DX          = size(X,1);        % dimension of decision variables
NX          = size(X,2);        % size of data
index       = randperm(NX);     %将NX个数进行打乱
Model.Mean  = X(:,index(1:NClu));           % reference vector to each cluster 选择NClu个个体(认为是质点），每个个体代表一族（此处选择两个个体，代表接下来聚类分两类）
Model.PI    = repmat(eye(DX) , [1 1 NClu]); % matrix PI to each cluster (NClu个单位矩阵，Dx乘Dx的矩阵）
Model.Eve   = repmat(eye(DX) , [1 1 NClu]); % eigenvectors 特征向量
Model.Eva   = zeros(DX,NClu);               % eigenvalues 特征值
Model.PMin  = zeros(DLat,NClu);             % min projection in each principal directions 每个主方向的最小投影
Model.PMax  = zeros(DLat,NClu);             % max projection in each principal directions

%% Step 2: main iterations
iter        = 1;
update      = NClu;
repartion   = 1;
while((update>0 && iter <= MaxIter) ||repartion>0)
    % Step 2.1 partition the population
    dis     = zeros(NX,NClu);%聚类，分为NClu个类，此处为100x2,每一列代表一个类，初始为0,下面通过计算确定分个第几类，则相应的值会更新为1
    %100个个体到两个质点的距离dis
    for c=1:1:NClu
        dis(:,c) = sum((X-repmat(Model.Mean(:,c), [1,NX]))'*Model.PI(:,:,c).*(X-repmat(Model.Mean(:,c), [1,NX]))',2);
    end
    
%     if iter > 30000
%          break;
%     end
    [mins, Model.Index] = min(dis,[],2);
    id                  = eye(NClu);
    cindex              = id(Model.Index,:);%两列中，值为1代表该点分为这列的族
    
    % Step 2.2 update the reference vectors
    update      = NClu;
    repartion   = 0;
    for c=1:1:NClu
        mean_old    = Model.Mean(:,c);
        if sum(cindex(:,c))<1
            index           = randperm(NX);
            Model.Mean(:,c) = X(:,index(1));
            Model.PI(:,:,c) = eye(DX);
            repartion       = 1;
        elseif sum(cindex(:,c))==1
            Model.Mean(:,c) = X(:,cindex(:,c)'>0);
            Model.PI(:,:,c) = eye(DX);
        elseif sum(cindex(:,c))>1
            cx                  = X(:,cindex(:,c)'>0);      % data in this cluster
            Model.Mean(:,c)     = mean(cx,2);               % mean 
            cy                  = cx - repmat(Model.Mean(:,c),[1 size(cx,2)]);
            % eigens and sort eigens 获取特征值与特征向量
            %PCA的原理是找出主成分代替所有样本（高维的数据用低维数据来表示，达到降维效果），推导计算方式为，求出样本的协方差矩阵，对该矩阵进行特征值分解，求出最大的d维的特征值对应的特征向量
            %经过标准化后，组成特征向量矩阵W,对样本x(i)转化为z(i)=WT x(i)，得到输出样本D=(z(1),z(2)...)
            [eve,eva]   = eig(cov(cy'));%cov为协方差 返回特征向量，特征值
            eva         = diag(eva);%diag返回主对角线上向量的元素
            [eva, perm] = sort(-eva);
            eva         = -eva;
            eve         = eve(:,perm);
            % set values
            Model.Eve(:,:,c)    = eve;
            Model.Eva(:,c)      = eva;
            Model.PI(:,:,c)     = eve(:,DLat+1:DX) * eve(:,DLat+1:DX)';
        end
        % check whether new center point is found
        err     = sqrt((mean_old-Model.Mean(:,c))'*(mean_old-Model.Mean(:,c)));
        if err<1.0e-5 
            update = update - 1; 
        end
    end
    iter = iter + 1;
end

%% Step 3: make all parameters feasible
Model.Eve = real(Model.Eve);
Model.Eva = real(Model.Eva);    Model.Eva(Model.Eva<realmin) = realmin;
Model.Mean= real(Model.Mean);
Model.PI  = real(Model.PI);

%% Step 4: calculate the projection
for c=1:1:NClu
    if sum(cindex(:,c))>1
        cx                  = X(:,cindex(:,c)'>0);      % data in this cluster
        cy                  = cx - repmat(Model.Mean(:,c),[1 size(cx,2)]);
        proj                = cy'*eve(:,1:DLat);
        Model.PMin(:,c)     = min(proj,[],1)';
        Model.PMax(:,c)     = max(proj,[],1)';
    end
end

clear eve eva X cindex;