projectPath = 'E:\workShop\autoMatRad'; 
addpath(genpath(projectPath));

matRad_rc;
auto_rc;
% 禁用GUI
matRad_cfg = MatRad_Config.instance();
matRad_cfg.disableGUI = true;
processor = autoProcessor(projectPath);


