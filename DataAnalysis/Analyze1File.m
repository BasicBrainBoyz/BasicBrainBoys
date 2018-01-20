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


guy = 'Brian';
number = '0004';

path = 'Raw actiCHamp Files\';
%[hdrFile, path] = uigetfile('Raw actiCHamp Files\*.vhdr');


hdrFile = strcat(path,guy,number,'.vhdr');
trigFile = strcat(path,guy,number,'.vmrk');

eeg = bva_loadeeg(hdrFile);
[fs label meta] = bva_readheader(hdrFile);


trigs = bva_readmarker(trigFile);
trigs = trigs(2:end);

oscData = eeg(13:15,:);

avgOscData_uf = double(mean(oscData));
avgOscData_uf = resample(avgOscData_uf,200,500);
avgOscData = filter(d,double(avgOscData_uf));
%avgOscData = avgOscData_uf(trigs:trigs+511) - mean(avgOscData_uf(trigs:trigs+511));
avgOscData = avgOscData(trigs:trigs+511);
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
%xlim([10,50])



