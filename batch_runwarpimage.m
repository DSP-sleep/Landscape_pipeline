%% Set your parameters
StructureParentDirs = {...
    %'/home/beowulf/Desktop/Landscape/fromTainaka/20170529_085935_SMA_637nm/X_000Y_000/WL_0' ,...
    '/home/beowulf/Desktop/Landscape/VirtualMultiplex/20170610_143626_Immunolabelling_NC_637nm/X_000Y_000/WL_0' ...
    }; % Parents folders of images of structures

MovingParentDirs = {...
    %'/home/beowulf/Desktop/Landscape/fromTainaka/20170529_100436_SMA_488nm/X_000Y_000/WL_0' ...
    '/home/beowulf/Desktop/Landscape/VirtualMultiplex/20170610_105637_Immunolabelling_NC_532nm/X_000Y_000/WL_0' ,...
    }; % Parents folders of images of your interest to warp

defaultdepth = 1500;
ImgType = '.tif';
option = 'SyN';
interpolation = 'linear'; % Input 'linear' or 'cubic'. 'linear' is less memory demanding. 'nearest' and 'spline' are also possible.
compratio = 0.2;
step = 10;% The lower we can save memory the more.

for k = 1:length(StructureParentDirs)
    StructureParentPath = char(StructureParentDirs(k));
    RegresultPath = [StructureParentPath '/Reg_result'];
    
    MovingParentPath = char(MovingParentDirs(k));
    ImgPath = [MovingParentPath '/Fusion'];
    SavePath = [MovingParentPath '/Warp'];
    if ~exist( SavePath, 'dir' )
        mkdir( SavePath );
    end
    AffinePath = [RegresultPath '/ex_Affine.txt'];
    if strcmp(option,'affine')
        disp('Current your option is affine');
        DeformPath = [];
    elseif strcmp(option,'SyN')
        disp('Current your option is SyN');
        DeformPath = [RegresultPath '/ex_Warp.nii'];
    else
        error('Your option is invalid.');
    end

    Imgs = dir( [ ImgPath '/*' ImgType] ); %This contains a list of file names e.g. 'abcd/efgh.tif'
    numImgs = size( Imgs, 1 );
    info = imfinfo([ImgPath '/' Imgs(1).name] );
    Height = info.Height; Width = info.Width;
    mov = zeros(Height,Width,defaultdepth);

    parfor i = 1:numImgs
        mov(:, :, i) = uint16(imread([ImgPath '/' Imgs(i).name]));%, 'Info', info ));
    end
    parfor i = numImgs+1:defaultdepth
        mov(:, :, i) = uint16(zeros(Height,Width));
    end
    disp('finish reading stack')

    mywarpimage3(mov,AffinePath,DeformPath,SavePath,compratio,step,interpolation);
end