% autoLoadDicom.m
% Sept. 2025 By Hang Lian
% To load and process the raw data automatically

auto_rc; % 将所需要的全部文件夹加入matlab的搜索路径
% 禁用GUI
matRad_cfg = MatRad_Config.instance();
matRad_cfg.disableGUI = true;

% 自动获取项目路径
projectPath = fileparts(mfilename("fullpath")); % 'E:\Workshop\autoMatRad\src\utils'
projectPath = fileparts(projectPath);
projectPath = fileparts(projectPath); % 'E:\Workshop\autoMatRad'

%% load Dicom
% 设置源路径和目的路径
% 源路径存放原始Dicom文件 目的路径存放原始mat文件
path_of_Dicom = 'E:\LG_PCT';

% path_of_rawMat = fullfile(projectPath,"data/mat_data"); % 'E:\Workshop\autoMatRad\data\mat_data'
% path_of_rawMat = autoLoadDicom(path_of_Dicom,path_of_rawMat);
path_of_rawMat = autoLoadDicom(path_of_Dicom);


%% process CST
% 若需要修改 oar 和 target 仍需要进入autoProcessCST 
% 修改expected_targets和expected_oar

projectPath = 'E:\Workshop\autoMatRad'; 
% % 手动配置路径
% path_of_rawMat = fullfile(projectPath,"data/mat_data"); % 'E:\Workshop\autoMatRad\data\mat_data'
% path_of_CSTMat = fullfile(projectPath,"data/cstProcessed_data");
% path_of_CSTMat = autoProcessCST(path_of_rawMat,path_of_CSTMat); 

% batch and pipeline
path_of_CSTMat = autoProcessCST(path_of_rawMat); 

% 视情况 额外编写后处理脚本 cst_processed_extra.m
% 单独运行

%% generate stf and pln

% 师姐将生成文件放在matRad_data文件夹下
% 我放在同级目录stfpln_data文件夹下

% 手动配置
% projectPath = 'E:\Workshop\autoMatRad';
% path_of_CSTMat = fullfile(projectPath,"data/cstProcessed_data");
% path_of_STFMat = fullfile(projectPath,"data/matRad_data")
% path_of_STFMat = autoGenerateSTF(path_of_CSTMat,path_of_STFMat);

% batch and pipeline
% 放在同级目录stfpln_data文件夹下
path_of_STFMat = autoGenerateSTF(path_of_CSTMat);


%% generate DJI
path_of_DIJ = autoGenerateSTF(path_of_)


%% test
projectPath = 'E:\Workshop\autoMatRad';
load('E:\Workshop\autoMatRad\data\mat_data\60-PT3169277.mat')

% cst(:,3)

cst{:,3}