function []=auto_rc(clearWindow)
% AUTO_RC 
% 
%  
%
% 
% Version v1.0, written in 2025.9.17, author: Hang Lian
if nargin < 1
    clearWindow = false;
end

% 获取当前脚本的完整路径
projectPath = fileparts(mfilename('fullpath'));
% 向上返回两级，回到项目根目录
projectPath = fileparts(projectPath);
projectPath = fileparts(projectPath);

libPath = fullfile(projectPath,'libs');

% 检查 lib 目录是否存在
if exist(libPath,'dir')
     % 将 lib 目录及其所有子目录添加到MATLAB路径
     addpath(genpath(libPath));
else
     % 如果 lib 目录不存在，则抛出错误
     error('lib directory not found. Please ensure all submodules are included.');
end

addpath(genpath(projectPath));

% disp("DONE");

% clear workspace and command prompt, close all figures
if clearWindow
    clc;
    close all;
end

end



















