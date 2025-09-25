function path_of_SFTMat = autoGenerateSTF(path_of_CSTMat,path_of_SFTMat)
% AUTOGENERATESTF 此处显示有关此函数的摘要
% input:
%   path_of_CSTMat
%   path_of_SFTMat
% output:
%   path_of_SFTMat
% call:
%   autoGenerateSTF(path_of_CSTMat,path_of_SFTMat);
%   autoGenerateSTF(path_of_CSTMat); 
%
%
% version: ver2.0, written by Ke Shi in 2025.9, modified by Hang Lian in
% 2025.9.19
% Authors: Ke Shi, Hang Lian

% Get_matRad_All.m
%% 路径参数设置
if nargin<2 % 使用默认路径
    % 自动获取项目路径
    projectPath = fileparts(mfilename("fullpath")); % 'E:\Workshop\autoMatRad\src\utils'
    projectPath = fileparts(projectPath);
    projectPath = fileparts(projectPath); % 'E:\Workshop\autoMatRad'
    % 自动获取存放路径
    path_of_SFTMat = fullfile(projectPath,"data/stfpln_data"); % 'E:\Workshop\autoMatRad\data\cstProcessed_data'
end
if ~exist(path_of_SFTMat,'dir')
    mkdir(path_of_SFTMat);
end

%% 获取所有病例的mat文件
matFiles = dir(fullfile(path_of_CSTMat,'*.mat'));

%% 批处理计算stf结构
for i = 1:numel(matFiles)
    fprintf('正在处理第 %s 个病人数据 %d \n',matFiles(i).name,i);
    filepath = fullfile(path_of_CSTMat,matFiles(i).name);
    
    % matRad_rc % 单独测试需要addpath
    % 生成stf 
    [stf, pln] = Get_matRad(filepath); % Get_matRad is a function to initial sth, written by Ke Shi
    % 将stf存入指定路径
    [~,filename, ext] = fileparts(matFiles(i).name);
    stf_filename = [filename '_Stf.mat'] 
    savepath = fullfile(path_of_SFTMat,stf_filename);
    save(savepath,'stf','pln');

end

path_of_SFTMat = path_of_SFTMat;


end

