classdef autoProcessor < handle
    % autoProcessor.m
    % Sept. 2025. By Hang Lian.
    % 这个类封装了matRad数据处理的自动化流程
    % 
    % version: 1.0  
    
    properties
        projectPath     % 项目的根路径
        path_of_Dicom % 不应该是一个类属性吧
        path_of_rawMat
        path_of_CSTMat
        path_of_STFMat
        path_of_DVH_QI
        path_of_STFCSV
        path_of_OrgCSV
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
            fprintf('projectPath now is %s',projectPath);

            % 设置各个阶段的路径默认值
            path_of_Dicom  = fullfile(obj.projectPath,'data\dicom_data');
            path_of_rawMat = fullfile(obj.projectPath,'data\rawMat_data'); % mat_data
            path_of_CSTMat = fullfile(obj.projectPath,'data\CSTMat_data'); % cstProcessed_data
            path_of_STFMat = fullfile(obj.projectPath,'data\STFMat_data'); % matRad_data
            path_of_DVH_QI = fullfile(obj.projectPath,'data\DVH_QI_data'); % dvh_qi_data
            path_of_STFCSV = fullfile(obj.projectPath,'data\STFCSV_file'); % stf_csvFiles
            path_of_OrgCSV = fullfile(obj.projectPath,'data\OrgCSV_file'); % 将包括BRS_data等各个器官的矩阵
            
            % 确保所有输出目录都存在
            % obj.ensureDirectories(); % TODO
        end
         
    end

    methods
        % 主流程方法
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
                patientDicomPath = fullfile(path_of_Dicom,curItem.name);
                
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
            % input: 
            %   obj 
            %   OARs            - (N x 2 CELL) 危及器官及约束条件的定义列表。
            %                       - 第 1 列: (STRING ARRAY) 别名列表。例如: ["Lung_R", "RLung"]。
            %                       - 第 2 列: (STRUCT ARRAY) 约束条件列表。
            %                           每个结构体必须包含以下字段:
            %                           1. .className  (STRING): 约束类型, 如 "MaxDose"。
            %                           2. .parameters (CELL): 参数值, 包含数字数组, 如 {5, [10, 20]}。
            %                           3. .penalty    (DOUBLE): 惩罚系数或权重 (标量)。 
            %   Targets         - (N x 2 CELL) 同 OARs
            %   path_of_rawMat  - Sring
            %   path_of_CSTMat  - String
            % output:
            %   
            % call:
            %   autoProcessCST(OARs, Targets, path_of_rawMat, path_of_CSTMat)
            %   autoProcessCST(OARs, Targets, path_of_rawMat)
            %   autoProcessCST(OARs, Targets)

            %% 验证参数
            arguments
                obj;
                OARs (:, 2) cell {autoProcessor.mustBeValidOARsStructure}
                Targets (:, 2) cell {autoProcessor.mustBeValidOARsStructure}
                path_of_rawMat {autoProcessor.mustBeTextOrEmpty} = [];
                path_of_CSTMat {autoProcessor.mustBeTextOrEmpty} = [];
            end
            
            %% 输出Target和OARs信息
            fprintf('Targets (%d个) 和 OARs (%d个) 列表验证成功。\n', size(Targets,1), size(OARs,1));
            fprintf('Targets: %s\n', strjoin([Targets{:,1}], ' | '));
            fprintf('OARs:    %s\n', strjoin([OARs{:,1}], ' | '));

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
            for i=1:1%numel(matFiles)
                %% 导入单个mat
                fprintf('Wait!----正在处理第 %d 个病人数据 %s \n',i,matFiles(i).name);
                curFilepath = fullfile(path_of_rawMat, matFiles(i).name);
                try
                    load(char(curFilepath),'cst','-mat');
                catch ME
                    fprintf(['Damn!----无法加载文件 %s \n' ...
                        '         错误信息: %s\n'], matFiles(i).name, ME.message);
                    continue; % 跳到下一个文件
                end

                %% 获取所需区域索引
                targetIndices = getTargetIndex(obj,Targets(:,1), cst(:, 2)); % 同理oarsIndices 但是只有一行
                oarsIndices = getOARsIndices(obj,OARs(:,1),cst(:,2)); % cst中索引 OARs中索引 double数值矩阵N*2

                %% 判断ROI数量是否合法
                if size(targetIndices, 1) ~= size(Targets, 1) 
                    % 只期望一个Target匹配 尽管暂时的工作只需要一个target 但为了之后的工作考虑
                    fprintf('Damn!----未识别 Target \n'+...
                        '         请检查患者 %s 的 Targets 命名是否符合规范',matFiles(i).name);
                    continue;
                end
                if size(oarsIndices,1)~=size(OARs,1) % 必须全部ROI都识别 才有效
                    fprintf('Ops! ----已识别 OAR 总数不符合要求\n'+...
                        '         请检查患者 %s 的 OARs 命名是否符合规范',matFiles(i).name);
                    continue;
                end
                
                %% 清除不关注的target的约束条件
                % tRows = ismember(cst(:, 3), {'TARGET'});
                % rowsToBeIgnored = tRows & ~targetIndex;
                % cst{rowsToBeIgnored, 6} = [];
                % oars也清除 更快更安全

                % allMatchedRows = unique([targetIndex(:,1); oarsIndices(:,1)]);
                % cstRows = (1:size(cst, 1))';
                % rowsToBeIgnored = ~ismember(cstRows, allMatchedRows);
                % cst(rowsToBeIgnored, 6) = {[]}; 
                % 为了省一点内存，只能牺牲代码的可读性了
                % 功能 只保留所需target的constraint
                cst(~ismember( (1:size(cst, 1))', unique([targetIndices(:, 1); oarsIndices(:, 1)]) ), 6) = {[]};
                
                %% 初始化所需OARs的约束条件 重置target的剂量约束条件
                % 向量化优化
                % oarsIndices(:, 2) 包含所有匹配到的 oars 的行索引
                % OARs(oarsIndices, 2) 返回一个 Cell 数组子集，其中每个元素是匹配到的结构体数组
                % oarsIndices(:, 1) 包含所有匹配到的 cst 的行索引
                % cst(oarsIndices, 6) 返回一个 Cell 数组子集，其结构与 OARs(oarsIndices, 2) 匹配
                % 要将一个 Cell 数组 赋给另一个 Cell 数组的子集，必须使用小括号 ()
                % if {} MATLAB 会尝试将整个 Cell 数组解包，然后将其中的第一个元素赋给 cst 索引处的所有位置
                cst(oarsIndices(:, 1), 6) = OARs(oarsIndices(:, 2), 2);
                cst(targetIndices(:,1),6) = Targets(targetIndices(:,2),2);
                
                %% save cstProcessed data
                load(char(curFilepath),'ct','-mat');
                curSavepath = fullfile(path_of_CSTMat,matFiles(i).name);
                save(curSavepath, 'cst','ct');
            end
        end
        
     
    end

    methods
        % 主流程工具函数
        function targetIndex = getTargetIndex(obj,Targets1col, cstSubset)
            % GETTARGETINDEX 找到 cst 中每个匹配 ROI 对应的第一个别名在展平列表中的索引。
            %
            % 该函数返回一个数值向量，记录 cst 中每个匹配 ROI 名称在 'allAliasNames' 
            % 展平列表中的最低索引（即第一次匹配到的别名索引）。
            %
            % input:
            %   Targets1col (N x 1 CELL) Target 的别名定义列表。
            %   cstSubset (M x 1 CELL) cst 数据中包含所有 ROI 名称的列 (如 cst(:, 2))。
            %
            % output:
            %   firstAliasIndices (K x 1 DOUBLE) 匹配成功的 K 个 ROI 在 'allAliasNames'
            %             列表中的索引。0 表示未匹配。
            
            %% 验证参数
            arguments
                obj
                Targets1col (:, 1) cell
                cstSubset (:, 1) cell
            end
            % mustBeNonEmpty验证不了 cstSubset (:, 1) cell {mustBeNonEmpty}
            if isempty(Targets1col) || isempty(cstSubset)
                error('getTargetIndex:EmptyInput', 'Targets1col 或 cstSubset 不能为空。');
            end
        
            %% 确保小写
            Targets1col = cellfun(@lower, Targets1col, 'UniformOutput', false);  
            cstNames = cellfun(@lower, cstSubset(:, 1), 'UniformOutput', false); 
        
            %% get targetIndices
            targetsRowIndicesCell = arrayfun(@(i) repmat(i, [1, length(Targets1col{i})]), ...
                                     (1:size(Targets1col,1))', ... % 确保输出也是列向量 不转置直接是行向量 结果没差 但是这样方便理解
                                     'UniformOutput', false);
            targetsRowMap = [targetsRowIndicesCell{:}]; % [1 1 ... N N ...]
            % allAliasNames：将所有别名展平成一个 String 数组
            Targets1col_transposed = cellfun(@(x) x', Targets1col, 'UniformOutput', false);
            allAliasNames = vertcat(Targets1col_transposed{:});
            
            % [Lia, Locb] = ismember(A, B)
            % A (cstNames) 有 M 个元素，B (allAliasNames) 有 P 个别名。
            % Locb 是 M x 1 的数值向量，记录 cstNames(k) 在 allAliasNames 中的位置 (0表示不匹配)。
            % Locb(cst_idx) = tarIdx // 指明是哪一行/哪一个器官
            [~, Locb] = ismember(cstNames, allAliasNames);
            targetIndices = [find(Locb > 0), targetsRowMap(Locb(Locb > 0))'];

            % get targetIndex
            % priorityMap: 创建组内优先级查找表 [1 2 3 ... 1 2 ...] (1 = 最高优先级)
            priorityIndicesCell = arrayfun(@(i) 1:length(Targets1col{i}), ...
                                           (1:size(Targets1col,1))', 'UniformOutput', false);
            priorityMap = [priorityIndicesCell{:}];
            % priorities 是
            priorities = priorityMap(Locb(Locb > 0))';
            % 获取分组信息
            groupKeys = targetsRowMap(Locb(Locb > 0))';
            % accumarray 找到每个 Target 定义组中的最高优先级值
            % 结果是短向量 只包含对应的行
            res = accumarray(groupKeys, priorities, [], @min, inf);
            isHighestPriority = (priorities == res(groupKeys));
            targetIndex = targetIndices(isHighestPriority,:);

        end

        function targetIndices = getTargetIndices(obj,Targets1col, cstSubset)
            % GETTARGETINDICES 全匹配 cst 中的 ROI 名称与 Target 别名列表。
            %
            % 该函数通过一次向量化查找，高效地识别出 cst 数据中所有匹配 Target
            % 别名的行，并建立 cst 行索引和 Targets 定义行索引之间的映射
            %
            % input:
            %   Targets1col (N x 1 CELL) Target 的别名定义列表。
            %             - 每个单元格包含一个 STRING ARRAY，定义了某一 Target 的所有可能别名。
            %             - 示例: {["ctv1", "ctv_p"]; ["gtv"]}
            %   cstSubset (M x 1 CELL) cst 数据中包含所有 ROI 名称的列。
            %             - 每个单元格包含一个 CHAR 或 STRING，即 ROI 的名称。
            %             - 注意：此参数仅包含 cst 的名称列 (如 cst(:, 2))。
            %
            % output:
            %   targetIndices (K x 2 DOUBLE) 匹配结果的索引矩阵，其中 K 为匹配成功的 ROI 数量。
            %             - 第 1 列: (DOUBLE) 匹配到的 ROI 在原始 cst 中的**行索引**。
            %             - 第 2 列: (DOUBLE) 匹配到的 ROI 对应于 Targets1col 中的**行索引**。
            %
            % call:
            %   targetIndices = getTargetIndices(Targets(:, 1), cst(:, 2)); 
            
            %% 参数验证
            arguments
                obj
                Targets1col (:, 1) cell
                cstSubset (:, 1) cell 
            end
            % mustBeNonEmpty验证不了 cstSubset (:, 1) cell {mustBeNonEmpty}
            if isempty(Targets1col) || isempty(cstSubset)
                error('getTargetIndices:EmptyInput', 'Targets1col 或 cstSubset 不能为空。');
            end

            %% 确保小写&清除空字符串
            %'UniformOutput', false：告诉 MATLAB，输出结果仍是元胞数组
            % （因为 lower 对 String 数组操作，返回的 String 数组大小不定）
            Targets1col = cellfun(@lower, Targets1col, 'UniformOutput', false);  
            cstNames = cellfun(@lower, cstSubset(:,1), 'UniformOutput', false);

            %% 对比
            % targetIndices = zeros(0, 2);
            % for i=1:numel(Targets1col)
            %     cstIndices = find( ismember( cstSubset(:,1), Targets1col{i} ) ); % 直接取来 cell array, 提取元胞里的 string array
            %     targetIndices = [targetIndices;[cstIndices,cstIndices * 0 + i]];
            % end
            % repmat
            % targetsRowMap 是一个行向量，记录了 Targets1col 中每个别名属于 Targets1col 的哪一行。
            targetsRowIndicesCell = arrayfun(@(i) repmat(i, [1, length(Targets1col{i})]), ...
                                     (1:size(Targets1col,1))', 'UniformOutput', false);
            targetsRowMap = [targetsRowIndicesCell{:}]; % [1 1 ... N N ...]
            % allAliasNames：将所有别名展平成一个 String 数组
            Targets1col_transposed = cellfun(@(x) x', Targets1col, 'UniformOutput', false);
            allAliasNames = vertcat(Targets1col_transposed{:});
            % [Lia, Locb] = ismember(A, B)
            % A (cstNames) 有 M 个元素，B (allAliasNames) 有 P 个别名。
            % Locb 是 M x 1 的数值向量，记录 cstNames(k) 在 allAliasNames 中的位置 (0表示不匹配)。
            [~, Locb] = ismember(cstNames, allAliasNames);
            targetIndices = [find(Locb > 0), targetsRowMap(Locb(Locb > 0))'];
        end

        function oarsIndices = getOARsIndices(obj, OARs, cstSubset)
            arguments
                obj
                OARs (:, 1) cell
                cstSubset (:, 1) cell
            end
            % mustBeNonEmpty验证不了 cstSubset (:, 1) cell {mustBeNonEmpty}
            if isempty(OARs) || isempty(cstSubset)
                error('getTargetIndex:EmptyInput', 'OARs 或 cstSubset 不能为空。');
            end
            oarsIndices = getTargetIndex(obj,OARs,cstSubset);


        end

    end

    methods (Static, Access = private)
        % 以下验证函数
        function mustBeTextOrEmpty(x)
        % MUSTBETEXTOREMPTY
            if ~isempty(x)
                % 检查它是否是有效的文本格式
                mustBeText(x); 
            end
        end

        function mustBeValidOARsStructure(organs)
            % MUSTBEVALIDOARSSTRUCTURE: 自定义验证函数,检查 OARs 和 Targets 的格式
            % 遍历每一行
            for i = 1:size(organs, 1)
                % --- 验证第一列：必须是非空的字符串数组 ---
                oarAliases = organs{i, 1};
                if ~isstring(oarAliases) || isempty(oarAliases)
                    error('Custom:InvalidOARs', ...
                        'OARs 数组第 %d 行的第 1 列必须是非空的字符串数组', i);
                end
                
                % --- 验证第二列：结构体数组及其内部格式 ---
                constraintArray = organs{i, 2};

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
                    % char vector/ string array/ "" 空字符串
                    % if ~isstring(currentConstraint.className) || numel(currentConstraint.className) ~= 1
                    if ~( (isstring(currentConstraint.className) && isscalar(currentConstraint.className)) || ...
                        (ischar(currentConstraint.className) && isrow(currentConstraint.className)) )
 
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