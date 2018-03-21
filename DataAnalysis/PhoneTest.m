clear all
%%bluetooth setup
phoneName = 'Pixel';
bytesPerPacket = 83 ;
phone = Bluetooth(phoneName, 8);

%fopen(phone);


%%eeg data setup
path = 'Raw actiCHamp Files\';
guy = 'Brian';
number = '0024';
baselineFile = '0001';
electrodes = 'Oz';
    
%%filter things 
Fstop = 0.1;
Fpass = 5;
Astop = 80;
Apass = 0.1;
Fs = 250;

d = designfilt('highpassiir','FilterOrder',2, ...
  'PassbandFrequency',Fpass, ...
  'PassbandRipple',Apass,'SampleRate',Fs);
  
fvtool(d);



hdrFile = strcat(path,guy,number,'.vhdr');
trigFile = strcat(path,guy,number,'.vmrk');

eeg = bva_loadeeg(hdrFile);
[origfs label meta] = bva_readheader(hdrFile);
elecIdx = find(strcmp(label, electrodes));


trigs = bva_readmarker(trigFile);
trigs = trigs(2:end)*Fs/500;

oscData = eeg(elecIdx,:);
if length(elecIdx) == 1
    avgOscData_uf = double(oscData); % dont take mean of single electrode
else
    avgOscData_uf = double(mean(oscData)); %take mean of multiple channels?
end
avgOscData_uf = resample(avgOscData_uf,Fs,500);
avgOscData = filter(d,double(avgOscData_uf));
%get rid of error on each end due to filter and convert units to volts
avgOscData = avgOscData(250:length(avgOscData)-250)/10^6;

%convert data to two byte data
ampGain = 1000*101;
DataToSample = (avgOscData.*ampGain + 3.3)/2;
%clip if too high or too low
DataToSample(DataToSample > 3.3) = 3.3;
DataToSample(DataToSample < 0) = 0;

singleSamp = uint16(round(DataToSample/3.3*2^16));
Bytes = typecast(singleSamp, 'uint8');

%%%now send sixty samples at a time
numPackets = floor(length(avgOscData)/bytesPerPacket);
fopen(phone);

for i = 1:numPackets
    %2 Bytes per packet
    BytesToSend = Bytes(120*(i-1) + 1:120*i);
    fwrite(phone, BytesToSend);
    pause(1/3)
    
end



received = native2unicode(fread(phone, 40))
fclose(phone);



