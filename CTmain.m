clc
clear
close all
warning('off')
addpath(genpath(fileparts(mfilename('fullpath'))));

% clc：清空命令行窗口
% clear：清空工作区变量
% close all：关闭所有图窗
% warning('off')：关闭警告
% addpath(genpath(...))：把当前工程目录及其所有子目录都加入 MATLAB 路径

%CreatTruePOF();
%error("E");
con=configure();
repeatMax=con.repeat;
functions=con.TestFunctions;
T_parameter=con.T_parameter;
popSize=con.popSize;
nGroup=size(T_parameter,1);
nFunc=size(functions,2);
nCase=nGroup*nFunc;
migdAll=zeros(repeatMax,nCase);

% repeat：重复运行次数
% TestFunctions：测试函数列表
% T_parameter：动态环境参数组
% popSize：种群大小

for rep=1:repeatMax
    filename = ['MIGD-', num2str(rep), '.txt'];
    fid = fopen(filename,'w');%第 rep 次独立实验开始，每次实验新建一个结果文件
    caseIdx=0;
    for testFuncNo=1:size(functions,2)
        Problem=TestFunctions(functions{testFuncNo});%从 functions 中取出一个测试问题名字
                                                     % 用 TestFunctions(...) 构造问题对象 Problem
        if Problem.NObj==3 
            popSize=150;%如果当前问题是 3 目标问题，就把种群大小改成 150
        end 
        for group=1:size(T_parameter,1) %遍历动态环境参数组
            MaxIt=T_parameter(group,2);
            fprintf('\n CTDMOEA rep:%d runing on: %s, configure: %d, environment:',rep,Problem.Name,group);
            % Problem：当前测试问题
            % popSize：种群大小
            % MaxIt：当前环境下的最大代数
            % T_parameter：动态环境参数总表
            % group：当前参数组编号
            res=CT_DMOEA(Problem,popSize,MaxIt,T_parameter,group);
            [resIGD,resMS]=computeMetrics(res,group,rep,testFuncNo);
            fprintf('\n %.3d',resIGD);
            fprintf(fid,'%f \n',resIGD);%最后取平均，得到 resIGD 和 resMS
            caseIdx=caseIdx+1;
            migdAll(rep,caseIdx)=resIGD;
        end %configure
    end%testF
    fclose(fid);
end%rep

summaryFile='MIGD-summary-mean-std.txt';
fidSummary=fopen(summaryFile,'w');
fprintf(fidSummary,'# Function Group MeanMIGD StdMIGD\n');
for testFuncNo=1:nFunc
    for group=1:nGroup
        idx=(testFuncNo-1)*nGroup+group;
        meanVal=mean(migdAll(:,idx));
        stdVal=std(migdAll(:,idx));
        fprintf(fidSummary,'%s %d %.10f %.10f\n',functions{testFuncNo},group,meanVal,stdVal);
    end
end
fclose(fidSummary);

tableFile='MIGD-table1-style.txt';
fidTable=fopen(tableFile,'w');
fprintf(fidTable,'# Function\t(nt,tau_t)=(10,10)\t(10,5)\t(5,10)\t(5,5)\n');
for testFuncNo=1:nFunc
    fprintf(fidTable,'%s',functions{testFuncNo});
    for group=1:nGroup
        idx=(testFuncNo-1)*nGroup+group;
        meanVal=mean(migdAll(:,idx));
        stdVal=std(migdAll(:,idx));
        fprintf(fidTable,'\t%.6e +- %.2e',meanVal,stdVal);
    end
    fprintf(fidTable,'\n');
end
fclose(fidTable);

function [resIGD,resMS]=computeMetrics(resStruct,group,rep,testFuncNo)   
     for T=1:size(resStruct,2)
        POFIter=resStruct{T}.POF_iter;
        POFbenchmark=resStruct{T}.turePOF;
        % resStruct{T}：第 T 个环境的结果
        % POF_iter：这个环境内每一代的 POF
        % turePOF：当前环境对应的真实 Pareto front
        for it=1:size(POFIter,2)    %对该环境内每一代计算 IGD / MS  
            pof=POFIter{it};
            pof(imag(pof)~=0) = abs(pof(imag(pof)~=0));
            igd(it)=IGD(pof',POFbenchmark);
            ms(it)=MS(pof',POFbenchmark);
        end
        IGD_T(T)=igd(end);  %每个环境只保留最后一代 IGD，记为 IGD_T(T)
        mstemp=ms(ms<=1&ms>0);
        if length(mstemp)==0
            MS_T(T)=0;
        else
            MS_T(T)=mstemp(end); 
        end 
        %只保留 (0,1] 范围内的 MS
        % 如果没有合法值，就记 0
        % 否则取最后一个合法值
     end
     resIGD=mean(IGD_T);
     resMS=mean(MS_T);
     
     filename = ['CT-DF',num2str(testFuncNo), '-IGD-', num2str(rep-1), '.txt'];
     if group == 1 && rep > 1
         fid = fopen(filename,'w');
         for i=1:size(IGD_T,2)
              fprintf(fid,'%f \n',IGD_T(i)); 
         end
         fclose(fid);
     end
     %{
     filename = ['CT-DF',num2str(testFuncNo), '-POF', '.txt'];
     if group == 1 && rep == 2
         fid = fopen(filename,'w');
         for T=1:size(resStruct,2)
              POFIter=resStruct{T}.POF_iter;
              pof = POFIter{size(POFIter,2)};
              pof(imag(pof)~=0) = abs(pof(imag(pof)~=0));
              for j=1:size(pof,2)
                  if testFuncNo <= 9
                      fprintf(fid,'%f \t %f \n',pof(1,j),pof(2,j)); 
                  else
                      fprintf(fid,'%f \t %f \t %f \n',pof(1,j),pof(2,j),pof(3,j)); 
                  end
              end
              fprintf(fid,'\n'); 
         end
         fclose(fid);  
     end 
 %}
     
end



                    