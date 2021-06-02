function [biomarkers, stats, extras, data] = doIbest

    in_logfile = ['./doIBEST.log'];
    diary(in_logfile)
    diary ON

    if ~isdeployed
        addpath('/home/agarcia/Codes/airway_measures/matlab/functions/');
        addpath('/home/agarcia/Codes/airway_measures/matlab/scripts/Ibest/');
    end

    % ----- load configurations -----------
    if true
        baseDataDir                     = '/scratch/agarcia/Tests/Tests_IBEST/'

        cfg.recompute_data              = true; % this might overwrite results!
        cfg.recompute_lung_volumes      = false;       
 
        % Using TMI parameters (with extendend flow lines)
        cfg.files.folderCT              = [baseDataDir '/CTs/'];
        cfg.files.folderOpfronted       = [baseDataDir '/Segmentations_opfronted_i256_I2_o128_O1_M5_N7/'];
        cfg.files.folderVesselsOpfronted= [baseDataDir '/Vessels_opfronted_i256_I2_M1_N5/'];
        cfg.files.subjects_file         = [baseDataDir '/Subjects.csv'];
        cfg.files.saveFileFolder        = [baseDataDir '/MATLAB_pairingResults/'];
        cfg.files.saveFileResultsAirways= [baseDataDir '/IBEST_ResultsPerAirway.csv'];
        cfg.files.saveFileResultsMedian = [baseDataDir '/IBEST_ResultsMedianPerSubject.csv'];
        cfg.files.visualisations        = [baseDataDir '/visualisations/'];
        % to measure lung volume for normalisation
        cfg.files.lungSegmentations     = [baseDataDir '/Lungs-bottom-d40-400-800/'];
        cfg.saveFileNameLungVolume      = [baseDataDir '/lungVolumes_Ivacaftor.mat'];

        % Analyse correlation of manual annotations with computed measurements of segmented airways / vessels
        cfg.matchWithGroundTruth        = true;
        cfg.files.folderGroundTruth     = [baseDataDir '/AirwaysVessels_Annotations/'];
        cfg.files.saveFileResultsAirwaysWithGT = [baseDataDir '/IBEST_ResultsPerAirwayWithGT.csv'];
        cfg.files.saveFileResultsVesselsWithGT = [baseDataDir '/IBEST_ResultsPerVesselWithGT.csv'];
        cfg.files.casesWithGroundTruth  = {'b1_03', 'b1_04', 'b1_05', 'b1_07', 'b1_15', 'b1_17', 'b1_18', 'b1_20', 'b1_23', 'b1_27', 'b1_36', 'b1_39', 'b1_41', 'b1_42', 'b1_45', 'b1_47', 'b2_01', 'b2_02', 'b2_05', 'b2_06', 'b2_09', 'b2_10', 'b2_11', 'b2_12', 'b2_14', 'b2_16', 'b2_20', 'b2_22'};

        cfg.do_normalisation            = false;    % Will use subjects.(cfg.normalised_strName) to normalise the measurements for differences in size.
        cfg.normalised_value            = 4000000;  % (in mm^2)
        cfg.normalised_value_dim        = 3; 	    % (1 length, 2 area, 3 volume) Dimensionality of the atribute used to normalise the volumes 
        cfg.normalised_strName          = 'lungVolume'; % Name of the filed in the subjects structure to normalise

        cfg.robustFittingForTapering    = 'on';     % 'off' or 'on'. If set at 'on', fit() will be called with the option fit(..., 'Robust', 'on') for tapering calculations
        cfg.max_borderDist              = 20;       % in mm (distance between outer border of vessel and airway)
        cfg.min_similarity              = 0.70;     % 0 for accepting all, 1 for only accepting ideal perfect matches, to consider a pair (at matching time)
        cfg.min_vessel_length           = 5;        % in mm
        cfg.min_airway_length           = 5;        % in mm
        cfg.airwaysPairingStep          = 1;        % step between centreline points to attempt an artery-airway pairing (1 == all points)
        cfg.airwaysPairingPadding       = 0;        % number of points at each end of the airway that will not be tried to match (3 seemed way better than 7, and 3 slightly better than 0,maybe 1 or 2 would be good too)
        cfg.orientationWidth            = 5;        % local orientation will be computed from (point - cfg.orientationWidth) to (point + cfg.orientationWidth)
    end  


    if cfg.matchWithGroundTruth
        casesWithGroundTruth_New = {};	
        for case_suffix = cfg.files.casesWithGroundTruth
            rootName  	= ['iBEST_' char(case_suffix)];
            casesWithGroundTruth_New{end+1} = rootName;
        end
        cfg.files.casesWithGroundTruth = casesWithGroundTruth_New;
    end


    % copy generic folders
    files = cfg.files;
    disp(files)

    % list all CTs
    fileList = dir([files.folderCT filesep '*.dcm']);
    nCTs = numel(fileList);
    fprintf(' > %d CTs found in %s\n\n', nCTs, files.folderCT);
 

    % *************** Measure lung volume segmentation ***************
    if cfg.recompute_lung_volumes

        for dd = 1:numel(fileList)
            [~, rootName, ext] = fileparts( fileList(dd).name );
            fprintf(' ------------ %d: %s -------------\n', dd, rootName);

            % create files structure
            files.rootName = rootName;
            files.ct    = [files.folderCT          files.rootName '.dcm'];
            files.lung  = [files.lungSegmentations files.rootName '-lungs.dcm'];

            try
                % voxel size info
                ctInfo = dicominfo(files.ct);
                voxelSize   = [ctInfo.PixelSpacing' ctInfo.SpacingBetweenSlices];
                voxelVolume = prod( voxelSize );
                imSize    = [ctInfo.Rows, ctInfo.Columns, ctInfo.NumberOfFrames];

                fprintf('\n ------ [ %s ] ------ \n', files.rootName );
                disp(cfg)
                fprintf(' +    ImSize: [%d %d %d]\n', imSize(:) );
                fprintf(' + VoxelSize: [%.4f %.4f %.4f] -> %.3f mm^3\n', voxelSize(:), voxelVolume );

                % lung segmentation
                lung_seg = readVolume( files.lung );
                nVoxels = sum( lung_seg(:) > 0 );
                lung_volume(dd) = nVoxels * voxelVolume;

                fprintf(' >> Lung volume: %.3f L (%d voxels)\n', lung_volume(dd) / 1000000, nVoxels );

            catch exception
                fprintf('\n ERROR: %s\n\n', exception.message);		
                return
            end
       end

       save(cfg.saveFileNameLungVolume, 'lung_volume');

    else
        fprintf('\n\nLoading lung volume data ...\n');
        fprintf('  %s\n', cfg.saveFileNameLungVolume);

        load ( cfg.saveFileNameLungVolume )
    end

    subjects.lungVolume = lung_volume;    
    % *************** Measure lung volume segmentation ***************

    
    % *************** Compute measurements ***************
    if cfg.recompute_data

        if ~exist(files.saveFileFolder, 'dir')
            mkdir(files.saveFileFolder)
        end
 
        for dd = 1:numel(fileList)
            [~, rootName, ext] = fileparts( fileList(dd).name );
            fprintf(' --- %d: %s ---\n', dd, rootName);

            % create files structure
            files.rootName = rootName;
            files.ct                  = [files.folderCT files.rootName '.dcm'];
            files.lumen               = [files.folderOpfronted files.rootName '_inner.csv'];
            files.wall                = [files.folderOpfronted files.rootName '_outer.csv'];
            files.airways_centreline  = [files.folderOpfronted files.rootName '_airways_centrelines.mat'];
            files.airways_inner_radii = [files.folderOpfronted files.rootName '_inner_localRadius.csv'];
            files.airways_outer_radii = [files.folderOpfronted files.rootName '_outer_localRadius.csv'];
            files.vessel              = [files.folderVesselsOpfronted files.rootName '_vessels.csv'];
            files.vessels_centreline  = [files.folderVesselsOpfronted files.rootName '_vessels_centrelines.mat'];
            files.vessels_radii       = [files.folderVesselsOpfronted files.rootName '_vessels_local_radius.csv'];
            files.matFile             = [files.saveFileFolder '/' files.rootName '_processed.mat'];

            if cfg.matchWithGroundTruth
                case_has_ground_truth = any(strcmp(files.casesWithGroundTruth, rootName));
                if case_has_ground_truth
                    gt_rootName       = ['Manual_' rootName '_cleaned'];
            	    files.ground_truth= [files.folderGroundTruth gt_rootName '.csv'];
                    fprintf('\nGround-truth Annotations found for this case in %s\n', files.ground_truth);
                end
            else
                case_has_ground_truth = false;
            end

            % read .m and save as .mat for faster analysis (this only needs to be run ONCE!)
            if true
                try
                    % original m files
                    vessels_centrelineM  = [files.folderVesselsOpfronted files.rootName '_vessels_centrelines.m'];
                    airways_centrelineM  = [files.folderOpfronted files.rootName '_airways_centrelines.m'];

                    % rename to soemthing that starts with a letter (MATLAB doesn;t like scripts that start with numbers)
                    vessels_centreline_tmp  = [files.folderVesselsOpfronted 'A' files.rootName '_vessels_centrelines.m'];
                    airways_centreline_tmp  = [files.folderOpfronted 'A' files.rootName '_airways_centrelines.m'];

                    % copy with different name
                    copyfile( vessels_centrelineM, vessels_centreline_tmp )
                    copyfile( airways_centrelineM, airways_centreline_tmp )

                    % convert to .mat
                    preReadCentrelines( airways_centreline_tmp, files.airways_centreline )
                    preReadCentrelines( vessels_centreline_tmp, files.vessels_centreline )

                    % delete temporal file
                    delete ( vessels_centreline_tmp )
                    delete ( airways_centreline_tmp )

            	catch exception
                    fprintf('\n ERROR: %s\n\n', exception.message);
                    return
                end
            end

            % process CT
            try
                % read files and obtain AAR measurements
                fprintf('\n ********** Compute Airway / Vessel measurements ********** \n');
                [airways, vessels, files, extras] = measureAAR( files, cfg, dd, subjects );
                fprintf('\n ********** Compute Airway / Vessel measurements ********** \n');

                if numel( airways ) > 1 && numel( vessels ) > 1

                    if cfg.matchWithGroundTruth
                        if case_has_ground_truth
                            % read the ground-truth file
                            fprintf('\n ********** Read Ground-truth Annotations and match them with Airways / Vessels ********** \n');
                            ground_truth = readGroundTruthCsv( files.ground_truth, extras.voxelSize, extras.imSize, dd, extras.normalising_factor_area );

                            % match grount-truth with measurements of airways / vessels, and update these
                            [airways, vessels] = matchWithGT( ground_truth, airways, vessels );
                            fprintf('\n ********** Read Ground-truth Annotations and match them with Airways / Vessels ********** \n');
                        else
                            % extend data structure with dummy data to be compatible with that with ground-truth
                            [airways, vessels] = setDummyDataWithGT( airways, vessels );
                        end
                    end

                    % Copy all in one single structure
                    singleData.airways = airways;
                    singleData.vessels = vessels;
                    singleData.files   = files;
                    singleData.extras  = extras;

                    if cfg.matchWithGroundTruth
                        if case_has_ground_truth
                            singleData.has_ground_truth = true;
                            singleData.ground_truth     = ground_truth;
                        else
                            % extend data structure with dummy data to be similar to that with ground-truth
                    	    singleData.has_ground_truth = false;
                    	    singleData.ground_truth     = -1;
                        end
                    end

                    singleCFG = cfg;

                    fprintf('Saving measurements in file %s...\n', files.matFile);
                    save(files.matFile, 'singleData', 'singleCFG', 'files', 'nCTs', '-v7.3');
                    clear singleData;
                else
                    warning(' ------- CASE %d has not enough airways or vessels and it is excluded ------ \n', dd);
                end

                clear airways vessels ground_truth

            catch exception
                fprintf('\n ERROR: %s\n\n', exception.message);
                return
            end
        end
    end
    % *************** Compute measurements ***************

    
    % *************** Load data *************** 
    id_images_processed = [];
    id_images_failed = [];
   
    if true
        if ~exist(files.saveFileFolder, 'dir')
            fprintf('ERROR: Folder to load Data not found...\n', files.saveFileFolder);
            return;
        end	

        for dd = 1:numel(fileList)
            [~, rootName, ext] = fileparts( fileList(dd).name );
            fprintf(' --- %d: %s ---\n', dd, rootName);

            files.matFile   = [files.saveFileFolder '/' rootName '_processed.mat'];

            % load .mat files
            try
                fprintf(' > Loading measurements from %s...', files.matFile); tic;
                load ( files.matFile )

                if cfg.matchWithGroundTruth
                    case_has_ground_truth = any(strcmp(files.casesWithGroundTruth, files.rootName));

                    if ~case_has_ground_truth
                        % extend data structure with dummy data to be compatible with that with ground-truth
                        [singleData.airways, singleData.vessels] = setDummyDataWithGT( singleData.airways, singleData.vessels );
                    end
                end

                data(dd) = singleData;
                id_images_processed(end+1) = dd;
                fprintf(' Done (%.1f)\n', toc);

            catch exception
                id_images_failed(end+1) = dd;
                fprintf(' FAIL (%.1f)\n', toc);
                fprintf('\n ERROR: %s\n\n', exception.message);
                return
            end
        end
    end
    
    fprintf('\n - %d cases did work\n', numel(id_images_processed));
    fprintf(' - %d cases did not work\n', numel(id_images_failed));
    % *************** Load data ***************


    % *************** Process Computed / Loaded Data ***************
    % PRINT DATA TO IDENTIFY HOW THE ANALYSIS WAS DONE
    display(cfg.files)
    display(cfg)
    display(subjects)

    printNumberAirways( data, id_images_processed );
    
    airways_all = organiseAirways( id_images_processed, data );
    
    if cfg.matchWithGroundTruth
        % organise data for airways / vesels paired with ground-truth
        fprintf('\n********** Organise data for airways / vesels paired with ground-truth ********** \n');
        data_with_gt = organiseDataWithGroundTruth( data, id_images_processed );
        fprintf('\n');
    end

    cfg_summarising.generations = 3:10;
    cfg_summarising.generation_limits = [-1 5.5 7.5 Inf];

    % Based on 1/3 and 2/3 diametre quantiles on controls from LUVAR
    cfg_summarising.artery_dimension_limits = [-Inf 2.82 4.04 Inf]; % using manual (Myrian) initial segmentation
    cfg_summarising.lumen_dimension_limits  = [-Inf 1.41 2.17 Inf];
    cfg_summarising.outer_dimension_limits  = [-Inf 3.53 4.51 Inf];

%     cfg_summarising.artery_dimension_limits = [-Inf 3.08 4.23 Inf]; % Using autoamtic intial segmentation
%     cfg_summarising.lumen_dimension_limits  = [-Inf 1.66 2.47 Inf];
%     cfg_summarising.outer_dimension_limits  = [-Inf 3.66 4.70 Inf];
    
    fprintf('   > Spliting inner airway sizes: %.2f & %.2f\n', cfg_summarising.lumen_dimension_limits(2),  cfg_summarising.lumen_dimension_limits(3) );
    fprintf('   > Spliting outer airway sizes: %.2f & %.2f\n', cfg_summarising.outer_dimension_limits(2),  cfg_summarising.outer_dimension_limits(3) );
    fprintf('   > Spliting artery sizes:       %.2f & %.2f\n', cfg_summarising.artery_dimension_limits(2), cfg_summarising.artery_dimension_limits(3) );

    % compute all biomarkers (1 sole summarising value per patient)
    [biomarkers] = getAllMeasurements( airways_all, [], [], id_images_processed, cfg_summarising);
    
    %if cfg.matchWithGroundTruth
    %	printCorrelationWithGroundTruth( data, id_images_processed );
    %end
    % *************** Process Computed / Loaded Data ***************


    % *************** Output results / plots ***************
    % figure with median AAR evolution
    str_statType = 'median';
    
    % save results
    saveResultsInCSV( data, biomarkers, subjects.lungVolume, fileList, id_images_processed, cfg.files.saveFileResultsMedian, cfg.files.saveFileResultsAirways, 'median' )

    if cfg.matchWithGroundTruth
	    saveResultsDataWithGTInCSV( data_with_gt, fileList, cfg.files.saveFileResultsAirwaysWithGT, cfg.files.saveFileResultsVesselsWithGT );
    end
    % *************** Output info / plots ***************

    ['debug'];

    diary OFF
end
