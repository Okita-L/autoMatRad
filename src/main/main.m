projectPath = 'E:\workShop\autoMatRad'; 
addpath(genpath(projectPath));

matRad_rc;
auto_rc;
% 禁用GUI
matRad_cfg = MatRad_Config.instance();
matRad_cfg.disableGUI = true;
processor = autoProcessor(projectPath);

%% 参数设置
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

Targets = {["ctv1", "ctv", "ctv2"], [constraintOfTarget1]};
OARs = {["body", "body1", "body3"],[constraintOfBody1];
    ["brainstem"],[constraint];
    ["opticnerve l"],[constraint];
    ["opticnerve r"],[constraint];
    ["opticchiasm","chiasm"],[constraint];
    ["parotid r"],[constraintOfParotid1];
    ["parotid l"],[constraintOfParotid1];
    }



%% 重新生成 cstprocessed之后的matrad数据
processor.autoLoadDicomBatch()