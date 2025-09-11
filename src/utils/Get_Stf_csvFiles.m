% Get_Stf_csvFiles.m
% Sept. 2025. Written by KeShi.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%savePath
savePath = 'D:\Sk-work\ShiKe\reasearch-Work\MyWorkForMedical\For_LH\matRad-RBErobOpt\YourWork\data\stf_csvFiles';
stfPath = 'D:\Sk-work\ShiKe\reasearch-Work\MyWorkForMedical\For_LH\matRad-RBErobOpt\YourWork\data\matRad_data';

% 获取所有子文件夹
subfeat_folders = dir(stfPath);
load('protons_Generic.mat','machine');
availableEnergies = [machine.data.energy];

for i=3:length(subfeat_folders)
    
    filePath = fullfile(stfPath, subfeat_folders(i).name);
    [~, ID, ~] = fileparts(subfeat_folders(i).name);% ID name
    filename = ID(1:end-7); % name
    mkdir(fullfile(savePath, filename));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    stf_data = dir(fullfile(filePath, "*_matRad.mat"));
    stf_data_path = fullfile(filePath, stf_data.name);
    load(stf_data_path); % Load patient data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Others.csv
    % 初始化除了ray外的stf数据信息
    gantryAngle = cell(length(stf),1);
    isoCenter = cell(length(stf),1);
    sourcePoint = cell(length(stf),1);
    numOfBixelsPerRay = cell(length(stf),1);
    totalnumOfBixels = cell(length(stf),1);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Ray.csv
    
    %存储赋值
    for j=1:length(stf)
        
        % 赋值除了ray外的stf数据
        gantryAngle{j}=stf(j).gantryAngle;
        isoCenter{j} =stf(j).isoCenter;
        sourcePoint{j} = stf(j).sourcePoint;
        totalnumOfBixels{j} = stf(j).totalNumOfBixels;
        
        % 初始化ray特征数组
        rayPos_bev = cell(stf(j).numOfRays, 1);
        targetPoint_bev = cell(stf(j).numOfRays, 1);
        rayPos = cell(stf(j).numOfRays, 1);
        targetPoint = cell(stf(j).numOfRays, 1);
        energy = cell(stf(j).numOfRays, 1);
        wet = cell(stf(j).numOfRays, 1);
        
        for k=1:stf(j).numOfRays
 
            minEnergy = min([stf(j).ray(k).energy]);%per ray
            maxEnergy = max([stf(j).ray(k).energy]);
            % 计算 WET 值
            wet_value = machine.data(maxEnergy == availableEnergies).peakPos - machine.data(minEnergy == availableEnergies).peakPos;
            
            rayPos_bev{k}=stf(j).ray(k).rayPos_bev;
            targetPoint_bev{k}=stf(j).ray(k).targetPoint_bev;
            rayPos{k}=stf(j).ray(k).rayPos;
            targetPoint{k}=stf(j).ray(k).targetPoint;
            energy{k}=stf(j).ray(k).energy;
            wet{k}=wet_value;
        end
        
        % 定义字段名
        raydata = [rayPos_bev, targetPoint_bev, rayPos, targetPoint, wet, energy];
        % 定义最终存储路径
        filename = subfeat_folders(i).name;
        name = filename(1:end-11);
        rayfinalPath = fullfile(savePath,name,[name, '_stf',num2str(j), '.csv']);   
        % 将特征存储到CSV文件
        writecell(raydata, rayfinalPath);  % 写入数据
    end
    
    filename = subfeat_folders(i).name;
    name = filename(1:end-11);
    otherdata = [gantryAngle, isoCenter, sourcePoint, totalnumOfBixels];
    otherfinalPath = fullfile(savePath,name,[name,'.csv']);
    writecell(otherdata, otherfinalPath);  % 写入数据
    
end
