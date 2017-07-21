function runwarpimage(RootDir, ImgType, StandardDir,  options)
% This function warps images of interests using the affine matrix and the 
% deformation field. Because the function is desinged to be memory
% efficient, image stacks with huge data size (more than TB) can be
% theoretically transformed.
%
% inputs,
%   RootDir ... The root folder of images which you would like to move 
%   against standard brain. The folder includes WL_0, WL_1, etc.
%   ImgType ... '.tiff' or '.tif'. We do not recommend other formats.
%   StandardDir ... The root folder of the standard brain (the fixed
%   image). The folder includes WL_0.
%   options ... Struct with input options,
%       .Parallelmode ... Set '0' if no parallel computations are required.
%       Otherwise, set '1'. Default 0.
%       .registration_option ... The option for the registration 
%       transformation models. Affine transformation ('affine') or
%       transformation in Symmetric Nomralization ('SyN') is available.
%       This option should be modified according to which model you used in
%       registration step. Default 'affine'
%       .interpolation ... The interporation methods to perform warping. 
%       'linear', 'nearest', 'cubic' and 'spline' are available. We
%       recommend 'linear' for efficient computation with high image
%       quality. Default 'linear'.
%       .readstep ... This parameter means how many images you load at single
%       step. If you choose smaller number, you require less memory and if
%       you choose larger number, the computation is more efficient. We do
%       not recommend larger number than 20. Default 5.

% Written by Tatsuya C. Murakami, 20/Jul/2017.
%% Process parameters

defaultoptions = struct('Parallelmode', 0, 'registration_option', 'affine', 'interpolation', 'linear', 'readstep', 5);


if(~exist('options','var')), 
    options=defaultoptions; 
else
    tags = fieldnames(defaultoptions);
    for i=1:length(tags)
         if(~isfield(options,tags{i})),  options.(tags{i})=defaultoptions.(tags{i}); end
    end
    if(length(tags)~=length(fieldnames(options))), 
        warning('runwarpimage:unknownoption','unknown options found');
    end
end

Parallelmode = options.Parallelmode;
registration_option = options.registration_option;
interpolation = options.interpolation;
readstep = options.readstep;


%% 
listing = dir([RootDir '/WL_*']);
channel_num = numel(listing);
StructureParentPath = [RootDir '/' listing(1).name];
RegresultPath = [StructureParentPath '/Reg_result'];
if ~exist( RegresultPath, 'dir')
    error('Image registration is required prior to the warping process.')
end

StandardImgPath = [StandardDir '/WL_0/Fusion' ];
if ~exist( StandardImgPath, 'dir' )
    error('Image fusion is required prior to the registration process. Please make fusioned images for your standard brain.')
else
    Imgs = dir( [ StandardImgPath '/*' ImgType] );
    info = imfinfo([StandardImgPath '/' Imgs(1).name] );
    original_size = [info.Height,info.Width,size( Imgs, 1 )];
end

StandardDownPath = [StandardDir '/WL_0/Downsampled/Downsampled.tiff'];
if ~exist(StandardDownPath, 'file')
    error('Downsampled standard image does not exist.')
else
    downinfo = imfinfo(StandardDownPath);
    down_size = [downinfo(1).Height,downinfo(1).Width,numel(downinfo)];
end

for k = 2:channel_num
    MovingParentPath = [RootDir '/' listing(k).name];
    MoveImgPath = [MovingParentPath '/Fusion'];
    if ~exist(MoveImgPath, 'dir')
        warning('Your %s does not include fused images. The warping was skipped for this channel. \n', listing(k).name);
        continue
    end
    MoveSavePath = [MovingParentPath '/Warp'];
    if ~exist( MoveSavePath, 'dir' )
        mkdir( MoveSavePath );
    end
    AffinePath = [RegresultPath '/ex_Affine.txt'];
    if strcmp(registration_option,'affine')
        disp('Current your option is affine');
        DeformPath = [];
    elseif strcmp(registration_option,'SyN')
        disp('Current your option is SyN');
        DeformPath = [RegresultPath '/ex_Warp.nii'];
    else
        error('Your option is invalid.');
    end

    warpimg = warpimage(MoveImgPath,ImgType,AffinePath,DeformPath,down_size,original_size,readstep,interpolation,Parallelmode);
    if Parallelmode == 0
        for i = 1:original_size(3)
            stri = num2str(i);
            while length(stri) < 5
                stri = strcat('0',stri);
            end
            imwrite(uint16(warpimg(:,:,i)),[MoveSavePath '/' stri ImgType]);
        end
    elseif Parallelmode == 1
        parfor i = 1:original_size(3)
            stri = num2str(i);
            while length(stri) < 5
                stri = strcat('0',stri);
            end
            imwrite(uint16(warpimg(:,:,i)),[MoveSavePath '/' stri ImgType]);
        end
    else
        error('Parallelmode should be 0 or 1.');
    end
end
