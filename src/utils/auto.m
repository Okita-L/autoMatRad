% autoLoadDicom.m
% Sept. 2025 By Hang Lian
% To load and process the raw data automatically
auto_rc; % 将所需要的全部文件夹加入matlab的搜索路径
% 禁用GUI
matRad_cfg = MatRad_Config.instance();
matRad_cfg.disableGUI = true;
% 设置DICOM源文件夹 和 生成的mat文件存放的目的文件夹
source_path_of_Dicom = 'E:\LG_PCT_Demo';
projectPath = fileparts(mfilename("fullpath")); % 'E:\Workshop\autoMatRad\src\utils'
projectPath = fileparts(projectPath);
projectPath = fileparts(projectPath); % 'E:\Workshop\autoMatRad'
dest_path_of_rawMat = fullfile(projectPath,"data/mat_data/"); % 'E:\Workshop\autoMatRad\data\mat_data'

if ~exist(dest_path_of_rawMat,'dir')
    mkdir(dest_path_of_rawMat);
end

allItems = dir(source_path_of_Dicom);
% 过滤当前目录和父目录 . 和 .. 以及非文件夹项
allItems = allItems([allItems.isdir])
allItems = allItems(~ismember({allItems.name},{'.','..'}));
fprintf('总共找到 %d 个病人文件夹。\n', numel(allItems));

% importer.pln.radiationMode = 'protons';        
importer.pln.machine       = 'Generic';
% importer.pln.bioModel      = 'constRBE';
% importer.pln.multScen      = 'nomScen';
% 
% importer.pln.propDoseCalc.calcLET = 0;
% importer.pln.propDoseCalc.engine = 'HongPB';
% 
% % the remaining plan parameters.
% importer.pln.numOfFractions        = 30;
% importer.pln.propStf.gantryAngles  = [90 270];
% importer.pln.propStf.couchAngles   = [0 0];
% importer.pln.propStf.bixelWidth    = 5;
% importer.pln.propStf.numOfBeams    = numel(pln.propStf.gantryAngles);
% importer.pln.propStf.isoCenter     = ones(pln.propStf.numOfBeams,1) * matRad_getIsoCenter(cst,ct,0);
% importer.pln.propOpt.runDAO        = 0;
% importer.pln.propSeq.runSequencing = 0;
% 
% % dose calculation settings
% importer.pln.propDoseCalc.doseGrid.resolution.x = 3; % [mm]
% importer.pln.propDoseCalc.doseGrid.resolution.y = 3; % [mm]
% importer.pln.propDoseCalc.doseGrid.resolution.z = 3; % [mm]
% 
% % Optimization settings
% importer.pln.propOpt.quantityOpt = 'RBExDose';


importer = matRad_DicomImporter('E:\Workshop\autoMatRad\data\dicom_data\pt14626121st_wang_zheng_ming\1');
importer.matRad_importDicom();
if ~isempty(importer.ct)
    ct = importer.ct;
    cst = importer.cst;
    save(dest_path_of_rawMat, 'cst','ct');
    fprintf('成功导入并保存数据到: %s\n', dest_path_of_rawMat);
else
    fprintf('  --> 导入失败: 未找到有效的CT或RTStruct数据。\n');
end
    

% for i = 1:length(allItems)
%     curItem = allItems(1); % i = 1
%     patientDicomPath = fullfile(source_path_of_Dicom,curItem.name,'pCT'); 
% 
%     fprintf('--------------------------------------------------\n');
%     fprintf('正在处理病人: %s\n', curItem.name);
% 
% 
%     try
%         % 提取当前病患的pCT中全部DICOM
%         importer = matRad_DicomImporter(patientDicomPath);
%         % 调用matRad_importDicom() 解析DICOM文件并填充Importer属性
%         importer.matRad_importDicom();
% 
%         % 访问实例Importer属性并保存数据到.mat文件
%         if ~isempty(importer.ct)
%             ct = importer.ct;
%             cst = importer.cst;
% 
%             save(dest_path_of_rawMat, 'cst','ct');
%             fprintf('成功导入并保存数据到: %s\n', dest_path_of_rawMat);
%         else
%             fprintf('  --> 导入失败: 未找到有效的CT或RTStruct数据。\n');
%         end
% 
%     catch
%         fprintf('  --> catch a error. \n');
%     end
% end



