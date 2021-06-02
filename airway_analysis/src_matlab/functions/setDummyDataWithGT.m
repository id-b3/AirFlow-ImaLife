function [airways, vessels] = setDummyDataWithGT( airways, vessels )

    num_airways = numel(airways);

    for aa=1:num_airways

        airways(aa).hasGT = false;
        airways(aa).gt.id = -1;
        airways(aa).gt.distance = Inf;
        airways(aa).gt.airway_point_id = -1;
    end

    num_vessels = numel(vessels);

    for vv=1:num_vessels

        vessels(vv).hasGT = false;
        vessels(vv).gt.id = -1;
        vessels(vv).gt.distance = Inf;
        vessels(vv).gt.vessel_point_id = -1;
    end
end
