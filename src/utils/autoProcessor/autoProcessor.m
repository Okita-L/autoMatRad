classdef autoProcessor < handle
    % autoProcessor.m
    % Sept. 2025. By Hang Lian.
    % 这个类封装了matRad数据处理的自动化流程
    % 
    % version: 1.0  
    
    properties
        % path
        projectPath     % 项目的根路径
        path_of_Dicom % 不应该是一个类属性吧
        path_of_rawMat
        path_of_CSTMat
        path_of_STFMat
        path_of_DVH_QI
        path_of_STFCSV
        path_of_DIJMat
        path_of_resultGUI
        path_of_OrgCSV
        

        % pln
        pln
    end
    
    % 构造函数
    methods

        function obj = autoProcessor(projectPath)
            % AUTOPROCESSOR 构造此类的实例
            % input:
            % output:
            % call:

            %% 参数验证
            arguments 
                projectPath {autoProcessor.mustBeTextOrEmpty} = [];
            end
            %% 初始化matRad
            try 
                matRad_rc;
            catch
                disp('Damn!----MatRad配置错误');
                disp('         请检查是否包含了MatRad子模块或设置了路径。');
            end

            %% 初始化projectPath
            if isempty(projectPath)
                obj.projectPath = fileparts(mfilename('fullpath')); % 'E:\Workshop\autoMatRad\src\utils\autoProcessor'
                obj.projectPath = fileparts(obj.projectPath); % 'E:\Workshop\autoMatRad\src\utils'
                obj.projectPath = fileparts(obj.projectPath); % 'E:\Workshop\autoMatRad\src'
                obj.projectPath = fileparts(obj.projectPath); % 'E:\Workshop\autoMatRad'
            else
                obj.projectPath = projectPath;
            end
            fprintf('projectPath now is %s\n',obj.projectPath);

            %% 初始化默认pln设置
            obj.pln.radiationMode = 'protons';            
            obj.pln.machine       = 'Generic';

            % for particles it is possible to also calculate the LET disutribution
            % alongside the physical dose. Therefore you need to activate the
            % corresponding option during dose calculcation
            obj.pln.propDoseCalc.calcLET = 0;

            obj.pln.numOfFractions        = 30;
            obj.pln.propStf.gantryAngles  = 0:5:359;
            numAngles = length(obj.pln.propStf.gantryAngles);
            obj.pln.propStf.couchAngles = zeros(1, numAngles);
            obj.pln.propStf.bixelWidth    = 5;
            obj.pln.propStf.numOfBeams    = numel(obj.pln.propStf.gantryAngles);
            obj.pln.propOpt.runDAO        = 0;
            obj.pln.propOpt.runSequencing = 0;

            % isoCenter在generateSTF时赋值
            % pln.propStf.isoCenter     = ones(pln.propStf.numOfBeams,1) * matRad_getIsoCenter(cst,ct,0);
            obj.pln.propStf.isoCenter = [];
            % multScen 同理
            % pln.multScen = matRad_multScen(ct,'nomScen');
            obj.pln.multScen = struct();

            % 用的最新版的matRad model = matRad_bioModel(sRadiationMode, sModel)
            obj.pln.bioParam = matRad_bioModel(obj.pln.radiationMode, 'constRBE');
            % 旧版为matRad_bioModel(pln.radiationMode,quantityOpt, modelName);
            % quantityOpt   = 'RBExD';
            % modelName     = 'constRBE';   
            % pln.bioParam = matRad_bioModel(pln.radiationMode, modelName);
            obj.pln.propOpt.quantityOpt = 'RBExD'; % 新版matRad在这里设置该参数

            % dose calculation settings
            obj.pln.propDoseCalc.doseGrid.resolution.x = 5; % [mm]
            obj.pln.propDoseCalc.doseGrid.resolution.y = 5; % [mm]
            obj.pln.propDoseCalc.doseGrid.resolution.z = 5; % [mm]

            
            %% 设置各个阶段的路径默认值
            obj.path_of_Dicom  = fullfile(obj.projectPath,'data','dicom_data');
            obj.path_of_rawMat = fullfile(obj.projectPath,'data','rawMat_data'); % mat_data
            obj.path_of_CSTMat = fullfile(obj.projectPath,'data','CSTMat_data'); % cstProcessed_data
            obj.path_of_STFMat = fullfile(obj.projectPath,'data','STFMat_data'); % matRad_data
            obj.path_of_DVH_QI = fullfile(obj.projectPath,'data','DVH_QI_data'); % dvh_qi_data
            obj.path_of_STFCSV = fullfile(obj.projectPath,'data','STFCSV_file'); % stf_csvFiles
            obj.path_of_DIJMat = fullfile(obj.projectPath,'data','DIJMat_data');
            obj.path_of_resultGUI = fullfile(obj.projectPath,'data','resultGUI_data');
            obj.path_of_OrgCSV = fullfile(obj.projectPath,'data','OrgCSV_file'); % 将包括BRS_data等各个器官的矩阵
            
            pathsToCreate = {obj.path_of_rawMat, obj.path_of_CSTMat, obj.path_of_STFMat, ...
                 obj.path_of_DVH_QI, obj.path_of_STFCSV, obj.path_of_DIJMat, obj.path_of_OrgCSV};

            for k = 1:numel(pathsToCreate)
                if ~exist(pathsToCreate{k},'dir')
                    mkdir(pathsToCreate{k});
                end
            end

        end
         
    end


    % 主流程方法
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
                path_of_rawMat = obj.path_of_rawMat;
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
                path_of_rawMat = obj.path_of_rawMat; % 'E:\Workshop\autoMatRad\data\rawMat_data'
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
            % ATTENTION! 对于每一个病人，CTV需要根据实际的医学意义选择
            %% 验证参数
            arguments
                obj;
                OARs (:, 2) cell {autoProcessor.mustBeValidOARsStructure}
                Targets (:, 2) cell {autoProcessor.mustBeValidOARsStructure}
                path_of_rawMat {autoProcessor.mustBeTextOrEmpty} = '';
                path_of_CSTMat {autoProcessor.mustBeTextOrEmpty} = '';
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
                    path_of_CSTMat = fullfile(obj.projectPath,"data/CSTMat_data");
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
                fprintf('Wait!----正在处理第 %d 个病人数据 %s \n',i,matFiles(i).name);
                curFilepath = fullfile(path_of_rawMat, matFiles(i).name);
                try
                    load(char(curFilepath),'cst','-mat');
                catch ME
                    fprintf(['Damn!----无法加载文件 %s \n' ...
                        '错误信息: %s\n'], matFiles(i).name, ME.message);
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
        
        function autoGenerateSTF(obj, path_of_CSTMat, path_of_SFTMat)
            % AUTOGENERATESTF 根据CST生成原始的STF和PLN的matRad格式数据
            % input:
            %   obj
            %   path_of_CSTMat
            %   path_of_SFTMat
            %
            % Authors: Ke Shi, Hang Lian
            % Get_matRad_All.m -- BY SK
            
            %% 参数验证
            arguments
                obj;
                path_of_CSTMat {autoProcessor.mustBeTextOrEmpty} = [];
                path_of_SFTMat {autoProcessor.mustBeTextOrEmpty} = [];
            end
            
            %% 路径参数设置与验证
            if isempty(path_of_CSTMat)
                if ~isempty(obj.path_of_CSTMat)
                    path_of_CSTMat = obj.path_of_CSTMat;
                else
                    fprintf("Damn!----生成失败: 无法找到原始 CSTMat 文件位置\n" + ...
                        "         因为传入路径为空\n");
                    return;
                end
            end

            if isempty(path_of_SFTMat)
                if ~isempty(obj.path_of_STFMat)
                    path_of_SFTMat = obj.path_of_STFMat;
                else
                    path_of_SFTMat = fullfile(obj.projectPath,'data','STFMat_data');
                end
            end

            if ~exist(path_of_SFTMat,'dir')
                mkdir(path_of_SFTMat)
            end

            %% 获取所有CSTMat文件
            matFiles = dir(fullfile(char(path_of_CSTMat), '*.mat'));
            if isempty(matFiles)
                fprintf('Ops! ----路径 %s 下无 mat 文件\n', path_of_CSTMat);
                return;
            end
            
            %% 批处理计算STF结构
            for i=1:numel(matFiles)
                %% 导入单个mat
                fprintf('Wait!----正在处理第 %d 个病人数据 %s \n',i,matFiles(i).name);
                curFilepath = fullfile(path_of_CSTMat, matFiles(i).name);

                %% 生成SFT PLN
                try
                    % [stf,pln] = GenerateSigleSTF(obj, pln, path_of_CurCSTMat)
                    [stf,pln] = obj.GenerateSigleSTF(curFilepath);
                catch ME
                    fprintf(['Damn!----%s 路径验证失败\n' ...
                        '         错误信息: %s\n'], matFiles(i).name, ME.message);
                    continue;
                end

                %% 将stf存入指定路径
                % [~,filename, ext] = fileparts(matFiles(i).name);
                [~,filename, ~] = fileparts(matFiles(i).name);
                stf_filename = [filename '_Stf.mat'];
                curSavepath = fullfile(path_of_SFTMat,stf_filename);

                %% !!! 检查点 2: 在函数内部确认值已存在 !!!
                % if isempty(pln.multScen)
                %     fprintf('Debug: multScen 在赋值后立即为空！\n');
                % else
                %     % 获取结构体数组的元素数量 (N)
                %     num_scenarios = numel(pln.multScen);
                % 
                %     fprintf('Debug: multScen 赋值成功，总共包含 %d 个不确定性场景。\n', num_scenarios);
                % 
                %     % 获取字段名列表
                %     meta_fields = fieldnames(pln.multScen);
                % 
                %     % ----------------------------------------------------
                %     % 外部循环：遍历结构体数组的每一个元素 (即每一个不确定性场景)
                %     % ----------------------------------------------------
                %     for i = 1:num_scenarios
                %         fprintf('\n========================================\n');
                %         fprintf('--- 场景编号 %d / %d (pln.multScen(%d)) 详细内容 ---\n', i, num_scenarios, i);
                %         fprintf('========================================\n');
                % 
                %         % 内部循环：遍历当前元素的每一个字段
                %         for k = 1:numel(meta_fields)
                %             fieldName = meta_fields{k};
                % 
                %             % 访问当前元素 (i) 的当前字段 (fieldName) 的值
                %             value = pln.multScen(i).(fieldName);
                % 
                %             fprintf('%s:\n', fieldName);
                % 
                %             % 使用 disp 打印值，即使值是空数组或复杂数组
                %             disp(value); 
                %         end
                %     end
                % end

                %% 
                save(curSavepath,'stf','pln', '-v7');
                
            end

        end
        
        function [dij,resultGUI]=autoGenerateDIJandResultGUI(obj, path_of_CSTMat, path_of_STFMat, path_of_DIJMat, path_of_resultGUI)
            
            %% 参数验证
            arguments
                obj 
                path_of_CSTMat {autoProcessor.mustBeTextOrEmpty} = ''; % 用 ''更好
                path_of_STFMat {autoProcessor.mustBeTextOrEmpty} = '';
                path_of_DIJMat {autoProcessor.mustBeTextOrEmpty} = '';
                path_of_resultGUI {autoProcessor.mustBeTextOrEmpty} = '';
            end

            if isempty(path_of_CSTMat)
                if ~isempty(obj.path_of_CSTMat)
                    path_of_CSTMat = obj.path_of_CSTMat;
                else
                    fprintf("Damn!----导入失败: 无法找到原始 CSTMat 文件位置\n" + ...
                        "         因为传入路径为空\n");
                    return;
                end
            end

            if isempty(path_of_STFMat)
                if ~isempty(obj.path_of_STFMat)
                    path_of_STFMat = obj.path_of_STFMat;
                else
                    fprintf("Damn!----导入失败: 无法找到原始 STFMat 文件位置\n" + ...
                        "         因为传入路径为空\n");
                    return;
                end
            end

            if isempty(path_of_DIJMat)
                if ~isempty(obj.path_of_DIJMat)
                    path_of_DIJMat = obj.path_of_DIJMat;
                end
            end
            if ~exist(path_of_DIJMat, 'dir')
                mkdir(path_of_DIJMat);
            end

            if isempty(path_of_resultGUI)
                if ~isempty(obj.path_of_resultGUI)
                    path_of_resultGUI = obj.path_of_resultGUI;
                end
            end
            if ~exist(path_of_resultGUI, 'dir')
                mkdir(path_of_resultGUI);
            end

            %% matRad_rc
            matRad_rc;

            %% 获取文件信息
            % CSTMatFiles = dir(fullfile(path_of_CSTMat,'*.mat'));
            STFMatFiles = dir(fullfile(path_of_STFMat,'*_Stf.mat'));
            if isempty(STFMatFiles)
                fprintf('Warning: 在 %s 中没有找到匹配的 STF 文件。\n', path_of_STFMat);
                return;
            end

            %% 批处理生成DIJ
            for i=1:numel(STFMatFiles)
                %% 加载STF PLN CST CT
                % 预先清除 dij，防止数据污染
                if exist('dij','var'); clear dij; end 

                curSTFMat = STFMatFiles(i);
                fprintf('Wait!----正在处理第 %d 个病人数据 %s \n',i,curSTFMat.name);
                try
                    [~,stfName,~] = fileparts(curSTFMat.name);
                    fileName = stfName(1:end-4);
                    cstName = [fileName, '.mat'];  % xx.mat
                    
                    % load stf pln
                    load(fullfile(curSTFMat.folder,curSTFMat.name));

                    curCSTMatPath = fullfile(path_of_CSTMat,cstName);
                    if ~exist(curCSTMatPath, 'file')
                        fprintf('Ops! ----找不到匹配的 CST 文件: %s. 跳过。\n', cstName);
                        continue;
                    end
                    load(curCSTMatPath);
                catch ME
                    fprintf(['Damn!----无法加载病人 %s 数据\n' ...
                        '错误信息: %s\n'], fileName, ME.message);
                    continue; % 跳到下一个文件
                end

                %% 计算DIJ
                dijSavepath = fullfile(path_of_DIJMat, [fileName,'_dij.mat'] );
                
                if exist(dijSavepath, 'file')
                    fprintf('Info!----DIJ 文件已存在 (%s)，跳过计算。\n', [fileName,'_dij.mat']);
                    continue;
                end
                try
                    dij = matRad_calcParticleDose(ct,stf,pln,cst);
                    %% 保存DIJ
                    save(dijSavepath,'dij','-v7.3');
                    fprintf('Yeah!----病人 %s 的 DIJ 已保存到 %s。\n', fileName, dijSavepath);
                catch ME
                    fprintf(['Damn!----病人 %s 的 DIJ 计算失败\n' ...
                        '错误信息: %s\n'], fileName, ME.message);
                    if exist('dij','var'); clear dij; end;
                    continue;
                end 

                %% 计算resultGUI
                resultGUISavepath = fullfile(path_of_resultGUI, [fileName,'_resGUI.mat']);
                if exist(resultGUISavepath, 'file')
                    fprintf('Info!----resultGUI 文件已存在 (%s)，跳过计算。\n', [fileName,'_resGUI.mat']);
                    continue;
                end
                try 
                    new_cst = matRad_resizeCstToGrid(cst,dij.ctGrid.x, dij.ctGrid.y, dij.ctGrid.z, ...
                        dij.doseGrid.x, dij.doseGrid.y, dij.doseGrid.z);
                    resultGUI = matRad_fluenceOptimization(dij, cst, pln);
                    % 保存resultGUI
                    save(resultGUISavepath,'resultGUI','-v7.3');
                    fprintf('Yeah!----病人 %s 的 resultGUI 已保存到 %s。\n', fileName, resultGUISavepath);
                catch ME
                    fprintf(['Damn!----病人 %s 的 resultGUI 计算失败\n' ...
                        '错误信息: %s\n'], fileName, ME.message);
                    if exist('resultGUI','var'); clear resultGUI new_cst; end;
                end

            end
        end
        
        function autoGenerateResultGUI(obj, path_of_CSTMat, path_of_STFMat, path_of_DIJMat,path_of_resultGUI)
            % load dij太耗时了
            % 集成到autoGenrateDIJandResultGUI
            error("使用autoGenrateDIJandResultGUI");
        end
        
        function autoGetOrgCSV(obj, path_of_CSTMat, path_of_STFMat, path_of_DIJMat,path_of_resultGUI, path_of_OrgCSV)

            %% 参数验证
            arguments
                obj;
                path_of_CSTMat {autoProcessor.mustBeTextOrEmpty} = '';
                path_of_STFMat {autoProcessor.mustBeTextOrEmpty} = '';
                path_of_DIJMat {autoProcessor.mustBeTextOrEmpty} = '';
                path_of_resultGUI {autoProcessor.mustBeTextOrEmpty} = '';
                path_of_OrgCSV {autoProcessor.mustBeTextOrEmpty} = '';
            end
            %% 路径参数验证与设置
            % 如果路径中为空，直接调用autoGenerateDIJandResultGUI 生成并保存数据
            if isempty(path_of_CSTMat)
                if ~isempty(obj.path_of_CSTMat)
                    path_of_CSTMat = obj.path_of_CSTMat;
                else
                    fprintf("Damn!----生成失败: 无法找到原始 CSTMat 文件位置\n" + ...
                        "         因为传入路径为空\n");
                    return;
                end
            end
            if isempty(path_of_STFMat)
                if ~isempty(obj.path_of_STFMat)
                    path_of_STFMat = obj.path_of_STFMat;
                else
                    fprintf("Damn!----导入失败: 无法找到原始 STFMat 文件位置\n" + ...
                        "         因为传入路径为空\n");
                    return;
                end
            end
            if isempty(path_of_DIJMat)
                if ~isempty(obj.path_of_DIJMat)
                    path_of_DIJMat = obj.path_of_DIJMat;
                else
                    fprintf("Damn!----导入失败: 无法找到原始 DIJMat 文件位置\n" + ...
                        "         因为传入路径为空\n");
                    return;
                end
            end
            if isempty(path_of_resultGUI)
                if ~isempty(obj.path_of_resultGUI)
                    path_of_DIJMat = obj.path_of_resultGUI;
                else
                    fprintf("Damn!----导入失败: 无法找到原始 resultGUI 文件位置\n" + ...
                        "         因为传入路径为空\n");
                    return;
                end
            end
            
            %% 获取 DIJ 和 resultGUI
            dijMatFiles = dir(fullfile(path_of_DIJMat, '*_dij.mat'));
            resultGUIFiles = dir(fullfile(path_of_resultGUI, '*_resGUI.mat'));
            if numel(dijMatFiles) == 0 || numel(resultGUIFiles) == 0
                fprintf('Info!----检测到DIJ或ResultGUI文件缺失，正在执行生成流程...\n');
                [dij, resultGUI] = autoGenerateDIJandResultGUI( ...
                    path_of_CSTMat, path_of_STFMat, ...
                    path_of_DIJMat, path_of_resultGUI);
                fprintf('Info!----文件生成完成。\n');
            else
                fprintf('Info!----已找到所有DIJ和ResultGUI文件，跳过生成步骤。\n');
            end
            
                

        end
    end
    
    % 主流程工具函数
    methods
        
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
                obj;
                Targets1col (:, 1) cell;
                cstSubset (:, 1) cell;
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
            % 'UniformOutput', false：告诉 MATLAB，输出结果仍是元胞数组
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


            %% TODO
            % 应该追加判断，是否第四列为空 为空的不要用！
            % 目前只有48号病人存在ctv1 第四列为空 导致stfmat生成失败
            % 如何修改，传入参数cst应该是两列 多加一个判断向量isNull即可
            % 日后再说

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

        function [stf,pln] = GenerateSigleSTF(obj, path_of_CurCSTMat, pln_in)
            %% 参数验证
            arguments
                obj;
                path_of_CurCSTMat {autoProcessor.mustBeTextOrEmpty} = [];
                pln_in {autoProcessor.mustBeValidPlnStructure} = [];
            end
            % 好习惯 保证怎么样都有定义
            stf = [];
            % pln = struct(); % 会导致赋值失败
            %% 检查路径
            if isempty(path_of_CurCSTMat)
                error('autoProcessor:MissingPath', '路径参数 path_of_CurCSTMat 不允许为空。');
            end
            if ~exist(path_of_CurCSTMat,'file')
                % 如果文件不存在，报告完整路径并退出
                error('autoProcessor:FileNotFound', 'Damn!----未找到目标CSTMat文件: %s', path_of_CurCSTMat);
            end
            
            %% 加载文件
            try
                load(path_of_CurCSTMat);
            catch ME
                error('autoProcessor:LoadFailed', '文件加载失败：%s', ME.message);
            end

            %% 设置pln
            if isempty(pln_in) % 继承默认的pln
                pln_in = obj.pln;
            end

            
            
            pln_in.propStf.isoCenter     = ones(pln_in.propStf.numOfBeams,1) * matRad_getIsoCenter(cst,ct,0);
            pln_in.multScen              = matRad_multScen(ct,'nomScen');

            %% !!! 检查点 1: 在函数内部确认值已存在 !!!
            % if isempty(pln_in.multScen)
            %     fprintf('Debug: multScen 在赋值后立即为空！\n');
            % else
            %     % 获取结构体数组的元素数量 (N)
            %     num_scenarios = numel(pln_in.multScen);
            % 
            %     fprintf('Debug: multScen 赋值成功，总共包含 %d 个不确定性场景。\n', num_scenarios);
            % 
            %     % 获取字段名列表
            %     meta_fields = fieldnames(pln_in.multScen);
            % 
            %     % ----------------------------------------------------
            %     % 外部循环：遍历结构体数组的每一个元素 (即每一个不确定性场景)
            %     % ----------------------------------------------------
            %     for i = 1:num_scenarios
            %         fprintf('\n========================================\n');
            %         fprintf('--- 场景编号 %d / %d (pln_in.multScen(%d)) 详细内容 ---\n', i, num_scenarios, i);
            %         fprintf('========================================\n');
            %         % 内部循环：遍历当前元素的每一个字段
            %         for k = 1:numel(meta_fields)
            %             fieldName = meta_fields{k};
            % 
            %             % 访问当前元素 (i) 的当前字段 (fieldName) 的值
            %             value = pln_in.multScen(i).(fieldName);
            % 
            %             fprintf('%s:', fieldName);
            % 
            %             % 使用 disp 打印值，即使值是空数组或复杂数组
            %             disp(value); 
            %         end
            %     end
            % end

            %% Generate Beam Geometry STF
            pln=pln_in;
            stf = matRad_generateStf(ct, cst, pln_in);

        end

        function count = countOrganOccurrences(obj, path_of_rawMat)

            % 统计各个器官的出现频次 在所有病人的数据中
            arguments
                obj;
                path_of_rawMat {mustBeTextOrEmpty} = '';
            end

        end

    end

    % 以下验证函数
    methods (Static, Access = private)
        
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
                
                % =========================================================
                % --- 验证第二列：必须是包含结构体的元胞数组 (CELL) ---
                % =========================================================
                
                constraintCell = organs{i, 2};
                
                % 1. 验证第二列必须是元胞数组 (Cell)
                if ~iscell(constraintCell)
                    error('Custom:InvalidOARs', ...
                        'OARs 数组第 %d 行的第 2 列必须是元胞数组 {}。', i);
                end

                % 2. 检查元胞数组是否为空或内容是否为空
                if isempty(constraintCell)
                    % 允许空 cell 数组 {}，表示没有约束
                    continue; 
                end

                % 3. 约束条件列表应位于 cell 数组内部
                % 假设约束结构体数组是 cell 数组的第一个（也是唯一）元素
                constraintArray = constraintCell{1}; 
                
                % 检查 cell 数组的第一个元素是否是结构体数组
                if ~isstruct(constraintArray)
                    error('Custom:InvalidOARs', ...
                        'OARs 数组第 %d 行的第 2 列的元胞数组中，第一个元素必须是结构体数组。', i);
                end
                
                % 允许空的结构体数组 []，表示没有约束
                if isempty(constraintArray)
                    continue;
                end
                
                % 4. 遍历结构体数组中的每一个约束元素
                for j = 1:numel(constraintArray)
                    currentConstraint = constraintArray(j); % 提取当前的约束结构体 (struct)
                    % 检查字段名是否存在
                    requiredFields = {'className', 'parameters', 'penalty'};
                    if ~all(isfield(currentConstraint, requiredFields))
                        error('Custom:InvalidOARs', ...
                            'OARs 数组第 %d 行, 约束 %d 缺少必需的字段: className, parameters, 或 penalty', i, j);
                    end
                    
                    % 验证 .className 字段：必须是单个字符串 
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

        function mustBeValidPlnStructure(pln)
            % MUSTBEVALIDPLNSTRUCTURE
            % 确保输入 v 是结构体或者为空
            if isempty(pln)
                return; % 允许空值
            end
            % 如果不为空，则必须是结构体
            mustBeA(pln, 'struct');

        end
            



    end

        






        




        






end