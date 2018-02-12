close all
clear all


Fstop = 0.1;
Fpass = 5;
Astop = 80;
Apass = 0.1;
Fs = 200;

d = designfilt('highpassiir','FilterOrder',2, ...
  'PassbandFrequency',Fpass, ...
  'PassbandRipple',Apass,'SampleRate',Fs);

%[b,a] = iirnotch(1e-9,0.1);

fvtool(d)


guy = 'Kris';
number = '0020';

path = 'Raw actiCHamp Files\';
%[hdrFile, path] = uigetfile('Raw actiCHamp Files\*.vhdr');


hdrFile = strcat(path,guy,number,'.vhdr');
trigFile = strcat(path,guy,number,'.vmrk');

eeg = bva_loadeeg(hdrFile);
[origfs label meta] = bva_readheader(hdrFile);


trigs = bva_readmarker(trigFile);
trigs = trigs(2:end)*Fs/500;

oscData = eeg(13,:);
avgOscData_uf = double(oscData);
%avgOscData_uf = double(mean(oscData));
avgOscData_uf = resample(avgOscData_uf,Fs,500);
avgOscData = filter(d,double(avgOscData_uf));
%avgOscData = avgOscData_uf(trigs:trigs+511) - mean(avgOscData_uf(trigs:trigs+511));
avgOscData = avgOscData(trigs:trigs+511);

subplot(2,1,1)
title('Raw Data Compared with Resampled and Filtered Data (Oz)')
plot(oscData)
xlabel('Sample')
ylabel('Original Signal (\muV)')
subplot(2,1,2)
plot(avgOscData);
xlabel('Sample')
ylabel('Processed Signal (\muV)')
figure()

Y = fft(double(avgOscData),1024);


L = length(avgOscData);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L;

thresh = 2*mean(P1(and(f>3,f<50)));

plot(f,P1)
hold on
%plot(f,thresh*ones(size(f)))
%xlim([10,50])

title('FFT of Signal Containing 20 Hz SSVEP')
xlabel('Frequency (Hz)')
ylabel('FFT Magnitude')



