% autoLoadDicom.m
% Sept. 2025 By Hang Lian
% To load and process the raw data automatically
auto_rc; % 将所需要的全部文件夹加入matlab的搜索路径

source_path_of_Dicom = 'E:\LG_PCT';
allItems = dir(source_path_of_Dicom);


for i = 1:length(allItems)
    importer = matRad_DicomImporter( fullfile(source_path_of_Dicom,allItems{i}.name)  );
end



