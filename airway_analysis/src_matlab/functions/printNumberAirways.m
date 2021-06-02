function printNumberAirways( data, id_images_processed )

    nCT = numel(id_images_processed);

    airways = [data(:).airways];
    vessels = [data(:).vessels];

    nAirways = numel( airways );
    nVessels = numel( vessels );
    
    nPairedAirways = sum( [airways.isPaired] );

    fprintf('\n\n --------------- TOTAL (%d CTs)----------------------\n', nCT);
    fprintf(' ++ Total airways: %d (%.1f x CT) | Total vessels: %d (%.1f x CT) ++\n', nAirways, nAirways/nCT, nVessels, nVessels/nCT);
    fprintf(' o Paired airways: %d (%.1f x CT) / (%.1f%% of airways)\n', nPairedAirways, nPairedAirways/nCT, nPairedAirways/nAirways*100 );
   
end