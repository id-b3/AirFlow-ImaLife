function compileMeasurements ()

    if ~isdeployed
        addpath('/home/agarcia/Codes/airway_measures/matlab/functions/');
        addpath('/home/agarcia/Codes/airway_measures/matlab/scripts/');
    end

    % ----- load configurations -----------
    baseDataDir                	= '/scratch/agarcia/Tests/Tests_CTs_IVAN/'

    cfg.files.folderCT         	= [baseDataDir '/CTs/'];
    cfg.files.folderOpfronted 	= [baseDataDir '/Segmentations/'];
    cfg.files.saveFileResults	= [baseDataDir '/IVACAFTOR_ResultsPerAirway.csv'];
    
    cfg.robustFittingForTapering= 'on';     % 'off' or 'on'. If set at 'on', fit() will be called with the option fit(..., 'Robust', 'on') for tapering calculations
    cfg.max_borderDist         	= 20;       % in mm (distance between outer border of vessel and airway)
    cfg.min_similarity         	= 0.70;     % 0 for accepting all, 1 for only accepting ideal perfect matches, to consider a pair (at matching time)
    cfg.min_vessel_length      	= 5;        % in mm
    cfg.min_airway_length      	= 0;        % in mm
    cfg.orientationWidth       	= 5;        % local orientation will be computed from (point - cfg.orientationWidth) to (point + cfg.orientationWidth)

    
    % copy generic folders
    files = cfg.files;
    disp(files)

    % list all CTs
    fileList = dir([files.folderCT filesep '*.dcm']);
    nCTs = numel(fileList);
    fprintf(' > %d CTs found in %s\n\n', nCTs, files.folderCT);
  
    
    % ----- Compute measurements -----------
    id_images_processed = [];
    id_images_failed = [];

    for dd = 1:numel(fileList)
        [~, rootName, ext] = fileparts( fileList(dd).name );
        fprintf('\n --- %d: %s ---\n', dd, rootName);

        % create files structure
        files.rootName = rootName;
        files.ct                  = [files.folderCT files.rootName '.dcm'];
        files.lumen               = [files.folderOpfronted files.rootName '_inner.csv'];
        files.wall                = [files.folderOpfronted files.rootName '_inner.csv'];
        files.airways_centreline  = [files.folderOpfronted files.rootName '_airways_centrelines.mat'];
        files.airways_inner_radii = [files.folderOpfronted files.rootName '_inner_localRadius.csv'];
        files.airways_outer_radii = [files.folderOpfronted files.rootName '_inner_localRadius.csv'];

        % read .m and save as .mat for faster analysis (this only needs to be run ONCE!)
        if true
            try
                % original m files
                airways_centrelineM  = [files.folderOpfronted files.rootName '_airways_centrelines.m'];

                % rename to soemthing that starts with a letter (MATLAB doesn;t like scripts that start with numbers)
                airways_centreline_tmp  = [files.folderOpfronted 'A' files.rootName '_airways_centrelines.m'];

                % copy with different name
                copyfile( airways_centrelineM, airways_centreline_tmp )

                % convert to .mat
                preReadCentrelines( airways_centreline_tmp, files.airways_centreline )

                % delete temporal file
                delete ( airways_centreline_tmp )

            catch exception
                fprintf('\n ERROR: %s\n\n', exception.message);
		id_images_failed(end+1) = dd;
            end
        end

        try
            % read files and obtain Airway measurements
            [airways] = measureAirways( files, cfg, dd );
	    
	    singleData.airways = airways;
	    data(dd) = singleData;
	    id_images_processed(end+1) = dd;

        catch exception
            fprintf('\n ERROR: %s\n\n', exception.message);
	    id_images_failed(end+1) = dd;
        end
    end
     
    fprintf('\n - %d cases did work\n', numel(id_images_processed));
    fprintf(' - %d cases did not work\n', numel(id_images_failed));

    
    % PRINT DATA TO IDENTIFY HOW THE ANALYSIS WAS DONE
    display(cfg.files)
    display(cfg)
   
    airways_all = organiseAirways( id_images_processed, data );

    % save results
    saveResultsInCSV( data, fileList, id_images_processed, cfg.files.saveFileResults )
   
    ['debug'];
end


%% ------------------------------- AUXILIARY FUNCTIONS -------------------------------------------
function saveResultsInCSV( data, fileList, id_images_processed, str_file_out )

    str_header = ['Patient_ID, airway_ID, midPoint_x, midPoint_y, midPoint_z, ' ...
                  'd_inner_global, d_outer_global, airway_length, generation, parent_ID, childrenID, ' ...
                  'begPoint_x, begPoint_y, begPoint_z, endPoint_x, endPoint_y, endPoint_z\n'];

    fprintf(' > Saving all airway measurements ...\n'); tic;
    
    fid = fopen(str_file_out, 'w');
    fprintf( fid, str_header );
    
    for dd = id_images_processed
    
        [~, image_id, ~] = fileparts( fileList(dd).name );
    
        for aa = 1:numel(data(dd).airways)
    
            str_row = {};
    
            aw = data(dd).airways(aa); % airway
    
            mp = ceil(data(dd).airways(aa).nPoints / 2); % middle point
    
            % ---------- Information of airways, paired or not ---------------
    
            % IDS: patient ID, airway ID,
            str_row{1} = sprintf('%s, %03d', image_id, aw.id );
    
            % position half way through the airways (x, y, z) VOXEL COORDS
            str_row{2} = sprintf('%.1f, %.1f, %.1f', aw.point(mp, :) );
    
            % DIAMETERS: global inner, global outer, length
            str_row{3} = sprintf('%.3f, %.3f, %.3f', aw.inner.global_radius*2, aw.outer.global_radius*2, aw.length );
    
            % EXTRA DATA: length, generation, parent, children
            str_row{4} = sprintf('%d, %d, %s', aw.generation, aw.parent, num2str(aw.children, '%d ') );

	    % extreme positions of the airways (x, y, z) VOXEL COORDS
	    str_row{5} = sprintf('%.1f, %.1f, %.1f, %.1f, %.1f, %.1f', aw.point(1, :), aw.point(end, :) );
    
            % save the line
            fprintf( fid, [strjoin(str_row, ', ') '\n']);
        end
    end
    
    fclose(fid);
    fprintf('   - Done (%s in %.1fs)\n\n', str_file_out, toc);
end
