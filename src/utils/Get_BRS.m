% Get_BRS.m
% Sept. 2025. Written by KeShi.
% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Add Path
addpath(genpath('E:\Workshop\autoMatRad'));
% addpath(genpath('D:\Sk-work\ShiKe\reasearch-Work\MyWorkForMedical\For_LH\matRad-RBErobOpt'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Naming
% 定义路径
% data = 'D:\Sk-work\ShiKe\reasearch-Work\MyWorkForMedical\For_LH\matRad-RBErobOpt\YourWork\data\matRad_data';
% cstPath = 'D:\Sk-work\ShiKe\reasearch-Work\MyWorkForMedical\For_LH\matRad-RBErobOpt\YourWork\data\cstProcessed_data';
% savePath = 'D:\Sk-work\ShiKe\reasearch-Work\MyWorkForMedical\For_LH\matRad-RBErobOpt\YourWork\data\BRS_data';

data = 'E:\Workshop\autoMatRad\data\matRad_data';
cstPath = 'E:\Workshop\autoMatRad\data\cstProcessed_data';
savePath = 'E:\Workshop\autoMatRad\data\BRS_data';

matRad_data = dir(fullfile(data, '*_Stf.mat'));
% matRad_data = dir(fullfile(data, '*_matRad.mat'));
matFiles = dir(fullfile(cstPath, '*.mat'));


%遍历所有mat文件
for count = 1:length(matRad_data)
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Naming
    try
        filePath = fullfile(data, matRad_data(count).name);
        [~, ID, ~] = fileparts(matRad_data(count).name);% ID name
        filename = ID(1:end-7); % name
        mkdir(fullfile(savePath, filename));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        matRad_data = dir(fullfile(filePath, "*_matRad.mat"));
        matRad_data_path = fullfile(filePath, matRad_data.name);
        load(matRad_data_path); % Load patient data for pln&stf
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        cst_filePath = fullfile(cstPath, matFiles(count).name);
        load(cst_filePath);
        
        dij = matRad_calcParticleDose(ct,stf,pln,cst);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Arc data


    %% Optimization
%         matRad_calcDoseInit;
%         cst = matRad_setOverlapPriorities(cst);
        new_cst = matRad_resizeCstToGrid(cst,dij.ctGrid.x,dij.ctGrid.y,dij.ctGrid.z,...
            dij.doseGrid.x,dij.doseGrid.y,dij.doseGrid.z);
        
        resultGUI = matRad_fluenceOptimization(dij,cst,pln);
        
        origin_BRS = Determine_origin(new_cst,dij,stf,resultGUI, ID);
        
     %% Save files
%         BRS_filename = [filename '_BRS.mat'];
%         output_path =  fullfile(savePath,filename, BRS_filename);
%         save(output_path,'origin_BRS');
        BRS_csvPath = fullfile(savePath,filename,[filename, '_BRS', '.csv']);   
        writecell(origin_BRS, BRS_csvPath); 
        close all;
    %% diary off   
        fprintf('All data were saved in %5s_BRS.csv\n',filename);
        diary off;
    catch ME % ME 是捕获到的错误信息
        % 打印错误信息和出错的文件名
        fprintf('Error processing file: %s\n', matFiles(count).name);
        fprintf('Error message: %s\n', ME.message);
        % 继续执行下一个文件
        continue;
    end
    %% 清除工作区变量
    clearvars -except data cstPath savePath subfeat_folders1 matFiles count; %全局变量和循环指数i保留
end
