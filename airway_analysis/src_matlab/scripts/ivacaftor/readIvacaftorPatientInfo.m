function subjects = readIvacaftorPatientInfo( fileList, file_subjects )

    fprintf('Reading %s...\n', file_subjects);

    subjects_table = readtable( file_subjects, 'Delimiter', ',' );
    subjects_all = table2struct( subjects_table );
    
    dataFound = false(numel(fileList), 1);

    % for all CTs, check if htere is clinical data
    for dd = 1:numel(fileList)
        [~, rootName, ext] = fileparts( fileList(dd).name );
        
        % look for entry with same name
        index = find( ismember({subjects_all.ID}, rootName) );
        
        if ~isempty( index )
           subjects(dd) = subjects_all( index );
           dataFound(dd) = true;
        end
    end
    
    fprintf(' + Read description of %d subjects\n', numel(subjects_all) );
    fprintf('   > %d subjects have clinical data (out of %d)\n\n', sum(dataFound), numel(fileList) );
end
