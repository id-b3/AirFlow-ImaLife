function [biomarkers, stats] = getAllMeasurements( airways_all, idGroup1, idGroup2, idAll, cfg_summarising )

    nGenerationGroups       = numel(cfg_summarising.generation_limits)-1;
    nLumenSizes             = numel(cfg_summarising.lumen_dimension_limits)-1;
    nOuterSizes             = numel(cfg_summarising.outer_dimension_limits)-1;
    nArterySizes            = numel(cfg_summarising.artery_dimension_limits)-1;

    fprintf('\n Obtaining biomarkers ...\n' );    

    % Prepare data
    airways_paired      = airways_all([airways_all(:).isPaired]);
    
    
    % preallocate
    summarised                      = emptyBiomarkerStruct( idAll );
    summarisedPerGeneration         = repmat( emptyBiomarkerStruct( idAll ), max(cfg_summarising.generations), 1 );
    summarisedPerGenerationGroup    = repmat( emptyBiomarkerStruct( idAll ), nGenerationGroups, 1 );
    summarisedPerArterySize         = repmat( emptyBiomarkerStruct( idAll ), nArterySizes, 1 );
    summarisedPerLumenSize          = repmat( emptyBiomarkerStruct( idAll ), nLumenSizes, 1 );
    summarisedPerOuterSize          = repmat( emptyBiomarkerStruct( idAll ), nOuterSizes, 1 );

    % Compute all biomarkers per patient we are interested on
    for cc = idAll

        ids_paired = [airways_paired(:).cases] == cc;
        ids_all    = [airways_all(:).cases] == cc;
        
        summarised = summariseAllBiomarkers( summarised, cc, airways_all, ids_all, airways_paired, ids_paired);
        

        % Biomarkers per generation
        for gg = cfg_summarising.generations;

            % all paired airways from a specific generation
            ids_paired = [airways_paired(:).cases] == cc & [airways_paired(:).airway_generation] == gg;
            ids_all    = [airways_all(:).cases]    == cc & [airways_all(:).airway_generation]    == gg;
            
            summarisedPerGeneration(gg) = summariseAllBiomarkers( summarisedPerGeneration(gg), cc, airways_all, ids_all, airways_paired, ids_paired);
        end

        % biomarkes per generation groups
        for gg = 1:nGenerationGroups;

            min_gen = cfg_summarising.generation_limits(gg);
            max_gen = cfg_summarising.generation_limits(gg+1);

            ids_paired = [airways_paired(:).cases] == cc & ...
                         [airways_paired(:).airway_generation] >= min_gen & ...
                           [airways_paired(:).airway_generation] <  max_gen; 

            ids_all     = [airways_all(:).cases] == cc & ...
                          [airways_all(:).airway_generation] >= min_gen & ...
                          [airways_all(:).airway_generation] <  max_gen; 
                       
            summarisedPerGenerationGroup(gg) = summariseAllBiomarkers( summarisedPerGenerationGroup(gg), cc, airways_all, ids_all, airways_paired, ids_paired);
        end

        % --- -- Biomarkers grouped per artery dimension -- ---
        for aa = 1:nArterySizes;

            min_artery = cfg_summarising.artery_dimension_limits(aa);
            max_artery = cfg_summarising.artery_dimension_limits(aa+1);

            ids_paired = [airways_paired(:).cases] == cc & ...
                         [airways_paired(:).airway_vessel_diam] >= min_artery & ...
                         [airways_paired(:).airway_vessel_diam] <  max_artery;
                       
            ids_all    = [airways_all(:).cases] == cc & ...
                         [airways_all(:).airway_vessel_diam] >= min_artery & ...
                         [airways_all(:).airway_vessel_diam] <  max_artery;
                       
            % it makes no sense to compute the all airway measurements, as only paired airways will fall in this group, but the code is nicer this way...
            summarisedPerArterySize(aa) = summariseAllBiomarkers( summarisedPerArterySize(aa), cc, airways_all, ids_all, airways_paired, ids_paired);
            
        end            

        % --- -- Biomarkers grouped per lumen dimension -- ---
        for aa = 1:nLumenSizes;

            min_airway = cfg_summarising.lumen_dimension_limits(aa);
            max_airway = cfg_summarising.lumen_dimension_limits(aa+1);

            ids_paired =  [airways_paired(:).cases] == cc & ...
                          [airways_paired(:).airway_inner_diam] >= min_airway & ...
                          [airways_paired(:).airway_inner_diam] <  max_airway;
                            
            ids_all =  [airways_all(:).cases] == cc & ...
                       [airways_all(:).airway_inner_diam] >= min_airway & ...
                       [airways_all(:).airway_inner_diam] <  max_airway;
                            
            summarisedPerLumenSize(aa) = summariseAllBiomarkers( summarisedPerLumenSize(aa) , cc, airways_all, ids_all, airways_paired, ids_paired);
        end                

        % --- -- Biomarkers grouped per outer dimension -- ---
        for aa = 1:nOuterSizes;
            min_airway = cfg_summarising.outer_dimension_limits(aa);
            max_airway = cfg_summarising.outer_dimension_limits(aa+1);

            ids_paired =  [airways_paired(:).cases] == cc & ...
                          [airways_paired(:).airway_outer_diam] >= min_airway & ...
                          [airways_paired(:).airway_outer_diam] <  max_airway;
                            
            ids_all =  [airways_all(:).cases] == cc & ...
                       [airways_all(:).airway_outer_diam] >= min_airway & ...
                       [airways_all(:).airway_outer_diam] <  max_airway;
                            
            summarisedPerOuterSize(aa) = summariseAllBiomarkers( summarisedPerOuterSize(aa), cc, airways_all, ids_all, airways_paired, ids_paired);
        end
    end
    
    fprintf('\n Performing statistical analysis ...\n' );
    
    % perform statistical analyisis on means of each patient to obtain pValues
    stats.means.all                        = statsAnalysis( summarised, idGroup1, idGroup2, 'mean' );
    stats.means.perGeneration              = statsAnalysis( summarisedPerGeneration, idGroup1, idGroup2, 'mean' );
    stats.means.perGenerationGroup         = statsAnalysis( summarisedPerGenerationGroup, idGroup1, idGroup2, 'mean' );
    stats.means.perArterySize              = statsAnalysis( summarisedPerArterySize, idGroup1, idGroup2, 'mean' );
    stats.means.perLumenSize               = statsAnalysis( summarisedPerLumenSize, idGroup1, idGroup2, 'mean' );
    stats.means.perOuterSize               = statsAnalysis( summarisedPerOuterSize, idGroup1, idGroup2, 'mean' );
    
    stats.medians.all                      = statsAnalysis( summarised, idGroup1, idGroup2, 'median' );
    stats.medians.perGeneration            = statsAnalysis( summarisedPerGeneration, idGroup1, idGroup2, 'median' );
    stats.medians.perGenerationGroup       = statsAnalysis( summarisedPerGenerationGroup, idGroup1, idGroup2, 'median' );
    stats.medians.perArterySize            = statsAnalysis( summarisedPerArterySize, idGroup1, idGroup2, 'median' );
    stats.medians.perLumenSize             = statsAnalysis( summarisedPerLumenSize, idGroup1, idGroup2, 'median' );
    stats.medians.perOuterSize             = statsAnalysis( summarisedPerOuterSize, idGroup1, idGroup2, 'median' );
    
    % copy into 1 structure for the output
    biomarkers.all                          = summarised;
    biomarkers.perGeneration                = summarisedPerGeneration;
    biomarkers.perGenerationGroup           = summarisedPerGenerationGroup;
    biomarkers.perArterySize                = summarisedPerArterySize;
    biomarkers.perLumenSize                 = summarisedPerLumenSize;
    biomarkers.perOuterSize                 = summarisedPerOuterSize;

end


%% ------------------- EXTRAS --------------
function statsOnMeans = statsAnalysis ( summarised, idCF, idNO, str_summarising )

    fn = fieldnames( summarised );
    for ff = 1:numel(fn)
        aux_bio_all = {summarised.(fn{ff})}; % copy all generations

        for gg = 1:numel(summarised)
            aux_bio = aux_bio_all{gg};
            
            statsOnMeans(gg).(fn{ff}) = summariseBiomarkerPerGroup( aux_bio, idCF, idNO, str_summarising );
        end
    end
end

%  get values per group (e.g. means of subject means)
function result = summariseBiomarkerPerGroup( biomarker, idG1, idG2, str_summarising )

    % str_summarising can be 'mean' or 'median'

    if isempty(biomarker)
        result.pValue = NaN;
        
        % only taking into acocunt mean per patient
        result.meanG1    = NaN;
        result.stdG1     = NaN;
        result.meanG2    = NaN;
        result.stdG2     = NaN;
        
        % taking into account all individual values
        
        result.pValueAllBranches    = NaN;
        result.meanAllBranchesG1    = NaN;
        result.stdAllBranchesG1     = NaN;
        result.meanAllBranchesG2    = NaN;
        result.stdAllBranchesG2     = NaN;
    else
        vecG1 = [biomarker(idG1).(str_summarising)]; % copy on new vector and remove NaNs
        vecG1 = vecG1( ~isnan(vecG1) );

        vecG2 = [biomarker(idG2).(str_summarising)]; % copy on new vector and remove NaNs
        vecG2 = vecG2( ~isnan(vecG2) );

        try
            [~, result.pValue] = ttest2( vecG1, vecG2 );
    %         result.pValue = ranksum( bCF, bNO );
        catch
            result.pValue = NaN;
        end
            
        result.meanG1    = nanmean( vecG1 );
        result.stdG1     =  nanstd( vecG1 );

        result.meanG2    = nanmean( vecG2 );
        result.stdG2     =  nanstd( vecG2 );
        
        % statistics on ALL branches (notice that the pValue is meaningless, as measurements of different branches on the same patient are not independent.
        try
            [~, result.pValueAllBranches] = ttest2( [biomarker(idG1).values], [biomarker(idG2).values] );
        catch
            result.pValueAllBranches = NaN;
        end        
        
        result.meanAllBranchesG1    = nanmean( [biomarker(idG1).values] );
        result.stdAllBranchesG1     =  nanstd( [biomarker(idG1).values] );
        
        result.meanAllBranchesG2    = nanmean( [biomarker(idG2).values] );
        result.stdAllBranchesG2     =  nanstd( [biomarker(idG2).values] );
    end
end