%start eeglab
addpath('C:\Users\wills14\Documents\MATLAB\EEGLAB\eeglab14_1_2b')
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% dsNames = dir('VMC-158_170515*.set')
% dsNames = {dsNames.name}'
for dsn = 1:length(dsNames)
  dsNames{dsn} = dsNames{dsn}(1:end-4);
end

for dsn = 1:length(dsNames)
    EEG = pop_loadset('filename',sprintf('%s.set',dsNames{dsn}),'filepath','C:\\Users\\wills14\\Documents\\SEDLINE\\data\\EEGLAB\\');
    % common average reference (pop_reref.m)
    EEG = pop_reref(EEG, []);
    EEG = pop_importevent( EEG, 'event','C:\\Users\\wills14\\Documents\\SEDLINE\\TEST EEG\\epochsFile.txt','fields',{'latency' 'type'},'timeunit',1);
    EEG = pop_epoch( EEG, {  '1'  }, [0  3], 'newname', sprintf('%s CAR 3q60',dsNames{dsn}), 'epochinfo', 'yes'); % This makes separate epochs
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, dsn+2,'gui','off');
end
EEG = pop_mergeset( ALLEEG, 1:dsn, 0); % merge EEGs
EEG = pop_saveset( EEG, 'filename',sprintf('%s-%s CAR3q60.set', dsNames{1}, dsNames{end}(end-12:end)),'filepath','C:\\Users\\wills14\\Documents\\SEDLINE\\data\\EEGLAB\\3s epochs\\');
% [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
