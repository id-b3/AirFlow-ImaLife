function [biomarkers, stats, extras, data] = doIvacaftor

    in_logfile = ['./doIVACAFTOR.log'];
    diary(in_logfile)
    diary ON

    if ~isdeployed
        addpath('/home/agarcia/Codes/airway_measures/matlab/functions/');
        addpath('/home/agarcia/Codes/airway_measures/matlab/scripts/Ivacaftor/');
    end

    % ----- load configurations -----------
    if true
        baseDataDir                     = '/scratch/agarcia/Tests/Tests_IVACAFTOR/'

        cfg.recompute_data              = true; % this might overwrite results!
        cfg.recompute_lung_volumes      = true;
        
        % Using TMI parameters (with extendend flow lines)
        cfg.files.folderCT              = [baseDataDir '/CTs/'];
        cfg.files.folderOpfronted       = [baseDataDir '/Segmentations_opfronted_i64_I3_o64_O1/'];
        cfg.files.folderVesselsOpfronted= [baseDataDir '/Vessels_opfronted_i4_I3/'];
        cfg.files.subjects_file         = [baseDataDir '/Subjects.csv'];
        cfg.files.saveFileFolder        = [baseDataDir '/MATLAB_pairingResults/'];
        cfg.files.saveFileResultsAirways= [baseDataDir '/IVACAFTOR_ResultsPerAirway.csv'];
        cfg.files.saveFileResultsMedian = [baseDataDir '/IVACAFTOR_ResultsMedianPerSubject.csv'];
        cfg.files.visualisations        = [baseDataDir '/visualisations/'];
        % to measure lung volume for normalisation
        cfg.files.lungSegmentations     = [baseDataDir '/Lungs-bottom-d40-400-800/'];
        cfg.saveFileNameLungVolume      = [baseDataDir '/lungVolumes_Ivacaftor.mat'];

        cfg.do_normalisation            = true;     % Will use subjects.(cfg.normalised_strName) to normalise the measurements for differences in size.
        cfg.same_normafactor_per_patient= true;     % Will use the same normalisation factor per patient (e.g. mean of subjects.(cfg.normalised_strName))
        cfg.normalised_value            = 4000000;  % (in mm^2)
        cfg.normalised_value_dim        = 3;        % (1 length, 2 area, 3 volume) Dimensionality of the atribute used to normalise the volumes
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
		        %return
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

    
    % *************** Characterise patients ***************
    if true
        fprintf(' + Read DICOM header info of %d subjects\n', nCTs );
        fprintf(' > %d CTs found in %s\n\n', nCTs, files.folderCT);

        for id = 1:numel(fileList)
            [~, rootName, ext] = fileparts( fileList(id).name );

            % create files structure
            files.rootName  = rootName;
            files.ct        = [files.folderCT          files.rootName '.dcm'];
            files.lung      = [files.lungSegmentations files.rootName '-lungs.dcm'];

            try
                subjects.ctInfo{id} = dicominfo(files.ct);
            
                % acquisition time
                st = subjects.ctInfo{id}.AcquisitionDateTime;
                str_time = sprintf( '%s.%s.%s', st(7:8), st(5:6), st(1:4) );
                %patient Age
                int_age = str2num(subjects.ctInfo{id}.PatientAge(1:3));

                fprintf('%s, %s, %d\n', rootName, str_time, int_age);

                subjects.str_time{id} = str_time;
                subjects.int_age{id}  = int_age;
            catch
                subjects.ctInfo{id} = -1;
                subjects.str_time{id} = -1;
                subjects.int_age{id} = -1;
            end
        end
       
        % get additional info from the csv
        subjectsCSVinfo = readIvacaftorPatientInfo( fileList, files.subjects_file );

        for id = 1:numel(fileList)
            subjects.age(id) = subjectsCSVinfo(id).age;
            subjects.patientID{id} = subjectsCSVinfo(id).patientID;
            subjects.patientID2{id} = subjectsCSVinfo(id).patientID2;
            subjects.istreated{id} = subjectsCSVinfo(id).istreated;
            subjects.isfollowup{id} = subjectsCSVinfo(id).isfollowup;
            subjects.center{id} = subjectsCSVinfo(id).center;
            subjects.acquisitionDate{id} = subjectsCSVinfo(id).acquisitionDate;
        end

        if cfg.do_normalisation && cfg.same_normafactor_per_patient
            fprintf('Assign the same normalisation factor for the two scans of the same patient...\n');
            fprintf('...Set the normal. factor for the follow-up scan the same as the one for first scan...\n');

            unique_patientsID = unique(subjects.patientID2);

            for i = 1:numel(unique_patientsID)
                i_patientID = char(unique_patientsID(i));
                indexes_subjs = find(ismember(subjects.patientID2, i_patientID));

                if length(indexes_subjs) == 2
                    id_subj1 = indexes_subjs(1);
                    id_subj2 = indexes_subjs(2);

                    if (subjects.isfollowup{id_subj1}) == 0 && (subjects.isfollowup{id_subj2} == 1)
                        id_subj_first = id_subj1;
                        id_subj_folup = id_subj2;
                    elseif (subjects.isfollowup{id_subj1}) == 1 && (subjects.isfollowup{id_subj2} == 0)
                        id_subj_first = id_subj2;
                        id_subj_folup = id_subj1;
                    else % Something is wrong
                        warning(' ------- Patient "%s", and cases %d and %d has something wrong. SKIP------ \n', i_patientID, id_subj1, id_subj2);
                        return;
                    end

                    fprintf('Patient "%s", set norm. factor of case %d (follow-up) same as case %d\n', i_patientID, id_subj_folup, id_subj_first)
                    subjects.lungVolume(id_subj_folup) = subjects.lungVolume(id_subj_first);

                else
                    warning(' ------- Patient "%s" is assigned to only one scan %d. SKIP------ \n', i_patientID, indexes_subjs(1));
                end
            end
        end
    end
    % *************** Characterise patients ***************


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
            
            % read .m and save as .mat for faster analysis (this only needs to be run ONCE!)
            if false
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
                    %return
                end
            end

            % process CT
            try
                % read files and obtain AAR measurements
                [airways, vessels, files, extras] = measureAAR( files, cfg, dd, subjects );

                if numel( airways ) > 1 && numel( vessels ) > 1

                    % Copy all in one single structure
                    singleData.airways = airways;
                    singleData.vessels = vessels;
                    singleData.files   = files;
                    singleData.extras  = extras;

                    singleCFG = cfg;
                    save(files.matFile, 'singleData', 'singleCFG', 'files', 'nCTs', '-v7.3');
                    clear singleData;
                else
                    warning(' ------- CASE %d has not enough airways or vessels and it is excluded ------ \n', dd);
                end

                clear airways vessels gt

            catch exception
                fprintf('\n ERROR: %s\n\n', exception.message);
		        %return
            end
        end
    end
    % *************** Compute measurements ***************
    

    % *************** Load data ***************
    id_images_processed = [];
    id_images_failed = [];
   
    if true
        for dd = 1:numel(fileList)
            [~, rootName, ext] = fileparts( fileList(dd).name );
            fprintf(' --- %d: %s ---\n', dd, rootName);

            files.matFile   = [files.saveFileFolder '/' rootName '_processed.mat'];
            
            % load .mat files
            try
                fprintf(' > Loading %s ...', files.matFile); tic;
                load ( files.matFile )
                data(dd) = singleData;
                id_images_processed(end+1) = dd;
                fprintf(' Done (%.1f)\n', toc);

            catch exception
                id_images_failed(end+1) = dd;
                fprintf(' FAIL (%.1f)\n', toc);
		        %return
            end
        end
    end
    
    fprintf('\n - %d cases did work\n', numel(id_images_processed));
    fprintf(' - %d cases did not work\n', numel(id_images_failed));
    % *************** Load data ***************


    % *************** Process Computed / Loaded Data ***************
    % read all patients info
%     patientInfo = read_NormalCTpatientInfo( fileList, subjects.subjects_file );
    
    % PRINT DATA TO IDENTIFY HOW THE ANALYSIS WAS DONE
    display(cfg.files)
    display(cfg)
    display(subjects)
   
    printNumberAirways( data, id_images_processed );
    
    airways_all = organiseAirways( id_images_processed, data );
    
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
    % *************** Process Computed / Loaded Data ***************


    % *************** Output results / plots ***************
    % figure with median AAR evolution
    str_statType = 'median';

    % save results
    saveResultsInCSV( data, biomarkers, subjects.lungVolume, fileList, id_images_processed, cfg.files.saveFileResultsMedian, cfg.files.saveFileResultsAirways, 'median' )

    % preliminary plots
    if false
        str_biomarkers = {'inner_AAR', 'outer_AAR', 'WAR', 'inner_taperingPerc_diam', 'outer_taperingPerc_diam', 'inner_interTapering', 'outer_interTapering', 'number_airways'};
%         str_biomarkers = {'inner_AAR'};
        
        for bb = 1:numel(str_biomarkers)
            str_bio = str_biomarkers{bb};
            fprintf('-- %s --\n', str_bio);

            figure; hold on;
            ylabel(str_bio); xlabel('Age');

            for id = id_images_processed
                str_id = subjects.patientID{id};

                % find other CT with same id
                ii = id + 1; pair_id = 0;
                while ii <= nCTs
                    if strcmp( subjects.patientID{ii}, str_id ) && ismember(ii, id_images_processed)
                        pair_id = ii;
                        break;
                    end
                    ii = ii + 1;
                end

                if pair_id > 0
                    fprintf('%s <%s (%d) & %s (%d)>, %.2f, %.2f, %+.2f\n', str_id, data(id).files.rootName, id, data(pair_id).files.rootName, pair_id, ...
                                                                            biomarkers.all.(str_bio)(id).(str_statType), biomarkers.all.(str_bio)(pair_id).(str_statType), ...
                                                                            biomarkers.all.(str_bio)(pair_id).(str_statType) - biomarkers.all.(str_bio)(id).(str_statType) );
                    if strcmp( str_id(1), 'c')
                        str_colour = 'og-';
                    else
                        str_colour = 'or-';
                    end
                    try
                        plot([subjects.age(id) subjects.age(pair_id)], [biomarkers.all.(str_bio)(id).(str_statType) biomarkers.all.(str_bio)(pair_id).(str_statType)], str_colour)
                    end
                end
            end
        end
    end
    % *************** Output results / plots ***************

    ['debug'];

    diary OFF
end
