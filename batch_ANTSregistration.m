%% Set your parameters

RootDirs = {...
    %'/home/beowulf/Desktop/Landscape/fromTainaka/20170529_085935_SMA_637nm/X_000Y_000/WL_0' ,...
    '/home/beowulf/Desktop/Landscape/VirtualMultiplex/20170610_143626_Immunolabelling_NC_637nm/X_000Y_000/WL_0' ...
    }; % Folders with images to be registration
StandardImg = '/home/beowulf/Desktop/Landscape/VirtualMultiplex/20170525_registration_standard/final.tif';
ImgType = '.tif';
defaultdepth = 1500;
compressionratio = 0.2;
option = 'SyN';% input 'affine' or 'SyN'
iteration_parameter = '100x10x3'; % Required if option is SyN.

%% Perform compression followed by ANTS registration
for k = 1:length(RootDirs)
    ParentPath = char(RootDirs(k));
    ImgPath = strcat(ParentPath,'/Fusion');% Your structure image path
    SavePath = strcat(ParentPath,'/Compress');
    if ~exist( SavePath, 'dir' )
        mkdir( SavePath );
    end
    [ImageScaled, numScaledImgs] = myrescale(ImgPath, ImgType, defaultdepth, compressionratio);
    for i = 1:numScaledImgs
        imwrite(uint16(ImageScaled(:,:,i)),[SavePath '/Compress.tif'],'writemode','append');
    end
    moveImg = strcat(ParentPath,'/Compress/Compress.tif');
    regresultPath = strcat(ParentPath, '/Reg_result');
    myANTSregistration2(StandardImg,moveImg,regresultPath,option,iteration_parameter);
    disp('Please confirm your registration result.');
end