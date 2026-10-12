% 定义函数入口与返回值
function res=CT_DMOEA(Problem,popSize,MaxIt,T_parameter,group)
% 将当前计算结果赋值给变量问题结构体 Problem、种群大小 popSize、最大迭代次数 MaxIt、
% 动态参数矩阵 T_parameter（包含变化强度、频率、总代数等）、组号 group
d = size(Problem.XLow,1);%获取决策变量的维度
res = cell(1,floor(T_parameter(group,3)/T_parameter(group,2)));
%预分配输出 res 为 cell 数组，长度为总环境个数。T_parameter(group,3) 是总运行代数，
% T_parameter(group,2) 是变化频率，相除取整得到环境变化次数。

for T = 1:floor(T_parameter(group,3)/T_parameter(group,2))
        
        t = 1/T_parameter(group,1)*(T-1);
        % 在命令行输出当前运行进度。
        fprintf(' %d',T);
        % 进行条件判断并进入对应分支。
        if T==1
            % 在当前环境下执行一次 MOEA/D 进化。
            [PopX,Pareto,POF_iter] = moead(Problem,popSize,MaxIt,t); 
           
            PS = Pareto.X;
            %提取 Pareto 解集（最优解）
            %PS = unique(PS', 'rows');
            %PS = PS';
          
            % 生成 popSize 个随机解，每个解在决策变量上下界内均匀分布，存入 random_PopX
            random_PopX = zeros(d,popSize);
            % 开始 for 循环迭代。
            for i=1:popSize
                % 在决策变量边界内均匀随机采样个体。
                random_PopX(:,i) = unifrnd(Problem.XLow, Problem.XUpp, [size(Problem.XLow,1) 1]);
            
            end
            % 将随机解和 Pareto 解集拼接在一起
            sourcePopX=[random_PopX PS];
          
            %sourcePopX=[addNoise(PopX, size(PopX,2)*2, size(PopX,1), Problem) PS];
            
            LastPareto = PS;
            %LastPareto = unique(LastPareto', 'rows');
            %LastPareto = LastPareto';
           
            % 为源域数据分配标签：随机解（坏样本）标签为 -1，Pareto 解（好样本）标签为 1
            % sourceRank 是与 sourcePopX 列对应的标签向量
            negtiveLabel=-1.*ones(1,size(sourcePopX,2)-size(PS,2));
            sourceRank=[negtiveLabel,ones(1,size(PS,2))]; 
        % 当前置条件不满足时执行 else 分支。
        else
        
        %Clustering Selection
     
        % 再次生成 popSize 个新环境的随机解，存入 random_PopX
        random_PopX = zeros(d,popSize);
        for i=1:popSize
            % 在决策变量边界内均匀随机采样个体。
            random_PopX(:,i) = unifrnd(Problem.XLow, Problem.XUpp, [size(Problem.XLow,1) 1]);
        
        end
  
        % 在当前环境下执行一次 MOEA/D 进化。
        [one_PopX, Pareto, ~] = moead(Problem,popSize,1,t,LastPareto);  
        %union_PopX = [one_PopX random_PopX];
        % 对解集加入高斯扰动以增强多样性。
        randomPopX1 = addGaussianNoise_2(one_PopX, size(one_PopX,2), size(one_PopX,1), Problem);
     
        randomPopX2 = addGaussianNoise_2(Pareto.X, size(Pareto.X,2), size(Pareto.X,1), Problem);
        % 对 one_PopX 进行去重
        one_PopX = unique(one_PopX', 'rows');
        one_PopX = one_PopX';
        %构建候选池 union_PopX：包含进化一代后的解、它们的噪声变异、以及当前 Pareto 解的噪声变异
        union_PopX = [one_PopX randomPopX1 randomPopX2];
        %union_PopX = [one_PopX addGaussianNoise(one_PopX, size(one_PopX,2), size(one_PopX,1), Problem) random_PopX];
        %union_PopX = [one_PopX  generateRandomPoints(LastPareto, Problem) random_PopX];
        %union_PopX = [one_PopX  addGaussianNoise(one_PopX, size(one_PopX,2), size(one_PopX,1), Problem) addGaussianNoise(Pareto.X, size(Pareto.X,2), size(Pareto.X,1), Problem) random_PopX];
        
        % 调用 getStSolutionSet 函数，对 union_PopX 进行非支配排序和选择，返回一个包含较优解的集合
        st = getStSolutionSet(union_PopX,Problem,t,popSize);
        clusterK = min(popSize, size(st, 2));
        [C_HCMset, ~] = HierarchicalClustering(st,Problem,t,clusterK); 
        % 从每个簇中选择收敛性最好的解，组成目标域数据集
        targetPopX = bestSolutionSelection(C_HCMset,Problem,t,popSize);
        % 计算 targetPopX 中每个解的 Pareto 支配等级（非支配解为 1，支配解为 0），得到标签向量
        targetRank=computeRank(targetPopX,Problem,t); 
        %提取 targetPopX 中的所有非支配解（标签为 1 的解）存入 targetNDS，用于后续生成测试解时的增强
        targetNDS = [];
        for i=1:size(targetRank,2)
          % 进行条件判断并进入对应分支。
          if targetRank(i) == 1
             % 将当前计算结果赋值给变量。
             targetNDS = [targetNDS targetPopX(:,i)];
          end
        end
        
        % target
        %{
        m = Problem.NObj;
        Objectives = zeros(size(targetRank,2),m);
        for i=1:size(targetRank,2)
           % 在当前时刻 t 计算目标函数值。
           [Objectives(i,:), ~] = Problem.FObj(targetPopX(:,i),t);
        end
       for i=1:size(targetRank,2)
          % 进行条件判断并进入对应分支。
          if  targetRank(i) == 1
             plot(Objectives(i,1),Objectives(i,2),'r*');
          % 当前置条件不满足时执行 else 分支。
          else
             plot(Objectives(i,1),Objectives(i,2),'b.')
          end
       hold on;
       end
       hold on;
       %}
        %初始化 cell 数组，用于存储源域和目标域按目标数聚类的子集
        M = Problem.NObj;
        
        subSourcePopX = cell(1,M);
        
        subSourceRank = cell(1,M);
        
        subTargetPopX = cell(1,M);
        
        subTargetRank = cell(1,M);
        % 对解集执行层次聚类。
        [subset1, subindex1] = HierarchicalClustering(sourcePopX,Problem,t,M);
        
        [subset2, subindex2] = HierarchicalClustering(targetPopX,Problem,t,M);
       
        % 将每个簇的解集和对应的标签分别存入 subSourcePopX/subSourceRank 和 subTargetPopX/subTargetRank
        for i=1:M
           subSourcePopX{i} = subset1{i};
           for j=1:size(subindex1{i},2)
               subSourceRank{i}(j) = sourceRank(subindex1{i}(j));
           end
           subTargetPopX{i} = subset2{i};
           for j=1:size(subindex2{i},2)
               subTargetRank{i}(j) = targetRank(subindex2{i}(j));
           end
        end

        % 初始化一个标志数组 sourceFlag，用于标记哪些源簇已经被使用过
        sourceFlag = zeros(1,M);

        %Clustering Transfer（CBT）
        %用于标记哪些源簇已经被使用过
        initPop = [];
        
        testPopMult = 90;
        if isfield(Problem, 'AppConfig') && isfield(Problem.AppConfig, 'testPopMult')
            testPopMult = Problem.AppConfig.testPopMult;
        end
        
        for i=1:M
            
            testPopX=[];
            for j = 1:popSize*testPopMult
               % 在决策变量边界内均匀随机采样个体。
               testPopX(:,j) = unifrnd(Problem.XLow, Problem.XUpp, [size(Problem.XLow,1), 1]);
           
            end
            % 将目标域中的非支配解 targetNDS 添加噪声后生成 10 份副本，拼接到 testPopX 前面，增加候选解中好解附近的样本
            for j=1:10
                % 对解集加入高斯扰动以增强多样性。
                testPopX = [addGaussianNoise_2(targetNDS, size(targetNDS,2), size(targetNDS,1), Problem) testPopX];
      
            end
           
            %testPopX=[subTargetPopX{i} testPopX];
            %testPopX=[addGaussianNoise(subTargetPopX{i}, size(subTargetPopX{i},2), size(subTargetPopX{i},1), Problem)  testPopX];
            %testPopX=[addGaussianNoise(subTargetPopX{i}, size(subTargetPopX{i},2), size(subTargetPopX{i},1), Problem)  testPopX];
           
            %调用 ClusterSelection 函数，根据当前目标簇 subTargetPopX{i} 和所有源簇，
            %选择一个最相似的且未被使用过的源簇，返回其索引 clusterIndex
            try
            % 将当前计算结果赋值给变量。
            clusterIndex = -1;
            % 为迁移选择最匹配的源簇。
            clusterIndex = ClusterSelection(subTargetPopX{i},subSourcePopX,sourceFlag,Problem,t);
            % 捕获并处理 try 代码块中的异常。
            catch ErrorInfo
                 
                 disp(ErrorInfo); 
                 
                 error("E");
           
            end
            
            sourceFlag(clusterIndex) = 1;
 
            useGBSVM = true;
            if isfield(Problem, 'AppConfig') && isfield(Problem.AppConfig, 'useGBSVM')
                useGBSVM = logical(Problem.AppConfig.useGBSVM);
            end
            if useGBSVM
                tmpPop = predictIndividuals(subSourcePopX{clusterIndex}',subSourceRank{clusterIndex}',subTargetPopX{i}',subTargetRank{i}',testPopX',popSize,M, Problem, t);
            else
                tmpPop = predictIndividualsSVM(subSourcePopX{clusterIndex}',subSourceRank{clusterIndex}',subTargetPopX{i}',subTargetRank{i}',testPopX',popSize,M, Problem, t);
            end
            % 将当前计算结果赋值给变量。
            initPop = [initPop; tmpPop];
        end

        %evolution 
          %initPop = targetNDS';  
          %initPop = [initPop; targetPopX'];
          %initPop = unique(initPop, 'rows');
          %initPop = getFilterSolutions(initPop,Problem,t,popSize);
          
          
          initPop = [targetNDS'; initPop];
          
          if size(initPop,1)>popSize
             
              initPop = initPop(1:popSize,:);
         
          end
          
          res{T}.initPopMeanSum = meanInitPopSum(initPop, Problem, t);
          
          %{
           
           m = Problem.NObj;
           
           Objectives = zeros(size(initPop,1),m);
           
           for i=1:size(initPop,1)
               % 在当前时刻 t 计算目标函数值。
               [Objectives(i,:), ~] = Problem.FObj(initPop(i,:),t);
           
           end
           
           for i=1:size(initPop,1)
               
               plot(Objectives(i,1),Objectives(i,2),'r.')
           
           hold on;
          
           end
            %}
           % 在当前环境下执行一次 MOEA/D 进化。
           [PopX,Pareto,POF_iter] = moead(Problem,popSize,MaxIt, t, initPop');
           
           PS = Pareto.X;
           %PS = unique(PS', 'rows');
           %PS = PS';
          
           % 再次生成随机解，用于构建下一环境的源域
           random_PopX = zeros(d,popSize);
          
           for i=1:popSize
               % 在决策变量边界内均匀随机采样个体。
               random_PopX(:,i) = unifrnd(Problem.XLow, Problem.XUpp, [size(Problem.XLow,1) 1]);
           
           end
           % 更新源域数据集，包含随机解和当前 Pareto 解
           sourcePopX=[random_PopX PS];
          
           %sourcePopX=[addNoise(PopX, size(PopX,2)*2, size(PopX,1), Problem) PS];
           % 将当前计算结果赋值给变量。
           LastPareto = PS;
           %LastPareto = unique(LastPareto', 'rows');
           %LastPareto = LastPareto';
           % 更新源域标签：随机解标签为 -1，Pareto 解标签为 1。
           negtiveLabel=-1.*ones(1,size(sourcePopX,2)-size(PS,2));
           
           sourceRank=[negtiveLabel,ones(1,size(PS,2))]; 
           % source
           %{
          
          m = Problem.NObj;
         
          Objectives = zeros(size(sourceRank,2),m);
          。
          for i=1:size(sourceRank,2)
            % 在当前时刻 t 计算目标函数值。
            [Objectives(i,:), ~] = Problem.FObj(sourcePopX(:,i),t);
          
          end
         
          for i=1:size(sourceRank,2)
            % 进行条件判断并进入对应分支。
            if  sourceRank(i) == 1
               % 执行当前语句。
               plot(Objectives(i,1),Objectives(i,2),'r*');
            % 当前置条件不满足时执行 else 分支。
            else
              % 执行当前语句。
              plot(Objectives(i,1),Objectives(i,2),'b.')
            
            end
           
            hold on;
          
          end
          
          hold on;
       %}
        % 结束当前控制代码块。
        end    
        % 将当前环境的真实 Pareto 前沿（通过 getBenchmarkPOF 获取）和优化过程中记录的 POF 迭代数据存入 res{T}
        res{T}.turePOF=getBenchmarkPOF(Problem.Name,group,T,T_parameter );
        
        res{T}.POF_iter=POF_iter;
        res{T}.Pareto=Pareto;
        if exist('PopX', 'var')
            res{T}.PopX = PopX;
        end

end

end





                    
