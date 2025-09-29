classdef autoProcessor < handle
    % autoProcessor.m
    % Sept. 2025. By Hang Lian.
    % 这个类封装了matRad数据处理的自动化流程
    % 
    % version: 1.0  
    
    properties
        projectPath     % 项目的根路径
        path_of_Dicom
        path_of_rawMat
        path_of_CSTMat
    end
    
    methods
        function obj = autoProcessor(projectPath)
            % AUTOPROCESSOR 构造此类的实例
            % input:
            % output:
            % call:

            %  构造函数：在创建对象时初始化路径
            if nargin > 0
                obj.projectPath = projectPath;
            else
                % 如果没有提供路径，自动推断
                obj.projectPath = fileparts(mfilename('fullpath')); % 'E:\Workshop\autoMatRad\src\utils'
                obj.projectPath = fileparts(obj.projectPath); % 'E:\Workshop\autoMatRad\src'
                obj.projectPath = fileparts(obj.projectPath); % 'E:\Workshop\autoMatRad'
            end
            disp(projectPath);

            % 设置各个阶段的路径
            
            
            % 确保所有输出目录都存在
            % obj.ensureDirectories(); % TODO
        end
        
        
    end

    methods
        % 以下方法均支持自定义存储路径
        % 修改方法：将目标路径作为第二个参数传入

        function autoLoadDicomSigle(obj,path_of_Dicom,path_of_rawMat)
            % AUTOLOADDICOMSIGLE: 将DICOM文件加载并转换为mat格式
            %   这个方法遍历指定路径下的DICOM文件，并转换为matRad所需的结构体
            %   保存到目标路径————可指定
            %
            % input:
            %   obj                 类的实例对象
            %   path_of_Dicom       包含原始DICOM文件的文件夹路径（字符串或字符数组）
            %   path_of_rawMat      [optional] 保存mat文件的目标文件夹路径
            %
            % output:
            %   path_of_rawMat      实际保存mat文件的文件夹路径
            % 
            % call:
            %   autoLoadDicomSingle(path_of_Dicom, path_of_rawMat);   % 存储到指定路径
            %   autoLoadDicomSingle(path_of_Dicom);                   % 默认存储到data/mat_data
            
            if nargin<3 % 使用默认路径
                path_of_rawMat = fullfile(obj.projectPath,"data/mat_data");
            end

            % 检查文件夹是否存在
            if ~exist(path_of_Dicom,'dir') % 2个参数的exist更快
                error('Damn!----输入DICOM文件夹不存在或不是一个文件夹: %s', path_of_Dicom)
            else
                obj.path_of_Dicom = path_of_Dicom;
            end
            if ~exist(path_of_rawMat,'dir')
                mkdir(path_of_rawMat);
            end
            
            % 检查文件可用性
            allDicoms = dir(fullfile(path_of_Dicom, '*.dcm'));
            if isempty(allDicoms)
                warning('Ops !----在文件夹 %s 中没有找到任何 .dcm 文件 导入终止\n', path_of_Dicom)
                obj.path_of_rawMat = '';
                return;
            end
            
            % 调用matRad的matRad_DicomImporter类实现导入
            importer = matRad_DicomImporter(path_of_Dicom);
            % 清空 RTPlan 文件的导入列表
            importer.importFiles.rtplan = [];
            % 调用matRad_importDicom() 解析DICOM文件并填充Importer属性
            importer.matRad_importDicom();
            % 访问实例Importer属性并保存数据到.mat文件
            [~, patientID, ~] = fileparts(path_of_Dicom);
            if ~isempty(importer.ct)
                ct = importer.ct;
                cst = importer.cst;
                savepath = fullfile(path_of_rawMat,[patientID,'.mat']);
                save(savepath, 'cst','ct');
            else
                warning('Ops !----导入失败: 未找到有效的CT。\n');
                obj.path_of_rawMat = '';
                return;
            end
            % 返回值 = 传入参数 或 默认值
            % path_of_rawMat = path_of_rawMat; % 自动继承同名局部变量 无须显示赋值
            % 类属性 = 返回值
            obj.path_of_rawMat = path_of_rawMat;
        end

        function autoLoadDicomBatch(obj,path_of_Dicom,path_of_rawMat)
            % AUTOLOADDICOMBATCH: 将DICOM文件加载并转换为mat格式
            %   这个方法遍历指定路径下每个病人的DICOM文件，并转换为matRad所需的结构体
            %   保存到目标路径————可指定
            %
            % input:
            %   obj                 类的实例对象
            %   path_of_Dicom       包含原始DICOM文件的文件夹路径（字符串或字符数组）
            %                       要求path_of_Dicom下面是每个病人的文件夹pti
            %                       pti文件夹名需要包含病人ID等标识信息
            %                           其下是否还有文件夹嵌套则由修改硬编码hardcode1解决
            %                       path_of_Dicom ----
            %                                       |-pt1
            %                                       |-pt2
            %   path_of_rawMat      [optional] 保存mat文件的目标文件夹路径
            %
            % output:
            %   path_of_rawMat      实际保存mat文件的文件夹路径
            % 
            % call:
            %   autoLoadDicomBatch(path_of_Dicom, path_of_rawMat);   % 存储到指定路径
            %   autoLoadDicomBatch(path_of_Dicom);                   % 默认存储到data/mat_data 
            if nargin<3 % 使用默认路径
                path_of_rawMat = fullfile(obj.projectPath,"data/mat_data"); % 'E:\Workshop\autoMatRad\data\mat_data'
            end
            if ~exist(path_of_rawMat,'dir')
                mkdir(path_of_rawMat);
            end

            allItems = dir(path_of_Dicom);
            % 过滤当前目录和父目录 . 和 .. 以及非文件夹项
            allItems = allItems([allItems.isdir])
            allItems = allItems(~ismember({allItems.name},{'.','..'}));
            
            fprintf('总共找到 %d 个病人文件夹。\n', numel(allItems));

            for i = 1:numel(allItems)
                curItem = allItems(i); 
                % 以下代码需要根据数据集的命名规范修改
                % 具体实现不免过于繁琐 也难以适应所心所欲的数据集格式
                % 修改硬编码即可 注意传入的参数path_of_Dicom只要求
                % hardcode1: 
                % patientDicomPath = fullfile(path_of_Dicom,curItem.name,'pCT'); 
                patientDicomPath = fullfile(path_of_Dicom,curItem.name)
                
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

                        % 若 savepath 是一个不带 .mat 扩展名的文件夹名，MATLAB 会默认在后面添加 .mat
                        % 但是会有warning
                        % 为了日志更简洁
                        % savepath = fullfile(path_of_rawMat,curItem.name);
                        % save(savepath, 'cst','ct'); 
                        savepath = fullfile(path_of_rawMat,[curItem.name,'.mat']);
                        save(savepath, 'cst','ct');

                        fprintf('Yeah!----成功导入并保存数据到: %s\n', savepath);
                    else
                        warning('Ops !----导入失败: 未找到有效的CT。\n');
                        continue;
                    end
            
                catch ME
                     fprintf('Damn!----处理病人 %s 时发生错误: %s\n', curItem.name, ME.message);
                     continue;
                end
            end
            
            % 如果导入全失败了，也是得到一个空文件夹
            % 部分成功，继续执行部分的后续
            % 所以这里返回对应的目录
            obj.path_of_rawMat = path_of_rawMat;
            
        end
        
        function autoProcessCST(obj, OARs, Targets, path_of_rawMat, path_of_CSTMat)
            % 方法实现自动筛选OAR和Target，并完成基础参数设置
            % input: 
            %   obj 
            % OARs    - (N x 2 CELL) 危及器官及约束条件的定义列表。
            %             - 第 1 列: (STRING ARRAY) 别名列表。例如: ["Lung_R", "RLung"]。
            %             - 第 2 列: (STRUCT ARRAY) 约束条件列表。
            %               每个结构体必须包含以下字段:
            %               1. .className  (STRING): 约束类型, 如 "MaxDose"。
            %               2. .parameters (CELL): 参数值, 包含数字数组, 如 {5, [10, 20]}。
            %               3. .penalty    (DOUBLE): 惩罚系数或权重 (标量)。 
            %   Targets
            %   path_of_rawMat
            %   path_of_CSTMat
            % output:
            %   
            % call:
            %   autoProcessCST(OARs, Targets, path_of_rawMat, path_of_CSTMat)
            %   autoProcessCST(OARs, Targets, path_of_rawMat)
            %   autoProcessCST(OARs, Targets)

            %% 验证参数
            arguments
                obj;
                % 期望结构
                % targets = ["ctv1", "ctv", "ctv2";  % 第一行代表一个目标，有 3 个可能的名称
                % "gvt",  "gvt-p", ""    % 第二行代表另一个目标，有 2 个可能的名称
                % ];
                % OARs { [字符串数组], constraints struct ;
                %           }
                % Targets 必须是字符串数组，且至少有一行（非空）

                OARs (:, 2) cell {mustBeValidOARsStructure}
                Targets {mustBeA(Targets, 'string'), mustBeNonEmpty}
                path_of_rawMat {mustBeTextOrEmpty} = [];
                path_of_CSTMat {mustBeTextOrEmpty} = [];
            end
            
            
            %% 输出Target和OARs信息
            fprintf('Targets (%d个) 和 OARs (%d个) 列表验证成功。\n', numel(Targets), numel(OARs));
            fprintf('Targets: %s\n', strjoin(Targets, ', '));
            fprintf('OARs:    %s\n', strjoin(OARs, ', '));

            %% 路径参数设置与验证
            if isempty(path_of_rawMat)
                if ~isempty(obj.path_of_rawMat)
                    path_of_rawMat = obj.path_of_rawMat;
                else
                    fprintf("Damn!----导入失败: 无法找到原始 Mat 文件位置\n" + ...
                        "         因为传入路径为空\n");
                    return;
                end

            end
            
            if isempty(path_of_CSTMat)
                if ~isempty(obj.path_of_CSTMat)
                    path_of_CSTMat = obj.path_of_CSTMat;
                else
                    path_of_CSTMat = fullfile(obj.projectPath,"data/cstProcessed_data");
                end
            end

            if ~exist(path_of_CSTMat, 'dir')
                mkdir(path_of_CSTMat);
            end
            
            %% 获取所有.mat文件
            matFiles = dir(fullfile(char(path_of_rawMat), '*.mat'));
            if isempty(matFiles)
                fprintf('Ops! ----路径 %s 下无 mat 文件', path_of_rawMat);
                return;
            end

            %% 识别并处理OARS和Targets
            for i=1:numel(matFiles)
                
                %% 导入单个mat
                fprintf('Wait!----正在处理第 %d 个病人数据 %s \n',matFiles(i).name,i);
                curFilepath = fullfile(path_of_rawMat, matFiles(i).name);
                try
                    load(char(curFilepath),'cst','-mat');
                catch ME
                    fprintf(['Damn!----无法加载文件 %s \n' ...
                        '         错误信息: %s\n'], matFiles(i).name, ME.message);
                    continue; % 跳到下一个文件
                end

                %% 获取所需区域索引
                targetIndex = getTargetIndex(Targets, cst(:, 1: 3));
                oarsIndices = getOARsIndices(OARs,cst(:,1:3)); % cst中索引 OARs中索引

                %% 判断ROI数量是否合法
                if isempty(targetIndex)
                    fprintf('Damn!----未识别 Target \n'+...
                        '         请检查患者 %s 的 Targets 命名是否符合规范',matFiles(i).name);
                    continue;
                end
                if numel(oarsIndices)~=size(OARs,1) || numel(oarsIndices) == 0
                    fprintf('Ops! ----已识别 OAR 总数不符合要求\n'+...
                        '         请检查患者 %s 的 OARs 命名是否符合规范',matFiles(i).name);
                    continue;
                end
                
                %% 清除不关注的target的约束条件
                % tRows = ismember(cst(:, 3), {'TARGET'});
                % rowsToBeIgnored = tRows & ~targetIndex;
                % cst{rowsToBeIgnored, 6} = [];
                % oars也清除 更快更安全
                cst{~targetIndex, 6} = [];

                %% 初始化所需OARs的约束条件
                % cell array 多行赋值用()
                % 单行用{}
                % OARs{}提取对应结构体数组
                cst(oarsIndices{1},6) = {OARs{oarsIndices{2},2}};
                
         
               
                




            end



            
        end

            
          


        function index = getTargetIndex(Targets, cstSubset)
            % GETTARGETINDEX: 取得唯一Target在cst中的索引
            % input:
            %
            % output:
            %
            % call:
            
            %% 
            arguments
                Targets (:,:) string {mustBeNonEmpty} % Targets 是多行字符串数组
                cstSubset (:, 3) cell {mustBeNonEmpty} % 验证：必须是非空的元胞数组，且只有两列
            end
            %% 确保小写&清除空字符串
            Targets = lower(Targets(Targets ~= ""));
            targetAliases = cellstr(Targets);
            

            % cst{:,3} 返回元胞数组 strcmp无法处理
                % tRows = strcmp(cst_subset{:,2}, 'TARGET');
                % tRowsNames = lower(cst_subset{tRows,2});
                % tRowsIgnore = ~ismember(tRowsNames,);



        end

        function indices = getOARsIndices(OARs, cstSubset)

            OARs = lower(OARs(OARs ~= ""));
            oarsAliases = cellstr(Oars);

        end

        function mustBeTextOrEmpty(x)
        % MUSTBETEXTOREMPTY
            if ~isempty(x)
                % 检查它是否是有效的文本格式
                mustBeText(x); 
            end
        end

        function mustBeValidOARsStructure(OARs)
            % MUSTBEVALIDOARSSTRUCTURE: 自定义验证函数,检查 OARs 的第二列结构体格式
            % 遍历 OARs 的每一行
            for i = 1:size(OARs, 1)
                
                % --- 验证第一列：必须是非空的字符串数组 ---
                oarAliases = OARs{i, 1};
                if ~isstring(oarAliases) || isempty(oarAliases)
                    error('Custom:InvalidOARs', ...
                        'OARs 数组第 %d 行的第 1 列必须是非空的字符串数组', i);
                end
                
                
                % --- 验证第二列：结构体数组及其内部格式 ---
                
                constraintArray = OARs{i, 2};
                
                % 1. 验证第二列：必须是结构体数组，且不能是空数组
                if ~isstruct(constraintArray) || isempty(constraintArray)
                    error('Custom:InvalidOARs', ...
                        'OARs 数组第 %d 行的第 2 列必须是非空的结构体数组', i);
                end
                
                % 2. 遍历结构体数组中的每一个约束元素
                for j = 1:numel(constraintArray)
                    currentConstraint = constraintArray(j); % 提取当前的约束结构体 (struct)
        
                    % 检查字段名是否存在
                    requiredFields = {'className', 'parameters', 'penalty'};
                    if ~all(isfield(currentConstraint, requiredFields))
                        error('Custom:InvalidOARs', ...
                            'OARs 数组第 %d 行, 约束 %d 缺少必需的字段: className, parameters, 或 penalty', i, j);
                    end
                    
                    % 验证 .className 字段：必须是单个字符串
                    if ~isstring(currentConstraint.className) || numel(currentConstraint.className) ~= 1
                        error('Custom:InvalidOARs', ...
                            'OARs 数组第 %d 行, 约束 %d 的 className 必须是单个字符串.', i, j);
                    end
                    
                    % 验证 .parameters 字段：必须是元胞数组 (cell)
                    if ~iscell(currentConstraint.parameters)
                        error('Custom:InvalidOARs', ...
                            'OARs 数组第 %d 行, 约束 %d 的 parameters 必须是元胞数组.', i, j);
                    end
                    
                    % 验证 .penalty 字段：必须是单个数字
                    if ~isnumeric(currentConstraint.penalty) || numel(currentConstraint.penalty) ~= 1
                        error('Custom:InvalidOARs', ...
                            'OARs 数组第 %d 行, 约束 %d 的 penalty 必须是单个数字.', i, j);
                    end
                end
            end
            
        end
        
            

    end

        






        




        






end