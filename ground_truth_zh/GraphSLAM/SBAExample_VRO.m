%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GTSAM Copyright 2010, Georgia Tech Research Corporation, 
% Atlanta, Georgia 30332-0415
% All Rights Reserved
% Authors: Frank Dellaert, et al. (see THANKS for the full author list)
% 
% See LICENSE for the license information
%
% @brief An SFM example (adapted from SFMExample.m) optimizing calibration
% @author Yong-Dian Jian
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Modify for utilizing VRO
% Author : Soonhac Hong (sxhong1@ualr.edu)
% Date : 3/10/11

addpath('../localization');
addpath('../sr4k_projection');


import gtsam.*

%% Assumptions
%  - Landmarks as 8 vertices of a cube: (10,10,10) (-10,10,10) etc...
%  - Cameras are on a circle around the cube, pointing at the world origin
%  - Each camera sees all landmarks. 
%  - Visual measurements as 2D points are given, corrupted by Gaussian noise.

% Data Options
options.triangle = false;
options.nrCameras = 10;
options.showImages = false;

%% Generate data
%[data,truth] = VisualISAMGenerateData(options);
[data,truth] = VisualISAMGenerateData_FromVRO(options);

measurementNoiseSigma = 1.0;
pointNoiseSigma = 0.1;
cameraNoiseSigmas = [0.001 0.001 0.001 0.1 0.1 0.1 ...
                     0.001*ones(1,5)]';

%% Create the graph (defined in visualSLAM.h, derived from NonlinearFactorGraph)
graph = NonlinearFactorGraph;

 
%% Add factors for all measurements
measurementNoise = noiseModel.Isotropic.Sigma(2,measurementNoiseSigma);
for i=1:length(data.Z)
    for k=1:length(data.Z{i})
        j = data.J{i}{k};
        graph.add(GeneralSFMFactorCal3_S2(data.Z{i}{k}, measurementNoise, symbol('c',i), symbol('p',j)));
    end
end

%% Add Gaussian priors for a pose and a landmark to constrain the system
cameraPriorNoise  = noiseModel.Diagonal.Sigmas(cameraNoiseSigmas);
firstCamera = SimpleCamera(truth.cameras{1}.pose, truth.K);
graph.add(PriorFactorSimpleCamera(symbol('c',1), firstCamera, cameraPriorNoise));

pointPriorNoise  = noiseModel.Isotropic.Sigma(3,pointNoiseSigma);
graph.add(PriorFactorPoint3(symbol('p',1), truth.points{1}, pointPriorNoise));

%% Print the graph
graph.print(sprintf('\nFactor graph:\n'));


%% Initialize cameras and points close to ground truth in this example
initialEstimate = Values;
for i=1:size(truth.cameras,2)
    %pose_i = truth.cameras{i}.pose.retract(0.1*randn(6,1));
    %camera_i = SimpleCamera(pose_i, truth.K);
    %initialEstimate.insert(symbol('c',i), camera_i);
    initialEstimate.insert(symbol('c',i), truth.cameras{i});
    transform_i = truth.cameras{i}.pose.matrix;
    translation(i,:) = transform_i(1:3,4)';    
end
figure;
plot3(translation(:,1),translation(:,2),translation(:,3),'o-');
hold off;
axis equal;

for j=1:size(truth.points,2)
    %point_j = truth.points{j}.retract(0.1*randn(3,1));
    %initialEstimate.insert(symbol('p',j), point_j);
    initialEstimate.insert(symbol('p',j), truth.points{j});
end
initialEstimate.print(sprintf('\nInitial estimate:\n  '));

%marginals = Marginals(graph, initialEstimate);
plot3DPoints(initialEstimate);
%plot3DTrajectory(result, '*', 1, 8, marginals);


%% Fine grain optimization, allowing user to iterate step by step
parameters = LevenbergMarquardtParams;
parameters.setlambdaInitial(1.0);
parameters.setVerbosityLM('trylambda');

optimizer = LevenbergMarquardtOptimizer(graph, initialEstimate, parameters);

for i=1:5
    optimizer.iterate();
end

result = optimizer.values();
result.print(sprintf('\nFinal result:\n  '));


%% Plot results with covariance ellipses
marginals = Marginals(graph, result);
cla
hold on;

plot3DPoints(result, [], marginals);
plot3DTrajectory(result, '*', 1, 8, marginals);

axis([-40 40 -40 40 -10 20]);axis equal
view(3)
colormap('hot')
