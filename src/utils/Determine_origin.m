function [origin_BRS] = Determine_origin(new_cst,dij,stf,resultGUI, ID)
% % 20241021 Daoriao 
% % Determine the originating beam, ray, and specific spot from which the voxel dose was derived
Dij = dij.physicalDose{1}; % dose influence matrix
if isfield(dij, 'RBE')
    Dij = dij.RBE*Dij;
end
dose = Dij*resultGUI.w; % voxel-dose
nonZeroIndices = find(dose ~= 0); % the voxel index which is hit by spots
% nonZeroIndices(101:end)=[];

V=[];
for i=1:size(new_cst, 1)
    if isequal(lower(new_cst{i,2}), 'brainstem') && ~isempty(new_cst{i,6})
        V = [V; vertcat(new_cst{i,4}{:})];
    end
end


intersection = intersect(nonZeroIndices, V);
% nonZeroIndices(indicesToClear) = [];

total_num_spot = cumsum([stf.totalNumOfBixels]);
for i = 1:length(intersection)
    Index = intersection(i);
    Di = Dij(Index,:);
    num_spot = find(Di);
    
    %if mod(i, 10) == 0    
    %    currentTime = datetime('now');
    %    fprintf('s%, i %d, len %d, %s \n', ID, i, length(intersection), datestr(currentTime)); 
    %end
    
    for j = 1:length(num_spot)
        beam_indx = min(find(num_spot(j)<total_num_spot));    
        Num_spot_beam = [];
        for k = 1:numel(stf(beam_indx).ray)
             num_spot_ray = numel(stf(beam_indx).ray(k).energy);
             Num_spot_beam = [Num_spot_beam num_spot_ray];
        end
        numel_spot_beam = cumsum(Num_spot_beam);
        if beam_indx == 1
             ray_indx = min(find(num_spot(j)<numel_spot_beam));
             spot_indx = numel_spot_beam(ray_indx) - num_spot(j);
        else
            spot_num = numel_spot_beam + total_num_spot(beam_indx-1);
            ray_indx = min(find(num_spot(j)<spot_num));
            spot_indx = spot_num(ray_indx) - num_spot(j);
        end
        origin_BRS{i,1} = Index;
        origin_BRS{i,j+1} =[beam_indx ray_indx spot_indx];
    end
end
end

