function airways_all = organiseAirways( id_images_processed, data )

    ii = 0;

    for dd = id_images_processed

        % MEASUREMNTS FOR ALL AIRWAYS
        for aa = 1:numel([data(dd).airways]);

            ii = ii + 1;

            tmp_airway = data(dd).airways(aa);

            mp = round((tmp_airway.nPoints + 0.5) / 2);

            % radius measurements half way
            airways_all(ii).airway_outer_diam_atMid  = 2 * tmp_airway.outer.radius( mp );    % does not take into consideration the pairing point
            airways_all(ii).airway_inner_diam_atMid  = 2 * tmp_airway.inner.radius( mp );

            % Wall 
            airways_all(ii).wall_thickness_atMid                   = tmp_airway.wall.thickness( mp );
            airways_all(ii).wall_areaPer_atMid                     = tmp_airway.wall.areaPer( mp );
            airways_all(ii).wall_thickness_ratio_atMid             = airways_all(ii).wall_thickness_atMid / airways_all(ii).airway_outer_diam_atMid;

            % Tapering
            airways_all(ii).inner_tapering_diam                    = tmp_airway.inner.tapering_diam;
            airways_all(ii).outer_tapering_diam                    = tmp_airway.outer.tapering_diam;
            airways_all(ii).wall_tapering_diam                     = tmp_airway.wall.tapering_diam;

            airways_all(ii).inner_tapering_area                    = tmp_airway.inner.tapering_area;
            airways_all(ii).outer_tapering_area                    = tmp_airway.outer.tapering_area;
            airways_all(ii).wall_tapering_area                     = tmp_airway.wall.tapering_area;

            airways_all(ii).inner_taperingPerc_diam                = tmp_airway.inner.taperingPerc_diam;
            airways_all(ii).outer_taperingPerc_diam                = tmp_airway.outer.taperingPerc_diam;
            airways_all(ii).wall_taperingPerc_diam                 = tmp_airway.wall.taperingPerc_diam;

            airways_all(ii).inner_taperingPerc_area                = tmp_airway.inner.taperingPerc_area;
            airways_all(ii).outer_taperingPerc_area                = tmp_airway.outer.taperingPerc_area;
            airways_all(ii).wall_taperingPerc_area                 = tmp_airway.wall.taperingPerc_area;

            % inter-branch
            airways_all(ii).airway_outer_parent_ratio_area         = tmp_airway.outer.parent_ratio_area;
            airways_all(ii).airway_inner_parent_ratio_area         = tmp_airway.inner.parent_ratio_area;

            airways_all(ii).airway_outer_parent_ratio_radius       = tmp_airway.outer.parent_ratio_radius;
            airways_all(ii).airway_inner_parent_ratio_radius       = tmp_airway.inner.parent_ratio_radius;
            
            airways_all(ii).airway_inner_interTapering             = (1 - tmp_airway.inner.parent_ratio_radius) * 100; % percentage reduction, compared with parent
            airways_all(ii).airway_outer_interTapering             = (1 - tmp_airway.outer.parent_ratio_radius) * 100;

            % Auxiliars
            airways_all(ii).airway_length                          = tmp_airway.length;
            airways_all(ii).airway_length_resolution               = tmp_airway.length / size(tmp_airway.centreline, 1);              

            airways_all(ii).airway_generation                      = tmp_airway.generation;
            airways_all(ii).cases                                  = dd;

            % Additional MEASURMENTS FOR AIRWAYS THAT HAVE BEEN PAIRED
            if tmp_airway.isPaired

                airways_all(ii).isPaired = true;

                ap = tmp_airway.pair.airway_point_id;

                % vessel info
                airways_all(ii).airway_vessel_diam                  = 2 * data(dd).vessels( tmp_airway.pair.vessel_id ).radius( tmp_airway.pair.vessel_point_id );
%                 airways_all(ii).airway_vessel_parent_ratio_radius   =     data(dd).vessels( tmp_airway.pair.vessel_id ).parent_ratio_radius;
     
                airways_all(ii).airway_outer_diam  = 2 * tmp_airway.outer.radius( ap );    % AT PAIRING POINT
                airways_all(ii).airway_inner_diam  = 2 * tmp_airway.inner.radius( ap );

                % AAR - radial
                airways_all(ii).airway_outer_AAR   = tmp_airway.outer.AAR_radial;
                airways_all(ii).airway_inner_AAR   = tmp_airway.inner.AAR_radial;

                % AAR - area
                airways_all(ii).airway_outer_AAR_area   = tmp_airway.outer.AAR_area;
                airways_all(ii).airway_inner_AAR_area   = tmp_airway.inner.AAR_area;

                % WTR - at pairing
                airways_all(ii).wall_thickness        = tmp_airway.wall.thickness( ap );
                airways_all(ii).wall_areaPer          = tmp_airway.wall.areaPer( ap );
                airways_all(ii).wall_thickness_ratio  = airways_all(ii).wall_thickness / airways_all(ii).airway_outer_diam;                    

                % Wall ratio (WAR)
                airways_all(ii).wall_WAR_area      = tmp_airway.wall.WAR_area;
                airways_all(ii).wall_WAR_radius    = tmp_airway.wall.WAR_radial;
                airways_all(ii).wall_WAR_diametre  = tmp_airway.wall.WAR_radial / 2; % divided by 2 because WAR_radial = thicknes / radius

                % Pairing similarity
                airways_all(ii).similarity         = tmp_airway.pair.similarity;

                % Tapering
                airways_all(ii).vessel_tapering_diam                   = data(dd).vessels( tmp_airway.pair.vessel_id ).tapering_diam;
                airways_all(ii).vessel_tapering_area                   = data(dd).vessels( tmp_airway.pair.vessel_id ).tapering_area;
                airways_all(ii).vessel_taperingPerc_diam               = data(dd).vessels( tmp_airway.pair.vessel_id ).taperingPerc_diam;
                airways_all(ii).vessel_taperingPerc_area               = data(dd).vessels( tmp_airway.pair.vessel_id ).taperingPerc_area;

                % Auxiliars
                airways_all(ii).airway_vessel_length                   = data(dd).vessels( tmp_airway.pair.vessel_id ).length;

                % if parent is also paired
                if tmp_airway.parent > 1 && tmp_airway.parent <= numel(data(dd).airways) && data(dd).airways(tmp_airway.parent).isPaired
                    airways_all(ii).airway_outer_parent_ratio_radius_bothPaired = tmp_airway.outer.global_radius / data(dd).airways(tmp_airway.parent).outer.global_radius;
                    airways_all(ii).airway_inner_parent_ratio_radius_bothPaired = tmp_airway.inner.global_radius / data(dd).airways(tmp_airway.parent).inner.global_radius;
                    
                    % vessel paired to parent airway
                    vP = data(dd).airways(tmp_airway.parent).pair.vessel_id;
                    
                    airways_all(ii).vessel_parent_ratio_radius_bothPaired = data(dd).vessels( tmp_airway.pair.vessel_id ).global_radius / data(dd).vessels( vP ).global_radius;
                else
                    airways_all(ii).airway_outer_parent_ratio_radius_bothPaired = NaN;
                    airways_all(ii).airway_inner_parent_ratio_radius_bothPaired = NaN;
                    airways_all(ii).vessel_parent_ratio_radius_bothPaired       = NaN;
                end
            else

                airways_all(ii).isPaired = false;

                airways_all(ii).airway_vessel_diam                  = NaN;
                airways_all(ii).airway_vessel_parent_ratio_radius   = NaN;

                airways_all(ii).airway_inner_diam = NaN;                    
                airways_all(ii).airway_outer_diam = NaN;

                % AAR - radial
                airways_all(ii).airway_outer_AAR   = NaN;
                airways_all(ii).airway_inner_AAR   = NaN;

                % AAR - area
                airways_all(ii).airway_outer_AAR_area   = NaN;
                airways_all(ii).airway_inner_AAR_area   = NaN;

                % WTR - at pairing
                airways_all(ii).wall_thickness        = NaN;
                airways_all(ii).wall_areaPer          = NaN;
                airways_all(ii).wall_thickness_ratio  = NaN;

                % Wall ratio (WAR)
                airways_all(ii).wall_WAR_area      = NaN;
                airways_all(ii).wall_WAR_radius    = NaN;
                airways_all(ii).wall_WAR_diametre  = NaN;

                % Pairing similarity
                airways_all(ii).similarity         = NaN;

                % Intra-branch
                airways_all(ii).vessel_tapering_slope              = NaN;

                % Auxiliars
                airways_all(ii).airway_vessel_length               = NaN;

                airways_all(ii).airway_outer_parent_ratio_radius_bothPaired = NaN;
                airways_all(ii).airway_inner_parent_ratio_radius_bothPaired = NaN;
                airways_all(ii).vessel_parent_ratio_radius_bothPaired       = NaN;
            end
        end
    end
end