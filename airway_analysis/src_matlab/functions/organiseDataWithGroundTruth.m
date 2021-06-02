function data_with_gt = organiseDataWithGroundTruth( data, id_images_processed )

    is_pair_data_with_gt_accurate = true;

    indexes_image_with_gt = [];
    airways_with_gt       = {};
    vessels_with_gt       = {};

    for dd = id_images_processed

        if data(dd).has_ground_truth
            fprintf('Process image %d: %s which has ground-truth...\n', dd, data(dd).files.rootName);

            try
                voxelSize                       = data(dd).extras.voxelSize;
                norm_length                     = sqrt(data(dd).extras.normalising_factor_area);
                voxelSize_norm                  = voxelSize .* norm_length;
                
                airways_this                    = data(dd).airways;
                vessels_this                    = data(dd).vessels;
                ground_truth_this               = data(dd).ground_truth;
                
                indexes_airways_with_gt         = find( [airways_this(:).hasGT] );
                airways_with_gt_this            = [airways_this(indexes_airways_with_gt)];
                num_airways_with_gt             = numel(airways_with_gt_this);
                
                indexes_vessels_with_gt         = find( [vessels_this(:).hasGT] );
                vessels_with_gt_this            = [vessels_this(indexes_vessels_with_gt)];
                num_vessels_with_gt             = numel(vessels_with_gt_this);
                
                aux_airways_with_gt_this__dot_gt = [airways_with_gt_this.gt];
                indexes_ground_truth_with_airway = [aux_airways_with_gt_this__dot_gt.id];
                
                aux_vessels_with_gt_this__dot_gt = [vessels_with_gt_this.gt];
                indexes_ground_truth_with_vessel = [aux_vessels_with_gt_this__dot_gt.id];
                
                ground_truth_with_airway_this   = [ground_truth_this(indexes_ground_truth_with_airway)];
                ground_truth_with_vessel_this   = [ground_truth_this(indexes_ground_truth_with_vessel)];
                
                aux_airways_with_gt_this__dot_inner	= [airways_with_gt_this.inner];
                aux_airways_with_gt_this__dot_outer = [airways_with_gt_this.outer];
                
                
                % retrieve the measurements for segmented airways / vessels
                if is_pair_data_with_gt_accurate	
                    num_airways_with_gt = numel(airways_with_gt_this);
                    indexes_points_inside_airway_paired_with_gt = [aux_airways_with_gt_this__dot_gt.airway_point_id];
                    
                    inner_radius_airways_with_gt 	= [];
                    inner_area_airways_with_gt   	= [];
                    outer_radius_airways_with_gt 	= [];
                    outer_area_airways_with_gt   	= [];
                    position_voxel_airways_with_gt	= [];
                    
                    for aa=1:num_airways_with_gt
                        index_point_inside_airway = indexes_points_inside_airway_paired_with_gt(aa);
                        
                        inner_radius_airways_with_gt(end+1)	= airways_with_gt_this(aa).inner.radius(index_point_inside_airway);
                        inner_area_airways_with_gt  (end+1) = airways_with_gt_this(aa).inner.area  (index_point_inside_airway);
                        outer_radius_airways_with_gt(end+1) = airways_with_gt_this(aa).outer.radius(index_point_inside_airway);
                        outer_area_airways_with_gt  (end+1)	= airways_with_gt_this(aa).outer.area  (index_point_inside_airway);
                        position_voxel_airways_with_gt      = [position_voxel_airways_with_gt; airways_with_gt_this(aa).centreline(index_point_inside_airway,:)];
                    end
                    
                    num_vessels_with_gt = numel(vessels_with_gt_this);
                    indexes_points_inside_vessel_paired_with_gt = [aux_vessels_with_gt_this__dot_gt.vessel_point_id];
                    
                    radius_vessels_with_gt          = [];
                    area_vessels_with_gt            = [];
                    position_voxel_vessels_with_gt  = [];
                    
                    for vv=1:num_vessels_with_gt
                        index_point_inside_vessel = indexes_points_inside_vessel_paired_with_gt(vv);
                        
                        radius_vessels_with_gt(end+1) 	= vessels_with_gt_this(vv).radius(index_point_inside_vessel);
                        area_vessels_with_gt  (end+1) 	= vessels_with_gt_this(vv).area  (index_point_inside_vessel);
                        position_voxel_vessels_with_gt 	= [position_voxel_vessels_with_gt; vessels_with_gt_this(vv).centreline(index_point_inside_vessel,:)];
                    end
                    
                else
                    inner_radius_airways_with_gt	= [aux_airways_with_gt_this__dot_inner.global_radius];
                    inner_area_airways_with_gt      = [aux_airways_with_gt_this__dot_inner.global_area]; 
                    outer_radius_airways_with_gt    = [aux_airways_with_gt_this__dot_outer.global_radius];
                    outer_area_airways_with_gt      = [aux_airways_with_gt_this__dot_outer.global_area];
                    position_voxel_airways_with_gt  = [];
                    
                    for aa=1:num_airways_with_gt
                        position_voxel_airways_with_gt 	= [position_voxel_airways_with_gt; airways_with_gt_this(aa).centreline(round(end/2),:)]; % middle point
                    end 
                    
                    radius_vessels_with_gt			= [vessels_with_gt_this.global_radius];
                    area_vessels_with_gt     		= [vessels_with_gt_this.global_area];
                    position_voxel_vessels_with_gt  = [];
                    
                    for vv=1:num_vessels_with_gt
                        position_voxel_vessels_with_gt 	= [position_voxel_vessels_with_gt; vessels_with_gt_this(vv).centreline(round(end/2),:)]; % middle point
                    end
                end  
                
                inner_AAR_airways_with_gt           = [aux_airways_with_gt_this__dot_inner.AAR_area];
                outer_AAR_airways_with_gt           = [aux_airways_with_gt_this__dot_outer.AAR_area];
                generation_airways_with_gt          = [airways_with_gt_this.generation];
                
                voxelSize_norm_repeatmat            = repmat(voxelSize_norm, num_airways_with_gt, 1);
                position_voxel_airways_with_gt      = position_voxel_airways_with_gt ./ voxelSize_norm_repeatmat;
                
                voxelSize_norm_repeatmat            = repmat(voxelSize_norm, num_vessels_with_gt, 1);
                position_voxel_vessels_with_gt      = position_voxel_vessels_with_gt ./ voxelSize_norm_repeatmat;
                
                
                % retrieve the ground-truth measurements
                aux_ground_truth_with_airway_this__dot_inner= [ground_truth_with_airway_this.inner];
                inner_radius_ground_truth_with_airway   = [aux_ground_truth_with_airway_this__dot_inner.global_radius];
                inner_area_ground_truth_with_airway     = [aux_ground_truth_with_airway_this__dot_inner.global_area];
                inner_AAR_ground_truth_with_airway      = [aux_ground_truth_with_airway_this__dot_inner.AAR_area];
                
                aux_ground_truth_with_airway_this__dot_outer= [ground_truth_with_airway_this.outer];
                outer_radius_ground_truth_with_airway   = [aux_ground_truth_with_airway_this__dot_outer.global_radius];
                outer_area_ground_truth_with_airway     = [aux_ground_truth_with_airway_this__dot_outer.global_area];
                outer_AAR_ground_truth_with_airway      = [aux_ground_truth_with_airway_this__dot_outer.AAR_area];
                generation_ground_truth_with_airway     = [ground_truth_with_airway_this.generation];
                
                aux_ground_truth_with_vessel_this__dot_vessel=[ground_truth_with_vessel_this.inner];
                radius_ground_truth_with_vessel         = [aux_ground_truth_with_vessel_this__dot_vessel.global_radius];
                area_ground_truth_with_vessel           = [aux_ground_truth_with_vessel_this__dot_vessel.global_area];
                
                position_voxel_ground_truth_with_airway = [ground_truth_with_airway_this.airway_position_voxel];
                position_voxel_ground_truth_with_vessel = [ground_truth_with_vessel_this.vessel_position_voxel];
                
                % reshape vector to 3-cols matrix
                position_voxel_ground_truth_with_airway	= reshape(position_voxel_ground_truth_with_airway, [3, num_airways_with_gt])';
                position_voxel_ground_truth_with_vessel	= reshape(position_voxel_ground_truth_with_vessel, [3, num_vessels_with_gt])';
                

                % save new data structure
                indexes_image_with_gt(end+1) = dd;
                
                airways_with_gt(dd).res_index           = indexes_airways_with_gt;
                airways_with_gt(dd).res_inner_radius	= inner_radius_airways_with_gt;
                airways_with_gt(dd).res_inner_area		= inner_area_airways_with_gt;
                airways_with_gt(dd).res_inner_AAR		= inner_AAR_airways_with_gt;
                airways_with_gt(dd).res_outer_radius	= outer_radius_airways_with_gt;
                airways_with_gt(dd).res_outer_area		= outer_area_airways_with_gt;
                airways_with_gt(dd).res_outer_AAR		= outer_AAR_airways_with_gt;
                airways_with_gt(dd).res_position_voxel  = position_voxel_airways_with_gt;
                airways_with_gt(dd).res_generation      = generation_airways_with_gt;
                
                airways_with_gt(dd).gt_index       		= indexes_ground_truth_with_airway;
                airways_with_gt(dd).gt_inner_radius		= inner_radius_ground_truth_with_airway;
                airways_with_gt(dd).gt_inner_area  		= inner_area_ground_truth_with_airway;
                airways_with_gt(dd).gt_inner_AAR   		= inner_AAR_ground_truth_with_airway;
                airways_with_gt(dd).gt_outer_radius		= outer_radius_ground_truth_with_airway;
                airways_with_gt(dd).gt_outer_area  		= outer_area_ground_truth_with_airway;
                airways_with_gt(dd).gt_outer_AAR   		= outer_AAR_ground_truth_with_airway;
                airways_with_gt(dd).gt_position_voxel   = position_voxel_ground_truth_with_airway;
                airways_with_gt(dd).gt_generation     	= generation_ground_truth_with_airway;
                
                vessels_with_gt(dd).res_index      		= indexes_vessels_with_gt;
                vessels_with_gt(dd).res_radius          = radius_vessels_with_gt;
                vessels_with_gt(dd).res_area       		= area_vessels_with_gt;
                vessels_with_gt(dd).res_position_voxel  = position_voxel_vessels_with_gt;
                
                vessels_with_gt(dd).gt_index       		= indexes_ground_truth_with_vessel;
                vessels_with_gt(dd).gt_radius      		= radius_ground_truth_with_vessel;
                vessels_with_gt(dd).gt_area        		= area_ground_truth_with_vessel;
                vessels_with_gt(dd).gt_position_voxel   = position_voxel_ground_truth_with_vessel;
            
            catch exception
                fprintf('\n ERROR with case %s, matching measurements with the ground-truth: %s\n\n', data(dd).files.rootName, exception.message);
            end
        end
    end

    data_with_gt.indexes_images = indexes_image_with_gt;
    data_with_gt.airways = airways_with_gt;
    data_with_gt.vessels = vessels_with_gt;
end
