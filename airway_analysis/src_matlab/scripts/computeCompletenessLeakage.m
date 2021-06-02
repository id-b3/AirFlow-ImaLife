function computeCompletenessLeakage ()

    baseDataDir                          = '/home/antonio/Results/Tests_LUVAR/';

    cfg.files.folderCT                   = [baseDataDir '/BaseData/CTs/'];
    cfg.files.folderReferenceMasks       = [baseDataDir '/BaseData/Reference_Airways/'];
    cfg.files.folderReferenceOuterwall   = [baseDataDir '/BaseData/Reference_Airways/'];
    cfg.files.folderReferenceCentrelines = [baseDataDir '/BaseData/Reference_Airways/'];
    cfg.files.folderCoarseAirways        = [baseDataDir '/BaseData/CoarseAirways/'];
    cfg.files.folderPredictedMasks       = [baseDataDir '/Predictions_Adria/'];
    cfg.files.folderPredictedCentrelines = [baseDataDir '/Predictions_Adria/'];
    cfg.files.outputFile                 = [baseDataDir '/completeness_leakage.csv'];
    
    %cfg.doCases = {'av01', 'av02', 'av03', 'av04', 'av05', 'av06', 'av07', 'av08', ...
    %               'av10', 'av11', 'av12', 'av13', 'av16', 'av17', 'av18', 'av19', ...
    %               'av21', 'av23', 'av24', 'av25', 'av26', 'av27', 'av28', 'av41'};
    cfg.doCases = {'av21', 'av23', 'av24', 'av25', 'av26', 'av27', 'av28', 'av41'};
    
    
    for dd = 1:numel(cfg.doCases)
        case_name = cfg.doCases{dd};
        
        fprintf('\nCase : %s\n', case_name);
        
        ctFile                     = [cfg.files.folderCT                   '/' case_name '.dcm'];
        files.referenceMasks       = [cfg.files.folderReferenceMasks       '/' case_name '_surface0.dcm'];
        files.referenceOuterwall   = [cfg.files.folderReferenceOuterwall   '/' case_name '_surface1.dcm'];
        files.referenceCentrelines = [cfg.files.folderReferenceCentrelines '/' case_name '_airways_centrelines.dcm'];
        files.coarseAirways        = [cfg.files.folderCoarseAirways        '/' case_name '-airways.dcm'];
        files.predictedMasks       = [cfg.files.folderPredictedMasks       '/' case_name '_surface0.dcm'];
        files.predictedCentrelines = [cfg.files.folderPredictedCentrelines '/' case_name '_airways_centrelines.dcm'];
        
        ctInfo                  = dicominfo(ctFile);
        reference_masks         = logical( squeeze( dicomread(files.referenceMasks) ));
        reference_outerwall     = logical( squeeze( dicomread(files.referenceOuterwall) ));
        reference_centrelines   = logical( squeeze( dicomread(files.referenceCentrelines) ));
        coarse_airways          = squeeze( dicomread(files.coarseAirways) );
        predicted_masks         = logical( squeeze( dicomread(files.predictedMasks) ));
        %predicted_centrelines   = logical( squeeze( dicomread(files.predictedCentrelines) ));
       

        % fill holes, if needed
        predicted_masks = imfill(predicted_masks, 'holes');
        
        % extract the trachea and 2 bronchii, if needed
        coarse_airways = (coarse_airways == 2 | coarse_airways == 3 | coarse_airways == 4); % (trachea and 2 bronchii)
        coarse_airways = imfill(coarse_airways,  'holes');
        
        % remove trachea region from the reference centrelines, and mask with reference (lumen) masks
        reference_centrelines = reference_centrelines & ~coarse_airways & reference_masks;

        predicted_masks_outside = predicted_masks & ~reference_outerwall & ~coarse_airways;
        predicted_centrelines_inside = predicted_masks & reference_centrelines;
        
        
        % remove trachea region from both the reference and predictions
        %reference_masks       = reference_masks & ~coarse_airways;
        %reference_outerwall   = reference_outerwall & ~coarse_airways;
        %reference_centrelines = reference_centrelines & ~coarse_airways;
        %predicted_masks       = predicted_masks & ~coarse_airways;
        %predicted_centrelines = predicted_centrelines & ~coarse_airways;
        
        %predicted_centrelines_inside = reference_centrelines & predicted_masks;
        %predicted_masks_outside      = predicted_masks & ~reference_masks;

        
        % completeness := percentage of reference centrelines inside predicted masks
        found_centrelines = sum(predicted_centrelines_inside(:));
        total_centrelines = sum(reference_centrelines(:));
        ratio_centrelines = found_centrelines / total_centrelines;
        
        % leakage := percentage of predicted masks outside the reference masks
        leak_segmentation  = sum(predicted_masks_outside(:));
        total_segmentation = sum(predicted_masks(:));
        ratio_leakage      = leak_segmentation / total_segmentation;
        
        
        fprintf('Completeness: %.6f %%\n', ratio_centrelines * 100);        
        fprintf('Leakage: %.6f %%\n', ratio_leakage * 100);
                    
        clear files reference_masks reference_outerwall reference_centrelines coarse_airways ...
            predicted_masks predicted_centrelines predicted_centrelines_inside predicted_masks_outside
        
        
        dd = dd + 1;
        out_info(dd).case         = case_name;
        out_info(dd).completeness = ratio_centrelines;
        out_info(dd).leakage      = ratio_leakage;
    end
    
    
    fprintf('Saving completeness and leakage in %s...\n', cfg.files.outputFile);
    
    fid = fopen(cfg.files.outputFile, 'w');
    str_header = '/case/, /completeness/, /volume_leakage/';
    fprintf( fid, str_header );
    
    for dd = 1:numel(out_info)
        str_row = sprintf('%s, %.6f, %.6f\n', out_info(dd).case, ...
                                              out_info(dd).completeness, ...
                                              out_info(dd).leakage);
        fprintf( fid, str_row );
    end
    
    fclose(fid);
end
