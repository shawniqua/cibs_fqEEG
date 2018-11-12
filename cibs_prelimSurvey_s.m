% cibs_prelimSurvey.m
%
% get some prelim descriptive statistics on the assessments

load('M:\Delirium\ac\Studies\Sedline\Sedline Data Transfers\EEGLAB\datasets\recordingLogTotal.mat', 'allAssessments')

subjs = unique(allAssessments.subjID);

for subjNo = 1:length(subjs)
    subjID = subjs{subjNo};
    assmtDurDays(subjNo) = max(allAssessments.date_time(ismember(allAssessments.subjID, subjID)))-min(allAssessments.date_time(ismember(allAssessments.subjID, subjID)));
end
medAsDur = median(assmtDurDays)
minMaxAsDur = minmax(assmtDurDays)

%%