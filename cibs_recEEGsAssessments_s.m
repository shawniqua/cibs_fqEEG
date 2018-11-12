% cibs_recEEGsAssessments_s.m
% reconcile EEGs in folder to assessments

EEGs = dir('V*set');
EEGs = {EEGs.name}';
%%
assessmentNum = nan(length(EEGs),1);
for en = 1:length(EEGs)
EEGstart = datenum(EEGs{en}(end-16:end-4), 'yymmdd_HHMMSS');
EEGend = EEGstart+datenum(0,0,0,0,15,0);
EEGsubjID = EEGs{en}(1:end-18);
assessmentNum(en) = find(ismember(allAssessments.subjID, EEGsubjID) & round(allAssessments.date_time,6)==round(EEGstart+datenum(0,0,0,0,5,0),6));
end

%%
concern = nan(length(EEGs),1);
comment = cell(length(EEGs),1);
for en=1:length(EEGs)
    concern(en) = input(sprintf('Concern for %s? 0=no, 1=minor, 2=major: ',EEGs{en}));
    comment{en} = input('Comment: ', 's');
end

%% put it all together
EEGtable = table(EEGs, assessmentNum, concern, comment);
% and add RASS and CAM
EEGtable.rass = allAssessments{EEGtable{:,2},3};
EEGtable.cam = allAssessments{EEGtable{:,2},4};

%% STILL NEED TO LOWER CONFIDENCE FOR THE ASSESSMENTS DONE PRIOR TO 7AM