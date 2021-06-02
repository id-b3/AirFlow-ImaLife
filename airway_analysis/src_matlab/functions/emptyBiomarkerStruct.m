function summarised = emptyBiomarkerStruct( id_cases )

    if nargin == 0
        id_cases = 1;
    end

    summarised.inner_AAR(id_cases)                     = extractBiomarkerProperties( [], [] );
    summarised.outer_AAR(id_cases)                     = extractBiomarkerProperties( [], [] );

    summarised.WAR(id_cases)                           = extractBiomarkerProperties( [], [] );
    summarised.WTR(id_cases)                           = extractBiomarkerProperties( [], [] );
    summarised.WTR_atMid(id_cases)                     = extractBiomarkerProperties( [], [] );
    summarised.WAP(id_cases)                           = extractBiomarkerProperties( [], [] );
    summarised.WAP_atMid(id_cases)                     = extractBiomarkerProperties( [], [] );

    summarised.inner_tapering_diam(id_cases)           = extractBiomarkerProperties( [], [] );
    summarised.outer_tapering_diam(id_cases)           = extractBiomarkerProperties( [], [] );
    summarised.wall_tapering_diam(id_cases)            = extractBiomarkerProperties( [], [] );
    summarised.vessel_tapering_diam(id_cases)          = extractBiomarkerProperties( [], [] );

    summarised.inner_taperingPerc_diam(id_cases)       = extractBiomarkerProperties( [], [] );
    summarised.outer_taperingPerc_diam(id_cases)       = extractBiomarkerProperties( [], [] );
    summarised.wall_taperingPerc_diam(id_cases)        = extractBiomarkerProperties( [], [] );
    summarised.vessel_taperingPerc_diam(id_cases)      = extractBiomarkerProperties( [], [] );

    summarised.inner_tapering_area(id_cases)           = extractBiomarkerProperties( [], [] );
    summarised.outer_tapering_area(id_cases)           = extractBiomarkerProperties( [], [] );
    summarised.wall_tapering_area(id_cases)            = extractBiomarkerProperties( [], [] );
    summarised.vessel_tapering_area(id_cases)          = extractBiomarkerProperties( [], [] );

    summarised.inner_taperingPerc_area(id_cases)       = extractBiomarkerProperties( [], [] );
    summarised.outer_taperingPerc_area(id_cases)       = extractBiomarkerProperties( [], [] );
    summarised.wall_taperingPerc_area(id_cases)        = extractBiomarkerProperties( [], [] );
    summarised.vessel_taperingPerc_area(id_cases)      = extractBiomarkerProperties( [], [] );

    summarised.inner_PR(id_cases)                      = extractBiomarkerProperties( [], [] );
    summarised.outer_PR(id_cases)                      = extractBiomarkerProperties( [], [] );
    summarised.vessel_PR(id_cases)                     = extractBiomarkerProperties( [], [] );
    
    summarised.inner_interTapering(id_cases)           = extractBiomarkerProperties( [], [] );
    summarised.outer_interTapering(id_cases)           = extractBiomarkerProperties( [], [] );
    
    
    summarised.inner_diam(id_cases)                    = extractBiomarkerProperties( [], [] );
    summarised.outer_diam(id_cases)                    = extractBiomarkerProperties( [], [] );
    summarised.wall_thickness(id_cases)                = extractBiomarkerProperties( [], [] );

    summarised.inner_diam_atMid(id_cases)              = extractBiomarkerProperties( [], [] );
    summarised.outer_diam_atMid(id_cases)              = extractBiomarkerProperties( [], [] );
    summarised.wall_thickness_atMid(id_cases)          = extractBiomarkerProperties( [], [] );

    summarised.vessel_diam(id_cases)                   = extractBiomarkerProperties( [], [] );

    summarised.airway_length(id_cases)                 = extractBiomarkerProperties( [], [] );
    summarised.all_airway_length(id_cases)             = extractBiomarkerProperties( [], [] );

    % ALL airways, including not paired ones
    summarised.all_WTR_atMid(id_cases)                 = extractBiomarkerProperties( [], [] );
    summarised.all_WAP_atMid(id_cases)                 = extractBiomarkerProperties( [], [] );

    summarised.all_inner_tapering_diam(id_cases)       = extractBiomarkerProperties( [], [] );
    summarised.all_outer_tapering_diam(id_cases)       = extractBiomarkerProperties( [], [] );
    summarised.all_wall_tapering_diam(id_cases)        = extractBiomarkerProperties( [], [] );

    summarised.all_inner_taperingPerc_diam(id_cases)   = extractBiomarkerProperties( [], [] );
    summarised.all_outer_taperingPerc_diam(id_cases)   = extractBiomarkerProperties( [], [] );
    summarised.all_wall_taperingPerc_diam(id_cases)    = extractBiomarkerProperties( [], [] );

    summarised.all_inner_tapering_area(id_cases)       = extractBiomarkerProperties( [], [] );
    summarised.all_outer_tapering_area(id_cases)       = extractBiomarkerProperties( [], [] );
    summarised.all_wall_tapering_area(id_cases)        = extractBiomarkerProperties( [], [] );

    summarised.all_inner_taperingPerc_area(id_cases)   = extractBiomarkerProperties( [], [] );
    summarised.all_outer_taperingPerc_area(id_cases)   = extractBiomarkerProperties( [], [] );
    summarised.all_wall_taperingPerc_area(id_cases)    = extractBiomarkerProperties( [], [] );

    summarised.all_inner_PR(id_cases)                  = extractBiomarkerProperties( [], [] );
    summarised.all_outer_PR(id_cases)                  = extractBiomarkerProperties( [], [] );
    
    summarised.all_inner_interTapering(id_cases)       = extractBiomarkerProperties( [], [] );
    summarised.all_outer_interTapering(id_cases)       = extractBiomarkerProperties( [], [] );

    summarised.all_inner_diam_atMid(id_cases)          = extractBiomarkerProperties( [], [] );
    summarised.all_outer_diam_atMid(id_cases)          = extractBiomarkerProperties( [], [] );
    summarised.all_wall_thickness_atMid(id_cases)      = extractBiomarkerProperties( [], [] );

    % Number of airways
    summarised.number_airways(id_cases)                = extractBiomarkerProperties( [], [] );
    summarised.all_number_airways(id_cases)            = extractBiomarkerProperties( [], [] );

    % Generation
    summarised.generation(id_cases)                    = extractBiomarkerProperties( [], [] );
    summarised.all_generation(id_cases)                = extractBiomarkerProperties( [], [] );
end