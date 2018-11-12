function fh = cibs_plotFeatVSrassCAM(featTable, feature)
% plots specified feature against RASS, different colors for each CAM value

camCols = 'brk';
fh = figure;
for camVal = 0:2
    scatter(featTable.rass(featTable.cam==camVal), featTable.(feature)(featTable.cam==camVal), camCols(camVal+1)); hold on
end
legend({'CAM negative', 'CAM positive', 'CAM unknown'})
xlabel('RASS')
ylabel(feature)
title(sprintf('%s vs RASS', feature))