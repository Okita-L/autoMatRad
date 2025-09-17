% autoLoadDicom.m
% Sept. 2025 By Hang Lian
% To load Dicoms in pCT automatically

function dest_path_of_Mat = autoLoadDicom(source_path_of_Dicom)
% AUTOLOADDICOM load DICOMs in specific directory by calling the API of matRad
% Input:
%   source_path_of_Dicom: the parent directory of all patients
% Output:
%   dest_path_of_Mat: the parent directory of all mat files. And the name
%   is automatically named as ptxxxxxxx.mat
%
% 调用说明：
%   autoLoadDicom(source_path_of_Dicom):
%   依次读取文件夹下每一个病人的pct文件夹下的dicom文件，生成正确命名的mat文件存于指定文件夹
%
%
%
% version v1.0, written in 2025.9.16, author: Hang Lian

% 检查是否更改了CT分辨率设置 matRad_DicomImport









end

