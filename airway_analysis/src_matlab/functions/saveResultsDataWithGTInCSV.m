function saveResultsDataWithGTInCSV( data_with_gt, fileList, str_out_file_airways, str_out_file_vessels )
          
str_header_airways = ['Patient_ID, airway_ID, inner_radius_air, inner_area_air, inner_AAR_air, outer_radius_air, outer_area_air, outer_AAR_air, positionX_air, positionY_air, positionZ_air, generation_air, gt_ID, inner_radius_gt, inner_area_gt, inner_AAR_gt, outer_radius_gt, outer_area_gt, outer_AAR_gt, positionX_gt, positionY_gt, positionZ_gt, generation_gt\n'];

str_header_vessels = ['Patient_ID, vessel_ID, radius_ves, area_ves, positionX_ves, positionY_ves, positionZ_ves, gt_ID, radius_gt, area_gt, positionX_gt, positionY_gt, positionZ_gt\n'];

fprintf(' > Saving airway and vessels measurements paired with ground-truth measurements...\n'); tic;


fid_air = fopen(str_out_file_airways, 'w');
fprintf( fid_air, str_header_airways );

fid_ves = fopen(str_out_file_vessels, 'w');
fprintf( fid_ves, str_header_vessels );


indexes_images_with_gt = data_with_gt.indexes_images;


for dd = indexes_images_with_gt

    [~, image_id, ~] = fileparts( fileList(dd).name );

    indexes_airways_with_gt    		= data_with_gt.airways(dd).res_index;
    inner_radius_airways_with_gt	= data_with_gt.airways(dd).res_inner_radius;
    inner_area_airways_with_gt 		= data_with_gt.airways(dd).res_inner_area;
    inner_AAR_airways_with_gt  		= data_with_gt.airways(dd).res_inner_AAR;
    outer_radius_airways_with_gt	= data_with_gt.airways(dd).res_outer_radius;
    outer_area_airways_with_gt		= data_with_gt.airways(dd).res_outer_area;
    outer_AAR_airways_with_gt		= data_with_gt.airways(dd).res_outer_AAR;
    position_voxel_airways_with_gt	= data_with_gt.airways(dd).res_position_voxel;
    generation_airways_with_gt    	= data_with_gt.airways(dd).res_generation;

    indexes_gt_with_airway    		= data_with_gt.airways(dd).gt_index;
    inner_radius_gt_with_airway		= data_with_gt.airways(dd).gt_inner_radius;
    inner_area_gt_with_airway  		= data_with_gt.airways(dd).gt_inner_area;
    inner_AAR_gt_with_airway   		= data_with_gt.airways(dd).gt_inner_AAR;
    outer_radius_gt_with_airway		= data_with_gt.airways(dd).gt_outer_radius;
    outer_area_gt_with_airway  		= data_with_gt.airways(dd).gt_outer_area;
    outer_AAR_gt_with_airway   		= data_with_gt.airways(dd).gt_outer_AAR;
    position_voxel_gt_with_airway   = data_with_gt.airways(dd).gt_position_voxel;
    generation_gt_with_airway     	= data_with_gt.airways(dd).gt_generation;

    num_airways_with_gt = length( indexes_airways_with_gt );

    for aa = 1:num_airways_with_gt
        % Information of airways and paired ground-truth
        str_row = {};

        % patient ID, airway ID,
        str_row{1} = sprintf('%s, %03d', image_id, indexes_airways_with_gt(aa));

        % INNER AIRWAY radius, area, AAR,
        str_row{2} = sprintf('%.3f, %.3f, %.3f', inner_radius_airways_with_gt(aa), inner_area_airways_with_gt(aa), inner_AAR_airways_with_gt(aa));

        % OUTER AIRWAY radius, area, AAR,
        str_row{3} = sprintf('%.3f, %.3f, %.3f', outer_radius_airways_with_gt(aa), outer_area_airways_with_gt(aa), outer_AAR_airways_with_gt(aa));

        % AIRWAY position, generation 
        str_row{4} = sprintf('%.1f, %.1f, %.1f, %02d', position_voxel_airways_with_gt(aa,1), position_voxel_airways_with_gt(aa,2), position_voxel_airways_with_gt(aa,3), generation_airways_with_gt(aa));

        % groun-truth airway ID,
        str_row{5} = sprintf('%03d', indexes_gt_with_airway(aa));

        % INNER GT AIRWAY radius, area, AAR,
        str_row{6} = sprintf('%.3f, %.3f, %.3f', inner_radius_gt_with_airway(aa), inner_area_gt_with_airway(aa), inner_AAR_gt_with_airway(aa));

        % OUTER GT AIRWAY radius, area, AAR,
        str_row{7} = sprintf('%.3f, %.3f, %.3f', outer_radius_gt_with_airway(aa), outer_area_gt_with_airway(aa), outer_AAR_gt_with_airway(aa));

        % GT AIRWAY position, generation 
        str_row{8} = sprintf('%.1f, %.1f, %.1f, %02d', position_voxel_gt_with_airway(aa,1), position_voxel_gt_with_airway(aa,2), position_voxel_gt_with_airway(aa,3), generation_gt_with_airway(aa));

        % save the line
        fprintf( fid_air, [strjoin(str_row, ', ') '\n']);
    end


    indexes_vessels_with_gt         = data_with_gt.vessels(dd).res_index;
    radius_vessels_with_gt          = data_with_gt.vessels(dd).res_radius;
    area_vessels_with_gt            = data_with_gt.vessels(dd).res_area;
    position_voxel_vessels_with_gt  = data_with_gt.vessels(dd).res_position_voxel;

    indexes_gt_with_vessel          = data_with_gt.vessels(dd).gt_index;
    radius_gt_with_vessel           = data_with_gt.vessels(dd).gt_radius;
    area_gt_with_vessel             = data_with_gt.vessels(dd).gt_area;
    position_voxel_gt_with_vessel   = data_with_gt.vessels(dd).gt_position_voxel;

    num_vessels_with_gt = numel( indexes_vessels_with_gt );

    for vv = 1:num_vessels_with_gt
        % Information of vessels and paired ground-truth
        str_row = {};

        % patient ID, airway ID,
        str_row{1} = sprintf('%s, %03d', image_id, indexes_vessels_with_gt(vv));

        % VESSEL radius, area,
        str_row{2} = sprintf('%.3f, %.3f', radius_vessels_with_gt(vv), area_vessels_with_gt(vv)); 

        % VESSEL position
        str_row{3} = sprintf('%.1f, %.1f, %.1f', position_voxel_vessels_with_gt(vv,1), position_voxel_vessels_with_gt(vv,2), position_voxel_vessels_with_gt(vv,3));

        % groun-truth vessel ID,
        str_row{4} = sprintf('%03d', indexes_gt_with_vessel(vv));

        % GT VESSEL radius, area,
        str_row{5} = sprintf('%.3f, %.3f', radius_gt_with_vessel(vv), area_gt_with_vessel(vv));

        % GT VESSEL position 
        str_row{6} = sprintf('%.1f, %.1f, %.1f', position_voxel_gt_with_vessel(vv,1), position_voxel_gt_with_vessel(vv,2), position_voxel_gt_with_vessel(vv,3));

        % save the line
        fprintf( fid_ves, [strjoin(str_row, ', ') '\n']);
    end
end


fclose(fid_air);
fclose(fid_ves);

fprintf('   - Done (%s)...\n', str_out_file_airways);
fprintf('     and (%s) in %.1fs\n\n', str_out_file_vessels, toc);

end
