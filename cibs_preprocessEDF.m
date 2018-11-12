function cibs_preprocessEDF(edfFile, varargin)
% use EEGLAB functions to process the dataset
% prerequisite: addpath <eeglab directory>
% Usage: cibs_preprocessEDF(edfFile, varargin)
%
% CHANGE CONTROL
% DATE      NAME        CHANGE
% 10/3/18   S. Williams Created

%start eeglab
addpath('C:\Users\wills14\Documents\MATLAB\EEGLAB\eeglab14_1_2b')
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
% load EEG dataset
for dsn = 1:length(dsNames)
    EEG = pop_loadset('filename',sprintf('%s.set',dsNames{dsn}),'filepath','C:\\Users\\wills14\\Documents\\SEDLINE\\data\\EEGLAB\\');
    % common average reference (pop_reref.m)
    EEG = pop_reref(EEG, []);
    EEG = pop_importevent( EEG, 'event','C:\\Users\\wills14\\Documents\\SEDLINE\\TEST EEG\\epochsFile.txt','fields',{'latency' 'type'},'timeunit',1);
    EEG = pop_epoch( EEG, {  '1'  }, [0  3], 'newname', sprintf('%s CAR 3q60',dsnames{dsn}), 'epochinfo', 'yes'); % This makes separate epochs
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, dsn+2,'gui','off');
end
EEG = pop_mergeset( ALLEEG, 3:dsn+2, 0); % merge last few EEGs
EEG = pop_saveset( EEG, 'filename','VMC-158_170512_1149-170512_1249 CAR 3q60.set','filepath','C:\\Users\\wills14\\Documents\\SEDLINE\\data\\EEGLAB\\3s epochs\\');
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%% create list of epoch start times (in seconds)
% epochs = (1:60:floor(EEG.times(end)*1e-3))';
% epochs = [epochs ones(length(epochs),1)];
% save epochsFile.txt epochs -ascii
%% load epochs as markers to current dataset
EEG = eeg_checkset( EEG );
EEG = pop_importevent( EEG, 'event','.\epochsFile.txt','fields',{'latency' 'type'},'timeunit',1);
%% select data using events (type=1, time range = [0 3]) and create a new dataset for them
EEG = eeg_checkset( EEG );
%     EEG = pop_rmdat( EEG, {'1'},[0 3] ,0); % This makes new annotations
%     at the beginning and end of each epoch, but doesn't make separate
%     epochs. 
%   This is better: Tools > Extract epochs. Do NOT remove baseline.
EEG = pop_epoch( EEG, {  '1'  }, [0  3], 'newname', 'EEG_CAR epochs', 'epochinfo', 'yes'); % This makes separate epochs
% save as a separate dataset, overwrite the previous one.
% something like: [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'setname','EEG_170512_121912_3sec','overwrite','on','gui','off');
% remove 
ALLEEG = pop_delset( ALLEEG, [1  2 ] );
%% review for artifact and reject some events (Tools > Reject Data Epochs by Inspection)
% Then you have to do Tools>Reject Marked Epochs to remove them.
%% save dataset as <filename>_PP.set
% EEG is now in format of C x S x E where C = channels, S = samples
% (timeseries), E = epochs
%% preprocess multiple datasets for a subject.
%% optionally concatenate 2 datasets to create 1 hour per evaluation (or do this up front?)
% Edit > Append datasets
%% run chronux multitaper functions vs MATLAB pmtm to get features.
cparams.tapers = [3 5];
cparams.pad = -1;
cparams.Fs = EEG.srate;
% cparams.fpass = [0 EEG.srate/2];
cparams.fpass = [0 40];
cparams.err = [1 0.05];
cparams.trialave = 1;

channames = {'Fp1', 'Fp2', 'F7', 'F8'};
%%
for ch=1:4
    [cspec(ch).S cspec(ch).f cspec(ch).Serr] = mtspectrumc(squeeze(EEG.data(ch,:,:)),cparams);
end
%% 
leadColors = [1 0 0; 1 1 0; 1 0 1; 0 0 1];
figure
for ch=1:4
%     figure
    plot(cspec(ch).f, 10*log10(cspec(ch).S), 'Color', leadColors(ch,:)/2); hold on
    plot(cspec(ch).f, 10*log10(cspec(ch).Serr), 'Color', leadColors(ch,:));
%     title(channames{ch})
end
axKids = findobj(gca);
lh2 = legend(axKids(end-1:-3:2), channames);
xlabel('Frequency (Hz)')
ylabel('Power (dB)')
title(strrep(EEG.setname, '_', ' '))


%% sample rough consolidation
allchs = [cspec.S];
% allchsdb = 10*log10(allchs);
allchsavg = mean(allchs,2);
rtp = mean(allchsavg(cspec(1).f>4 & cspec(1).f<8))/mean(allchsavg);
rap = mean(allchsavg(cspec(1).f>8 & cspec(1).f<13))/mean(allchsavg);
rb1p = mean(allchsavg(cspec(1).f>13 & cspec(1).f<25))/mean(allchsavg);
rb2p = mean(allchsavg(cspec(1).f>25 & cspec(1).f<40))/mean(allchsavg);
TP = mean(allchsavg);
relPowers(end+1,:) = [rtp rap rb1p rb2p TP]

tp = @(cspec) mean(mean([cspec.S],2));
end