close;clc;clear;
warning('off','all');
filename = dir('BCICIV_2a_gdf/*T*.gdf');
cd BCICIV_2a_gdf;

%Design a band-pass filter (7-35Hz)
fs=250;
% Wn=[1 45]/(fs/2);
% [b,a]=butter(20,Wn,'bandpass');
d = fdesign.bandpass('N,F3dB1,F3dB2',6,7,35,250);
Hd = design(d,'butter'); %use butterworth

%Load data and apply the filter
for j = 1:length(filename)
    file = filename(j).name;
    [s, HDR] = sload(file);
    type=HDR.EVENT.TYP;
    pos=HDR.EVENT.POS;
    dur=HDR.EVENT.DUR;
    fs = HDR.SampleRate;
    iv_c1=1; iv_c2=1;
    for i=1:size(type,1)
        if type(i,1)==276 %open
            subdata=s(pos(i,1):pos(i,1)+dur(i,1),:);
            [m,n]=size(subdata);
            sig_C1(1:m,1:n,iv_c1,j)=subdata(:,:);
%             filter_sig_C1(1:m,1:n,iv_c1,j)=filtfilt(b,a,subdata);
            filter_sig_C1(1:m,1:n,iv_c1,j)= filter(Hd,subdata);
            iv_c1=iv_c1+1;
        elseif type(i,1)==277 %close
            subdata=s(pos(i,1):pos(i,1)+dur(i,1),:);
            [m,n]=size(subdata);            
            sig_C2(1:m,1:n,iv_c2,j)=subdata(:,:);
            filter_sig_C2(1:m,1:n,iv_c2,j)= filter(Hd,subdata);
%             filter_sig_C2(1:m,1:n,iv_c2,j)=filtfilt(b,a,subdata);
            iv_c2=iv_c2+1;
        end
    end
end

x=sig_C1(:,:,1,2);
[N,m]=size(x);
t = [0:1:N-1]/fs;
y=filter_sig_C1(:,:,1,2);
figure(1);
subplot(211);
plot(t,x(:,1)); xlim([0 3]); %plot the initial data
title('Original Signal'); xlabel('Time(s)');
ylabel('Voltage(mV)');
subplot(212);
plot(t,y(:,1));xlim([0 3]); %plot the filter signal
title('Filtered Signal'); xlabel('Time(s)');
ylabel('Voltage(mV)');

%EOG removal
eogchan = [23 24 25]; %identify the eog channels 
% eogchan can be matrix in order to convert 
%     monopolar EOG to bipolar EOG channels
eegchan = find(HDR.CHANTYP=='E'); %identify non-eeg channel
R = regress_eog(y, eegchan,eogchan);
y1 = y*R.r0; % reduce EOG artifacts
figure(2);
subplot(211);
eogdata = y(:, [23 24 25]); %select 3 EOG channels
plot(t, eogdata); xlim([0 3]); %plot 3 EOG channels
legend('channel 23', 'channel 24', 'channel 25');
title('EOG Signal');
xlabel('Time(s)');
ylabel('Voltage(mV)');
subplot(212);
plot(t,y1(:,1));xlim([0 3]); %plot the signal after remove EOG
title('EOG Removal Signal');
xlabel('Time(s)');
ylabel('Voltage(mV)');