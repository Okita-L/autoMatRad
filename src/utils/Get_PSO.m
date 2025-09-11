% GetPSO.m
% Sept 2025. Written by KeShi.
% Use PSO algorithm for selecting the optimal EL (which corresponds to BPPs).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Add Path
addpath(genpath('D:\Sk-work\ShiKe\reasearch-Work\MyWorkForMedical\For_LH\matRad-RBErobOpt'));
% addpath(genpath('matRad-RBErobOpt\sk-work\RegArc'));
% addpath(genpath('RegArc\FullPSOdata'));
% addpath(genpath('FinalCode\SharedArcPSO'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Naming
% 定义路径
data = 'D:\Sk-work\ShiKe\reasearch-Work\MyWorkForMedical\For_LH\matRad-RBErobOpt\YourWork\data\cstProcessed_data';
PSOpath = 'D:\Sk-work\ShiKe\reasearch-Work\MyWorkForMedical\matRad-RBErobOpt\sk-work\RegArc\fullPSOdata';

% 获取所有.mat文件
matFiles = dir(fullfile(data, '*.mat'));

%遍历所有mat文件
for i = 1:length(matFiles)
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Naming
    try
        filePath = fullfile(data, matFiles(i).name);
        [~, ID, ~] = fileparts(matFiles(i).name);% ID name
        filename = [ID '_ArcPSO']; % name
        mkdir(fullfile(PSOpath, filename));
        dyfile = fullfile(PSOpath, filename, [filename '_diary.txt']);

        diary(dyfile);
        fprintf('Test ID: %5s \n',ID);
        Nowtime = datetime(); fprintf('Test time %5s \n',Nowtime);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        load(filePath); % Load patient data

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Arc data
    %% Treatment Plan
    % The next step is to define your treatment plan labeled as 'pln'. This 
    % structure requires input from the treatment planner and defines the most
    % important cornerstones of your treatment plan.
    %%
    % First of all, we need to define what kind of radiation modality we would
    % like to use. Possible values are photons, protons or carbon. In this
    % example we would like to use protons for robust treatment planning. Next, we
    % need to define a treatment machine to correctly load the corresponding 
    % base data. matRad features generic base data in the file
    % 'carbon_Generic.mat'; consequently the machine has to be set accordingly
        pln.radiationMode = 'protons';            
        pln.machine       = 'Generic';
        load('protons_Generic.mat','machine');

    %%
    % for particles it is possible to also calculate the LET disutribution
    % alongside the physical dose. Therefore you need to activate the
    % corresponding option during dose calculcation
        pln.propDoseCalc.calcLET = 0;

    %%
    % Define the biological optimization model for treatment planning along
    % with the quantity that should be used for optimization. Possible model values 
    % are:
    % 'none':     physical optimization;
    % 'constRBE': constant RBE of 1.1; 
    % 'MCN':      McNamara-variable RBE model for protons; 
    % 'WED':      Wedenberg-variable RBE model for protons
    % 'LEM':      Local Effect Model 
    % and possible quantityOpt are 'physicalDose', 'effect' or 'RBExD'.
    % As we use protons, we use a constant RBE of 1.1.
        modelName    = 'constRBE';
        quantityOpt  = 'RBExD';   

    %%
    % The remaining plan parameters are set like in the previous example files
        pln.numOfFractions        = 30;
        pln.propStf.gantryAngles  = 0:5:359; 
        pln.propStf.couchAngles   = zeros(size(pln.propStf.gantryAngles));
        pln.propStf.bixelWidth    = 5;
        pln.propStf.numOfBeams    = numel(pln.propStf.gantryAngles);
        pln.propStf.isoCenter     = ones(pln.propStf.numOfBeams,1) * matRad_getIsoCenter(cst,ct,0);
        pln.propOpt.runDAO        = 0;
        pln.propOpt.runSequencing = 0;

    % retrieve bio model parameters
        pln.bioParam = matRad_bioModel(pln.radiationMode,quantityOpt,modelName);

    % scenarios for dose calculation and optimziation
        pln.multScen = matRad_multScen(ct,'nomScen'); %'nomScen'   create only the nominal scenario
    %                       'wcScen'    create worst case scenarios
    %                       'impScen'   create important/grid scenarios
    %                       'rndScen'   create random scenarios
    %pln.multScen.shiftSD = [3,3,3]; % if have shiftSD

        pln.propDoseCalc.doseGrid.resolution.x = 5; % [mm]
        pln.propDoseCalc.doseGrid.resolution.y = 5; % [mm]
        pln.propDoseCalc.doseGrid.resolution.z = 5; % [mm]


    %% Generate Beam Geometry STF
        stf = matRad_generateStf(ct,cst,pln);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Start PSO

    %% Get WET
        wet = ArcPSO_GetWET(stf,machine); 

    %% KMeans
        [KMeansdata,Num_clusters] = ArcPSO_KMeans(wet);

    %% Get best energy 
        EnergyBest   = cell(Num_clusters,1);
        ClusterAngle = cell(Num_clusters,1);
        ClusterStf   = cell(Num_clusters,1);
        for id = 1:Num_clusters
            clusterNumber = id;
            logicalIndex = (KMeansdata(:, 3) == clusterNumber);
            SCAngle = KMeansdata(logicalIndex, 1);
            [SingleClusterBestEnergy,SingleStf] = ArcPSO_GetOptimalSolution(pln,SCAngle,ct,cst);
            EnergyBest{id}    = SingleClusterBestEnergy;
            ClusterAngle{id}  = SCAngle;
            ClusterStf{id}    = SingleStf;
        end

    %% Sort the energy in order of gantry angles
        [sortedEnergy,sortedAngle] = ArcPSO_SortEnergy(ClusterAngle,EnergyBest);

    %% Obtain PSO's energies
        PSOStf = ArcPSO_GetPSOStf(stf,sortedEnergy);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Inverse Optimization

    %% dose influence matrix
        dij = matRad_calcParticleDose(ct,PSOStf,pln,cst); 

    %% Optimization
        resultGUI = matRad_fluenceOptimization(dij,cst,pln);
        w_opt = resultGUI.w;

        [dvh,qi] = matRad_indicatorWrapper(cst,pln,resultGUI);
        ixRectum = 1;
        display(qi(ixRectum).D_5);

    %% Plot Slice
        slice = round(pln.propStf.isoCenter(1,3)./ct.resolution.z);
        doseWindow = [0 max(resultGUI.RBExD(:))];
        figure,title('original plan')
        % matRad_plotSliceWrapper(axesHandle,ct,cst,cubeIdx,dose,plane,slice,thresh,alpha,contourColorMap,...doseColorMap,doseWindow,doseIsoLevels,voiSelection,colorBarLabel,boolPlotLegend,varargin)
        matRad_plotSliceWrapper(gca,ct,cst,1,resultGUI.RBExD,3,slice,[],0.75,colorcube,[],doseWindow,[]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Save data
        filenm1 = [filename  '_matRadData'   '.mat' ];
        filenm2 = [filename  '_ArcPSOdata'   '.mat' ];

        cd([PSOpath, '/',filename]);
        % save(filenm1,'pln','stf','PSOStf','dij');
        save(filenm1,'pln','PSOStf','dij');
        save(filenm2,'wet','KMeansdata','Num_clusters','EnergyBest','ClusterAngle',...
            'ClusterStf','sortedEnergy','sortedAngle');

        saveas(figure(1),[filename '_SC.fig']);
        saveas(figure(2),[filename '_KMeans.fig']);
        saveas(figure(3),[filename '_DVH.fig']);
        saveas(figure(4),[filename '_Slice.fig']);
        
        close all;
    %% diary off   
        fprintf('All data were saved in %5s_data/plnstf.mat\n',filename);
        diary off;
    catch ME % ME 是捕获到的错误信息
        % 打印错误信息和出错的文件名
        fprintf('Error processing file: %s\n', matFiles(i).name);
        fprintf('Error message: %s\n', ME.message);
        % 继续执行下一个文件
        continue;
    end
    %% 清除工作区变量
    clearvars -except data PSOpath matFiles i; %全局变量和循环指数i保留
end
