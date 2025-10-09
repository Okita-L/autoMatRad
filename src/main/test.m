projectPath = 'E:\workShop\autoMatRad'; 
addpath(genpath(projectPath));

matRad_rc;
auto_rc;
% 禁用GUI
matRad_cfg = MatRad_Config.instance();
matRad_cfg.disableGUI = true;
processor = autoProcessor(projectPath);


%% test autoProcessCST(obj, OARs, Targets, path_of_rawMat, path_of_CSTMat)
% % all passed
% % but noticed that if u want to declare a variable as cell array
% % u should let the stupid matlab know that declaration before u using it
% load('E:\Workshop\autoMatRad\data\mat_data\1-PT3113820.mat','cst','-mat');
% % constraintOfTarget
% constraintOfTarget1.className = 'DoseObjectives.matRad_SquaredDeviation';
% constraintOfTarget1.parameters = {}; % 否则matlab不知道这是一个元胞数组
% constraintOfTarget1.parameters{1} = 30;
% constraintOfTarget1.penalty = 800;
% % constrainOfOARs
% constraint.className = 'DoseObjectives.matRad_SquaredOverdosing';
% constraint.parameters={};
% constraint.parameters{1} = 54;
% constraint.penalty = 300;
% % constraintOfParotid
% constraintOfParotid1.className = constraint.className;
% constraintOfParotid1.parameters={};
% constraintOfParotid1.parameters{1} = 28;
% constraintOfParotid1.penalty = 300;
% % constraintOfBody
% constraintOfBody1.className = constraint.className;
% constraintOfBody1.parameters = {};
% constraintOfBody1.parameters{1} = 55;
% constraintOfBody1.penalty = 300;
% 
% Targets = {["ctv1", "ctv", "ctv2"], [constraintOfTarget1]};
% OARs = {["body", "body1", "body3"],[constraintOfBody1];
%     ["brainstem"],[constraint];
%     ["opticnerve l"],[constraint];
%     ["opticnerve r"],[constraint];
%     ["opticchiasm","chiasm"],[constraint];
%     ["parotid r"],[constraintOfParotid1];
%     ["parotid l"],[constraintOfParotid1];
%     }
% path_of_rawMat = 'E:\Workshop\autoMatRad\data\mat_data';
% path_of_CSTMat = 'C:\Users\Administrator\Desktop'
% processor.autoProcessCST(OARs,Targets, path_of_rawMat,path_of_CSTMat);


%% getTargeIndices and oarsIndices
% test getTargeIndices and oarsIndices. all passed
% 
% load('E:\Workshop\autoMatRad\data\mat_data\1-PT3113820.mat','cst','-mat');
% Targets1col = {["body","body1","body3"],[cst{43,6}{1,1}];
%     ["opticchiasm","chiasm"], [cst{43,6}{1,1}];
%     ["ctv1","ctv2"], [cst{43,6}{1,1}];
%     } % 如果 '' 就无法识别 因为 [] 的串联行为
% cstSubset= cst(:, 2);
% Targets1col = Targets1col(:,1);
% 
% Index = processor.getTargetIndex(Targets1col,cstSubset);
% idx = processor.getOARsIndices(Targets1col,cstSubset);

%% autoLoadDicom
% autoLoadDicomSigle Pass!
% processor.autoLoadDicomSigle('D:\workShop\autoMatRad\data\dicom_data\test\1-PT3113820');

% autoLoadDicomBatch Pass!
% processor.autoLoadDicomBatch('D:\workShop\autoMatRad\data\dicom_data\test')

