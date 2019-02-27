function sheetposfusion(RootDir, ImgType, Parallelmode, GPUmode)
% This function 'sheetposfusion' fuses images taken with multiple focus
% shifts. This code also achieves the fusion of images taken from left and 
% right arm of light-sheet microscopy.
% The algorighm used in this code is described in 'Preibisch et al., Proc.
% SPIE 6914 (2008)'. 
% Because gaussian convolutions with a large sigma size are computationally 
% intensive, we strongly recommend to turn on 'GPUmode', if GPUs are
% available.
% Parallel computing is supported if parallel computing toolbox is
% available.

% sheetposfution(RootDir, ImgType, Parallelmode, GPUmode)
%   RootDir ... The root folder which includes WL_0, WL_1, etc.
%   ImgType ... '.tiff' or '.tif'. We do not recommend other formats.
%   Parallelmode ... Set '0' if no parallel computations are required.
%   Otherwise, set '1'.
%   GPUmode ... Set '0' if no GPU computatings are required.
%   Otherwise, set '1'.

% Written by Tatsuya C. Murakami, 20/Jul/2017.

%% parameters for sheet position fusion
if nargin > 5
    error( 'sheetposfusion:TooManyInputs', ...
        'requires at most 4 inputs');
elseif nargin < 4
    error( 'sheetposfusion:LessInputs', ...
        'requires 4 inputs');
end

sigma1 = 42;
sigma2 = 88;

%% Repeat fusion until all processes are completed
listing = dir([RootDir '/WL_*']);
channel_num = numel(listing);

for k = 1:channel_num
    ParentPath = [RootDir '/' listing(k).name];
    RightStackDir = [ParentPath '/Right/LPC'];
    LeftStackDir = [ParentPath '/Left/LPC'];
    Rightexist = exist(RightStackDir);
    Leftexist = exist(LeftStackDir);
    if Rightexist == 0 && Leftexist == 0
        warning('The channel of %s is skipped because of the absence of "Right" or "Left" folder. Please reconfirm the name of your folders. \n', listing(k).name);
        continue
    elseif Rightexist == 7 && Leftexist == 0
        LRoption = 'Right';
        Imgs = dir( [ RightStackDir '/*' ImgType] );
        info = imfinfo([ RightStackDir '/' Imgs(1).name] );
        height = info.Height; width = info.Width;
        temp = strsplit(Imgs(end).name,'_');
        strlen = length(temp{1});
        depth = str2double(temp{1})+1;
    elseif Rightexist == 0 && Leftexist == 7
        LRoption = 'Left';
        Imgs = dir( [ LeftStackDir '/*' ImgType] );
        info = imfinfo([ LeftStackDir '/' Imgs(1).name] );
        height = info.Height; width = info.Width;
        temp = strsplit(Imgs(end).name,'_');
        strlen = length(temp{1});
        depth = str2double(temp{1})+1;
    elseif Rightexist == 7 && Leftexist == 7
        LRoption = 'Both'; 
        Imgs = dir( [ RightStackDir '/*' ImgType] );
        info = imfinfo([ RightStackDir '/' Imgs(1).name] );
        height = info.Height; width = info.Width;
        temp = strsplit(Imgs(end).name,'_');
        strlen = length(temp{1});
        depth = str2double(temp{1})+1;
    else
        error('Your folder structures seem to be wrong. Please check https://github.com/DSP-sleep/Landscape_pipeline/wiki');
    end
    
    SavePath = [ParentPath '/Fusion'];
    if ~exist( SavePath, 'dir' )
        mkdir( SavePath );
    end
    
    if strcmp(LRoption,'Right')
        StackDir = {RightStackDir};
    elseif strcmp(LRoption,'Left')
        StackDir = {LeftStackDir};
    elseif strcmp(LRoption,'Both')
        StackDir = {RightStackDir,LeftStackDir};
    end
    
    if Parallelmode == 0
        for i = 0:depth-1 % Image fusion for every single plane
            stri = num2str(i);
            while length(stri) < strlen
                stri = strcat('0',stri);
            end
            if exist([SavePath '/' stri ImgType], 'file')
                fprintf('%s exists. Skip fusion of this plane. \n', [stri ImgType]);
                continue
            end
            fprintf( 'Now fusing: %s %s\n', LRoption, stri );

            imagelist = {};
            counter = 1;
            for l = 1:numel(StackDir)
                SlicePaths = dir([StackDir{l} '/' stri '*']);
                for j = 1:numel(SlicePaths)
                    imagelist{counter} = [StackDir{l} '/' SlicePaths(j).name];
                    counter = counter + 1;
                end
            end

            if numel(imagelist) == 0
                warning('No images to fuse exist at %s . This may result in incontinuous image stack.\n',stri)
                continue
            else
                if GPUmode == 0
                    Ifused = fusion(imagelist,height,width,sigma1,sigma2);
                elseif GPUmode == 1
                    Ifused = GPUfusion(imagelist,height,width,sigma1,sigma2);
                else
                    error('GPUmode should be 0 or 1.');
                end
            end          
            imwrite(Ifused, [SavePath '/' stri ImgType]);
        end
        disp('finish reading stack')
    elseif Parallelmode == 1
        parfor i = 0:depth-1 % Image fusion for every single plane
            stri = num2str(i);
            while length(stri) < strlen
                stri = strcat('0',stri);
            end
            if exist([SavePath '/' stri ImgType], 'file')
                fprintf('%s exists. Skip fusion of this plane. \n', [stri ImgType]);
                continue
            end
            fprintf( 'Now fusing: %s %s\n', LRoption, stri );

            imagelist = {};
            counter = 1;
            for l = 1:numel(StackDir)
                SlicePaths = dir([StackDir{l} '/' stri '*']);
                for j = 1:numel(SlicePaths)
                    imagelist{counter} = [StackDir{l} '/' SlicePaths(j).name];
                    counter = counter + 1;
                end
            end

            if numel(imagelist) == 0
                warning('No images to fuse exist at %s . This may result in incontinuous image stack.\n',stri)
                continue
            else
                if GPUmode == 0
                    Ifused = fusion(imagelist,height,width,sigma1,sigma2);
                elseif GPUmode == 1
                    Ifused = GPUfusion(imagelist,height,width,sigma1,sigma2);
                else
                    error('GPUmode should be 0 or 1.');
                end
            end          
            imwrite(Ifused, [SavePath '/' stri ImgType]);
        end
        disp('finish reading stack')
    else
        error('Parallelmode should be 0 or 1.')
    end
end

%% Function of image fusion 
function Ifused = fusion(imagelist,height,width,sigma1,sigma2)
WI = zeros(height,width);
W = zeros(height,width);
for a = 1:numel(imagelist)
    Ia = double(imread(imagelist{a}));
    Wa1 = Ia - imgaussfilt(Ia,sigma1);
    Wa2 = imgaussfilt(Wa1 .^ 2, sigma2);
    WI = WI + Ia .* Wa2;
    W = W + Wa2;
end
Ifused = uint16(WI ./ W);

%% Function of gpu based image fusion 
function Ifused = GPUfusion(imagelist,height,width,sigma1,sigma2)
WI = gpuArray(zeros(height,width));
W = gpuArray(zeros(height,width));
for a = 1:numel(imagelist)
    Ia = double(imread(imagelist{a}));
    gpuIa = gpuArray(Ia);
    Wa1 = gpuIa - imgaussfilt(gpuIa,sigma1);
    Wa2 = imgaussfilt(Wa1 .^ 2, sigma2);
    WI = WI + gpuIa .* Wa2;
    W = W + Wa2;
end
Ifused = uint16(gather(WI ./ W));
