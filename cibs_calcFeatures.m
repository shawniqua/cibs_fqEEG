function featTable = cibs_calcFeatures(EEGtable)
% calculate EEG features of interest for a given set of EEGs

featTable = EEGtable;
dsDir = '//bigdatavuhcifs/PUL2/Data/Ely CT/Delirium/ac/Studies/Sedline/Sedline Data Transfers/EEGLAB/datasets/3q30x15min epochs';
% channames = {'Fp1', 'Fp2', 'F7', 'F8'};
shent = @(data) wentropy(data, 'shannon');

cparams.tapers = [3 5];
cparams.pad = -1;
cparams.fpass = [1 40];
cparams.err = [1 0.05];
cparams.trialave = 1;

cohparams = cparams;
cohparams.tapers = [5 9];

cspec = struct;
cspec4sv = struct;

for eegNo = 1:height(EEGtable)
    try
        EEG = pop_loadset('filename',EEGtable.EEGs{eegNo},'filepath',dsDir);
    catch
        fprintf('WARNING: Could not load EEG %s - skipping.\n', EEGtable.EEGs{eegNo})
        continue
    end
    
    % get spectral features
    cparams.Fs = EEG.srate;
    cohparams.Fs = EEG.srate;
    cohparams.err = [2 .05];
    cparams4sv = cparams;
    cparams4sv.trialave = 0;
    
    [nchs, ~, neps] = size(EEG.data);
    EEGdataTEC = permute(EEG.data,[2,3,1]); % time epochs chans
    AEprecision = nan(nchs);
    for ch=1:nchs
        [cspec(ch).S, cspec(ch).f, cspec(ch).Serr] = mtspectrumc(EEGdataTEC(:,:,ch),cparams);
        chData = EEG.data(ch,:,:);
        AEprecision(ch) = 0.1*(std(chData(:)));
    end
    allchsS = [cspec.S];  
    allchsavgS = mean(allchsS,2);
    featTable.rdp(eegNo) = mean(allchsavgS(cspec(1).f>1 & cspec(1).f<4))/mean(allchsavgS);
    featTable.rtp(eegNo) = mean(allchsavgS(cspec(1).f>4 & cspec(1).f<8))/mean(allchsavgS);
    featTable.rap(eegNo) = mean(allchsavgS(cspec(1).f>8 & cspec(1).f<13))/mean(allchsavgS);
    featTable.rb1p(eegNo) = mean(allchsavgS(cspec(1).f>13 & cspec(1).f<25))/mean(allchsavgS);
    featTable.rb2p(eegNo) = mean(allchsavgS(cspec(1).f>25 & cspec(1).f<40))/mean(allchsavgS);
    featTable.avgPower(eegNo) = mean(allchsavgS);
    
    % get spectral variability (20181107)
    rdp = nan(nchs,neps);
    rtp = nan(nchs,neps);
    rap = nan(nchs,neps);
    b1p = nan(nchs,neps);
    b2p = nan(nchs,neps);
    chAmp = nan(1,nchs);
    for ch=1:nchs
        [cspec4sv.S, cspec4sv.f, cspec4sv.Serr] = mtspectrumc(EEGdataTEC(:,:,ch),cparams4sv);
        % S is therefore #freqs x #epochs
        % and Serrr is hiLow x #freqs x #epochs
        meanS = mean(cspec4sv.S,1); % 1 x #ep
        rdp(ch,:) = mean(cspec4sv.S(cspec4sv.f>1 & cspec4sv.f<4,:),1)./meanS;
        rtp(ch,:) = mean(cspec4sv.S(cspec4sv.f>4 & cspec4sv.f<8,:),1)./meanS;
        rap(ch,:) = mean(cspec4sv.S(cspec4sv.f>8 & cspec4sv.f<13,:),1)./meanS;
        b1p(ch,:) = mean(cspec4sv.S(cspec4sv.f>13 & cspec4sv.f<25,:),1)./meanS;
        b2p(ch,:) = mean(cspec4sv.S(cspec4sv.f>25 & cspec4sv.f<40,:),1)./meanS;
        % also get mean analytic amplitude while you are going through channels
        [envhi, envlo] = envelope(EEGdataTEC(:,:,ch),round(EEG.srate/5),'analytic'); % these should be in samples x epochs
        chAmp(ch) = mean(mean(envhi-envlo)); 
    end
    featTable.svD(eegNo) = std(mean(rdp,1))/mean(mean(rdp));     % taking mean rel power across channels and calculating CoV of that
    featTable.svT(eegNo) = std(mean(rtp,1))/mean(mean(rtp));     % so this would be how the mean relative power varies cross epochs
    featTable.svA(eegNo) = std(mean(rap,1))/mean(mean(rap));     % still not sure if I should introduce log in here somewhere to normalize (normalize what?)
    featTable.svB1(eegNo) = std(mean(b1p,1))/mean(mean(b1p));     
    featTable.svB2(eegNo) = std(mean(b2p,1))/mean(mean(b2p));     
    featTable.sigAmp(eegNo) = mean(chAmp);
    
    % get interhemispheric coherence in low and high frequency ranges
    [coh,~, ~, ~, ~, f, ~, ~] = coherencyc(EEGdataTEC(:,:,3), EEGdataTEC(:,:,4), cohparams);
    featTable.ihcTemporalLow(eegNo) = mean(coh(f>1 & f<7));
    featTable.ihcTemporalHigh(eegNo) = mean(coh(f>8 & f<40));
    
    % get peak IHC frequency (although rare, account for possibility of
    % multiple frequencies with the same power)
    % (20181107)
    lowPeaks = f(coh == max(coh(f>1 & f<8))); 
    lowPeaks = lowPeaks(lowPeaks>1 & lowPeaks<8); 
    featTable.ihcLowPeak(eegNo) = round(lowPeaks(1));
    
    alphaPeaks = f(coh == max(coh(f>8 & f<13)));
    alphaPeaks = alphaPeaks(alphaPeaks>8 & alphaPeaks<13);
    featTable.ihcAlphaPeak(eegNo) = round(alphaPeaks(1));
    
    betaPeaks = f(coh == max(coh(f>13 & f<40)));
    betaPeaks = betaPeaks(betaPeaks>13 & betaPeaks<40);  
    featTable.ihcBetaPeak(eegNo) = round(betaPeaks(1));
    
    % get frontotemporal coherence
    [coh,~, ~, ~, ~, f, ~, ~, ~] = coherencyc(EEGdataTEC(:,:,1), EEGdataTEC(:,:,4), cohparams);
    featTable.ftXcLRLow(eegNo) = mean(coh(f>1 & f<7));
    featTable.ftXcLRHigh(eegNo) = mean(coh(f>8 & f<40));
    
    % get Shannon Entropy
    eegCell = mat2cell(EEG.data, 4,size(EEG.data, 2),ones(1,size(EEG.data,3))); % 1 cell per epoch
    eegCell = squeeze(eegCell);
    featTable.shEnt(eegNo) = -mean(cellfun(shent, eegCell)); % shannon entropy, averaged across all epochs
    
    % get Approximate Entropy (20181107)
    histPersp = round(EEG.srate/(15*2));
    ae = nan(nchs, neps);
    for ep = 1:neps
        for ch = 1:nchs
            ae(ch,ep) = ApEn(histPersp, AEprecision(ch), EEG.data(ch,:,ep));
        end
    end
    featTable.meanAE(eegNo) = mean(mean(ae));
    
    % get mean analytic amplitude
    

end