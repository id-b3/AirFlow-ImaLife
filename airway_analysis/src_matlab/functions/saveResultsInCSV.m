function saveResultsInCSV( data, biomarkers, lungVolume, fileList, id_images_processed, str_file, str_file_all, str_average )

% str_header = ['Patient_ID, airway_ID, vessel_ID, normalizing_length_factor, ' ...
%               'pos_x, poz_y, posz, ' ...
%               'similarity, similarity_ratio, similarity_angle, similarity_dist, ' ...
%               'd_inner_atPairing, d_outer_atPairing, d_vessel_atParing, ' ...
%               'd_inner_global, d_outer_global, d_vessel_global, ' ...
%               'airway_length, generation, parent_ID, childrenID, ' ...
%               'inner_AAR, outer_AAR, WAR, WTR, WAP, ' ...
%               'inner_intraBT, outer_intraBT, inner_interBT, outer_interBT\n'];
          
str_header = ['Patient_ID, airway_ID, normalizing_length_factor, ' ...
              'midPoint_x, midPoint_y, midPoint_z, ' ...
              'd_inner_global, d_outer_global, ' ...
              'airway_length, generation, parent_ID, childrenID, ' ...
              'inner_intraBT, outer_intraBT, wall_intraBT, inner_interBT, outer_interBT, ' ...
              'WTR_global, WAP_global, ' ...
              'vessel_ID, d_vessel_global, ' ...
              'airway_x, airway_y, airway_z, ' ...
              'vessel_x, vessel_y, vessel_z, ' ...
              'similarity, similarity_ratio, similarity_angle, similarity_dist, ' ...
              'd_inner_atPairing, d_outer_atPairing, wall_thickness, d_vessel_atParing, ' ...
              'inner_AAR, outer_AAR, WAR, WTR, WAP\n'];
          
fprintf(' > Saving all airway measurements ...\n'); tic;

% save CSV with info for each AA pair
fid = fopen(str_file_all, 'w');
fprintf( fid, str_header );

for dd = id_images_processed

    [~, image_id, ~] = fileparts( fileList(dd).name );

    norm_length = sqrt(data(dd).extras.normalising_factor_area);

    for aa = 1:numel(data(dd).airways)

        str_row = {};
        
        aw = data(dd).airways(aa); % airway
        
        mp = ceil(data(dd).airways(aa).nPoints / 2); % middle point
        
        % ---------- Information of airways, paired or not ---------------
        
        % IDS: patient ID, airway ID, normalising factor (length),
        str_row{1} = sprintf('%s, %03d, %.3f', image_id, aw.id, norm_length );

        % position half way through the airways (x, y, z) CORRECTED: VOXEL COORDS, NOT NORMALISED
        str_row{2} = sprintf('%.1f, %.1f, %.1f', aw.point(mp, :) );   % aw.centreline(mp, :) );

        % DIAMETERS: global inner, global outer, ,
        str_row{3} = sprintf('%.3f, %.3f', aw.inner.global_radius*2, aw.outer.global_radius*2 );
        
        % EXTRA DATA: length, generation, parent, children
        str_row{4} = sprintf('%.3f, %d, %d, %s', aw.length, aw.generation, aw.parent, num2str(aw.children, '%d ') );
        
        % Tapering BIOMARKERS: inner intraBT, outer intraBT, wall intraBT, inner interBT, outer interBT,
        inner_interBT = (1 - aw.inner.parent_ratio_radius) * 100;
        outer_interBT = (1 - aw.outer.parent_ratio_radius) * 100;
        str_row{5} = sprintf('%.3f, %.3f, %.3f, %.3f, %.3f', aw.inner.taperingPerc_diam, aw.outer.taperingPerc_diam, aw.wall.taperingPerc_diam, inner_interBT, outer_interBT );
        
        % WTR, WAP (using global measurements)
        globalWTR = aw.wall.global_thickness / (aw.outer.global_radius*2);
        str_row{6} = sprintf('%.3f, %.3f ', globalWTR, aw.wall.global_areaPer );
        
        % if airways is paired
        if aw.isPaired

            % accompanying artery (vessel)
            vs = data(dd).vessels( aw.pair.vessel_id );

            % pairing points
            ap = aw.pair.airway_point_id;
            vp = aw.pair.vessel_point_id;

            % 'vessel_ID, d_vessel_global
            str_row{7} = sprintf('%d, %.3f', aw.pair.vessel_id, vs.global_radius*2 );
            
            % airway and vessel position (at pairing) CORRECTED: VOXEL COORDS, NOT NORMALISED
            str_row{8} = sprintf('%.1f, %.1f, %.1f, %.1f, %.1f, %.1f', aw.point(ap,:), vs.point(vp,:) );   % aw.centreline(ap,:), vs.centreline(vp,:) );

            % similarity, similarity_ratio, similarity_angle, similarity_dist,
            str_row{9} = sprintf('%.3f, %.3f, %.3f, %.3f', aw.pair.similarity, aw.pair.similarity_ratio, aw.pair.similarity_angle, aw.pair.similarity_dist );

            % diam inner, diam outer, wall_thickness, diam vessel,
            str_row{10} = sprintf('%.3f, %.3f, %.3f, %.3f', aw.inner.radius(ap)*2, aw.outer.radius(ap)*2, aw.wall.thickness(ap), vs.radius(vp)*2 );
            
            % BIOMARKERS at pairing point: AAR_inner, AAR_outer, WAR, WTR, WAP
            WTR = aw.wall.thickness(ap) / (aw.outer.radius(ap)*2);
            str_row{11} = sprintf('%.3f, %.3f, %.3f, %.3f, %.3f', aw.inner.AAR_radial, aw.outer.AAR_radial, aw.wall.WAR_radial, WTR, aw.wall.areaPer(ap) );
        end
        
        % save the line
        fprintf( fid, [strjoin(str_row, ', ') '\n']);
        
    end
end

fclose(fid);
fprintf('   - Done (%s in %.1fs)\n\n', str_file_all, toc);


str_header = ['Patient_ID, normalizing_length_factor, lung_volume, ' ...
              'inner_AAR, outer_AAR, WAR, WTR, WAP, ' ...
              'inner_intraBT, outer_intraBT, wall_intraBT, vessel_intraBT,' ...
              'inner_interBT, outer_interBT, airway_length, number_paired_airways, all_number_airways,\n'];
          
bio_names  = {'inner_AAR', 'outer_AAR', 'WAR', 'WTR', 'WAP', ...
              'inner_taperingPerc_diam', 'outer_taperingPerc_diam', 'wall_taperingPerc_diam', 'vessel_taperingPerc_diam', ...
              'inner_interTapering', 'outer_interTapering', 'airway_length', 'number_airways', 'all_number_airways'};

fprintf(' > Saving summarised paired airway measurements ...\n'); tic;

% save CSV with summarising values for each subject
fid = fopen(str_file, 'w');
fprintf( fid, str_header );

for dd = id_images_processed

    [~, image_id, ~] = fileparts( fileList(dd).name );

    norm_length = sqrt(data(dd).extras.normalising_factor_area);
    
    str_row = {};

    % IDS: patient ID, normalising factor (length),
    str_row{1} = sprintf('%s, %.3f, %.4f', image_id, norm_length, lungVolume(dd)/1000000);

    for bb = 1:numel(bio_names)-1
        str_row{1+bb} = sprintf('%.4f', biomarkers.all.(bio_names{bb})(dd).(str_average) );
    end
    for bb = numel(bio_names)-1:numel(bio_names)
        str_row{1+bb} = sprintf('%d', biomarkers.all.(bio_names{bb})(dd).(str_average) );
    end
    
    str_row{end+1} = sprintf('\n');
    
    fprintf( fid, strjoin(str_row, ', ') );
end

fclose(fid);
fprintf('   - Done (%s in %.1fs)\n\n', str_file, toc);
