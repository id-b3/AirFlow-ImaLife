function [airways, vessels] = matchWithGT( gt, airways, vessels )


    debugVessels = false;
    debugAirways = false;

    %% COMPARE INDIVIDUAL MEASUREMENTS
    % find pairs between AIRWAYS and GT
    fprintf('\nPairing airways with ground truth (distance has to be smaller than airway radius according to GT)...\n');
    airways = matchAirwaysWithGT(gt, airways);
    
    % get ids of pired airways
    id_withGT = find( [airways(:).hasGT] );    % indices of airways that have a GT pair
    aux_gts   = [airways( id_withGT ).gt];
    
    try
        id_GTs    = [aux_gts.id];      % indices of GT airways that are paired
    catch
        id_GTs    = [];
    end        

    nPairs   = numel(id_withGT);
    
    fprintf(' + %d matching pairs found out of %d automatic airways (%.1f%%) and %d GT airways (%.1f%%)\n\n', ...
            nPairs, numel(airways), (nPairs/numel(airways))*100, numel(gt), (nPairs/numel(gt))*100 );


    % find pairs between VESSELS and GT
    fprintf('Pairing vessels with ground truth (distance has to be smaller than vessel radius according to GT)...\n');
    vessels = matchVesselsWithGT(gt, vessels);
    
    % get ids of paired vessels
    idV_withGT = find( [vessels(:).hasGT] );     % indices of vessels that have a GT pair
    aux_gts    = [vessels( idV_withGT ).gt];
    if isempty(aux_gts)
        idV_GTs = [];                 % if we are skipping vessel matching
    else
        idV_GTs    = aux_gts.id;      % indices of GT vessels that are paired
    end
    
    nvPairs   = numel(idV_withGT);
    fprintf(' + %d matching pairs found out of %d automatic vessels (%.1f%%) and %d GT vessels (%.1f%%)\n\n', ...
            nvPairs, numel(vessels), (nvPairs/numel(vessels))*100, numel(gt), (nvPairs/numel(gt))*100 );
    
    % plot 3d paired
    if false
        figure; hold on; axis equal;
        xlabel('Paired airways to GT');
        
        for id_airway = 1:numel(airways)
            
            id_gt = airways(id_airway).gt_id;
            
            if id_gt > 0
                
                % draw airway cenreline
                plot3( airways(id_airway).centreline(:,1), airways(id_airway).centreline(:,2), airways(id_airway).centreline(:,3), '-b');

                % draw GT airways centrepoint
                plot3(  gt(id_gt).airway_position(1),  gt(id_gt).airway_position(2),  gt(id_gt).airway_position(3), 'om');
                
                % draw airway centrepoint
%                plot3( airways(id_airway).midPoint(1), airways(id_airway).midPoint(2), airways(id_airway).midPoint(3), 'og');
                
                % draw airway-GT connection
                plot3( [airways(id_airway).midPoint(1) gt(id_gt).airway_position(1)], ...
                       [airways(id_airway).midPoint(2) gt(id_gt).airway_position(2)], ...
                       [airways(id_airway).midPoint(3) gt(id_gt).airway_position(3)], '-k');
                
            else
                plot3( airways(id_airway).centreline(:,1), airways(id_airway).centreline(:,2), airways(id_airway).centreline(:,3), '-c');
            end
        end
    end
    
    % histogram of distances
    if false
        figure; subplot(2,1,1);
        max_dist = max( [airways(id_withGT).gtDistance] );
        hist( [airways(id_withGT).gtDistance], 0:0.1:max_dist+0.1);
        xlabel('Distance between airway-GT pairs (mm)');
        
        subplot(2,1,2);
        max_dist = max( [vessels(idV_withGT).gtDistance] );
        hist( [vessels(idV_withGT).gtDistance], 0:0.1:max_dist+0.2);
        xlabel('Distance between vessel-GT pairs (mm)');
    end
    
    % plot vessel raddi information for airway-vessel pairs with GT
    if debugVessels
        id_withGT = find( [airways(:).vessel_id] > 0 );    % indices of airways that have a vessel pair

        nAirways = numel(id_withGT);
        aa = 0;
        
        while aa < nAirways
            
            ff = mod(aa, 25) + 1;
            
            aa = aa+1;
            
            aID = id_withGT(aa);
        
            if ff == 1
                figure('Name', 'Vessels from Paired airways');
            end

            subplot(5,5,ff); hold on;
            
            plot( airways(aID).vessel.localArea(:), '-r' );
            plot( airways(aID).vessel.localRadius(:).^2 * pi, '-g' );
            
%             medianArea = median(airways(aID).vessel.localRadius(:));
%             medianArea = medianArea^2 * pi;
%             
            plotWidth = numel(airways(aID).vessel.localRadius(:));
%             plot( [0 plotWidth], [medianArea medianArea], '--m' );
%             plot( [0 plotWidth], [airways(aID).vessel.area airways(aID).vessel.area], '--b' );
            
            vPoint = airways(aID).vesselPairPoint;
            plot( vPoint, airways(aID).vessel.localArea( vPoint ), 'ob')
            
            % if airway is paried with GT
            if airways(aID).gt_id > 0
                gtArea = airways(aID).gt.vessel_area;
                plot( [0 plotWidth], [gtArea gtArea], '-b' );
            end
            
            % if vessel is paried with its own GT (that info is not in airways(aa).vessel, so we have to find that on the main 'vessels' structure)
            vID = airways(aID).vessel_id;
            if vessels(vID).gt_id > 0
                gt_vessel_Area = vessels(vID).gt.vessel_area;
                plot( [0 plotWidth], [gt_vessel_Area gt_vessel_Area], '-m' );
                
                vPoint = vessels(vID).gtPairPoint;
                plot( vPoint, airways(aID).vessel.localArea( vPoint ), 'om');
            end
            
            xlabel(['airway: ' num2str(aID) ' (' num2str(airways(aID).gt_id) ') - vessel: ' num2str(vID) ' (' num2str(vessels(vID).gt_id) ')']);
            
            if ff == 1
%                 legend('area', 'radius', 'median', 'global', 'AAR measurement', 'airway GT', 'vessel GT', 'GT measurment');
                legend('area', 'non-smoothed', 'AAR measurement', 'airway GT', 'vessel GT', 'GT measurment');
            end
            
        end
    end    

    if debugAirways
        nAirways = numel(airways);
        
        for aID = 1:nAirways
            
            ff = mod(aID-1, 9) + 1;
        
            if ff == 1
                figure('Name', 'Airways');
            end

            subplot(3,3,ff); hold on;
            
            plot( airways(aID).inner_localRadius(:).^2 * pi, '-c' );
            plot( airways(aID).inner_localArea(:), '-g', 'lineWidth', 2 );
            
            plot( airways(aID).outer_localRadius(:).^2 * pi, '-c' );
            plot( airways(aID).outer_localArea(:), '-b', 'lineWidth', 2 );
            
            
%             medianArea = median(airways(aID).vessel.localRadius(:));
%             medianArea = medianArea^2 * pi;
%             
            plotWidth = numel(airways(aID).inner_localArea(:));
%             plot( [0 plotWidth], [medianArea medianArea], '--m' );
%             plot( [0 plotWidth], [airways(aID).vessel.area airways(aID).vessel.area], '--b' );
                       
            % if airway is paried with GT
            if airways(aID).gt_id > 0
                innerArea = airways(aID).gt.inner_area;
                outerArea = airways(aID).gt.outer_area;
                plot( [0 plotWidth], [innerArea innerArea], '-r' );
                plot( [0 plotWidth], [outerArea outerArea], '-m' );
            end
            
            xlabel(['airway: ' num2str(aID) ' (' num2str(airways(aID).gt_id) ')']);
            
            if ff == 1
%                 legend('area', 'radius', 'median', 'global', 'AAR measurement', 'airway GT', 'vessel GT', 'GT measurment');
                legend('lumen (non-smoothed)', 'lumen', 'outer (non-smoothed)', 'outer', 'lumen GT', 'outer GT');
            end
            
        end
    end   
    
    
    % plot radii information for ALL vessels paired with GT
    if false
        
        % get all teh indices
        idV_withGT = find( [vessels(:).gt_id] > 0 );     % indices of vessels that have a GT pair
        idV_GTs    = [vessels( idV_withGT ).gt_id];      % indices of GT vessels that are paired

    
        % we want to iterate over vessels that are paired to airways and that these airwyas are paried to GT
        nVessels = numel(idV_withGT);
        vv = 0;
        
        while vv < nVessels
            
            ff = mod(vv, 25) + 1;
            vv = vv+1;
        
            if ff == 1
                figure;
            end
            
            idV = idV_withGT(vv);
            
            subplot(5,5,ff); hold on;
            
            plot( vessels(idV).localArea(:), '-r' );
            plot( airways(aID).vessel.localRadius(:).^2 * pi, '-g' );
            
            medianArea = median(vessels(idV).localRadius(:));
            medianArea = medianArea^2 * pi;
            
            plot( [0 numel(vessels(idV).localRadius(:))], [medianArea medianArea], ':c' );
            plot( [0 numel(vessels(idV).localRadius(:))], [vessels(idV).area vessels(idV).area], ':b' );
            
            gtArea = gt( idV_GTs(vv) ).vessel_area;
            plot( [0 numel(vessels(idV).localRadius(:))], [gtArea gtArea], '-m' );
            
            vPoint = vessels(idV).gtPairPoint;
            plot( vPoint, vessels(idV).localArea( vPoint ), 'om')
            
            xlabel(['vessel: ' num2str(idV)]);
            
            if ff == 1
                legend('area', 'non-smoothed', 'median', 'global', 'GT', 'GT-point');
            end
            
        end
    end            
end


function airways = matchAirwaysWithGT(gt, airways)

    nA  = numel(airways);
    nGT = numel(gt);
    
    for aa = 1:nA
        
        airways(aa).hasGT = false;
        airways(aa).gt.id = -1;
        airways(aa).gt.distance = Inf;
        airways(aa).gt.airway_point_id = -1;
        
        for gg = 1:nGT

            [dist, point_id] = minDistance( gt(gg).airway_position, airways(aa).centreline );
            max_dist = gt(gg).outer.global_radius;
            
            % closer than max_distance & (closest point found or not point found)
            if dist < max_dist && dist < airways(aa).gt.distance
                airways(aa).gt.id = gg;
                airways(aa).gt.distance = dist;
                airways(aa).gt.airway_point_id = point_id;

                airways(aa).hasGT = true;
            end
        end
    end
end

function vessels = matchVesselsWithGT(gt, vessels)

    nV  = numel(vessels);
    nGT = numel(gt);
    
    for vv = 1:nV
        
        vessels(vv).hasGT = false;
        vessels(vv).gt.id = -1;
        vessels(vv).gt.distance = Inf;
        vessels(vv).gt.vessel_point_id = -1;
        
        vessel_midPoint = vessels(vv).centreline(round(end/2), :);
        vesselRadiusSearch = vessels(vv).length / 2;
        
        for gg = 1:nGT

            max_dist = gt(gg).vessel.global_radius;

            % check first if the gt is close enough to the vessel mid-point
            gt_dist = sqrt( sum( (vessel_midPoint - gt(gg).vessel_position).^2, 2) );

            % add gt radii (max_dist) and 10 mm just in case
            if gt_dist < vessels(vv).global_radius + vesselRadiusSearch + max_dist + 10
            
                [dist, point_id] = minDistance( gt(gg).vessel_position, vessels(vv).centreline );

                % closer than max_distance & (closest point found or not point found)
                if dist < max_dist && dist < vessels(vv).gt.distance
                    vessels(vv).gt.id = gg;
                    vessels(vv).gt.distance = dist;
                    vessels(vv).gt.vessel_point_id = point_id;

                    vessels(vv).hasGT = true;
                end
            end
            
        end
    end
end

function [min_dist, point_id] = minDistance( point, line )

    nP          = size(line,1);
    repPoint    = repmat(point, nP, 1);
    
    distV = (repPoint - line);
    dists = sqrt( sum(distV.^2, 2) );
    
    [min_dist, point_id] = min(dists);
end