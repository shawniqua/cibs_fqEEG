function EEG = cibs_getRecordings(subjID, time, varargin)
% given a subject ID and an assessment time, pulls out the EEG records
% within a given timeframe before and after the assessment time, based on
% the recording log file. By default assumes recording log file is in the
% current directory, and creates a new dataset in a subdirectory of the path
% where the datasets are located.
%
% Usage: EEG = cibs_getRecordings(subjID, time, <Name/Value>)
% Optional arguments:
%   epochLen (in seconds, default 3)
%   epochQ (in seconds, default 30)
%   period (2 element array indicating pre- and post- buffer, in minutes, default [-5 10])
%   rlFile (recording Log, should be in the same folder as the EEG datasets)
%   dsPath (where the datasets are located)
%   newDSfolder (subfolder name where the new datasets will be saved)
% 
% SWR 2018/10/09

p = inputParser;

addRequired(p, 'subjID')
addRequired(p, 'time') % assessment start time to the minute, in matlab date format
addParameter(p, 'epochLen', 3) % in seconds
addParameter(p, 'epochQ', 30) % pick epochs every Q seconds
addParameter(p, 'period', [-5 10]) % number of minutes before/after assessment time to pull epochs from
addParameter(p, 'rlFile', 'recordingLogTotal.mat') % assume recording log file is in same directory as originating EEG datasets
addParameter(p, 'dsPath', '\\bigdatavuhcifs.mc.vanderbilt.edu\PUL2\Data\Ely CT\Delirium\ac\Studies\Sedline\Sedline Data Transfers\EEGLAB\datasets')
addParameter(p, 'newDSfolder', 'placeholderFolderName')

parse(p, subjID, time, varargin{:});
epochLen = p.Results.epochLen;
epochQ = p.Results.epochQ;
period = p.Results.period;
dsPath = p.Results.dsPath;
rlFile = p.Results.rlFile;
% CHECK that you have all the parameters including subjID and time
if ~ismember('newDSfolder', p.UsingDefaults)
    newDSfolder = p.Results.newDSfolder;
else
    newDSfolder = sprintf('%dq%dx%dmin epochs', epochLen, epochQ, period(2)-period(1));
end
newDSpath = fullfile(dsPath, newDSfolder);
% CHECK that newDSfolder is appropriately set (with and without explicit setting in command line) 

pdStart = time + period(1)/(60*24);
pdEnd = time + period(2)/(60*24);

load(fullfile(dsPath, rlFile), 'recordingLog')
currentSets = [];  % probably obsolete - was used for tracking datasets to clear

%% iff eeglab not loaded, open it
if ~exist('pop_loadset.m', 'file')
    [ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
end

%% look through dataset table for the appropriate dataset(s)

% prelim look at number of assessments with -15/+15 recordings - 194
% for asn = 1:height(assessments)
%     nRecs(asn,1) = sum(ismember(recordingLog.subjID, assessments.id{asn}) & recordingLog.endTime > period(asn,1) & recordingLog.startTime < period(asn,2));
% end

% CHECK that pdStart and pdEnd are appropriate, 
% CHECK that EEGLAB is started if not previously
% CHECK what are the datasets currently in EEGLAB (don't really want to
% overwrite any or lose data, also want to save the correct datasets)
relevantDSs = strcmp(recordingLog.subjID, subjID) & ...
    recordingLog.endTime > pdStart & ...
    recordingLog.startTime < pdEnd;
relvtDSixs = find(relevantDSs);

if isempty(relvtDSixs)
    fprintf('NO EEG RECORDINGS FOUND FOR THIS PERIOD.\n')
    fprintf('subject ID: %s\ntime: %s\nrecording period:%s to %s\n',...
        subjID, datestr(time), datestr(pdStart), datestr(pdEnd));
    return
end

% CHECK that the appropriate datasets are identified out of recordingLog
for dsn = 1:length(relvtDSixs) 
    rcdNum = relvtDSixs(dsn);
    recdStartEnd = recordingLog{rcdNum,[2 3]};
    offsetStartInSec = max(0,pdStart-recdStartEnd(1))*3600*24; 
    offsetEndInSec = min(recdStartEnd(2)-datenum(0,0,0,0,0,epochLen)-recdStartEnd(1), pdEnd-recdStartEnd(1))*3600*24; % subtract epochLen to ensure enough space to accommodate a full epoch
    eventTimes = (offsetStartInSec:epochQ:offsetEndInSec)';
    eventTimes = [ones(length(eventTimes),1) eventTimes]; % first type then latency
    if size(eventTimes,1) == 1
        eventTimes = [eventTimes; 2 eventTimes(2)]; %workaround to accommodate EEGLAB limitation in handling single event upload
    end
    % CHECK that event times are as expected
    EEG = pop_loadset('filename',sprintf('%s.set', recordingLog.dsName{rcdNum}),'filepath',dsPath);
    % initialize ALLEEG if necessary
    if ~exist('ALLEEG', 'var')
        ALLEEG = [];
    end
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    EEG = eeg_checkset( EEG );
    % CHECK which dataset just got loaded
    EEG = pop_reref(EEG, []); % Common average reference
    EEG = pop_importevent( EEG, 'append','no','event',eventTimes,'fields',{'type' 'latency'},'timeunit',1,'align',nan);
    [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    EEG = eeg_checkset( EEG );
    % CHECK dataset now is CAR and events flagged
    EEG = pop_epoch( EEG, { '1' }, [0  epochLen], 'newname', sprintf('%s %dq%d', recordingLog.dsName{rcdNum}, epochLen, epochQ), 'epochinfo', 'yes');
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'overwrite','on','gui','off'); 
    EEG = eeg_checkset( EEG );
    currentSets = [currentSets CURRENTSET];
    % CHECK current list of datasets against currentSets var
end
%% downsample to the lowest common denominator (note this is better done BEFORE epoching)
srates = [ALLEEG(currentSets).srate];
minSrate = min(srates);
needsDownSampling = find(srates>minSrate);
for dsndsn = 1:length(needsDownSampling)
    set2resample = currentSets(needsDownSampling(dsndsn));
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'retrieve',set2resample,'study',0); 
    fprintf('resampling dataset %s to %f\n', EEG.setname, minSrate)
    EEG = pop_resample( EEG,minSrate);
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'overwrite','on','gui','off');
end
%% merge datasets
EEG = pop_mergeset( ALLEEG, currentSets, 0);  % append the extracted epoch datasets
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'setname',sprintf('%s_%s',subjID, datestr(pdStart, 'yymmdd_HHMMSS')),'gui','off');
currentSets = [currentSets CURRENTSET];
EEG = eeg_checkset( EEG );
% CHECK list of current sets
if exist(newDSpath, 'dir')
    fprintf('Storing EEG %s in folder %s\n', EEG.setname, newDSpath);
else
    fprintf('Creating new folder %s to store EEG %s\n', newDSpath, EEG.setname);
    mkdir(newDSpath)
end
EEG = pop_saveset( EEG, 'filename',sprintf('%s.set', EEG.setname),'filepath',newDSpath);
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
EEG = eeg_checkset( EEG );

end

