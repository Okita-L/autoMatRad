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
source_path_of_Dicom = 'E:\LG_PCT';
dest_path_of_rawMat = fullfile(projectPath,"data/mat_data"); % 'E:\Workshop\autoMatRad\data\mat_data'

source_path_of_rawMat = autoLoadDicom(source_path_of_Dicom,dest_path_of_rawMat);

%% process CST
