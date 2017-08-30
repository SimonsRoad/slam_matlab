function dump2ply(fname, x, y, z, img)

[m, n] = size(x); 
vx = reshape(x', m*n, 1); 
vy = reshape(y', m*n, 1); 
vz = reshape(z', m*n, 1);
vi = double(reshape(img', m*n, 1)); 
txt_result = [vx vy vz vi vi vi];
% txt_result=load('pointCLoud.dat');
fid=fopen(fname, 'w');
fprintf(fid, 'ply\nformat ascii 1.0\nelement vertex %d\nproperty float x\nproperty float y\nproperty float z\nproperty uchar red\nproperty uchar green\nproperty uchar blue\nend_header\n', m*n);
fclose(fid);

dlmwrite(fname,...
    txt_result,...
    '-append', 'delimiter',' ');

end