% cibs_getAssessments_s.m
%
% pulls data from Assessments.xls to a table in matlab
% SWR 20181024

dataDir = 'M:\Delirium\ac\Studies\Sedline\Sedline Data Transfers';
assessmentFile = 'All Assessments on Sedline Subjects 20181024.xlsx';

allAssessments = readtable(fullfile(dataDir, assessmentFile));

allAssessments.date_time = datenum(allAssessments.sl_date)+datenum(allAssessments.sl_cam_rass_time);
% allAssessments.date_time
% datestr(allAssessments.date_time)

allAssessments = allAssessments(:,[1 8 7 6]);
allAssessments.Properties.VariableNames{4} = 'cam';
allAssessments.Properties.VariableNames{3} = 'rass';
