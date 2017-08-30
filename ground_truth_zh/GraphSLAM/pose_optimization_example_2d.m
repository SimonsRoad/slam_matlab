% 2D Example of Pose Graph Optimization
% Data : 4/12/12
% Author : Soonhac Hong (sxhong1@ualr.edu)

function pose_optimization_example_2d()

% 2D case
pose_data=[1 1 0 0 0; 1 2 2 0 0 ; 2 3 2 0 pi/2; 3 4 2 0 pi/2; 4 5 2 0 pi/2 ; 5 2 2 0 pi/2]; % [first pose, second pose, constraint[x,y,theta]]
xinit = [0.5; 0.0; 0.2; 2.3; 0.1; -0.2; 4.1; 0.1;  pi/2; 4.0; 2.0;  pi; 2.1; 2.1; -pi/2]
motion_noise = [0.3;0.3;0.1];

variable_size = (size(pose_data,2)-2);  % size of each variable [x, y, r]
pose_num = size(unique(pose_data(:,1:2)),1)*variable_size;  % first position is not optimized.

Omega = zeros(pose_num,pose_num);
Xi = zeros(pose_num,1);
Odometry=zeros(pose_num,1);
%Odometry = zeros(pose_num,1);

% Fill the elements of Omega and Xi
% Initial point
for i=1:variable_size
    Omega(i,i) = 1;
    Xi(i) = pose_data(1,i+2);
    Odometry(i) = pose_data(1,i+2);  
end

for i=2:size(pose_data,1)
    unit_data = pose_data(i,:);
    current_index = unit_data(1);
    next_index = unit_data(2);
    movement = unit_data(3:2+variable_size);
    previous_theta = pose_data(i-1,2+variable_size);
    
    % Adjust index according to the size of each variable
    if current_index ~= 1
        current_index = (current_index - 1) * variable_size + 1;
    end
    if next_index ~= -1
        next_index = (next_index - 1) * variable_size + 1;
    end
    
   
    for j=0:variable_size-1
        % Fill diagonal elements of Omega
        switch j
            case 0
                diagonal_factor = cos(movement(3));
                offdiagonal_factor = 1;
            case 1
                diagonal_factor = cos(movement(3));
                offdiagonal_factor = -1;
            case 2
                diagonal_factor = 1;
                offdiagonal_factor = -1;
        end
                 
        Omega(current_index+j,current_index+j) = Omega(current_index+j,current_index+j) + diagonal_factor*motion_noise(j+1);
        Omega(next_index+j,next_index+j) = Omega(next_index+j,next_index+j) + 1/motion_noise(j+1);

        % Fill Off-diagonal elements of Omega
        Omega(current_index+j,next_index+j) = Omega(current_index+j,next_index+j) + (-1)/motion_noise(j+1);
        Omega(next_index+j,current_index+j) = Omega(next_index+j,current_index+j) + (-1)*diagonal_factor/motion_noise(j+1);
        if j <= 1
            Omega(current_index+j,current_index+j+offdiagonal_factor) = Omega(current_index+j,next_index+j+offdiagonal_factor) + (-1)*offdiagonal_factor*sin(movement(3))/motion_noise(j+1);
            Omega(next_index+j,current_index+j+offdiagonal_factor) = Omega(next_index+j,current_index+j+offdiagonal_factor) + offdiagonal_factor*sin(movement(3))/motion_noise(j+1);
        end

        % Fill Xi
        Xi(current_index+j) = Xi(current_index+j) + (-1)*movement(j+1)/motion_noise(j+1);
        Xi(next_index+j) = Xi(next_index+j) + movement(j+1)/motion_noise(j+1);
    end
    
    % Update Odometry
    if abs(current_index - next_index) == 3
        translation=[0 0 1]'; 
        for t=i:-1:2
            unit_movement=pose_data(t,3:5);
            translation = [cos(unit_movement(3)) -sin(unit_movement(3)) unit_movement(1); sin(unit_movement(3)) cos(unit_movement(3)) unit_movement(2); 0 0 1]*translation;
        end
        %translation = Odometry(current_index:current_index+1) + movement(1:2)';
        Odometry(next_index:next_index+1) = translation(1:2);
        orientation = Odometry(current_index+2) + movement(3);
        if orientation > pi*2
            orientation = orientation - pi*2;
        end
        Odometry(next_index+2) = orientation;
    end
    
end

%Omega
%Xi
%mu = Omega^-1 * Xi

% Using LM
xdata = Omega;
ydata = Xi;
%myfun = @(x,xdata)Rot(x(1:3))*xdata+repmat(x(4:6),1,length(xdata));
myfun = @(x,xdata)xdata*x(1:size(xdata,1));
options = optimset('Algorithm', 'levenberg-marquardt');
%x = lsqcurvefit(myfun, zeros(6,1), p, q, [], [], options);
x = lsqcurvefit(myfun, xinit, xdata, ydata, [], [], options)

x_mat = vec2mat(x,3);
Odometry_mat = vec2mat(Odometry,3);
xinit_mat = vec2mat(xinit,3);

plot(xinit_mat(:,1), xinit_mat(:,2) ,'bd-');
hold on;
plot(Odometry_mat(:,1), Odometry_mat(:,2) ,'gd-');
plot(x_mat(:,1), x_mat(:,2) ,'ro-');
hold off;
legend('Initial','Odometry','Optimized');
%legend('Initial','Optimized');
end