function runANTsregistration(RootDir, ImgType, StandardDir, options)
% This function runs image registration after downsampling of a stack image.
% ANTs registration software (Avants et al., NeuroImage, 54, 3, 2033-2044 (2011)) 
% is used for image registration.
% Installation of ANTs software is madatory before running this function.
% inputs,
%   RootDir ... The root folder of images which you would like to move 
%   against standard brain. The folder includes WL_0, WL_1, etc.
%   ImgType ... '.tiff' or '.tif'. We do not recommend other formats.
%   StandardDir ... The root folder of the standard brain (the fixed
%   image). The folder includes WL_0.
%   options ... Struct with input options,
%       .Parallelmode ... Set '0' if no parallel computations are required.
%       Otherwise, set '1'. Default 0.
%       .compression_ratio ... The scale for downsampling. The function
%       export images of 'compressionratio' times of original images.
%       Downsamping is performed in voxel not in actual size (e.g. um). For
%       2160x2560 image, we recommend 0.2-0.25. Default 0.2.
%       .registration_option ... The option for the registration 
%       transformation models. Affine transformation ('affine') or
%       transformation in Symmetric Nomralization ('SyN') is available.
%       Default 'affine'
%       .iteration_parameter ... The iteration parameter for SyN
%       transofmation. Please refere ANTs manual for details. Default
%       '100x10x3'

% Written by Tatsuya C. Murakami, 20/Jul/2017.
%% Process inputs

defaultoptions = struct('Parallelmode', 0, 'compression_ratio', 0.2, 'registration_option', 'affine', 'iteration_parameter', '100x10x3');

if(~exist('options','var')), 
    options=defaultoptions; 
else
    tags = fieldnames(defaultoptions);
    for i=1:length(tags)
         if(~isfield(options,tags{i})),  options.(tags{i})=defaultoptions.(tags{i}); end
    end
    if(length(tags)~=length(fieldnames(options))), 
        warning('runANTsregistration:unknownoption','unknown options found');
    end
end

Parallelmode = options.Parallelmode;
compression_ratio = options.compression_ratio;
registration_option = options.registration_option;
iteration_parameter = options.iteration_parameter;


%% Downsamping of standard image (fixed image).
StandardImgPath = [StandardDir '/WL_0/Fusion'];
if ~exist( StandardImgPath, 'dir' )
    error('Image fusion is required prior to the registration process. Please make fusioned images for your standard brain.')
else
    StSavePath = [StandardDir '/WL_0/Downsampled'];
    if ~exist( StSavePath, 'dir' )
        mkdir( StSavePath );
    end
    StandardImg = [StSavePath '/Downsampled' ImgType];
    if ~exist(StandardImg)
        [StImageScaled, StDepthScaledImgs] = rescale(StandardImgPath, ImgType, compression_ratio, Parallelmode);
        for i = 1:StDepthScaledImgs
            imwrite(uint16(StImageScaled(:,:,i)),StandardImg,'writemode','append');
        end
    else
        disp('Skipped the downsampling process of the standard brain.');
    end
end

%% Downsampling of moving image followed by ANTS registration
ImgPath = [RootDir '/WL_0/Fusion'];% Your structure image path
if ~exist( ImgPath, 'dir' )
    error('Image fusion is required prior to the registration process. Please make fusioned images for your standard brain.')
else
    SavePath = [RootDir '/WL_0/Downsampled'];

    if ~exist( SavePath, 'dir' )
        mkdir( SavePath );
    end
    MoveImg = [SavePath '/Downsampled' ImgType];
    if ~exist(MoveImg)
        [ImageScaled, DepthScaledImgs] = rescale(ImgPath, ImgType, compression_ratio, Parallelmode);
        for i = 1:DepthScaledImgs
            imwrite(uint16(ImageScaled(:,:,i)),MoveImg,'writemode','append');
        end
    else
        disp('Skipped the downsampling process of the moving image.');
    end

    regresultPath = [RootDir '/WL_0/Reg_result'];
    
    disp('start registration');
    ANTSregistration(StandardImg,MoveImg,regresultPath,registration_option,iteration_parameter);
    fprintf('Please confirm your registration result. The standard image is %s. \n', StandardImg);
    fprintf('The registered result is in %s. \n', regresultPath);
    fprintf('If the result does not satisfy your criteria, \nplease think about changing the registration_option and iteration_parameter.\n');
end

end

%% Subfunction to run ANTs
function ANTSregistration(fixedImg,moveImg,regresultPath,option,iteration_parameter)

info = imfinfo(fixedImg);
num_imgs = numel(info);
fix = zeros(info(1).Height,info(1).Width,num_imgs);
for k = 1:num_imgs
    fix(:,:,k) = imread(fixedImg,k,'Info',info);
end

if ~exist( regresultPath, 'dir' )
    mkdir( regresultPath );
end
info = imfinfo(moveImg);
num_imgs = numel(info);
mov = zeros(info(1).Height,info(1).Width,num_imgs);
for k = 1:num_imgs
    mov(:,:,k) = imread(moveImg,k,'Info',info);
end

% Run ANTS
scriptPath = [regresultPath '/command.sh'];
fid = fopen(scriptPath,'wt');

out = [regresultPath '/ex_.nii'];

if strcmp(option,'affine')
    cmd = sprintf(['ANTS 3 ' ...
        '-i 0 ' ...
        '-o %s ' ...
        '--MI-option 64x300000 ' ...
        '-m CC[%s,%s,1,5]'],out,fixedImg,moveImg);
elseif strcmp(option,'SyN')
    cmd = sprintf(['ANTS 3 ' ...
        '-i ' iteration_parameter ' '...
        '-o %s ' ...
        '--MI-option 64x300000 ' ...
        '-m CC[%s,%s,1,5]'],out,fixedImg,moveImg);
else
    error('Your option is invalid. Please choose from affine or SyN.' );
end

fprintf(fid,'%s\n',cmd);
fclose(fid);
[status,cmdout] = system(['bash ' scriptPath]);

if strcmp(option,'affine')
    [status,cmdout] = system(['WarpImageMultiTransform 3 ' moveImg ' ' regresultPath '/result.tif ' regresultPath '/ex_Affine.txt -R ' fixedImg]);
elseif strcmp(option,'SyN')
    [status,cmdout] = system(['WarpImageMultiTransform 3 ' moveImg ' ' regresultPath '/result.tif -R ' fixedImg ' ' regresultPath '/ex_Warp.nii ' regresultPath '/ex_Affine.txt']);
end


end