function plot_gt()
inch2m = 0.0254;        % 1 inch = 0.0254 m

gt_x = [0 0 190 910 965 965 910 50 0 0];
gt_y = [0 24 172.5 172.5 122.5 -122.5 -162.5 -162.5 -24 0];

gt_x = gt_x * inch2m;
gt_y = gt_y * inch2m;

gt_x2 = [0 0 60 60+138 60+138+40 60+138+40 60+138 60 0 0];
gt_y2 = [0 24 38.5+40 38.5+40 38.5 -38.5 -38.5-40 -38.5-40 -24 0];

gt_x2 = gt_x2 * inch2m;
gt_y2 = gt_y2 * inch2m;

figure;
plot(gt_x,gt_y,'r-','LineWidth',2);
hold on;
plot(gt_x2,gt_y2,'r-','LineWidth',2);
axis equal
hold off;

end