% 定义源路径和目标路径
source_path = 'C:\Users\Administrator\Desktop\LG';
destination_path = 'E:\LG_PCT';

% 确保目标根路径存在，如果不存在则创建
if ~exist(destination_path, 'dir')
    % fprintf('目标根路径 "%s" 不存在，正在创建...\n', destination_path);
    mkdir(destination_path);
end

% 获取源路径下的所有文件和文件夹信息
all_items = dir(source_path);
% 过滤掉代表当前目录和父目录的 '.' 和 '..'
all_items = all_items(~ismember({all_items.name}, {'.', '..'}));

% 遍历列表中的每一个项目
for i = 1:length(all_items)
    current_item = all_items(i);
    % 检查当前项目是否为文件夹且名字中包含 'pt', 'IgnoreCase'和true参数用于确保大小写不敏感
    if current_item.isdir && contains(current_item.name, 'pt', 'IgnoreCase', true)
        % 构造源 pCT 文件夹的完整路径
        source_pct_folder = fullfile(source_path, current_item.name, 'pCT');     
        if exist(source_pct_folder, 'dir')  % 检查源 pCT 文件夹是否存在
            % 构造目标 ptxxxxx 文件夹的完整路径
            destination_pt_folder = fullfile(destination_path, current_item.name);
            % 如果目标 ptxxxxx 文件夹不存在，则创建它
            if ~exist(destination_pt_folder, 'dir')
                % fprintf('正在创建目标文件夹 "%s"\n', destination_pt_folder);
                mkdir(destination_pt_folder);
            end
            % 构造最终目标 pCT 文件夹的完整路径
            destination_pct_folder = fullfile(destination_pt_folder, 'pCT');
            % 使用 copyfile 函数移动整个 pCT 文件夹
            [status, msg] = copyfile(source_pct_folder, destination_pct_folder, 'f'); % 'f' 选项表示如果目标已存在，则强制覆盖
            % print info
            if status
                fprintf('已成功将 "%s" 移动到 "%s"。\n', source_pct_folder, destination_pct_folder);
            else
                fprintf('移动 "%s" 时出错: %s\n', source_pct_folder, msg);
            end
        else
            fprintf('警告：在 "%s" 中找不到 "pCT" 文件夹。\n', current_item.name);
        end
    end
end