% cst_processing.m
% Sept. 2025 Written by Ke Shi.
% To adjust Target&OAR&constraints

% 定义路径
path1='E:\Workshop\autoMatRad\data\mat_data';
path2='E:\Workshop\autoMatRad\data\cstProcessed_data';
data = path1;
savepath= path2;
% data = 'D:\Sk-work\ShiKe\reasearch-Work\MyWorkForMedical\For_LH\matRad-RBErobOpt\YourWork\data\mat_data';
% savepath = 'D:\Sk-work\ShiKe\reasearch-Work\MyWorkForMedical\For_LH\matRad-RBErobOpt\YourWork\data\cstProcessed_data';

% 获取所有.mat文件
matFiles = dir(fullfile(data, '*.mat'));

% 定义target和oars
expected_targets = {'ctv1','ctv'};
expected_oar = {'body', 'brainstem',...
    'opticnerve r','opticnerve l',...
    'chiasm',...
    'parotid r','parotid l'};

for i = 1:length(matFiles)
    filepath = fullfile(data, matFiles(i).name);
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
            case 'body'
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
    cst{target_Indices, 6}{1, 1}.parameters{1} = 54;
    cst{target_Indices, 6}{1, 1}.penalty = 800;
 
    % save cstProcessed data
    newfilepath = fullfile(savepath, matFiles(i).name);
    save(newfilepath, 'cst', 'ct');
end