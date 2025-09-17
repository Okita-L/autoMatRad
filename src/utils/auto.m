% autoLoadDicom.m
% Sept. 2025 By Hang Lian
% To load and process the raw data automatically
auto_rc; % 将所需要的全部文件夹加入matlab的搜索路径

% 设置DICOM源文件夹 和 生成的mat文件存放的目的文件夹
source_path_of_Dicom = 'E:\LG_PCT';
projectPath = fileparts(mfilename("fullpath")); % 'E:\Workshop\autoMatRad\src\utils'
projectPath = fileparts(projectPath)
projectPath = fileparts(projectPath) % 'E:\Workshop\autoMatRad'
dest_path_of_rawMat = fullfile(projectPath,"data/mat_data/"); % 'E:\Workshop\autoMatRad\data\mat_data'

allItems = dir(source_path_of_Dicom);
% 过滤当前目录和父目录 . 和 ..
allItems = allItems(~ismember({allItems.name},{'.','..'}));


% 出错 matRad_DicomImporter/matRad_importDicomRTPlan (第 139 行)
% if isfield(BeamSequence.Item_1, 'TreatmentMachineName')
%            ^^^^^^^^^^^^^^^^^^^
% 出错 matRad_DicomImporter/matRad_importDicom (第 143 行)
%         obj = matRad_importDicomRTPlan(obj);
%               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
% 出错 auto (第 22 行)
%     importer.matRad_importDicom();
% 推测 未设置pln
% TODO：检查对应examples里面的流程

% 师姐的Get_matRad代码是否值得保留？
% %% Treatment Plan
% % The next step is to define your treatment plan labeled as 'pln'. This 
% % structure requires input from the treatment planner and defines the most 
% % important cornerstones of your treatment plan.
% 
% %%
% % First of all, we need to define what kind of radiation modality we would
% % like to use. Possible values are photons, protons or carbon. In this
% % example we would like to use protons for treatment planning. Next, we
% % need to define a treatment machine to correctly load the corresponding 
% % base data. matRad features generic base data in the file
% % 'proton_Generic.mat'; consequently the machine has to be set accordingly
% pln.radiationMode = 'protons';        
% pln.machine       = 'Generic';
% pln.bioModel      = 'constRBE';
% pln.multScen      = 'nomScen';
% 
% %%
% % for particles it is possible to also calculate the LET disutribution
% % alongside the physical dose. Therefore you need to activate the
% % corresponding option during dose calculcation. We also explicitly say to
% % use the Hong Pencil Beam Algorithm
% pln.propDoseCalc.calcLET = 0;
% pln.propDoseCalc.engine = 'HongPB';
% 
% %%
% % Now we have to set the remaining plan parameters.
% pln.numOfFractions        = 30;
% pln.propStf.gantryAngles  = [90 270];
% pln.propStf.couchAngles   = [0 0];
% pln.propStf.bixelWidth    = 5;
% pln.propStf.numOfBeams    = numel(pln.propStf.gantryAngles);
% pln.propStf.isoCenter     = ones(pln.propStf.numOfBeams,1) * matRad_getIsoCenter(cst,ct,0);
% pln.propOpt.runDAO        = 0;
% pln.propSeq.runSequencing = 0;
% 
% % dose calculation settings
% pln.propDoseCalc.doseGrid.resolution.x = 3; % [mm]
% pln.propDoseCalc.doseGrid.resolution.y = 3; % [mm]
% pln.propDoseCalc.doseGrid.resolution.z = 3; % [mm]
% 
% % Optimization settings
% pln.propOpt.quantityOpt = 'RBExDose';








for i = 1:length(allItems)
    curItem = allItems(1); % i = 1
    % 提取当前病患的pCT中全部DICOM
    importer = matRad_DicomImporter( fullfile(source_path_of_Dicom,curItem.name,'pCT')  );
    % fullfile(source_path_of_Dicom,curItem.name,'pCT');
    importer.matRad_importDicom();
    importer.matRad_createCst();
    ct = importer.ct;
    cst = importer.cst;
    save( fullfile(source_path_of_Dicom,curItem.name,'pCT','ct_cst.mat'),'ct','cst' );
    % TODO:
    % 检查一下代码逻辑是否正确处理单个病人的DICOM
    % 实现为批处理
    % 调用cst_processing.m（先改写为函数
    % .....
    
end



