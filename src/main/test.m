
projectPath = 'D:\workShop\autoMatRad'; 
addpath(genpath(projectPath));
matRad_rc;
auto_rc;
% 禁用GUI
matRad_cfg = MatRad_Config.instance();
matRad_cfg.disableGUI = true;
processor = autoProcessor(projectPath);
% autoLoadDicomSigle Pass!
% processor.autoLoadDicomSigle('D:\workShop\autoMatRad\data\dicom_data\test\1-PT3113820');

% autoLoadDicomBatch Pass!
% processor.autoLoadDicomBatch('D:\workShop\autoMatRad\data\dicom_data\test')


