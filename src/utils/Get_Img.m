
%% init
% 需要cst ct pln stf这四个结构
path_of_CSTMat = 'E:\Workshop\autoMatRad\data\cstProcessed_data';
path_of_StfMat = 'E:\Workshop\autoMatRad\data\matRad_data';
path_of_BRS = 'E:\Workshop\autoMatRad\data\BRS_data';
path_of_DVHQI = 'E:\Workshop\autoMatRad\data\dvh_qi_data';

Stf_data = dir(fullfile(path_of_StfMat,"*_Stf.mat")); % marRad_data
CST_data = dir(fullfile(path_of_CSTMat,"*.mat"));

addpath(genpath('E:\Workshop\autoMatRad'));

%% generator DIJ
diary('generator_brs_dvh_qi_log.text')
for i=1:1 %numel(Stf_data)
    
    try
        % 设置保存路径
        curItem = CST_data(i);
        [~,ID,~] = fileparts(curItem.name);
        saveDir_of_BRS = fullfile(path_of_BRS,curItem.name);
        if ~exist(saveDir_of_BRS)
            mkdir(saveDir_of_BRS);
        end
        savePath_of_BRSfile = fullfile(path_of_BRS,curItem.name,[curItem.name(1:end-4),'_BRS','.csv']);
        savePath_of_DVHQI = fullfile(path_of_DVHQI,curItem.name);
        % 取出 cst ct
        load(fullfile(path_of_CSTMat,CST_data(i).name));
        % 取出 stf pln
        load(fullfile(path_of_StfMat,Stf_data(i).name));

        % calculate DIJ
        dij = matRad_calcParticleDose(ct,stf,pln,cst);

        % Optimization
        new_cst = matRad_resizeCstToGrid(cst,...
            dij.ctGrid.x,dij.ctGrid.y,dij.ctGrid.z,...
            dij.doseGrid.x,dij.doseGrid.y,dij.doseGrid.z);

        resultGUI = matRad_fluenceOptimization(dij,cst,pln);

        origin_BRS = Determine_origin(nee.cst,dij,stf,resultGUI, ID);

        [dvh,qi] = matRad_indicatorWrapper(cst,pln,resultGUI);
        % save
        writecell(origin_BRS, savePath_of_BRSfile);
        sve(savePath_of_DVHQI,'dvh','qi');
        close all;
        fprintf('All data has been saved in %s',savePath_of_BRSfile);
        
    
    catch ER % ER 是捕获到的错误信息
        % 打印错误信息和出错的文件名
        fprintf('Error processing file: %s\n', 'dd'); 
        fprintf('Error message: %s\n', ME.message);
        % 继续执行下一个文件
        continue;
    end
    
end
diary off;