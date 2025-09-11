% 初始化matRad环境
matRad_rc

% 扫描DICOM文件夹
importFiles=struct();
importFiles.patDir = "E:\Workshop\autoMatRad\data\dicomdata\pt15609471stlichao\1";
[allfiles,patients] = matRad_scanDicomImportFolder(importFiles); % 路径为Dicom文件夹路径

% 筛选CT和RT结构文件
ctFiles = strcmp(allfiles(:,2),'CT');
rtssFiles = strcmp(allfiles(:,2),'rtstruct');

% 从第一个CT文件获取分辨率参数
% 从第一个CT文件获取分辨率参效
demInfoct = dicominfo(importFiles.ct{1});
importFiles.resx = dcmInfoCt.PixelSpacing(1);
importFiles.resy = dcmInfoCt.PixelSpacing(2);
importFiles.resz = dcmInfoCt.SliceThickness;
% 没置关健参数
importFiles.useDoseGrid = false;
% 执行导入
[ct, cst] = matRad_importDicom(importFiles);
% 后动GUI并显示数据
matRadGUI

