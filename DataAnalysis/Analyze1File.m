close all
clear all


Fstop = 1;
Fpass = 10;
Astop = 25;
Apass = 0.5;
%Fs = 500;

%d = designfilt('highpassfir','StopbandFrequency',Fstop, ...
  %'PassbandFrequency',Fpass,'StopbandAttenuation',Astop, ...
  %'PassbandRipple',Apass,'SampleRate',Fs,'DesignMethod','equiripple');

[b,a] = iirnotch(0.001,0.03);

fvtool(b,a)


guy = 'Kris';
number = '0005';

path = 'Raw actiCHamp Files\';
%[hdrFile, path] = uigetfile('Raw actiCHamp Files\*.vhdr');


hdrFile = strcat(path,guy,number,'.vhdr');
trigFile = strcat(path,guy,number,'.vmrk');

eeg = bva_loadeeg(hdrFile);
[fs label meta] = bva_readheader(hdrFile);


trigs = bva_readmarker(trigFile);
trigs = trigs(2:end);

oscData = eeg(13:15,:);

avgOscData_uf = mean(oscData);
%avgOscData = filter(b,a,double(avgOscData_uf));
avgOscData = avgOscData_uf(trigs:trigs+511) - mean(avgOscData_uf(trigs:trigs+511));
%avgOscData = avgOscData(trigs:trigs+511);
plot(avgOscData);
figure()

Y = fft(double(avgOscData),1024);


L = length(avgOscData);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = fs*(0:(L/2))/L;

thresh = 2*mean(P1(and(f>3,f<50)));

plot(f,P1)
hold on
plot(f,thresh*ones(size(f)))
xlim([10,50])



