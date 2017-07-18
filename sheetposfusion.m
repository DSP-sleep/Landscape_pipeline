%% Sheet position fusion
RootDirs = {...
    %'/home/beowulf/Desktop/Landscape/VirtualMultiplex/20170607_cancer_MDA_637nm_/X_000Y_000/WL_0' ,...
    '/home/beowulf/Desktop/Landscape/20170421_155540_HB_Semioval_ex637_x6.3/X_000Y_000/WL_0' ...
    }; % Folders with images to be registration

sheetposshift = 4;
ImgType = '.tiff';
LRoption = 'both'; %input left or right or both, for future use
prefix = 'Image_Z_';
midfix = '_LP_00';
suffix = '';
defaultdepth = 400;%start from 0
sigma1 = 42;
sigma2 = 88;

%% Repeat fusion until all processes are completed
for k = 1:length(RootDirs)
    ParentPath = char(RootDirs(k));
    SavePath = [ParentPath '/Fusion'];
    if ~exist( SavePath, 'dir' )
        mkdir( SavePath );
    end
    RightStackPath = [ParentPath '/Right/LPC'];
    LeftStackPath = [ParentPath '/Left/LPC'];
    Imgs = dir( [ RightStackPath '/*' ImgType] ); %This contains a list of file names e.g. 'abcd/efgh.tif'
    info = imfinfo([ RightStackPath '/' Imgs(1).name] );
    height = info.Height; width = info.Width;
    parfor i = 0:defaultdepth-1
        stri = num2str(i);
        while length(stri) < 5
            stri = strcat('0',stri);
        end
        disp(stri);
        C = cell(sheetposshift*2,1);
        validpos = [];
        for j = 0:sheetposshift-1
            SlicePath = [RightStackPath '/' prefix stri midfix num2str(j) suffix ImgType];
            if exist(SlicePath,'file') == 2
                C(j+1) = {imread( SlicePath )};
                validpos = horzcat(validpos,j+1);
            end
            %I = uint16(imread( [ImgPath '/' Imgs(i).name]));
        end
        for j = 0:sheetposshift-1
            SlicePath = [LeftStackPath '/' prefix stri midfix num2str(j) suffix ImgType];
            if exist(SlicePath,'file') == 2
                C(j+1+sheetposshift) = {imread( SlicePath )};
                validpos = horzcat(validpos,j+1+sheetposshift);
            end
            %I = uint16(imread( [ImgPath '/' Imgs(i).name]));
        end
        WI = gpuArray(zeros(height,width));
        W = gpuArray(zeros(height,width));
        tic
        if ~isempty(validpos)
            for a = validpos
                Ia = double(C{a});
                gpuIa = gpuArray(Ia);
                Wa1 = gpuIa - imgaussfilt(gpuIa,sigma1);
                Wa2 = imgaussfilt(Wa1 .^ 2,sigma2);
                WI = WI + Ia .* Wa2;
                W = W + Wa2;
            end
        else
            W = W + 1;
        end
        Ifused = uint16(gather(WI ./ W));
        imwrite(Ifused, [SavePath '/' stri '.tif']);
        toc
    end
    disp('finish reading stack')
end