% cst_processing.m
% Sept. 2025 Written by Ke Shi.
% To adjust Target&OAR&constraints

% 定义路径
data = 'D:\Sk-work\ShiKe\reasearch-Work\MyWorkForMedical\For_LH\matRad-RBErobOpt\YourWork\data\mat_data';
savepath = 'D:\Sk-work\ShiKe\reasearch-Work\MyWorkForMedical\For_LH\matRad-RBErobOpt\YourWork\data\cstProcessed_data';

% 获取所有.mat文件
matFiles = dir(fullfile(data, '*.mat'));

% 定义target和oar映射关系
expected_targets = {'ctv1'};

expected_oar = {'body', 'brainstem'};

for i = 1:length(matFiles)
    filepath = fullfile(data, matFiles(1).name);
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
    % 取出'body', 'brainstem'的索引
    oar_Indices = find(cellfun(@(x) any(ismember(lower(x), expected_oar)), cst(:,2)));
    
    for j = 1:size(oar_Indices,1)
        
        % 初始化oar的剂量约束
        cst{oar_Indices(j), 6} = cst{target_Indices(1), 6};
        
        % 设置oar的剂量约束条件        
        cst{oar_Indices(j), 6}{1, 1}.className = 'DoseObjectives.matRad_SquaredOverdosing';
        
        if strcmpi(cst{oar_Indices(j), 2}, 'body')
            cst{oar_Indices(j), 6}{1, 1}.parameters{1} = 55;
            cst{oar_Indices(j), 6}{1, 1}.penalty = 1000;
        else 
            cst{oar_Indices(j), 6}{1, 1}.parameters{1} = 54;
            cst{oar_Indices(j), 6}{1, 1}.penalty = 300;
        end
    end
    % 设置target的剂量约束条件   
    cst{target_Indices, 6}{1, 1}.parameters{1} = 54;
    cst{target_Indices, 6}{1, 1}.penalty = 800;
 
    % save cstProcessed data
    newfilepath = fullfile(savepath, matFiles(1).name);
    save(newfilepath, 'cst', 'ct');
end