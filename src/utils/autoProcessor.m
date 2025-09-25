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
    end
    
    methods
        function obj = autoProcessor(projectPath)
            % AUTOPROCESSOR 构造此类的实例
            % input:
            % output:
            % call:

            %  构造函数：在创建对象时初始化路径
            if nargin > 0
                obj.projectPath = projectRootPath;
            else
                % 如果没有提供路径，自动推断
                obj.projectPath = fileparts(mfilename('fullpath')); % 'E:\Workshop\autoMatRad\src\utils'
                obj.projectPath = fileparts(obj.projectPath); % 'E:\Workshop\autoMatRad\src'
                obj.projectPath = fileparts(obj.projectPath); % 'E:\Workshop\autoMatRad'
            end
            disp(projectPath);

            % 设置各个阶段的路径
            
            
            % 确保所有输出目录都存在
            obj.ensureDirectories(); % ? 
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
            importer.importFiles.replan = [];
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
                patientDicomPath = fullfile(path_of_Dicom,curItem.name,'pCT'); 
                
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







        
        path_of_CSTMat = autoProcessCST(path_of_rawMat);
        path_of_STFMat = autoGenerateSTF(path_ofCSTMat);





    end






end

