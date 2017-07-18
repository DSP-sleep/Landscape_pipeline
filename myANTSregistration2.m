function myANTSregistration2(fixedImg,moveImg,regresultPath,option,iteration_parameter)

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
disp('start registration');
tic

scriptPath = [regresultPath '/command.sh'];
fid = fopen(scriptPath,'wt');

out1 = [regresultPath '/ex_.nii'];
%out2 = [regresultPath '/result.nii.gz'];
if strcmp(option,'affine')
    cmd = sprintf(['ANTS 3 ' ...
        '-i 0 ' ...
        '-o %s ' ...
        '--MI-option 64x300000 ' ...
        '-m CC[%s,%s,1,5]'],out1,fixedImg,moveImg);
elseif strcmp(option,'SyN')
    cmd = sprintf(['ANTS 3 ' ...
        '-i ' iteration_parameter ' '...
        '-o %s ' ...
        '--MI-option 64x300000 ' ...
        '-m CC[%s,%s,1,5]'],out1,fixedImg,moveImg);
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
%status = system(['c3d ' out2 ' -o ' regresultPath '/result.tif']);
%if strcmp(option,'SyN')
%    gunzip([regresultPath '/ex_1Warp.nii.gz'], regresultPath);
%end
toc
end