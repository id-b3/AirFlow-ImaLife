function [vol, extraInfo] = readVolume(fileName, fileFormat)

if nargin < 1
    error(' Not enough parameters, usage: readVolume(fileName) or readVolume(fileName, type)');
end

if nargin <2
    
    % check if it is a folder
    if exist(fileName, 'dir');

        fileExtension = [];
        fileFormat = 'DICOM FOLDER';
        
    else
    
        % detect file type by extension
        [~, ~, fileExtension] = fileparts(fileName);

        switch fileExtension
            case {'.dcm', '.DCM', '.dicom', '.DICOM'}

                 fileFormat = 'DICOM';

            case {'.HR2', '.hr2'}

                 fileFormat = 'HR2';
                 
            case {'.MHD', '.mhd'}

                 fileFormat = 'MHD';
                 
            otherwise

                fileFormat = fileExtension;
    %            warning(' INCORECT file extension. Supported extensions are dcm, DCM, dicom, DICOM, hr2, HR2');
        end
    end
    
    fprintf(' File extension: %s -> %s\n', fileExtension, fileFormat);
end

if strcmp(fileFormat, 'HR2')

    [vol, extraInfo] = readHR2(fileName);
    
elseif strcmp(fileFormat, 'MHD')

    try
        % use function from look3d_v3
        disp('* Using third-party look3d_v3/mhd_read_image.m');
        data = mhd_read_image(fileName);
        vol = data.data;
        
    catch
        
        % screw it up, just go for the data (based on read_mhd.m)
        disp('* WARNING: Using alterantive mhd reading method (does not suppot compression)...');
        
        info = mhareadheader(fileName); % originally inside read_mrh.m
        path = fileparts(fileName);        
        
        if (isfield(info,'ElementNumberOfChannels'))
            ndims = str2num(info.ElementNumberOfChannels);
        else
            ndims = 1;
        end
        
        vol = read_raw([ path  filesep  info.DataFile ], info.Dimensions,info.DataType,'native',0,ndims);
    end
    
elseif strcmp(fileFormat, 'DICOM');

    extraInfo = dicominfo(fileName);
    vol = dicomread(fileName);
    
elseif strcmp(fileFormat, 'DICOM FOLDER');

    disp('* Using third-party dicom_read_volume.m');
    vol = dicom_read_volume(fileName);
    
else
    
    % Use third-party ReadData3D for other 3D volumes
    disp('* Using third-party ReadData3D.m');
    [vol, extraInfo] = ReadData3D( fileName );
    
end

vol = squeeze(vol); % warning: HR2 might have already done the squeeze.

volSize = size( vol );
nVoxels = numel( vol );

fprintf(' Volume format: %s | file: %s\n', fileFormat, fileName );
fprintf(' Dimensions: [%s] | %d voxels\n', num2str(volSize), nVoxels );

if ~exist('extraInfo', 'var')
    extraInfo = [];
end
