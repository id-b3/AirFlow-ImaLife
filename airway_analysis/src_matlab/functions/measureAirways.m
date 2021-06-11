function [airways] = measureAirways ( files, cfg, case_num )

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
    
    if false
        % OLD way, parsing the .m files
	% read centrelines (RUN THEM BEFORE CREATING THE STRUCTURE airway)
    	% notice centrelines are stored in voxel coordinates and not real coordiantes (voxel * voxel spacing)
        run(files.airways_centreline);
        airway_cl = airway;
        clear airway;
    else
        % FASTER and EFFICIENT way, reading the .mat files created with preReadCentrelines()
        tmp_var = load(files.airways_centreline);
        airway_cl = tmp_var.airway;
    end
        

    % READ info by parsing files
    lumen_csv  = parseBranches( files.lumen );
    airway_csv = parseBranches( files.wall );
    
    inner_radius_csv = parseRadius( files.airways_inner_radii );
    outer_radius_csv = parseRadius( files.airways_outer_radii );
    
    % Put all data together in a nice way
    [airways] = organiseData( airway_cl, lumen_csv, airway_csv, inner_radius_csv, outer_radius_csv, case_num, voxelSize, cfg );
   
    fprintf('Computing measurements...\n');

    [airways] = computeMeasurements( airways, cfg );


    
    %% Some plots
    % draw centrepoints in 3D
    if false
        figure; hold on; axis equal

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
        maxValue = max([[airways(:).inner_area] [airways(:).outer_area]]);
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
    end
    
    % plot radii histograms
    if false
        maxValue = max([[airways(:).inner_radius] [airways(:).outer_radius]]);
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
    end
end


%% ------------------------------- AUXILIARY FUNCTIONS -------------------------------------------
function [airways] = organiseData( airway_cl, lumen_csv, airway_csv, inner_radius_csv, outer_radius_csv, case_num, voxelSize, cfg )
                                        
    fprintf('Organising all data\n');
    
    x = -3:3; %Done
    sigma = 2; %Done
    kernel = exp(-x .^ 2 / (2 * sigma ^ 2)); %Done
    kernel = kernel / sum (kernel); % normalise Done

    fprintf(' + using [%s] gauss window with simga %.2f for smoothing local area cross-section\n', num2str(kernel, '%.3f '), sigma);
    
    airways = airway_cl;
    
    for aa = 1:numel(airways)
        if ( airways(aa).id ~= airway_csv.id(aa) || airways(aa).id ~= lumen_csv.id(aa) )
            error('ERROR airways(aa).id is not the same than airway_csv.id(aa) or lumen_csv.id(aa) in organiseData()');
        else
            airways(aa).original_id                 = airway_csv.id(aa);
            airways(aa).inner.global_radius         = lumen_csv.radius(aa);
            airways(aa).inner.global_area           = lumen_csv.area(aa);
            airways(aa).inner.global_intensity      = lumen_csv.intensity(aa);
            airways(aa).inner.nSamples              = lumen_csv.nSamples(aa);
            
            airways(aa).outer.global_radius         = airway_csv.radius(aa);
            airways(aa).outer.global_area           = airway_csv.area(aa);
            airways(aa).outer.global_intensity      = airway_csv.intensity(aa);
            airways(aa).outer.nSamples              = airway_csv.nSamples(aa);
            
            airways(aa).inner.nonSmoothed_radius    = [inner_radius_csv{aa}];
            airways(aa).outer.nonSmoothed_radius    = [outer_radius_csv{aa}];
            
            % points is stored in voxel coordinates, centrelines are in normalised real-wrld coordinates (mm)
            airways(aa).centreline                  = airways(aa).point .* repmat(voxelSize, size(airways(aa).point,1), 1);
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

	    airways(aa).isPaired = false;
        end
    end
    
    fprintf(' + %d airways parsed\n', numel(airways));
    
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
    
    fprintf(' + %d airways remainging after cleaning\n\n', numel(airways));
end


function [airways] = computeMeasurements( airways, cfg )
   
% this is done in organiseData()
    for id_airway = 1:numel(airways)
        
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
