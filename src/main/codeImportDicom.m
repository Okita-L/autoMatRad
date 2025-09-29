% 初始化matRad环境
matRad_rc;
auto_rc;

projectPath = fileparts(mfilename("fullpath")); % 'E:\Workshop\autoMatRad\src\utils'
projectPath = fileparts(projectPath);
projectPath = fileparts(projectPath); % 'E:\Workshop\autoMatRad'
processor = autoProcessor();
