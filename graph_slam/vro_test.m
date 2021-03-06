%%
% Oct. 8 2015, David Z
% read dataset and using my VRO to get the result 
%

clear;
clc;
% clf;

%% global definition 
global_def; 
global g_data_dir  

addpath('../SIFT/sift-0.9.19-bin/sift');
addpath('../Localization'); 

pre_check_dir(g_data_dir);

%% Set initila parameters
global g_camera_type 
data_name = g_camera_type;

%% file path 
global g_src_data_path g_tar_data_path g_vo_data_dir
src_data_path = g_src_data_path;
tar_data_path = g_tar_data_path;

%% return parameters 
t = []; 
e = [];
pose_std = [];

index = 1; % index 
 
for j=1:20
    
    f = 77;
    
    %% load tar data 
    g_vo_data_dir = tar_data_path;
    [img1, frm1, des1, p1, ld_err] = load_camera_frame(f);
    if ld_err > 0
        fprintf('vro_test.m: no data for %d tar data, next frame!\n', f);
    end
    %% load src data 
    g_vo_data_dir = src_data_path;
    [img2, frm2, des2, p2, ld_err] = load_camera_frame(f);
    if ld_err > 0
        fprintf('vro_test.m: no data for %d src data, next frame!\n', f);
    end
    
    %% match this two frames 
    [t(:,index), pose_std(:,index), e(index)] = VRO(f, f, img1, img2, des1, frm1, p1, des2, frm2, p2); 
     
    %% record this result 
    if e(index) ~= 0 % fail 
        fprintf('vro_test.m: VRO failed at %d\n', f);
    else
        fprintf('vro_test.m: VRO succeed at %d = %f %f %f %f %f %f\n', f, t(:, index));
    end
    index = index + 1;
end 

%% output 

error_file_name = sprintf(strcat(g_data_dir, '/results/error.dat')); 
err_fid = fopen(error_file_name, 'w');
t(1:3,:) = t(1:3,:).*180./pi;
fprintf(err_fid, '%f %f %f %f %f %f\n', t);
fclose(err_fid);

%% statistical data
if size(t,1) > 1
    t_mean = mean(t'); 
    disp(t_mean);
    t_std = std(t');
    disp(t_std);
else
    disp(t);
end


