projectPath = 'E:\workShop\autoMatRad'; 
addpath(genpath(projectPath));

matRad_rc;
auto_rc;
% 禁用GUI
matRad_cfg = MatRad_Config.instance();
matRad_cfg.disableGUI = true;
processor = autoProcessor(projectPath);

%% 限制参数设置
% 最后是一个struct 应该被放到一个cell中
% constraintOfTarget
constraintOfTarget1.className = 'DoseObjectives.matRad_SquaredDeviation';
constraintOfTarget1.parameters = {}; % 否则matlab不知道这是一个元胞数组
constraintOfTarget1.parameters{1} = 30;
constraintOfTarget1.penalty = 800;
% constrainOfOARs
constraint.className = 'DoseObjectives.matRad_SquaredOverdosing';
constraint.parameters={};
constraint.parameters{1} = 54;
constraint.penalty = 300;
% constraintOfParotid
constraintOfParotid1.className = constraint.className;
constraintOfParotid1.parameters={};
constraintOfParotid1.parameters{1} = 28;
constraintOfParotid1.penalty = 300;
% constraintOfBody
constraintOfBody1.className = constraint.className;
constraintOfBody1.parameters = {};
constraintOfBody1.parameters{1} = 55;
constraintOfBody1.penalty = 300;

%% ROI设置
Targets = {["ctv1", "ctv", "ctv2"], {constraintOfTarget1}};
OARs = { ...
    ["body", "body1", "body3"], {constraintOfBody1};  % 将 constraintOfBody1 放入 {}
    ["brainstem"],              {constraint};         % 将 constraint 放入 {}
    ["opticnerve l"],           {constraint};         % 将 constraint 放入 {}
    ["opticnerve r"],           {constraint};         % 将 constraint 放入 {}
    ["opticchiasm","chiasm"],   {constraint};         % 将 constraint 放入 {}
    ["parotid r"],              {constraintOfParotid1}; % 将 constraintOfParotid1 放入 {}
    ["parotid l"],              {constraintOfParotid1}; % 将 constraintOfParotid1 放入 {}
    };


%% 路径设置
path_of_Dicom = 'E:\Workshop\autoMatRad\data\dicom_data';

%% 导入DICOM 生成rawMat文件
% processor.autoLoadDicomBatch(path_of_Dicom);

%% 处理CST提取ROI 生成CSTMat文件
% processor.autoProcessCST(OARs,Targets);

%% 生成原始的stfFiles
% processor.autoGenerateSTF('E:\Workshop\autoMatRad\data\CSTMat_data','C:\Users\Administrator\Desktop');

%% 修改48的rawMat
% load('E:\Workshop\autoMatRad\data\CSTMat_data\48-PT3312724a.mat');
% cst{63,6} = cst{136,6};
% cst{136,6} = [];
% save('C:\Users\Administrator\Desktop\48-PT3312724a.mat','cst','ct','-v7');


%% old autoGenerate New CST generate STF
% autoGenerateSTF('C:\Users\Administrator\Desktop\ErrorSTF','C:\Users\Administrator\Desktop\OldCodeNewCST_STF');

%% old autoGenerate Old CST generate STF
% autoGenerateSTF('C:\Users\Administrator\Desktop\OldCst','C:\Users\Administrator\Desktop\OldCodeOldCST_STF');

