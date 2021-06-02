function gt = read_groundTruth_csv( file_gt, voxelSize, imSize, case_num, normalising_factor_area )

    normalising_factor_length = sqrt(normalising_factor_area);

    % size of volume in mm
    imSize_mm = double(imSize) .* voxelSize;

    fprintf('Reading %s...\n', file_gt);
    fileID = fopen(file_gt);
    
    % drop header line
    str_line = fgetl( fileID );

    % get first branch info
    str_line = fgetl( fileID );
    
    %iterate remaining lines
    id = 0;
    while ischar(str_line)
        id = id + 1;

        cell_line = strsplit( str_line, ',', 'CollapseDelimiters', false);

        gt(id).id                       = id;
        gt(id).case_num                 = case_num;
        
%         gt(id).wyeing_id          = str2num( cell_line{1} );
        gt(id).inner.global_area        = str2num( cell_line{2} );
        gt(id).outer.global_area        = str2num( cell_line{3} );
        gt(id).vessel.global_area       = str2num( cell_line{4} );
               
        if normalising_factor_area ~= 1;
            gt(id).inner.global_area    = gt(id).inner.global_area .* normalising_factor_area;
            gt(id).outer.global_area    = gt(id).outer.global_area .* normalising_factor_area;
            gt(id).vessel.global_area   = gt(id).vessel.global_area .* normalising_factor_area;
        end
        
        % estimates of radius
        gt(id).inner.global_radius      = areaToRadius( gt(id).inner.global_area );
        gt(id).outer.global_radius      = areaToRadius( gt(id).outer.global_area );
        gt(id).vessel.global_radius     = areaToRadius( gt(id).vessel.global_area );
        
       
        gt(id).lobe                     = cell_line{7};
        gt(id).branch                   = cell_line{8};
        gt(id).generation               = str2num( cell_line{9} );
        
        % area based
        gt(id).outer.AAR_area           = gt(id).outer.global_area / gt(id).vessel.global_area;
        gt(id).inner.AAR_area           = gt(id).inner.global_area / gt(id).vessel.global_area;
        
        % radial based
        gt(id).outer.AAR_radial         = gt(id).outer.global_radius / gt(id).vessel.global_radius;
        gt(id).inner.AAR_radial         = gt(id).inner.global_radius / gt(id).vessel.global_radius;
        
        gt(id).wall.global_area         = gt(id).outer.global_area - gt(id).inner.global_area;
        gt(id).wall.global_areaPer      = gt(id).wall.global_area / gt(id).outer.global_area * 100;
        gt(id).wall.global_thickness    = gt(id).outer.global_radius - gt(id).inner.global_radius;
        gt(id).wall.global_thicknessPer = gt(id).wall.global_thickness / gt(id).outer.global_radius * 100;
        
        gt(id).wall.WAR_area            = gt(id).wall.global_area   ./ gt(id).vessel.global_area;
        gt(id).wall.WAR_radial          = gt(id).wall.global_thickness ./ gt(id).vessel.global_radius;
        
        
        % this is only for debugging (so positions can be assessed using Myrian)
        gt(id).airway_position_voxel    = [str2num(cell_line{10} ) str2num( cell_line{11} ) str2num( cell_line{12} )];
        gt(id).vessel_position_voxel    = [str2num(cell_line{13} ) str2num( cell_line{14} ) str2num( cell_line{15} )];
        
        gt(id).airway_position          = [str2num(cell_line{10} ) str2num( cell_line{11} ) str2num( cell_line{12} )] .* voxelSize;
        gt(id).vessel_position          = [str2num(cell_line{13} ) str2num( cell_line{14} ) str2num( cell_line{15} )] .* voxelSize;
        
        % flip vertically
        %gt(id).airway_position(3) = imSize_mm(3) - gt(id).airway_position(3);
        %gt(id).vessel_position(3) = imSize_mm(3) - gt(id).vessel_position(3);        
        str_line = fgetl( fileID );
        
        % normalise positions to be able to match with normalised measurements
        if normalising_factor_length ~= 1;
            gt(id).airway_position(:) = gt(id).airway_position(:) .* normalising_factor_length;
            gt(id).vessel_position(:) = gt(id).vessel_position(:) .* normalising_factor_length;
        end
    end
    
    %     [info_branch, nCharacters ] = textscan(fileID, '%f', 'delimiter', ',', 'HeaderLines', 1 );
    fclose(fileID);

    fprintf(' + Read %d GT measurments\n', id);
       
end

function radius = areaToRadius( area )
    radius = sqrt(area ./ pi);
end

function area = radiusToArea ( radius )
    area = radius.^2 * pi;
end

    %         1: Branch id
    %         2: Area airway (myrian) - empty
    %         3: Area lumen  (myrian)
    %         4: Area Lumen 
    %         5: Area outer wall
    %         6: Area vessel
    %         7: empty
    %         8: AVR inner
    %         9: AVR outer
    %        10: Thickness (empty)
    %     11-13: Airway position [x y z]
    %     14-16: Vessel position [x y z]
    %        17: Lobe label - NULL?
    %        18: Brach Label - NULL?
    %        19: Generation
    %   --------- xlmread only read until here --------- ??
    %        20: Position of the measurement 
    %        21: comments
