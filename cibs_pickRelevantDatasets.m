function relevantDatasets = cibs_pickRelevantDatasets(subjID, varargin)

p = inputParser();
addRequired(p, subjID);
addParameter(p, period);
addParameter(p, recordingLog, 'C:\Users\wills14\Documents\SEDLINE\data\EEGLAB\recordingLogTotal.mat');

parse(p, subjID, varargin)
subjID = p.Results.subjID;
period = p.Results.period;

if (~exist('recordingLog', 'var') || ismember(varargin, 'recordingLog'))
    rL = load(p.Results.recordingLog);
    recordingLog = rL.recordingLog;
end

relevantDatasets = recordingLog(ismember(recordingLog.subjID, subjID) &...
    recordingLog.startTime > period(2) &...
    recordingLog.endTime < period(1),:);
end
