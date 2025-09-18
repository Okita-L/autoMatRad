function path_of_rawMat = autoLoadDicom(path_of_Dicom, path_of_rawMat)
% AUTOLOADDICOM: automatically load DICOMs of a batch of patients
% input:
%   source_path_of_Dicom
%   dest_path_of_rawMat
% output:
%   source_path_of_rawMat
% call:
%   autoLoadDicom(path_of_Dicom, path_of_rawMat); %
%   提取path_of_Dicom中的文件，生成mat并存储到path_of_rawMat
%   autoLoadDicom(path_of_Dicom, path_of_rawMat); % 默认存储到data/mat_data
%
% version 1.0, written in 2025.9.17.
% Author: Hang Lian
if nargin<2 % 使用默认路径
    % 自动获取项目路径
    projectPath = fileparts(mfilename("fullpath")); % 'E:\Workshop\autoMatRad\src\utils'
    projectPath = fileparts(projectPath);
    projectPath = fileparts(projectPath); % 'E:\Workshop\autoMatRad'
    % 自动获取存放路径
    path_of_rawMat = fullfile(projectPath,"data/mat_data"); % 'E:\Workshop\autoMatRad\data\mat_data'
end
if ~exist(path_of_rawMat,'dir')
    mkdir(path_of_rawMat);
end

allItems = dir(path_of_Dicom);
% 过滤当前目录和父目录 . 和 .. 以及非文件夹项
allItems = allItems([allItems.isdir])
allItems = allItems(~ismember({allItems.name},{'.','..'}));
fprintf('总共找到 %d 个病人文件夹。\n', numel(allItems));

for i = 1:length(allItems)
    curItem = allItems(i); % i = 1
    patientDicomPath = fullfile(path_of_Dicom,curItem.name,'pCT'); 

    fprintf('--------------------------------------------------\n');
    fprintf('正在处理病人: %s\n', curItem.name);

    try
        % 提取当前病患的pCT中全部DICOM
        importer = matRad_DicomImporter(patientDicomPath);
        % 清空 RTPlan 文件的导入列表
        importer.importFiles.rtplan = [];
        % 调用matRad_importDicom() 解析DICOM文件并填充Importer属性
        importer.matRad_importDicom();

        % 访问实例Importer属性并保存数据到.mat文件
        if ~isempty(importer.ct)
            ct = importer.ct;
            cst = importer.cst;
            
            savepath = fullfile(path_of_rawMat,curItem.name);
            save(savepath, 'cst','ct');
            fprintf('成功导入并保存数据到: %s\n', savepath);
        else
            fprintf('  --> 导入失败: 未找到有效的CT或RTStruct数据。\n');
        end

    catch
        fprintf('  --> catch a error. \n');
    end
end

path_of_rawMat = path_of_rawMat;

end










