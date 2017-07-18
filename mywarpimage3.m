function mywarpimage3(mov,AffinePath,DeformPath,SavePath,compratio,step,interpolation)

% This warpimage.m transform (warp) images with given affine parameters.
% This code is optimized to be memory efficient. The transformation of 
% large data (e.g. data of LSFM) can be applied. 
% Trilinear interporation is used as defaut. 
% step - controls how many image slices put on your computer, 10
% recommended
% compratio - comprassion ratio of registered image

fileID = fopen(AffinePath);
C = textscan(fileID,'%s');
C = C{1,1};
a11 = str2double(C{10}); a12 = str2double(C{11}); a13 = str2double(C{12}); 
a21 = str2double(C{13}); a22 = str2double(C{14}); a23 = str2double(C{15});
a31 = str2double(C{16}); a32 = str2double(C{17}); a33 = str2double(C{18});
t1 = str2double(C{19}); t2 = str2double(C{20}); t3 = str2double(C{21});
c1 = str2double(C{23}); c2 = str2double(C{24}); c3 = str2double(C{25});
A = [a11 a12 a13; a21 a22 a23; a31 a32 a33];
T = [t1 t2 t3];
center = [c1 c2 c3];
offset = [0 0 0];
for i = 1:3
    offset(i) = T(i) + center(i);
    for j = 1:3
        offset(i) = offset(i) - A(i,j) * center(j);
    end
end
affinematrix = [a11 a12 a13 offset(1);
    a21 a22 a23 offset(2);
    a31 a32 a33 offset(3);
    0 0 0 1];

originalimsize = size(mov);
imsize = round(originalimsize*compratio);

tic

[locX,locY,locZ] = meshgrid(1:imsize(2),1:imsize(1),1:imsize(3));
locX = reshape(locX,[imsize(2)*imsize(1)*imsize(3),1,1]);
locY = reshape(locY,[imsize(2)*imsize(1)*imsize(3),1,1]);
locZ = reshape(locZ,[imsize(2)*imsize(1)*imsize(3),1,1]);
m2d = [locX';
    locY';
    locZ';
    ones(1,imsize(2)*imsize(1)*imsize(3))];
m2d = affinematrix * m2d;
m2d = m2d';

locX = reshape(m2d(:,1),[imsize(1),imsize(2),imsize(3)]);
locY = reshape(m2d(:,2),[imsize(1),imsize(2),imsize(3)]);
locZ = reshape(m2d(:,3),[imsize(1),imsize(2),imsize(3)]);

%-------------
% PLEASE INSERT DEFORMATION FIELDS HERE
if isempty(DeformPath)
    disp('affine transformation skips deformation')
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
%-------------
locX(locX <= 1) = 1;locX(locX >= imsize(2)) = imsize(2);
locY(locY <= 1) = 1;locY(locY >= imsize(1)) = imsize(1);
locZ(locZ <= 1) = 1;locZ(locZ >= imsize(3)) = imsize(3);

% Following step requires huge memory if done in original scale, so dividing into substacks are required
affinemov = uint16(zeros(originalimsize));
subranges = floor(1:step:originalimsize(3));
subranges = [subranges originalimsize(3)+1];

for i = 1:length(subranges)-1
    p = i*step;
    fprintf('%d th image started \n',p);
    [LlocX,LlocY,LlocZ] = meshgrid(1:originalimsize(2),...
        1:originalimsize(1),...
        subranges(i):subranges(i+1)-1);
    LlocX = LlocX .* compratio;
    LlocY = LlocY .* compratio;
    LlocZ = LlocZ .* compratio;

    % calcultion of trilinear interporation
    NlocX = interp3(locX,LlocX,LlocY,LlocZ,interpolation)/compratio;
    NlocY = interp3(locY,LlocX,LlocY,LlocZ,interpolation)/compratio;
    NlocZ = interp3(locZ,LlocX,LlocY,LlocZ,interpolation)/compratio;
    %clear LlocX; clear LlocY; clear LlocZ;
    black = (NlocX < 1/compratio+1) | ...
        (NlocX > originalimsize(2)-1) | ...
        (NlocY < 1/compratio+1) | ...
        (NlocY > originalimsize(1)-1) | ...
        (NlocZ < 1/compratio+1) | ...
        (NlocZ > originalimsize(3)-1);
    
    % re-sampling of intensity of 8 neigbouring pixels
    subaffinemov = interp3(mov,NlocX,NlocY,NlocZ,interpolation);
    subaffinemov(black) = 0;
    
    affinemov(:,:,subranges(i):subranges(i+1)-1) = subaffinemov;

end

toc

parfor i = 1:originalimsize(3)
    k = num2str(i);
    while length(k) < 6
        k = strcat('0',k);
    end
    imwrite(uint16(affinemov(:,:,i)),[SavePath '/' k '.tif']);
end

end