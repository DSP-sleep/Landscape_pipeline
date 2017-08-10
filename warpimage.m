function warpimage(MoveImgPath,MoveSavePath,ImgType,AffinePath,DeformPath,down_size,original_size,step,interpolation,Parallelmode)

% This function is a subfunction of runwarpimage.m.
% This warpimage.m transform images without killing original resolution.
% This code is optimized to be memory efficient. The transformation of 
% large data (e.g. data of LSFM) can be performed. 

% inputs,
%   MoveImgPath ... Fluorescent labeled image, which is going to be warped.
%   MoveSavePath ... Folder to output warped images.
%   ImgType ... '.tiff' or '.tif'. We do not recommend other formats.
%   AffinePath ... A path for the output file of ANTs with affine
%   matrix information.
%   DeformPath ... A path for the output file of ANTs with deformation
%   field information.
%   down_size ... The size of the image of downsampled standard brain.
%   original_size ... The size of the image of standard brain before
%   downsampling
%   step ... This parameter means how many images you load at single step.
%   interpolation ... The interporation methods to perform warping. 
%   Parallelmode ... Parallel computing option, 0 or 1.

% Written by Tatsuya C. Murakami, 20/Jul/2017.
%% Warp image stack
affinematrix = return_affine_mat(AffinePath);

% Apply affine matrix in downsampled size
[locX,locY,locZ] = meshgrid(1:down_size(2),1:down_size(1),1:down_size(3));
locX = reshape(locX,[down_size(2)*down_size(1)*down_size(3),1,1]);
locY = reshape(locY,[down_size(2)*down_size(1)*down_size(3),1,1]);
locZ = reshape(locZ,[down_size(2)*down_size(1)*down_size(3),1,1]);
m2d = [locX';
    locY';
    locZ';
    ones(1,down_size(2)*down_size(1)*down_size(3))];
m2d = affinematrix * m2d;
m2d = m2d';

locX = reshape(m2d(:,1),[down_size(1),down_size(2),down_size(3)]);
locY = reshape(m2d(:,2),[down_size(1),down_size(2),down_size(3)]);
locZ = reshape(m2d(:,3),[down_size(1),down_size(2),down_size(3)]);


% Apply deformation fields in downsampled size
if isempty(DeformPath)
    disp('You chose affine transformation. Application of deformation fields is skipped.')
else
    disp('Read deformation field')
    DeformInfo = load_nii(DeformPath);
    Deform = DeformInfo.img;
    DeformX = rot90(double(permute(Deform(:,:,:,1,1),[2,1,3])),2);
    DeformY = rot90(double(permute(Deform(:,:,:,1,2),[2,1,3])),2);
    DeformZ = rot90(double(permute(Deform(:,:,:,1,3),[2,1,3])),2);
    locX = locX + DeformX;
    locY = locY + DeformY;
    locZ = locZ + DeformZ;
end


% Processing of loc matrix to avoid error
locX(locX <= 1) = 1;locX(locX >= down_size(2)) = down_size(2);
locY(locY <= 1) = 1;locY(locY >= down_size(1)) = down_size(1);
locZ(locZ <= 1) = 1;locZ(locZ >= down_size(3)) = down_size(3);

% Obtain information of moving image prior to warp.
movImgs = dir( [ MoveImgPath '/*' ImgType] ); 
movdepth = size( movImgs, 1 );
info = imfinfo([MoveImgPath '/' movImgs(1).name] );
movheight = info.Height; movwidth = info.Width;

% Following step requires huge memory if done in a whole stack, so
% The stack is divided into substacks.
subranges = floor(1:step:original_size(3));
subranges = [subranges original_size(3)+1];

for i = 1:length(subranges)-1
    p = i*step;
    fprintf('Transformation: %d th image started \n',p);
    [LlocX,LlocY,LlocZ] = meshgrid(1:original_size(2),...
        1:original_size(1),...
        subranges(i):subranges(i+1)-1);
    LlocX = LlocX .* (down_size(2) / original_size(2));
    LlocY = LlocY .* (down_size(1) / original_size(1));
    LlocZ = LlocZ .* (down_size(3) / original_size(3));

    % calcultion of trilinear interporation
    NlocX = interp3(locX,LlocX,LlocY,LlocZ,interpolation) / (down_size(2) / original_size(2));
    NlocY = interp3(locY,LlocX,LlocY,LlocZ,interpolation) / (down_size(1) / original_size(1));
    NlocZ = interp3(locZ,LlocX,LlocY,LlocZ,interpolation) / (down_size(3) / original_size(3));
    
    % make matrix to remove the void space. 
    black = (NlocX < 1/(down_size(2) / original_size(2))+1) | ...
        (NlocX > original_size(2)-1) | ...
        (NlocY < 1/(down_size(1) / original_size(1))+1) | ...
        (NlocY > original_size(1)-1) | ...
        (NlocZ < 1/(down_size(3) / original_size(3))+1) | ...
        (NlocZ > original_size(3)-1);
    
    % re-sampling of intensity of neigbouring pixels
    minZ = min(NlocZ(:)); maxZ = max(NlocZ(:));
    if isnan(minZ)
        subwarpimg = zeros(size(NlocZ));
    else
        submov = zeros(movheight,movwidth,ceil(maxZ)-floor(minZ)+1);
        if Parallelmode == 0
            for j = 1:ceil(maxZ)-floor(minZ)+1
                if j+floor(minZ)-1 < 1
                    continue
                elseif j+floor(minZ)-1 > movdepth
                    continue
                else
                    submov(:, :, j) = uint16(imread([MoveImgPath '/' movImgs(j+floor(minZ)-1).name]));
                end
            end      
        elseif Parallelmode == 1
            parfor j = 1:ceil(maxZ)-floor(minZ)+1
                if j+floor(minZ)-1 < 1
                    continue
                elseif j+floor(minZ)-1 > movdepth
                    continue
                else
                    submov(:, :, j) = uint16(imread([MoveImgPath '/' movImgs(j+floor(minZ)-1).name]));
                end
            end
        else
            error('Parallelmode should be 0 or 1.');
        end
        subwarpimg = interp3(submov,NlocX,NlocY,NlocZ-floor(minZ)+1,interpolation,0);
    end

    subwarpimg(black) = 0;
    printranges = [subranges(i) subranges(i+1)-1];
    printimage(subwarpimg,MoveSavePath,ImgType,printranges,Parallelmode)

end


end

%% subfucntion for print images
function printimage(subwarpimg,MoveSavePath,ImgType,ranges,Parallelmode)

if Parallelmode == 0
    for i = 1:ranges(2)-ranges(1)+1
        stri = num2str(i+ranges(1)-1);
        while length(stri) < 5
            stri = strcat('0',stri);
        end
        imwrite(uint16(subwarpimg(:,:,i)),[MoveSavePath '/' stri ImgType]);
    end
elseif Parallelmode == 1
    parfor i = 1:ranges(2)-ranges(1)+1
        stri = num2str(i+ranges(1)-1);
        while length(stri) < 5
            stri = strcat('0',stri);
        end
        imwrite(uint16(subwarpimg(:,:,i)),[MoveSavePath '/' stri ImgType]);
    end
else
    error('Parallelmode should be 0 or 1.');
end

end