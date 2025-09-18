% autoLoadDicom.m
% Sept. 2025 By Hang Lian
% To load Dicoms in pCT automatically

function source_path_of_rawMat = autoLoadDicom(source_path_of_Dicom,dest_path_of_rawMat)
% AUTOLOADDICOM: automatically load DICOMs of a batch of patients
% input:
%   source_path_of_Dicom
%   dest_path_of_rawMat
% output:
%   source_path_of_rawMat
%
%
% version 1.0, written in 2025.9.17, author: Hang Lian

if ~exist(dest_path_of_rawMat,'dir')
    mkdir(dest_path_of_rawMat);
end

allItems = dir(source_path_of_Dicom);
% 过滤当前目录和父目录 . 和 .. 以及非文件夹项
allItems = allItems([allItems.isdir])
allItems = allItems(~ismember({allItems.name},{'.','..'}));
fprintf('总共找到 %d 个病人文件夹。\n', numel(allItems));

for i = 1:length(allItems)
    curItem = allItems(i); % i = 1
    patientDicomPath = fullfile(source_path_of_Dicom,curItem.name,'pCT'); 

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
            
            savepath = fullfile(dest_path_of_rawMat,curItem.name);
            save(savepath, 'cst','ct');
            fprintf('成功导入并保存数据到: %s\n', savepath);
        else
            fprintf('  --> 导入失败: 未找到有效的CT或RTStruct数据。\n');
        end

    catch
        fprintf('  --> catch a error. \n');
    end
end

source_path_of_rawMat = dest_path_of_rawMat;

end










