function [ImageScaled, numScaledImgs] = myrescale(ImgPath, ImgType, defaultdepth, compratio)


Imgs = dir( [ ImgPath '/*' ImgType] ); %This contains a list of file names e.g. 'abcd/efgh.tif'
numImgs = size( Imgs, 1 );
info = imfinfo([ImgPath '/' Imgs(1).name] );
Height = info.Height; Width = info.Width;
I = zeros(Height,Width,defaultdepth);

parfor i = 1:numImgs
    I(:, :, i) = imread( [ImgPath '/' Imgs(i).name]);
end

parfor i = numImgs+1:defaultdepth
    I(:, :, i) = zeros(Height,Width);
end
disp('finish reading stack')

tic
T = maketform('affine',[compratio 0 0; 0 compratio 0; 0 0 compratio; 0 0 0;]);
R = makeresampler({'cubic','cubic','cubic'},'fill');
ImageScaled = tformarray(I,T,R,[1 2 3],[1 2 3], round(size(I)*compratio),[],0);
toc
numScaledImgs = size(ImageScaled,3);

end
