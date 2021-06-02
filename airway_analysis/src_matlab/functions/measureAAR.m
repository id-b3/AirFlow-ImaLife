function [airways, vessels, files, extras] = measureAAR ( files, cfg, case_num, subjects )

    % remove warning for max number of iterations reached when fitting the function on radius measurements
    warning('off', 'curvefit:fit:iterationLimitReached')

    
    %% read original file to get voxel size
    ctInfo = dicominfo(files.ct);
    voxelSize = [ctInfo.PixelSpacing' ctInfo.SpacingBetweenSlices];
    imSize    = [ctInfo.Rows, ctInfo.Columns, ctInfo.NumberOfFrames];

    fprintf('\n ------ [ %s ] ------ \n', files.rootName );
    disp(cfg)
    fprintf(' +    ImSize: [%d %d %d]\n', imSize(:) );
    fprintf(' + VoxelSize: [%.4f %.4f %.4f]\n', voxelSize(:) );
    
    if cfg.do_normalisation
        
        normalising_factor = cfg.normalised_value / subjects.(cfg.normalised_strName)(case_num);
        
        normalising_factor_volume   = normalising_factor ^ (cfg.normalised_value_dim / 3) ;
        normalising_factor_area     = normalising_factor_volume ^ (2/3);
        normalising_factor_length   = normalising_factor_volume ^ (1/3);
        
        fprintf('\nUsing Normalisation...\n');
        fprintf(' + Subject %s: %.3f, normalising to %s: %.3f\n', cfg.normalised_strName, subjects.(cfg.normalised_strName)(case_num), cfg.normalised_strName, cfg.normalised_value);
        fprintf('   Normalising volume factor: %.3f\n', normalising_factor_volume);
        fprintf('   Normalising   area factor: %.3f\n', normalising_factor_area);
        fprintf('   Normalising length factor: %.3f\n\n', normalising_factor_length);
    else
        fprintf('\nNo Normalisation\n\n');
        normalising_factor_area = 1;
    end    
    
    if nargout >= 4
        extras.voxelSize                = voxelSize;
        extras.ctInfo                   = ctInfo;
        extras.imSize                   = imSize;
        extras.normalising_factor_area  = normalising_factor_area;
    end
    

    if false
        % OLD way, parsing the .m files
	% read centrelines (RUN THEM BEFORE CREATING THE STRUCTURE airway)
    	% notice centrelines are stored in voxel coordinates and not real coordiantes (voxel * voxel spacing)
        run(files.airways_centreline);
        airway_cl = airway;
        clear airway;

        run(files.vessels_centreline);
        vessel_cl = airway;
        clear airway;
    else
        % FASTER and EFFICIENT way, reading the .mat files created with preReadCentrelines()
        tmp_var = load(files.airways_centreline);
        airway_cl = tmp_var.airway;
        
        tmp_var = load(files.vessels_centreline);
        vessel_cl = tmp_var.airway;
    end
        

    % READ info by parsing files
    lumen_csv   = parseBranches( files.lumen );
    airway_csv  = parseBranches( files.wall );
    vessel_csv  = parseBranches( files.vessel );
    
    vessel_radius_csv = parseRadius( files.vessels_radii );
    inner_radius_csv  = parseRadius( files.airways_inner_radii );
    outer_radius_csv  = parseRadius( files.airways_outer_radii );
    
    % Put all data together in a nice way
    [vessels, airways] = organiseData( airway_cl, vessel_cl, lumen_csv, airway_csv, vessel_csv, inner_radius_csv, outer_radius_csv, vessel_radius_csv, case_num, voxelSize, normalising_factor_area, cfg );
    
    
    %% Some plots
    % draw centrepoints in 3D
    if false
        figure; hold on; axis equal

        % get mid point coordinates using the magic of arrayfunc
%         mP_x = arrayfun(@(x) x.midPoint(1), vessels);
%         mP_y = arrayfun(@(x) x.midPoint(2), vessels);
%         mP_z = arrayfun(@(x) x.midPoint(3), vessels);
%         plot3(mP_x, mP_y, mP_z, 'xr');

        mP_x = arrayfun(@(x) x.midPoint(1), airways);
        mP_y = arrayfun(@(x) x.midPoint(2), airways);
        mP_z = arrayfun(@(x) x.midPoint(3), airways);
        plot3(mP_x, mP_y, mP_z, 'ob');
        
        mP_x = arrayfun(@(x) x.airway_position(1), gt.airways);
        mP_y = arrayfun(@(x) x.airway_position(2), gt.airways);
        mP_z = arrayfun(@(x) x.airway_position(3), gt.airways);
        plot3(mP_x, mP_y, mP_z, 'om');
    end
    
    % plot area histograms
    if false
        maxValue = max([[airways(:).inner_area] [airways(:).outer_area] [vessels(:).area]]);
        xvalues = 0:2:ceil(maxValue);

        figure;
        subplot(3,1,1);
        [values, centres] = hist([airways(:).inner_area], xvalues);
        bar(centres, values, 'g');
        ylabel('outer border');
        xlabel('area (mm^2)');
        
        subplot(3,1,2);
        [values, centres] = hist([airways(:).outer_area], xvalues);
        bar(centres, values, 'b');
        ylabel('inner border (lumen)');
        xlabel('area (mm^2)');

        subplot(3,1,3);
        [values, centres] = hist([vessels(:).area], xvalues);
        bar(centres, values, 'r');
        ylabel('vessels');
        xlabel('area (mm^2)');
    end
    
    % plot radii histograms
    if false
        maxValue = max([[airways(:).inner_radius] [airways(:).outer_radius] [vessels(:).radius]]);
        xvalues = 0:0.25:ceil(maxValue);

        figure;
        subplot(3,1,1);
        [values, centres] = hist([airways(:).inner_radius], xvalues);
        bar(centres, values, 'g');
        ylabel('outer border');
        xlabel('radius (mm)');
        
        subplot(3,1,2);
        [values, centres] = hist([airways(:).outer_radius], xvalues);
        bar(centres, values, 'b');
        ylabel('inner border (lumen)');
        xlabel('radius (mm)');

        subplot(3,1,3);
        [values, centres] = hist([vessels(:).radius], xvalues);
        bar(centres, values, 'r');
        ylabel('vessels');
        xlabel('radius (mm)');
    end
    
    % plot radii for ALL airways
    if false
        
        nVessels = numel(vessels);
        vv = 0;
        
        while vv < nVessels
            
            ff = mod(vv, 25) + 1;
            vv = vv+1;
        
            if ff == 1
                figure;
            end
            
            subplot(5,5,ff); hold on;
            
            plot( vessels(vv).localArea(:), '-r' );
            plot( vessels(vv).localRadius(:), '-g' );
            
            medianVessel = median(vessels(vv).localRadius(:));
            medianVessel = medianVessel^2 * pi;
            
            plot( [0 numel(vessels(vv).localRadius(:))], [medianVessel medianVessel], '-m' );
            plot( [0 numel(vessels(vv).localRadius(:))], [vessels(vv).area vessels(vv).area], '-b' );
            
            xlabel(['vessel: ' num2str(vv)]);
            
            if ff == 1
                legend('area', 'radius', 'median', 'global');
            end
            
        end
    end
    
    %% ARTERY-airway pair
    fprintf('\nLooking for airway-artery pairs...\n');
    
    airways = matchBranches( airways, vessels, cfg );
    
    pairedAirways = find( [airways(:).isPaired] );

    nPairs   = numel( pairedAirways );
    nAirways = numel( airways );
    nVessels = numel( vessels );
    
    fprintf(' + %d pairs found (%.1f%%) out of %d\n\n', nPairs, (nPairs/nAirways)*100, nAirways );

    fprintf('Computing measurements...\n');
    
    [airways, vessels] = computeMeasurements( airways, vessels, cfg );
    
end


%% ------------------------------- AUXILIARY FUNCTIONS -------------------------------------------
function [vessels, airways] = organiseData( airway_cl, vessel_cl, lumen_csv, airway_csv, vessel_csv, inner_radius_csv, outer_radius_csv, vessel_radius_csv, case_num, voxelSize, normalising_factor_area, cfg)
                                        
    normalising_factor_length = sqrt( normalising_factor_area );

    fprintf('Organising all data\n');
    vessels = vessel_cl;
    
    x = -3:3;
    sigma = 2;
    kernel = exp(-x .^ 2 / (2 * sigma ^ 2));
    kernel = kernel / sum (kernel); % normalise

    fprintf(' + using [%s] gauss window with simga %.2f for smoothing local area cross-section\n', num2str(kernel, '%.3f '), sigma);
    
    for vv = 1:numel(vessels)
        if vessels(vv).id ~= vessel_csv.id(vv)
            error('ERROR vessel(vv).id is not the same than vessel_csv.id(vv) in organiseData()');
        else
            vessels(vv).original_id             = vessel_csv.id(vv);
            vessels(vv).global_radius           = vessel_csv.radius(vv) .* normalising_factor_length;
            vessels(vv).global_area             = vessel_csv.area(vv)   .* normalising_factor_area;
            vessels(vv).global_intensity        = vessel_csv.intensity(vv);
            vessels(vv).nSamples                = vessel_csv.nSamples(vv);
            
            % points is stored in voxel coordinates, centrelines are in normalised coordinates (mm)
            vessels(vv).centreline              = vessels(vv).point .* repmat(voxelSize, size(vessels(vv).point,1), 1) .* normalising_factor_length;

            vessels(vv).nPoints                 = size( vessels(vv).point, 1);
            
            % calculate total centreline length
            vessels(vv).length                  = getCentrelineLength( vessels(vv).centreline );

            vessels(vv).nonSmoothed_radius      = [vessel_radius_csv{vv}] .* normalising_factor_length;
            
            % OLD way
            vessels(vv).radius                  = paddedSmooth( vessels(vv).nonSmoothed_radius, kernel );
            
            % compute tapering and interpolated measurements
%             [vessels(vv).tapering_slope, vessels(vv).radius] = getTaperingSlope( vessels(vv).nonSmoothed_radius, vessels(vv).centreline );

            vessels(vv).area                    = radiusToArea( vessels(vv).radius ); % redundant
            
            vessels(vv).orientation             = getLocalOrientations( vessels(vv).centreline, cfg.orientationWidth );
            
            vessels(vv).case_num                = case_num;
        end
    end

    airways = airway_cl;
    
    for aa = 1:numel(airways)
        if ( airways(aa).id ~= airway_csv.id(aa) || airways(aa).id ~= lumen_csv.id(aa) )
            error('ERROR airways(aa).id is not the same than airway_csv.id(aa) or lumen_csv.id(aa) in organiseData()');
        else
            airways(aa).original_id                 = airway_csv.id(aa);
            airways(aa).inner.global_radius         = lumen_csv.radius(aa) .* normalising_factor_length;
            airways(aa).inner.global_area           = lumen_csv.area(aa)   .* normalising_factor_area;
            airways(aa).inner.global_intensity      = lumen_csv.intensity(aa);
            airways(aa).inner.nSamples              = lumen_csv.nSamples(aa);
            
            airways(aa).outer.global_radius         = airway_csv.radius(aa) .* normalising_factor_length;
            airways(aa).outer.global_area           = airway_csv.area(aa);
            airways(aa).outer.global_intensity      = airway_csv.intensity(aa);
            airways(aa).outer.nSamples              = airway_csv.nSamples(aa);
            
            airways(aa).inner.nonSmoothed_radius    = [inner_radius_csv{aa}] .* normalising_factor_length;
            airways(aa).outer.nonSmoothed_radius    = [outer_radius_csv{aa}] .* normalising_factor_length;
            
            % points is stored in voxel coordinates, centrelines are in normalised real-wrld coordinates (mm)
            airways(aa).centreline                  = airways(aa).point .* repmat(voxelSize, size(airways(aa).point,1), 1) .* normalising_factor_length;
            airways(aa).nPoints                     = size( airways(aa).point, 1);
            
            % calculate total centreline length
            airways(aa).length                      = getCentrelineLength( airways(aa).centreline );
            
            airways(aa).orientation                 = getLocalOrientations( airways(aa).centreline, cfg.orientationWidth );
            
            % compute tapering and interpolated radi measurements
%             [airways(aa).inner.tapering_slope, airways(aa).inner.radius] = getTaperingSlope( airways(aa).inner.nonSmoothed_radius, airways(aa).centreline );
%             [airways(aa).outer.tapering_slope, airways(aa).outer.radius] = getTaperingSlope( airways(aa).outer.nonSmoothed_radius, airways(aa).centreline );
%             [airways(aa).wall.tapering_slope,  airways(aa).wall.radius]  = getTaperingSlope( airways(aa).outer.nonSmoothed_radius - airways(aa).inner.nonSmoothed_radius, airways(aa).centreline );
            
            % OLD version
            airways(aa).inner.radius                = paddedSmooth( airways(aa).inner.nonSmoothed_radius, kernel );
            airways(aa).outer.radius                = paddedSmooth( airways(aa).outer.nonSmoothed_radius, kernel );

            airways(aa).inner.area                  = radiusToArea( airways(aa).inner.radius );
            airways(aa).outer.area                  = radiusToArea( airways(aa).outer.radius );
            
            airways(aa).wall.global_area            = airways(aa).outer.global_area - airways(aa).inner.global_area;
            airways(aa).wall.global_areaPer         = airways(aa).wall.global_area / airways(aa).outer.global_area * 100;
            
            airways(aa).wall.global_thickness       = airways(aa).outer.global_radius - airways(aa).inner.global_radius;
            airways(aa).wall.global_thicknessPer    = airways(aa).wall.global_thickness / airways(aa).outer.global_radius * 100;
            
            airways(aa).wall.thickness              = airways(aa).outer.radius - airways(aa).inner.radius;
            airways(aa).wall.area                   = airways(aa).outer.area - airways(aa).inner.area;
            
            airways(aa).wall.areaPer                = airways(aa).wall.area ./ airways(aa).outer.area .*100;
            
            airways(aa).case_num = case_num;
        end
    end
    
    fprintf(' + %d airways and %d vessels parsed\n', numel(airways), numel(vessels));
    
    % use pechin id to preserve parent-children connectivity
    airways( [airways.pechin_id] ) = airways;
    
    % find new ID for all airways
    cum_id = 0; nAirways = numel(airways);
    for aa = 1:nAirways
        if isempty( airways(aa).outer ) ...
                || isempty(airways(aa).inner.nonSmoothed_radius) || isempty(airways(aa).outer.nonSmoothed_radius) ...
                || airways(aa).inner.global_radius <= 0          || airways(aa).outer.global_radius <= 0 ...
                || airways(aa).length <= cfg.min_airway_length
                
            newIDs(aa) = NaN;
        else
            cum_id = cum_id + 1;
            newIDs(aa) = cum_id;
        end
    end

    % replace IDs from own, children and parent
    for aa = 1:nAirways
        airways(aa).id = newIDs(aa);
        
        if airways(aa).parent > 0
            airways(aa).parent = newIDs(airways(aa).parent);
        end
        
        airways(aa).children = newIDs(airways(aa).children);
    end
    
    airways = airways( newIDs > 0 ); % drop useless airways form the array
    
   
    % old ./be using vessels created vessels id starting at 0 instead of 1.
    if vessels(1).id == 0 || vessels(1).pechin_id == 0
        warning('First vessel ID is 0, shifting vessels id by 1');
        for vv = 1:numel(vessels)
            vessels(vv).id = vessels(vv).id + 1;
            vessels(vv).pechin_id = vessels(vv).pechin_id + 1;
            
            vessels(vv).parent = vessels(vv).parent + 1;
            vessels(vv).children = vessels(vv).children + 1;
        end
    end
    
    % use pechin id to preserve parent-children connectivity
    vessels( [vessels.pechin_id] ) = deal(vessels);

    % find new ID for all vessels
    cum_id = 0; nVessels = numel(vessels); newIDs = [];
    for vv = 1:nVessels
        if isempty(vessels(vv).global_radius) || vessels(vv).global_radius < 0 ...
                || vessels(vv).length <= cfg.min_vessel_length
            newIDs(vv) = NaN;
        else
            cum_id = cum_id + 1;
            newIDs(vv) = cum_id;
        end
    end

    % replace IDs from own, children and parent
    for vv = 1:nVessels
        vessels(vv).id = newIDs(vv);
        
        if vessels(vv).parent > 0
            try
                vessels(vv).parent = newIDs(vessels(vv).parent);
            catch
                warning('vessels(vv).parent is out of range -> connectivity is removed');
                vessels(vv).parent = NaN;
            end                
        end
        
        for cc = 1:length(vessels(vv).children)
            try
                vessels(vv).children(cc) = newIDs(vessels(vv).children(cc));
            catch
                warning('vessels(vv).children(cc) is out of range -> connectivity is removed');
                vessels(vv).children(cc) = NaN;
            end                
        end
    end
    
    vessels = vessels( newIDs > 0 ); % drop useless airways form the array
    
    fprintf(' + %d airways and %d vessels remainging after cleaning\n\n', numel(airways), numel(vessels));

end

function airways = matchBranches(airways, vessels, cfg)

    pair_empty.similarity          = -1;
    pair_empty.similarity_ad       = -1;
    pair_empty.similarity_ratio    = -1;
    pair_empty.similarity_angle    = -1;
    pair_empty.similarity_dist     = -1;
    pair_empty.similarity_centre   = -1;

    pair_empty.dist_to_centre      = -1;
    
    pair_empty.vessel_id           = -1;
    pair_empty.vessel_point_id     = -1;
    pair_empty.airway_point_id     = -1;

    pair_empty.borderDistance      = Inf;
    pair_empty.angle               = Inf;

    for aa = 1:numel(airways)

        airwaysAA = airways(aa);

        % select plausible vessels for speed up distance search
        c_vessels_id = select_closeby_vessels( airwaysAA, vessels );
        c_vessels    = vessels(c_vessels_id);
        
        % initialise pair
        isPaired = false;
        pair = pair_empty;
        
        % list of airway points that are candidate to get matched
        nPoints = size( airways(aa).point, 1 );
        centrePoint = (nPoints/2) + 0.5;

        %% All candidate points with padding and step
%         step    = cfg.airwaysPairingStep;
%         padding = cfg.airwaysPairingPadding;
%         if nPoints > step + (padding*2)
%             point_candidates = 1+padding:step:nPoints-padding;
%         else
%             point_candidates = round(nPoints/2);
%         end

        %% All candidate points
%          point_candidates = 1:nPoints;
        
        %% All candidate points, starting from the centre
        % sort points from the centre to the border
        sorted_cps = 1:nPoints;
        sorted_cps = abs(sorted_cps - centrePoint);
        [~, point_candidates] = sort( sorted_cps, 'ascend' );
        
        %% only try to match the middle point 
%         point_candidates = round(nPoints/2);
        
%         s_centre_vec = gausswin( numel(point_candidates), 1.5 );

        % position in the airway centreline
        for pAirway = point_candidates
            
            if ~isPaired % stop finding candiates after the first pairing is made!

                % higher score for points in the centre (halfway) of the airway
%                 s_centre = 1 - (abs(centrePoint - pAirway) / centrePoint);

%                 s_centre = s_centre_vec(pp); % gaussian weighting

                s_centre = 1;

                for cv = 1:numel(c_vessels) % for all plausible vessels (for this point)

                    % find closest vessel point
                    [dist, pVessel] = minDistance( airwaysAA.centreline(pAirway,:), c_vessels(cv).centreline );

                    % only consider vessels when the closest point is not an extreme
                    if pVessel ~= 1 || pVessel ~= c_vessels(cv).nPoints

                        % measure distance between outer borders of vessel and airway
                        borderDist = dist - airwaysAA.outer.radius(pAirway) - c_vessels(cv).radius(pVessel);

                        if borderDist <= cfg.max_borderDist

                            theta = getAngle( c_vessels(cv).orientation(pVessel,:), airwaysAA.orientation(pAirway,:) );

                            s_angle = (90 - theta) / 90; % 0 for perpendicular, 1 for parallel

                            s_dist  = (cfg.max_borderDist - max(borderDist, 0)) / cfg.max_borderDist; % 1 for touching, 0 for anything over max_dist

                            s_ratio = airwaysAA.outer.radius(pAirway) / c_vessels(cv).radius(pVessel);
                            s_ratio = min( s_ratio, 1/s_ratio ); % 1 for identical sizes
%                             s_ratio = sqrt(s_ratio);
                            s_ratio = (s_ratio)^(1/3);
                            
%                             s_ratio = 1;

                            similarity_score = s_angle * s_dist * s_centre * s_ratio;
                            similarity_ad    = s_angle * s_dist * s_centre;

                            if similarity_score > pair.similarity && similarity_score >= cfg.min_similarity

                                isPaired                 = true;

                                pair.similarity          = similarity_score;
                                pair.similarity_ad       = similarity_ad;
                                pair.similarity_ratio    = s_ratio;
                                pair.similarity_angle    = s_angle;
                                pair.similarity_dist     = s_dist;
                                pair.similarity_centre   = s_centre;
                                
                                pair.dist_to_centre      = abs(pAirway - centrePoint); % for debugging purposes

                                pair.vessel_id           = c_vessels_id(cv);
                                pair.vessel_point_id     = pVessel;
                                pair.airway_point_id     = pAirway;

                                pair.borderDistance      = borderDist;
                                pair.angle               = theta;
                            end
                        end
                    end
                end
            end % stop iterating after first pairing (cehck all vessels for that point thought)
        end
        
        airways(aa).isPaired = isPaired;
        airways(aa).pair = pair;
        
        clear pair;
        % ---------------------------------------------------------------------
        
        % chose the best pair from the best pairing vessel (NEW METHOD) -------
%         if isPaired
%             % find sum of weights of each vessel and pick the highest one
%             candidate_vessels = unique([pair(:).vessel_id]);
%             pair_similarities = [pair(:).similarity];
%             for cc = 1:numel(candidate_vessels)
%                sum_weight(cc) = sum(pair_similarities( [pair(:).vessel_id] == candidate_vessels(cc) ));
%             end
% 
%             [~, v_id] = max(sum_weight);
% 
%             % find the best pair (USING size ratio) from the vessel with highest sum of similarities
%             pairs_selected = pair( [pair(:).vessel_id] ==  candidate_vessels(v_id) );
% 
%             [~, p_id] = max([pairs_selected.similarity]);
% 
%             airways(aa).pair = pairs_selected(p_id);
%             
%         else
%             airways(aa).pair = pair_empty;
%         end
%         clear pair pairs_selected v_id p_id candidate_vessels sum_weight;
        % ---------------------
        
    end
end

function close_vessels = select_closeby_vessels( airway, vessels )

    close_vessels = [];
    
    airwayPoint  = airway.centreline(round(end/2),:);
    airwayRadius = airway.length / 2;
    airwayR      = airway.outer.global_radius;
    
    for vv = 1:numel(vessels)
        
        vesselPoint  = vessels(vv).centreline(round(end/2),:);
        vesselRadius = vessels(vv).length / 2;
        vesselR      = vessels(vv).global_radius;
        
        av_dist = sqrt( sum( (vesselPoint - airwayPoint).^2, 2) );
        
        % add 10 mm plus both radii
        if av_dist < vesselRadius + airwayRadius + airwayR + vesselR + 10 
            close_vessels(end+1) = vv;
        end
    end

end

function [airways, vessels] = computeMeasurements(airways, vessels, cfg)
   
% this is done in organiseData()
    for id_vessel = 1:numel(vessels)
        
        % area tapering
        [vessels(id_vessel).tapering_area, vessels(id_vessel).taperingPerc_area] = ...
            getTapering( radiusToArea( vessels(id_vessel).nonSmoothed_radius ), vessels(id_vessel).centreline, cfg.robustFittingForTapering );
        
        % diameter tapering
        [vessels(id_vessel).tapering_diam, vessels(id_vessel).taperingPerc_diam] = ...
            getTapering( 2 .* vessels(id_vessel).nonSmoothed_radius, vessels(id_vessel).centreline, cfg.robustFittingForTapering );
    end
    
    for id_airway = 1:numel(airways)

        % -- AIRWAY-ARTERY measurements
        if airways(id_airway).isPaired
            
            id_vessel   = airways(id_airway).pair.vessel_id;
            vesselPoint = airways(id_airway).pair.vessel_point_id;
            airwayPoint = airways(id_airway).pair.airway_point_id;
            
            % AAR using radii
            airways(id_airway).inner.AAR_radial         = airways(id_airway).inner.radius( airwayPoint ) ./ vessels(id_vessel).radius( vesselPoint );
            airways(id_airway).outer.AAR_radial         = airways(id_airway).outer.radius( airwayPoint ) ./ vessels(id_vessel).radius( vesselPoint );

            % AAR using area
            airways(id_airway).inner.AAR_area           = airways(id_airway).inner.area( airwayPoint ) ./ vessels(id_vessel).area( vesselPoint );
            airways(id_airway).outer.AAR_area           = airways(id_airway).outer.area( airwayPoint ) ./ vessels(id_vessel).area( vesselPoint );
            
            % WAR wall / vessel
            airways(id_airway).wall.WAR_area            = airways(id_airway).wall.area( airwayPoint )      ./ vessels(id_vessel).area( vesselPoint );
            airways(id_airway).wall.WAR_radial          = airways(id_airway).wall.thickness( airwayPoint ) ./ vessels(id_vessel).radius( vesselPoint );
            
        else
            airways(id_airway).inner.AAR_radial         = NaN;
            airways(id_airway).outer.AAR_radial         = NaN;
            
            airways(id_airway).inner.AAR_area           = NaN;
            airways(id_airway).outer.AAR_area           = NaN;
            
            airways(id_airway).wall.WAR_area            = NaN;
            airways(id_airway).wall.WAR_radial          = NaN;
        end
        
        % -- PARENT-CHILD measurements
        if airways(id_airway).parent > 0
            
            airways(id_airway).outer.parent_ratio_radius  = (airways(id_airway).outer.global_radius / airways(airways(id_airway).parent).outer.global_radius);
            airways(id_airway).inner.parent_ratio_radius  = (airways(id_airway).inner.global_radius / airways(airways(id_airway).parent).inner.global_radius);
            
            airways(id_airway).outer.parent_ratio_area    = (airways(id_airway).outer.global_area / airways(airways(id_airway).parent).outer.global_area);
            airways(id_airway).inner.parent_ratio_area    = (airways(id_airway).inner.global_area / airways(airways(id_airway).parent).inner.global_area);
        else
            
            airways(id_airway).outer.parent_ratio_radius  = NaN;
            airways(id_airway).inner.parent_ratio_radius  = NaN;

            airways(id_airway).outer.parent_ratio_area    = NaN;
            airways(id_airway).inner.parent_ratio_area    = NaN;
        end
        
        % TAPERING measurements - AREA
        [airways(id_airway).inner.tapering_area, airways(id_airway).inner.taperingPerc_area] = ...
                getTapering( radiusToArea( airways(id_airway).inner.nonSmoothed_radius ), airways(id_airway).centreline, cfg.robustFittingForTapering );
            
        [airways(id_airway).outer.tapering_area, airways(id_airway).outer.taperingPerc_area] = ...
                getTapering( radiusToArea( airways(id_airway).outer.nonSmoothed_radius ), airways(id_airway).centreline, cfg.robustFittingForTapering );

        [airways(id_airway).wall.tapering_area, airways(id_airway).wall.taperingPerc_area] = ...
                getTapering( radiusToArea( airways(id_airway).outer.nonSmoothed_radius - airways(id_airway).inner.nonSmoothed_radius ), airways(id_airway).centreline, cfg.robustFittingForTapering );
            
            
        % TAPERING measurements - Diameter
        [airways(id_airway).inner.tapering_diam, airways(id_airway).inner.taperingPerc_diam] = ...
                getTapering( 2 .* airways(id_airway).inner.nonSmoothed_radius, airways(id_airway).centreline, cfg.robustFittingForTapering );
            
        [airways(id_airway).outer.tapering_diam, airways(id_airway).outer.taperingPerc_diam] = ...
                getTapering( 2 .* ( airways(id_airway).outer.nonSmoothed_radius ), airways(id_airway).centreline, cfg.robustFittingForTapering );

        [airways(id_airway).wall.tapering_diam, airways(id_airway).wall.taperingPerc_diam] = ...
                getTapering( 2 .* ( airways(id_airway).outer.nonSmoothed_radius - airways(id_airway).inner.nonSmoothed_radius ), airways(id_airway).centreline, cfg.robustFittingForTapering );
            
    end

end

function [tapering, tapering_percentage, interpolatedValues] = getTapering( yData, centreline, str_use_robust )

    if numel(yData) < 2
        tapering = NaN;
        tapering_percentage = NaN;
        interpolatedValues = yData;
        return
    end

    % accumlated distance between centreline points
    xx = NaN( 1, numel(yData)); xx(1) = 0;
    for pp = 2:numel(xx)
        xx(pp) = xx(pp-1) + norm( centreline(pp,:) - centreline(pp - 1,:) );
    end

    % fitting
    myFit = fit(xx', yData', 'poly1', 'Robust', str_use_robust);
    
    % These 2 methods are equivalent.
    if false
        branchLength = xx(end);
        
        % get interpolated yData at start and end according to fit
        tmp_points = polyval([myFit.p1 myFit.p2], [0 branchLength]);
        vStart  = tmp_points(1);
        vEnd    = tmp_points(2);

        % reduction (in absolute value) per mm
        tapering = (vStart - vEnd) / branchLength;

        % percentage reduction per mm
        tapering_percentage = (((vStart - vEnd) / vStart) / branchLength) * 100;
    else
        tapering = -myFit.p1;
        tapering_percentage = (-myFit.p1 / myFit.p2) * 100;
    end
        

    if nargout > 2
        % Obtain interpolated radi measurements using the fitted function
        interpolatedValues = polyval([myFit.p1 myFit.p2], xx);
    end

    if false
        interpolatedValues = polyval([myFit.p1 myFit.p2], xx);
        
        figure; hold on;
        plot(xx, yData, 'ro');
        plot(xx, interpolatedValues, 'g-');
    end
end

function [min_dist, point_id] = minDistance( point, line )

    nP = size(line,1);
    
    repPoint     = repmat(point, nP, 1);
%     repVoxelSize = repmat(voxelSize, nP, 1);
    
    distV = (repPoint - line); % ./ repVoxelSize;
    dists = sqrt( sum(distV.^2, 2) );
    
    [min_dist, point_id] = min(dists);

end

function theta = getAngle (a, b)

    vTheta(1) = acos( dot( a, b) );
    vTheta(2) = acos( dot(-a, b) );
    vTheta(3) = acos( dot( a,-b) );
    vTheta(4) = acos( dot(-a,-b) );
    
    theta = min(vTheta) * (180/pi);

end            

function output = parseBranches ( file_name )

    fprintf('Reading %s...\n', file_name);
    fileID = fopen(file_name);
%     [info_lumen, nCharacters ] = textscan(fileID, '%d %d %f %f %d %f %f %f %f %f %f %f %f %f', 'delimiter', ',', 'HeaderLines', 1 );
    [info_branch, nCharacters ] = textscan(fileID, '%d %d %f %f %d', 'delimiter', ',', 'HeaderLines', 1 );
    fclose(fileID);

    nLumen = size( info_branch{1}, 1 );
    fprintf(' + Read %d branches with %d characters\n\n', nLumen, nCharacters);

    % IN THE OLD APPRAOCH: branch, generation, radius, intensity, nSamples, midPoint_x, midPoint_y, midPoint_z, firstPoint_x, firstPoint_y, firstPoint_z, lastPoint_x, lastPoint_y, lastPoint_z, 
    % branch, generation, radius, intensity, nSamples 
    output.id            = info_branch{1};
    output.generation    = info_branch{2};
    output.radius        = info_branch{3};
    output.intensity     = info_branch{4};
    output.nSamples       = info_branch{5};

    output.area          = pi .* output.radius.^2;

%     output.midPoint      = [info_lumen{6:8}];
%     output.firstPoint    = [info_lumen{9:11}];
%     output.lastPoint     = [info_lumen{12:14}];
% 
%     ori_tmp   = output.lastPoint - output.firstPoint;
%     ori_norm = sqrt( sum( ori_tmp.^2, 2 ) );
%     ori_norm( ori_norm == 0 ) = 1; % patch to overcome rows with zero norm
%     output.orientation = bsxfun( @rdivide, ori_tmp, ori_norm ); % divide by norm
end

function output = parseRadius ( file_name )

    fprintf('Reading %s...\n', file_name);
    fileID = fopen(file_name);
    
    % drop header line
    str_line = fgetl( fileID );

    % get first branch info
    str_line = fgetl( fileID );
    
    %iterate remaining lines
    br = 0;
    while ischar(str_line)
        br = br + 1;

        num_line = str2num( str_line );
        output{br} = num_line(2:end);
        
        str_line = fgetl( fileID );
    end
    
    %     [info_branch, nCharacters ] = textscan(fileID, '%f', 'delimiter', ',', 'HeaderLines', 1 );
    fclose(fileID);
    
    nMeasurements = sum([output{:}] > 0);
    
    fprintf(' + Read %d radius measurments for %d branches\n\n', nMeasurements, br);
end

function length = getCentrelineLength( points )

    length = 0;
   
    nPoints = size(points, 1);
    
    for pp = 2:nPoints
       local_dist = norm( points(pp, :) - points(pp-1, :) );
       length = length + local_dist;
    end
end

function smoothed = paddedSmooth( data, filter )
% filter has to contain odd #elements

   if numel(data) < numel(filter)
       smoothed = data;
       return
   end

   lengthF = numel(filter);
   middleF = (lengthF + 1) /2;
   
   for ii = 0:(middleF-2)
       tmp_filter = filter( middleF-ii:end );
       tmp_filter = tmp_filter ./ sum( tmp_filter );
      
       left(ii+1) = sum( data(1:middleF+ii) .* tmp_filter );
   end
   
   middle = conv( data, filter, 'valid' );
   
   for ii = 0:(middleF-2)
       tmp_filter = filter( 1:middleF+ii );
       tmp_filter = tmp_filter ./ sum( tmp_filter );
      
       right(middleF-ii-1) = sum( data(end-middleF-ii+1:end) .* tmp_filter );
   end
   
   smoothed = [left middle right];

end

function ori = getLocalOrientations( points, width )

    nPoints = size(points,1);
    
    ori = zeros(nPoints,3); % pre-allocate
    
    for pp = 1:nPoints
        
        sumLengthLeft = 0;
        sumLengthRight = 0;
        
        pl = pp;
        pr = pp;
        
%         left = max(1, pp - width);
%         right = min(nPoints, pp + width);
        
        % while there are points left and we haven;t used reach far enough
        while pl > 1 && sumLengthLeft < width / 2;
            local_dist = norm( points(pl, :) - points(pl-1, :) );
            sumLengthLeft = sumLengthLeft + local_dist;
            pl = pl - 1;
        end
            
        while pr < nPoints-1 && sumLengthRight < width / 2;
            local_dist = norm( points(pr, :) - points(pr+1, :) );
            sumLengthRight = sumLengthRight + local_dist;
            pr = pr + 1;
        end
            
        
        oriTMP  = points(pr, :) - points(pl, :);
        oriNorm = norm(oriTMP);
        if oriNorm > 0
           ori(pp,:) = oriTMP ./ norm(oriTMP);
        end
    end
    
end

function diam = areaToDiam( area )
    diam = 2 .* sqrt(area ./ pi);
end

function radius = areaToRadius( area )
    radius = sqrt(area ./ pi);
end

function area = radiusToArea( radius )
    area = pi .* (radius.^2);
end
