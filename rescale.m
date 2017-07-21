function [ImageScaled, DepthScaledImgs] = rescale(ImgPath, ImgType, compratio, Parallelmode)
% This function is a subfunction of runANTsregistration.m
% To save memory and computational time, downsamping is performed first in
% xy-dimension, then in z-dimension. Although this two-step downsampling is 
% not as accurate as three-dimensional one-step downsampling, 
% the difference shows ignorable affects in registration process.
% Written by Tatsuya C. Murakami, 20/Jul/2017.
Imgs = dir( [ ImgPath '/*' ImgType] ); %This contains a list of file names e.g. 'abcd/efgh.tif'
Depth = size( Imgs, 1 );

resizeinfo = size(imresize(imread([ImgPath '/' Imgs(1).name]),compratio));
Ixydown = zeros(resizeinfo(1),resizeinfo(2),Depth);

if Parallelmode == 0
    for i = 1:Depth
        Ixydown(:,:,i) = imresize(imread([ImgPath '/' Imgs(i).name]),compratio);
    end
elseif Parallelmode == 1
    parfor i = 1:Depth
        Ixydown(:,:,i) = imresize(imread([ImgPath '/' Imgs(i).name]),compratio);
    end
else
    error('Parallelmode shoule be 0 or 1.')
end
fprintf('Finished downsampling in xy-dimension: %s\n', ImgPath)

[y, x, z] = ndgrid(linspace(1,resizeinfo(1),resizeinfo(1)),...
    linspace(1,resizeinfo(2),resizeinfo(2)),...
    linspace(1,Depth,round(Depth*compratio)));
ImageScaled = interp3(Ixydown,x,y,z);
DepthScaledImgs = size(ImageScaled,3);

fprintf('Finished downsampling: %s\n', ImgPath)

end
