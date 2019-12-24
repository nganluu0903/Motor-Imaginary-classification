close;clc;clear;
addpath data2a\
file='A0%dT.gdf';
features=[];labels=[];
for i = 1:9
    filename=sprintf(file,i)
    [s,HDR]=sload(filename);
    % Step 1b: extract trigger and classlabels (if not already available) ==%
%--------- extraction from event table 
    ix = find((HDR.EVENT.TYP>hex2dec('300'))&(HDR.EVENT.TYP<hex2dec('30d'))); % 0x0300..0x03ff
    [i,j,HDR.Classlabel] = unique(HDR.EVENT.TYP(ix));

    t0 = HDR.EVENT.POS(ix);
    t0 = (t0(1) - HDR.TRIG(1))/HDR.SampleRate; 	% time between trial start and cue; 

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
    eegchan=find(HDR.CHANTYP=='E'); % select EEG channels 
    bands = [8,14;19,24;24,30]; % define frequency bands 
    win = 2; 	% length of smoothing window in seconds
    f3 = bandpower(s, HDR.SampleRate, bands, win);
    
% Step 4: Classification ==================== %
    TrialLen = 6; % seconds
    SegmentLen = 100; % samples
    NoS = ceil(TrialLen*HDR.SampleRate/SegmentLen);
    MODE.T   = reshape((1:NoS*SegmentLen),SegmentLen,NoS)';
    % valid segments for building classifier must be after cue.
    MODE.WIN = MODE.T(:,1) > 3*HDR.SampleRate+1;	% cue @ t=3s.
    MODE.t0= t0;
    MODE.t = [min(MODE.T(:)):max(MODE.T(:))]'/HDR.SampleRate;
    MODE.Segments = MODE.T;
    MODE.Fs = HDR.SampleRate;  
    
    TYPE.TYPE = 'LDA';	% classifier type 
    classlabels=HDR.Classlabel;
    [d c]=reshape_label_feature(f3, HDR.TRIG, HDR.Classlabel, MODE, [], TYPE);
%     if isempty(features)
        features=d;
        labels=c;
        lda = fitcdiscr(features,labels);
        pred_c = predict(lda,features);
        train_kappa = get_kappa(pred_c, labels,4)
%     else
%         [row col] = size(features);
%         [row1 col1]=size(d);
%         features(row+1:row+row1,:)=d;
%         labels(row+1:row+row1,:)=c;
%     end
end
% lda = fitcdiscr(features,labels);
% pred_c = predict(lda,features);
% accuracy = mean(pred_c==labels)
 
