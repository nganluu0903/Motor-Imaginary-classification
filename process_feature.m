function [s,feat, HDR, features, labels, MODE]=process_feature(s,HDR)
    %Filter [7 - 30] Hz
    s = remove_artifacts(s,HDR);
    %Correction of EOG artifacts: regress_eog.m, get_regress_eog.m   
    eogchan=identify_eog_channels(HDR); 
    eegchan=find(HDR.CHANTYP=='E'); % exclude any non-eeg channel. 
    R = regress_eog(s,eegchan,eogchan); 
    s = s*R.r0; 	% reduce EOG artifacts 
    s=s(:,1:22);
    %resampling 
    DIV = 4; 
    s = rs(s,HDR.SampleRate,HDR.SampleRate/DIV);   % downsampling by a factor of DIV; 
    HDR.SampleRate = HDR.SampleRate/DIV; 
    HDR.EVENT.POS = round(HDR.EVENT.POS/DIV); 
    HDR.EVENT.DUR = round(HDR.EVENT.DUR/DIV); 
    HDR.TRIG      = round(HDR.TRIG/DIV); 
    %Common spatial pattern filter
    csp_matrix = multiclass_csp(s,HDR);    
    s=s*csp_matrix;
    % Feature extraction ====================%
    bands=[4,8;8,12;12,16;16,20;20,24;24,28;28,30];
%     bands = [8,14;19,24;24,30]; % define frequency bands 
    win = 2; 	% length of smoothing window in seconds
    feat = bandpower(s, HDR.SampleRate, bands, win);
    TrialLen = 6; % seconds
    SegmentLen = 100; % samples
    NoS = ceil(TrialLen*HDR.SampleRate/SegmentLen);
    MODE.T   = reshape((1:NoS*SegmentLen),SegmentLen,NoS)';
    % valid segments for building classifier must be after cue.
    MODE.WIN = MODE.T(:,1) > 3*HDR.SampleRate+1;	% cue @ t=3s.
    MODE.Segments = MODE.T;
    [features, labels]=reshape_label_feature(feat, HDR.TRIG, HDR.Classlabel, MODE);
end
