function [data,truth] = VisualISAMGenerateData_SIM(options)
% VisualISAMGenerateData creates data for viusalSLAM::iSAM examples
% Authors: Duy Nguyen Ta and Frank Dellaert

%% Generate simulated data
import gtsam.*
if options.triangle % Create a triangle target, just 3 points on a plane
    nrPoints = 3;
    r = 10;
    for j=1:nrPoints
        theta = (j-1)*2*pi/nrPoints;
        truth.points{j} = Point3([r*cos(theta), r*sin(theta), 0]');
    end
else % 3D landmarks as vertices of a cube
    nrPoints = 8;
    truth.points = {Point3([10 10 10]'),...
        Point3([-10 10 10]'),...
        Point3([-10 -10 10]'),...
        Point3([10 -10 10]'),...
        Point3([10 10 -10]'),...
        Point3([-10 10 -10]'),...
        Point3([-10 -10 -10]'),...
        Point3([10 -10 -10]')};
end

%% Create camera cameras on a circle around the triangle
import gtsam.*
height = 10; r = 40;
truth.K = Cal3_S2(500,500,0,640/2,480/2);
data.K = truth.K;
noise = normrnd(0,0.034);  % SR4K noise : 0.01 [m]
for i=1:options.nrCameras
    theta = (i-1)*2*pi/options.nrCameras;
    t = Point3([r*cos(theta)+noise, r*sin(theta)+noise, height+noise]');
    truth.cameras{i} = SimpleCamera.Lookat(t, Point3, Point3([0,0,1]'), truth.K);
    % Create measurements
    for j=1:nrPoints
        % All landmarks seen in every frame
        data.Z{i}{j} = truth.cameras{i}.project(truth.points{j});
        data.J{i}{j} = j;
    end    
end

%% show images if asked
if options.showImages
    gui = gcf;
    for i=1:options.nrCameras
        figure(2+i);clf;hold on
        set(2+i,'NumberTitle','off','Name',sprintf('Camera %d',i));
        for j=1:nrPoints
            zij = truth.cameras{i}.project(truth.points{j});
            plot(zij.x,zij.y,'*');
            axis([1 640 1 480]);
        end
    end
    figure(gui);
end

%% Calculate odometry between cameras
for i=1:options.nrCameras-1
    odometry = truth.cameras{i}.pose.between(truth.cameras{i+1}.pose);
    data.odometry{i}=odometry;
end