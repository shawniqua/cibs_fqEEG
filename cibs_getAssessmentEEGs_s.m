% cibs_getAssessmentEEGs_s.m
% wrapper function to call cibs_getRecordings based on all the assessment
% times listed in recordingLogTotal/allAssesssments
%
% SWR 20181024

% prereq:
% load recordingLogTotal.mat

for asn = 580:605
    cibs_getRecordings(allAssessments.subjID{asn}, allAssessments.date_time(asn), 'dsPath', 'M:\Delirium\ac\Studies\Sedline\Sedline Data Transfers\EEGLAB\datasets');
end