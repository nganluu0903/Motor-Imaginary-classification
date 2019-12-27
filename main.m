close;clc;clear;
addpath data2a\
file='A0%dT.gdf';
features=[];labels=[];

for k = 1:9
    filename=sprintf(file,k);
    [s,HDR]=sload(filename);
%     % Step 1b: extract trigger and classlabels (if not already available) ==%
% %--------- extraction from event table 
%     ix = find((HDR.EVENT.TYP>hex2dec('300'))&(HDR.EVENT.TYP<hex2dec('30d'))); % 0x0300..0x03ff
%     [i,j,HDR.Classlabel] = unique(HDR.EVENT.TYP(ix));
% 
%     t0 = HDR.EVENT.POS(ix);
%     t0 = (t0(1) - HDR.TRIG(1))/HDR.SampleRate; 	% time between trial start and cue; 

%   2c: resampling 
    DIV = 4; 
    s = rs(s,250,62.5);   % downsampling by a factor of DIV; 
    HDR.SampleRate = HDR.SampleRate/DIV; 
    HDR.EVENT.POS = round(HDR.EVENT.POS/DIV); 
    HDR.EVENT.DUR = round(HDR.EVENT.DUR/DIV); 
    HDR.TRIG      = round(HDR.TRIG/DIV); 

%   2d: Correction of EOG artifacts: regress_eog.m, get_regress_eog.m   
    eogchan=identify_eog_channels(filename); 
	% eogchan can be matrix in order to convert 
      	%     monopolar EOG to bipolar EOG channels
    eegchan=find(HDR.CHANTYP=='E'); % exclude any non-eeg channel. 
    R = regress_eog(s,eegchan,eogchan); 
    s = s*R.r0; 	% reduce EOG artifacts 
    s=s(:,1:22);
% Step 3: Feature extraction ====================%
    bands = [8,14;19,24;24,30]; % define frequency bands 
%     bands = [8,14;19,24];
    win = 2; 	% length of smoothing window in seconds
    f3 = bandpower(s, HDR.SampleRate, bands, win);
    TrialLen = 6; % seconds
    SegmentLen = 100; % samples
    NoS = ceil(TrialLen*HDR.SampleRate/SegmentLen);
    MODE.T   = reshape((1:NoS*SegmentLen),SegmentLen,NoS)';
    % valid segments for building classifier must be after cue.
    MODE.WIN = MODE.T(:,1) > 3*HDR.SampleRate+1;	% cue @ t=3s.
    MODE.Segments = MODE.T;
%     TYPE.TYPE = 'LDA';	% classifier type   
    [features, labels]=reshape_label_feature(f3, HDR.TRIG, HDR.Classlabel, MODE);
% Step 4: Classification ==================== %
    lda = fitcdiscr(features, labels);
    %Compute loss of model and loss of cross-validate model
    %To make sure model is not overfitting
    ResubErr(1,k) = resubLoss(lda);
    
    cp = cvpartition(labels,'KFold',10);
    cvmodel = crossval(lda,'CVPartition',cp);
    CVErr(1,k) = kfoldLoss(cvmodel);
    %Compute kappa score
    pred_c = predict(lda,features);
    kappa = get_kappa(pred_c, labels,4);
    train_kappa(1,k)=kappa;     
end
mean(train_kappa)
