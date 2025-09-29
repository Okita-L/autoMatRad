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

data = 'C:\Users\Administrator\Desktop\stf5'; % 存放matRad_data的路径
cstPath = 'C:\Users\Administrator\Desktop\cst5'; % 存放cstProcessed_data的路径
savePath = 'C:\Users\Administrator\Desktop\brs5'; % 存放brs结果的路径


% data = 'E:\Workshop\autoMatRad\data\matRad_data';
% cstPath = 'E:\Workshop\autoMatRad\data\cstProcessed_data';
% savePath = 'E:\Workshop\autoMatRad\data\BRS_data';

matRad_data = dir(fullfile(data, '*_Stf.mat'));
% matRad_data = dir(fullfile(data, '*_matRad.mat'));
matFiles = dir(fullfile(cstPath, '*.mat'));


%遍历所有mat文件
for count = 1:numel(matRad_data)
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Naming
    try
        
        [~, stfName, ~] = fileparts(matRad_data(count).name);% ID name
        filename = stfName(1:end-4); % name
        
        mkdir(fullfile(savePath, filename));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        cur_matRad_data = matRad_data(count);
        cur_matRad_data_path = fullfile(matRad_data(count).folder,stfName);
        load(cur_matRad_data_path); % Load patient data for pln&stf
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        cstFileName = [filename, '.mat']; % CST 文件名就是 'PatientID.mat'
        cst_filePath = fullfile(cstPath, cstFileName);
        if ~exist(cst_filePath, 'file')
            warning('Skipping %s: Matching CST file "%s" not found in %s.', ...
                    stfName, cstFileName, cstPath);
            continue;
        end
        load(cst_filePath);
        
        dij = matRad_calcParticleDose(ct,stf,pln,cst);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Arc data


    %% Optimization
%         matRad_calcDoseInit;
%         cst = matRad_setOverlapPriorities(cst);
        new_cst = matRad_resizeCstToGrid(cst,dij.ctGrid.x,dij.ctGrid.y,dij.ctGrid.z,...
            dij.doseGrid.x,dij.doseGrid.y,dij.doseGrid.z);
        
        resultGUI = matRad_fluenceOptimization(dij,cst,pln);
        
        origin_BRS = Determine_origin(new_cst,dij,stf,resultGUI, stfName);
        
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
