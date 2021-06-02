function summarised = summariseAllBiomarkers( summarised, cc, airways_all, ids_all, airways_paired, ids_paired)

    % it recives a 'summarised' structure and adds the values for the cc case.

    summarised.inner_AAR(cc)                     = extractBiomarkerProperties( [airways_paired(ids_paired).airway_inner_AAR], [airways_paired(ids_paired).airway_length] );
    summarised.outer_AAR(cc)                     = extractBiomarkerProperties( [airways_paired(ids_paired).airway_outer_AAR], [airways_paired(ids_paired).airway_length] );

    summarised.WAR(cc)                           = extractBiomarkerProperties( [airways_paired(ids_paired).wall_WAR_radius], [airways_paired(ids_paired).airway_length] );
    summarised.WTR(cc)                           = extractBiomarkerProperties( [airways_paired(ids_paired).wall_thickness_ratio], [airways_paired(ids_paired).airway_length] );
    summarised.WTR_atMid(cc)                     = extractBiomarkerProperties( [airways_paired(ids_paired).wall_thickness_ratio_atMid], [airways_paired(ids_paired).airway_length] );
    summarised.WAP(cc)                           = extractBiomarkerProperties( [airways_paired(ids_paired).wall_areaPer], [airways_paired(ids_paired).airway_length] );
    summarised.WAP_atMid(cc)                     = extractBiomarkerProperties( [airways_paired(ids_paired).wall_areaPer_atMid], [airways_paired(ids_paired).airway_length] );

    summarised.inner_tapering_diam(cc)           = extractBiomarkerProperties( [airways_paired(ids_paired).inner_tapering_diam],  [airways_paired(ids_paired).airway_length] );
    summarised.outer_tapering_diam(cc)           = extractBiomarkerProperties( [airways_paired(ids_paired).outer_tapering_diam],  [airways_paired(ids_paired).airway_length] );
    summarised.wall_tapering_diam(cc)            = extractBiomarkerProperties( [airways_paired(ids_paired).wall_tapering_diam],   [airways_paired(ids_paired).airway_length] );
    summarised.vessel_tapering_diam(cc)          = extractBiomarkerProperties( [airways_paired(ids_paired).vessel_tapering_diam], [airways_paired(ids_paired).airway_length] );

    summarised.inner_taperingPerc_diam(cc)       = extractBiomarkerProperties( [airways_paired(ids_paired).inner_taperingPerc_diam],  [airways_paired(ids_paired).airway_length] );
    summarised.outer_taperingPerc_diam(cc)       = extractBiomarkerProperties( [airways_paired(ids_paired).outer_taperingPerc_diam],  [airways_paired(ids_paired).airway_length] );
    summarised.wall_taperingPerc_diam(cc)        = extractBiomarkerProperties( [airways_paired(ids_paired).wall_taperingPerc_diam],   [airways_paired(ids_paired).airway_length] );
    summarised.vessel_taperingPerc_diam(cc)      = extractBiomarkerProperties( [airways_paired(ids_paired).vessel_taperingPerc_diam], [airways_paired(ids_paired).airway_length] );

    summarised.inner_tapering_area(cc)           = extractBiomarkerProperties( [airways_paired(ids_paired).inner_tapering_area],  [airways_paired(ids_paired).airway_length] );
    summarised.outer_tapering_area(cc)           = extractBiomarkerProperties( [airways_paired(ids_paired).outer_tapering_area],  [airways_paired(ids_paired).airway_length] );
    summarised.wall_tapering_area(cc)            = extractBiomarkerProperties( [airways_paired(ids_paired).wall_tapering_area],   [airways_paired(ids_paired).airway_length] );
    summarised.vessel_tapering_area(cc)          = extractBiomarkerProperties( [airways_paired(ids_paired).vessel_tapering_area], [airways_paired(ids_paired).airway_length] );

    summarised.inner_taperingPerc_area(cc)       = extractBiomarkerProperties( [airways_paired(ids_paired).inner_taperingPerc_area],  [airways_paired(ids_paired).airway_length] );
    summarised.outer_taperingPerc_area(cc)       = extractBiomarkerProperties( [airways_paired(ids_paired).outer_taperingPerc_area],  [airways_paired(ids_paired).airway_length] );
    summarised.wall_taperingPerc_area(cc)        = extractBiomarkerProperties( [airways_paired(ids_paired).wall_taperingPerc_area],   [airways_paired(ids_paired).airway_length] );
    summarised.vessel_taperingPerc_area(cc)      = extractBiomarkerProperties( [airways_paired(ids_paired).vessel_taperingPerc_area], [airways_paired(ids_paired).airway_length] );

    summarised.inner_PR(cc)                      = extractBiomarkerProperties( [airways_paired(ids_paired).airway_inner_parent_ratio_radius], [airways_paired(ids_paired).airway_length] );
    summarised.outer_PR(cc)                      = extractBiomarkerProperties( [airways_paired(ids_paired).airway_outer_parent_ratio_radius], [airways_paired(ids_paired).airway_length] );
    
    % this is the vessel vs the paired vessel of the parent airway
    summarised.vessel_PR(cc)                     = extractBiomarkerProperties( [airways_paired(ids_paired).vessel_parent_ratio_radius_bothPaired], [airways_paired(ids_paired).airway_length] );

    summarised.inner_interTapering(cc)           = extractBiomarkerProperties( [airways_paired(ids_paired).airway_inner_interTapering], [airways_paired(ids_paired).airway_length] );
    summarised.outer_interTapering(cc)           = extractBiomarkerProperties( [airways_paired(ids_paired).airway_outer_interTapering], [airways_paired(ids_paired).airway_length] );

    summarised.inner_diam(cc)                    = extractBiomarkerProperties( [airways_paired(ids_paired).airway_inner_diam],                  [airways_paired(ids_paired).airway_length] );
    summarised.outer_diam(cc)                    = extractBiomarkerProperties( [airways_paired(ids_paired).airway_outer_diam],                  [airways_paired(ids_paired).airway_length] );
    summarised.wall_thickness(cc)                = extractBiomarkerProperties( [airways_paired(ids_paired).wall_thickness],                     [airways_paired(ids_paired).airway_length] );

    summarised.inner_diam_atMid(cc)              = extractBiomarkerProperties( [airways_paired(ids_paired).airway_inner_diam_atMid],            [airways_paired(ids_paired).airway_length] );
    summarised.outer_diam_atMid(cc)              = extractBiomarkerProperties( [airways_paired(ids_paired).airway_outer_diam_atMid],            [airways_paired(ids_paired).airway_length] );
    summarised.wall_thickness_atMid(cc)          = extractBiomarkerProperties( [airways_paired(ids_paired).wall_thickness_atMid],               [airways_paired(ids_paired).airway_length] );

    summarised.vessel_diam(cc)                   = extractBiomarkerProperties( [airways_paired(ids_paired).airway_vessel_diam],                 [airways_paired(ids_paired).airway_length] );

    summarised.airway_length(cc)                 = extractBiomarkerProperties( [airways_paired(ids_paired).airway_length],                      [airways_paired(ids_paired).airway_length] );
    summarised.all_airway_length(cc)             = extractBiomarkerProperties( [airways_all(ids_all).airway_length],                            [airways_all(ids_all).airway_length] );

    % ALL airways, including not paired ones
    summarised.all_WTR_atMid(cc)                 = extractBiomarkerProperties( [airways_all(ids_all).wall_thickness_ratio_atMid],               [airways_all(ids_all).airway_length] );
    summarised.all_WAP_atMid(cc)                 = extractBiomarkerProperties( [airways_all(ids_all).wall_areaPer_atMid],                       [airways_all(ids_all).airway_length] );

    summarised.all_inner_tapering_diam(cc)       = extractBiomarkerProperties( [airways_all(ids_all).inner_tapering_diam],  [airways_all(ids_all).airway_length] );
    summarised.all_outer_tapering_diam(cc)       = extractBiomarkerProperties( [airways_all(ids_all).outer_tapering_diam],  [airways_all(ids_all).airway_length] );
    summarised.all_wall_tapering_diam(cc)        = extractBiomarkerProperties( [airways_all(ids_all).wall_tapering_diam],   [airways_all(ids_all).airway_length] );

    summarised.all_inner_taperingPerc_diam(cc)   = extractBiomarkerProperties( [airways_all(ids_all).inner_taperingPerc_diam],  [airways_all(ids_all).airway_length] );
    summarised.all_outer_taperingPerc_diam(cc)   = extractBiomarkerProperties( [airways_all(ids_all).outer_taperingPerc_diam],  [airways_all(ids_all).airway_length] );
    summarised.all_wall_taperingPerc_diam(cc)    = extractBiomarkerProperties( [airways_all(ids_all).wall_taperingPerc_diam],   [airways_all(ids_all).airway_length] );

    summarised.all_inner_tapering_area(cc)       = extractBiomarkerProperties( [airways_all(ids_all).inner_tapering_area],  [airways_all(ids_all).airway_length] );
    summarised.all_outer_tapering_area(cc)       = extractBiomarkerProperties( [airways_all(ids_all).outer_tapering_area],  [airways_all(ids_all).airway_length] );
    summarised.all_wall_tapering_area(cc)        = extractBiomarkerProperties( [airways_all(ids_all).wall_tapering_area],   [airways_all(ids_all).airway_length] );

    summarised.all_inner_taperingPerc_area(cc)   = extractBiomarkerProperties( [airways_all(ids_all).inner_taperingPerc_area],  [airways_all(ids_all).airway_length] );
    summarised.all_outer_taperingPerc_area(cc)   = extractBiomarkerProperties( [airways_all(ids_all).outer_taperingPerc_area],  [airways_all(ids_all).airway_length] );
    summarised.all_wall_taperingPerc_area(cc)    = extractBiomarkerProperties( [airways_all(ids_all).wall_taperingPerc_area],   [airways_all(ids_all).airway_length] );

    summarised.all_inner_PR(cc)                  = extractBiomarkerProperties( [airways_all(ids_all).airway_inner_parent_ratio_radius],        [airways_all(ids_all).airway_length] );
    summarised.all_outer_PR(cc)                  = extractBiomarkerProperties( [airways_all(ids_all).airway_outer_parent_ratio_radius],        [airways_all(ids_all).airway_length] );
    
    summarised.all_inner_interTapering(cc)       = extractBiomarkerProperties( [airways_all(ids_all).airway_inner_interTapering],    [airways_all(ids_paired).airway_length] );
    summarised.all_outer_interTapering(cc)       = extractBiomarkerProperties( [airways_all(ids_all).airway_outer_interTapering],    [airways_all(ids_paired).airway_length] );
    
    summarised.all_inner_diam_atMid(cc)          = extractBiomarkerProperties( [airways_all(ids_all).airway_inner_diam_atMid],                 [airways_all(ids_all).airway_length] );
    summarised.all_outer_diam_atMid(cc)          = extractBiomarkerProperties( [airways_all(ids_all).airway_outer_diam_atMid],                 [airways_all(ids_all).airway_length] );
    summarised.all_wall_thickness_atMid(cc)      = extractBiomarkerProperties( [airways_all(ids_all).wall_thickness_atMid],                    [airways_all(ids_all).airway_length] );

    % Number of airways
    summarised.number_airways(cc)                = extractBiomarkerProperties ( sum( ids_paired ) );
    summarised.all_number_airways(cc)            = extractBiomarkerProperties ( sum( ids_all ) );

    % Generation
    summarised.generation(cc)                    = extractBiomarkerProperties( [airways_paired(ids_paired).airway_generation], [airways_paired(ids_paired).airway_length] );
    summarised.all_generation(cc)                = extractBiomarkerProperties( [airways_all(ids_all).airway_generation],       [airways_all(ids_all).airway_length] );
end
