function analyseDataset ()

    if ~isdeployed
        addpath('/home/agarcia/Codes/airway_measures/matlab/functions/');
        addpath('/home/agarcia/Codes/airway_measures/matlab/scripts/');
    end

    baseDataDir                     = '/scratch/agarcia/Tests/Tests_IBEST/'

    files.folderCT                  = [baseDataDir '/CTs/'];
    files.folderSegmentations       = [baseDataDir '/Annotations/'];
    files.folderOpfronted           = [baseDataDir '/Segmentations_opfronted_i64_I3_o64_O1_M5_N7/'];
    files.folderVessels             = [baseDataDir '/Vessels/'];
    files.folderVesselsOpfronted    = [baseDataDir '/Vessels_opfronted_i4_I3_M5_N7/'];
    files.subjects_file             = [baseDataDir '/Subjects.csv'];
    files.saveFileNameAnalysis      = [baseDataDir '/AnalysisDataset.mat'];
%    files.saveFileNameMATLAB        = [baseDataDir '/MATLAB/doNormalCT.mat']; % < Normalised by lung volume at 4L | 0.7 similarity
    % to measure lung volume for normalisation
    files.lungSegmentations         = [files.baseDataDir '/Lungs-bottom-d40-400-800/'];

    if true
        % list all CTs
        fileList = dir([files.folderCT filesep '*.dcm']);
        nCTs = numel(fileList);
        fprintf(' > %d CTs found in %s\n\n', nCTs, files.folderCT);
        
        % convert the .m files into .mat files to avoid wasting too much memory
        if false 
            for dd = 1:nCTs
                [~, rootName, ~] = fileparts( fileList(dd).name );
                fprintf(' > %3d: %s ... ', dd, rootName);
                tic;

                case_files.airways_centreline       = [files.folderOpfronted rootName '_airways_centrelines.m'];
                case_files.vessels_centreline       = [files.folderVesselsOpfronted rootName '_vessels_centrelines.m'];
                case_files.airways_centreline_mat   = [files.folderOpfronted rootName '_airways_centrelines.mat'];
                case_files.vessels_centreline_mat   = [files.folderVesselsOpfronted rootName '_vessels_centrelines.mat'];

                try
                    preReadCentrelines( case_files.airways_centreline, case_files.airways_centreline_mat);
                end
                try
                    preReadCentrelines( case_files.vessels_centreline, case_files.vessels_centreline_mat);
                end

                fprintf(' > %.1fs\n', toc);
            end
        end
        
        % pre-allocate
        if true
%             longString = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
            
%             [case_files(1:nCTs).rootName]                 = deal(longString);
%             [case_files(1:nCTs).ct]                       = deal(longString);
%             [case_files(1:nCTs).segName]                  = deal(longString);
%             [case_files(1:nCTs).airways_centreline]       = deal(longString);
%             [case_files(1:nCTs).lung]                     = deal(longString);
%             [case_files(1:nCTs).vessels_seg]              = deal(longString);
%             [case_files(1:nCTs).vessels_seg_processed]    = deal(longString);
%             [case_files(1:nCTs).vessels_brh]              = deal(longString);
%             [case_files(1:nCTs).vessels_centreline]       = deal(longString);

%             % prea-allocate & set all to false
%             [results(1:nCTs).dicomOK]                   = deal(false);
%             [results(1:nCTs).segmentationExists]        = deal(false);
% 
%             [results(1:nCTs).airwaysOpfrontOK]          = deal(false);
%             [results(1:nCTs).numAirwaysOpfronted]       = deal(NaN);
% 
%             [results(1:nCTs).lungSegmentationExists]    = deal(false);
%             [results(1:nCTs).nLungVoxels]               = deal(NaN); % in voxels
%             [results(1:nCTs).numVoxels]                 = deal(NaN); % # voxels in the lung segmentations files (Segmented or not, it's the same than everywhere else)
% 
%             [results(1:nCTs).vesselSegExists]           = deal(false);
%             [results(1:nCTs).vesselSegProcessedExists]  = deal(false);
%     %         [results(1:nCTs).nVesselVoxels]             = deal(NaN); % in voxels
%             [results(1:nCTs).nVesselProcessedVoxels]    = deal(NaN); % in voxels
% 
%             [results(1:nCTs).vesselsOpfrontOK]          = deal(false);
%             [results(1:nCTs).numVesselsOpfronted]       = deal(NaN);                
            
            dicomOK                   = false(1,nCTs);
            segmentationExists        = false(1,nCTs);

            airwaysOpfrontOK          = false(1,nCTs);
            numAirwaysOpfronted       = nan(1, nCTs);

            lungSegmentationExists    = false(1,nCTs);
            nLungVoxels               = nan(1, nCTs); % in voxels
            numVoxels                 = nan(1, nCTs); % # voxels in the lung segmentations files (Segmented or not, it's the same than everywhere else)

            vesselSegExists           = false(1,nCTs);
            vesselSegProcessedExists  = false(1,nCTs);
    %         [results(1:nCTs).nVesselVoxels]             = deal(NaN); % in voxels
            nVesselProcessedVoxels    = nan(1, nCTs); % in voxels

            vesselsOpfrontOK          = false(1,nCTs);
            numVesselsOpfronted       = nan(1, nCTs);
        end        

        % do the analysis
        for dd = 1:nCTs
            [~, rootName, ~] = fileparts( fileList(dd).name );
            fprintf(' > %3d: %s ... ', dd, rootName);
            tic;

            % create files structure for this CT
            case_files.rootName = rootName;
            case_files.ct                       = [files.folderCT rootName '.dcm'];
            case_files.segName                  = [files.folderSegmentations rootName '_seg.dcm'];
            case_files.lung                     = [files.lungSegmentations rootName '-lungs.dcm'];
            case_files.vessels_seg              = [files.folderVessels rootName '-vessels.dcm'];
            case_files.vessels_seg_processed    = [files.folderVessels rootName '-vessels-processed.dcm'];
            case_files.vessels_brh              = [files.folderVesselsOpfronted rootName '_vessels.brh'];
            case_files.airways_centreline_mat   = [files.folderOpfronted rootName '_airways_centrelines.mat'];
            case_files.vessels_centreline_mat   = [files.folderVesselsOpfronted rootName '_vessels_centrelines.mat'];

            % are dicom files OK?
            try
%                 ctInfo{dd}          = dicominfo(case_files.ct);
                dicomOK(dd) = true;
            end

            % are there manual segmentations?
            if exist( case_files.segName, 'file' )
                segmentationExists(dd) = true;
            end

            % check number of airways segmented (without analysis)
            try
                load( case_files.airways_centreline_mat )
                numAirwaysOpfronted(dd) = numel(airway);
                airwaysOpfrontOK(dd) = true;
                airway = [];
            end

            % check if there are lung files
            if exist( case_files.lung, 'file' )
                lungSegmentationExists(dd) = true;
            end

            % check lung volume (in voxels)
            try
%                 lv = readVolume( case_files.lung );
%                 nLungVoxels(dd) = sum( lv(:) > 0 );
%                 numVoxels(dd)  = numel ( lv );
%                 clear lv
            end

            % check if there are vessel files
            if exist( case_files.vessels_seg, 'file' )
                vesselSegExists(dd) = true;
                
%                 vs = readVolume( case_files.vessels_seg );
%                 nVesselVoxels = sum( vs(:) > 0 );
%                 clear vs
            end

            % check if there are processed vessel files
%             if exist( case_files.vessels_seg_processed, 'file' )
%                 vesselSegProcessedExists = true;
%                 
%                 vs = readVolume( case_files.vessels_seg_processed );
%                 nVesselProcessedVoxels = sum( vs(:) > 0 );
%                 clear vs
%             end

            % check if there are processed vessel files
            if exist( case_files.vessels_brh, 'file' )
                vesselsOpfrontOK(dd) = true;
            end
            

            % check number of vessels opfronted (without analysis)
            try
                load( case_files.vessels_centreline_mat )
                numVesselsOpfronted(dd) = numel(airway);
                airwaysOpfrontOK(dd) = true;
                airway = [];
            end

            % check pairs
            fprintf(' > %.1fs\n', toc);
        end

        save(files.saveFileNameAnalysis);
    else
        load(files.saveFileNameAnalysis);
    end

    nSegmentations = sum(segmentationExists);
    
    fprintf('Number of CTs: %d\n', nCTs)
    fprintf(' + of wich the dicom header worked: %d\n', sum(dicomOK) );

    fprintf('Number of segmentations: %d\n', nSegmentations );
    fprintf(' + of wich opfront led to results: %d\n',  sum(airwaysOpfrontOK) );
    fprintf(' + with more than 10 airways after opfront: %d\n',  sum(numAirwaysOpfronted > 10) );
    
    portionLungs = (nLungVoxels ./ numVoxels * 100); 
    fprintf('Number of lung segmentations: %d\n', sum(lungSegmentationExists) );
    fprintf(' + with more than 2%% of voxels label as lung: %d\n',  sum( portionLungs > 2) );
    
    fprintf('Number of vessel segmentations: %d\n', sum(vesselSegExists) );
%     fprintf(' + with at least 1 voxel labelled as vessels: %d\n',  sum(nVesselVoxels > 0) );
    
%     fprintf('Number of processed vessel segmentations: %d\n', sum(vesselSegProcessedExists) );
%     fprintf(' + with at least 1 voxel labelled as processed vessels: %d\n',  sum(nVesselProcessedVoxels > 0) );
    
    fprintf('Number of vessel segmentations that opfront led to results: %d\n',  sum(vesselsOpfrontOK) );
    fprintf(' + with more than 20 vessels after opfront: %d\n',  sum(numVesselsOpfronted > 20) );
    
%     fprintf('Number of vessel segmentations (processed): %d\n', sum([results(:).vesselSegProcessedExists]) );

    good = numVesselsOpfronted > 20 & numAirwaysOpfronted > 10 & lungSegmentationExists;
    fprintf('Number of CTs with #vessels > 20, #airways > 10, and lung segmentation: %d\n',  sum(good) );

    if true
        fprintf( 'name, dicomOK, segmentationExists, OpfrontOK, nAirways, lungSegExists, vessSegExists, nVessels\n')
        for dd = 1:nCTs
            fprintf( '%s, %d, %d, %d, %d, %d, %d, %d, %d\n', ...
                     fileList(dd).name, dicomOK(dd), segmentationExists(dd), airwaysOpfrontOK(dd), numAirwaysOpfronted(dd), lungSegmentationExists(dd), ...
                     vesselSegExists(dd), vesselsOpfrontOK(dd), numVesselsOpfronted(dd) )
        end
    end
        %     fprintf('List of CTs with lung and airways segmetnations but not enough vessels: %d\n', nCTs)

%     sum(bad)
%     
%     fileList(bad).name

    figure;
    hist( numAirwaysOpfronted, 200 )
    xlabel('Number of vessels extracted'); ylabel('# of CTs');
end

    
