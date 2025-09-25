% Get_matRad.m
% Jun. 2024 Written by Ke Shi.
% To generate and save stf&pln from a phantom case.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Naming
function [stf,pln] = Get_matRad(inputfile_path)
    %% set matRad runtime configuration
    matRad_rc; %If this throws an error, run it from the parent directory first to set the paths
    load(inputfile_path);
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
    % Now we have to set the remaining plan parameters.
    pln.numOfFractions        = 30;
    pln.propStf.gantryAngles  = 0:5:359;
    numAngles = length(pln.propStf.gantryAngles);
    pln.propStf.couchAngles = zeros(1, numAngles);
    pln.propStf.bixelWidth    = 5;
    pln.propStf.numOfBeams    = numel(pln.propStf.gantryAngles);
    pln.propStf.isoCenter     = ones(pln.propStf.numOfBeams,1) * matRad_getIsoCenter(cst,ct,0);
    pln.propOpt.runDAO        = 0;
    pln.propOpt.runSequencing = 0;

    % Define the flavor of biological optimization for treatment planning along
    % with the quantity that should be used for optimization.

    quantityOpt   = 'RBExD';            % either  physicalDose / effect / RBExD
    modelName     = 'constRBE';         % none: for photons, protons, carbon                                    constRBE: constant RBE model
                                        % MCN: McNamara-variable RBE model for protons                          WED: Wedenberg-variable RBE model for protons 
                                        % LEM: Local Effect Model for carbon ions
    % retrieve bio model parameters
    % pln.bioParam = matRad_bioModel(pln.radiationMode,quantityOpt, modelName);
    pln.bioParam = matRad_bioModel(pln.radiationMode, modelName);

    % retrieve scenarios for dose calculation and optimziation
    pln.multScen = matRad_multScen(ct,'nomScen');

    % dose calculation settings
    pln.propDoseCalc.doseGrid.resolution.x = 5; % [mm]
    pln.propDoseCalc.doseGrid.resolution.y = 5; % [mm]
    pln.propDoseCalc.doseGrid.resolution.z = 5; % [mm]

    %% Generate Beam Geometry STF
    stf = matRad_generateStf(ct, cst, pln);
    
    