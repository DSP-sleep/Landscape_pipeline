function affinematrix = return_affine_mat(AffinePath)
% This function is a subfunction of warpimage.m
% This function extract affine matrix from output result of registration.
% Written by Tatsuya C. Murakami, 20/Jul/2017.

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
