path_of_rawMat = 'E:\check';
path_of_CSTMat = 'E:\checkRes';

disp(['当前正在执行的脚本路径是: ' mfilename('fullpath')]);
disp(['path_of_rawMat 的值是: ' path_of_rawMat]);

% 获取所有.mat文件
matFiles = dir(fullfile(char(path_of_rawMat), '*.mat'));

% 定义target和oars
expected_targets = {'ctv1','ctv','ctv2'};
expected_oar = {'body','body1','body3',...
    'brainstem',...
    'opticnerve l','opticnerve r',...
    'chiasm',...
    'parotid r','parotid l'};  % 7个 不取'chiasm'
numOfOAR = 7;

for i = 1:length(matFiles)
    fprintf('正在处理第 %s 个病人数据 %d \n',matFiles(i).name,i);
    filepath = fullfile(path_of_rawMat, matFiles(i).name);
    load(filepath);
    
    % 移除不关注的target的约束条件
    for k = 1:size(cst,1)
        if isequal(cst{k,3},'TARGET')
            if ~any(ismember(lower(cst{k,2}), expected_targets))
                cst{k,6} = [];
            end
        end
    end
  
    % 取出'ctv1'的索引
    target_Indices = find(cellfun(@(x) any(ismember(lower(x), expected_targets)), cst(:,2)));
    % 取出OAR的索引
    oar_Indices = find(cellfun(@(x) any(ismember(lower(x), expected_oar)), cst(:,2)));
    
    % 检查是否全部识别
    if isempty(target_Indices)
        fprintf('错误：文件 %s 未识别到任何目标靶区 (target)。\n', matFiles(i).name);
        % 跳过当前文件的后续处理，直接进入下一个循环
        continue;
    end

    if numel(oar_Indices) ~= numOfOAR
         fprintf('警告：文件 %s 识别到的危及器官 (OAR) 数量不符合预期。实际数量：%d，预期数量：%d。\n', matFiles(i).name, numel(oar_Indices), numOfOAR);
    end

    % 为OAR设置新的剂量约束
    for j = 1:size(oar_Indices,1)
        % 初始化oar的剂量约束 ————————————er
        cst{oar_Indices(j), 6} = cst{target_Indices(1), 6}; % 第六列的cell中存的是约束条件struct
        
        % 设置oar的剂量约束条件    
        % 将指定危及器官的第一个剂量约束条件的目标函数改为平方超剂量函数----用于OAR
        % 惩罚 = penalty * max(0, dose - constraint_value)^2
        cst{oar_Indices(j), 6}{1, 1}.className = 'DoseObjectives.matRad_SquaredOverdosing';
         
        % 根据不同OAR设置不同参数
        switch cst{oar_Indices(j),2}
            case {'body','body1','body3'}
                cst{oar_Indices(j), 6}{1, 1}.parameters{1} = 55;
                cst{oar_Indices(j), 6}{1, 1}.penalty = 1000;
            case {'parotid r', 'parotid l'} % 使用单元格数组处理多个相同情况
                cst{oar_Indices(j), 6}{1, 1}.parameters{1} = 28;
                cst{oar_Indices(j), 6}{1, 1}.penalty = 300;
            otherwise
                cst{oar_Indices(j), 6}{1, 1}.parameters{1} = 54;
                cst{oar_Indices(j), 6}{1, 1}.penalty = 300;
        end
    end
    
    % 设置target的剂量约束条件
    for m = 1:numel(target_Indices)
        cst{target_Indices(m), 6}{1, 1}.parameters{1} = 54;
        cst{target_Indices(m), 6}{1, 1}.penalty = 800;
    end

    % save cstProcessed data
    newfilepath = fullfile(path_of_CSTMat, matFiles(i).name);
    save(newfilepath, 'cst', 'ct');
end


