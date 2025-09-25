% Get_matRad_All.m
% Sept. 2025 Written by Ke Shi.
% To generate and save stf&pln from all phantom cases.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Naming
%% addpath in to local workspace
% addpath(genpath('D:\Sk-work\ShiKe\reasearch-Work\MyWorkForMedical\For_LH\matRad-RBErobOpt'));

%% 设置输入输出文件的路径
% 设置包含.mat文件的文件夹路径
input_folder = "E:\Workshop\autoMatRad\data\cstProcessed_data";
% 设置输出文件夹路径
output_folder = "E:\Workshop\autoMatRad\data\matRadOld_data";

%% 获取所有病例的mat文件
matfiles = dir(fullfile(input_folder, '*.mat'));


% %% 处理某一两个数据异常 修改i即可
% matfile_path = fullfile(input_folder, matfiles(60).name);
% % 构造存储stf结构的list
%     [stf, pln]=Get_matRad(matfile_path);
%     % 将stf存入指定路径
%     fullfilename = matfiles(60).name;
%     [~, filename, ext] = fileparts(fullfilename);
%     stf_filename = [filename '_matRad.mat'];
%     output_path =  fullfile(output_folder, stf_filename);
%     save(output_path, 'stf','pln');    


%% 为每个病例mat文件计算stf结构
for i =1:length(matfiles)
    
    matfile_path = fullfile(input_folder, matfiles(i).name);
    
    % 构造存储stf结构的list
    [stf, pln]=Get_matRad(matfile_path);
    % 将stf存入指定路径
    fullfilename = matfiles(i).name;
    [~, filename, ext] = fileparts(fullfilename);
    stf_filename = [filename '_matRad.mat'];
    output_path =  fullfile(output_folder, stf_filename);
    save(output_path, 'stf','pln');    
end
 
