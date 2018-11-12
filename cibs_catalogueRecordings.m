function [recordingLog, warningLog] = cibs_catalogueRecordings(subjFolders)

% go through and find all the recordings, create EEGLAB datasets to be saved
% in my own separate folder, and  make a log of them for sifting through
% later. saves recordingLog to a path in the current working directory.
% PREREQUISITE: ADD TO PATH EEGLAB.
% ASSUMPTION: There should be no duplicate datasets with the same start time and the
% same subject ID.
%
% Usage: recordingLog = cibs_catalogueRecordings(subjFolders)

% Shawniqua Williams Roberson 2018/10/09

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

recordingDir = 'M:\Delirium\ac\Studies\Sedline\Sedline Data Transfers';  
% recordingDir = '/Users/shawniqua/Google Drive/Projects/ICUdelirium';
recordingLog = struct; % ('VariableNames', {'subjID', 'startTime', 'endTime', 'dsName', 'dir'});
nextRecord = 1;
warningLog = struct;
nextMsg = 1;
dsDir = 'M:\Delirium\ac\Studies\Sedline\Sedline Data Transfers\EEGLAB\datasets';    % 20181024 rerun for VMC-197
% dsDir = 'C:\Users\wills14\Documents\SEDLINE\data\EEGLAB';                         % 20181010 run
% dsDir = '/Users/shawniqua/Google Drive/Projects/ICUdelirium/EEGLAB/datasets';
wd = pwd;

for sn = 1:length(subjFolders)
    
    switch subjFolders{sn}
        case {'VIN-0045VMO-069'}
            subj = 'VIN-0045';
        case {'VMC-171VMO-023'}
            subj = 'VMC-171';
        case {'VMO-078VIN-0052'}
            subj = 'VMO-078';
        case {'VMO-083 VIN0056'}
            subj = 'VMO-083';
        otherwise
            subj = subjFolders{sn};
    end
        
    fprintf('processing subject: %s\n', subj)
    cd(fullfile(recordingDir, subjFolders{sn}))
    try
        cd('edf')
    catch
        disp('apparently no edf subfolder. perusing subfolders...')
    end
    dirContents = dir;
    subDirs = dirContents([dirContents.isdir]);
    subDirs = subDirs(3:end);
    for sdn = 1:length(subDirs)
        % get a list of the edfs.
        cd(subDirs(sdn).name)
        edfList = dir;           
        edfList = edfList(endsWith({edfList.name}, '.edf'));
        
        % load each one and create an EEGLAB dataset
        for fileNum = 1:length(edfList)
            try
                EEG = pop_biosig(edfList(fileNum).name, 'importevent','off');
                setName = [subj '_' edfList(fileNum).name(5:end-4)];
                EEG.setname = setName; % for shortcut
                %%{
                % This section commented out for ptList 23:28 shortcut (see notes 10/10/18)
                [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',setName,'gui','off');
                EEG = eeg_checkset( EEG );
                EEG = pop_saveset( EEG, 'filename',sprintf('%s.set',setName),'filepath',dsDir);
                [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
                ALLEEG = pop_delset( ALLEEG, 1 );
                %}
                
                % chart this record in the recording log
                recordingLog(nextRecord).subjID = subj;
                try
                    recordingLog(nextRecord).startTime = datenum(EEG.setname(end-12:end), 'yymmdd_HHMMSS');
                    recordingLog(nextRecord).endTime = recordingLog(nextRecord).startTime + (EEG.times(end)*1e-3/(60*60*24));
                catch
                    warningLog(nextMsg).dsName = EEG.setname;
                    warningLog(nextMsg).msg = 'Cannot assign dataset start/end times';
                    nextMsg = nextMsg+1;
                end
                recordingLog(nextRecord).dsName = EEG.setname;
                recordingLog(nextRecord).sourceDir = pwd;
                nextRecord = nextRecord+1;
            catch
                warningLog(nextMsg).dsName = edfList(fileNum).name;
                warningLog(nextMsg).msg = 'Cannot load .edf file - skipping.';
                nextMsg = nextMsg+1;
            end
        end
        cd ..
    end
end
recordingLog = struct2table(recordingLog);
cd(wd)
rlFilename = sprintf('recordingLog_%s', datestr(now, 'yyyymmdd_HHMMSS'));
save(rlFilename, 'recordingLog', 'warningLog', 'subjFolders')