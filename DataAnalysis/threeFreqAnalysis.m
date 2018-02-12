close all;
clear all;

guy = 'Brian';
dataPath = 'Raw actiCHamp Files\';
%electrodes = {'Oz', 'O1','O2'};
sampSize = 512;
sampInterval = 60;

thresh = 0.5; %threshold expressed as a multiple of the mean of fft
                %thresh = 1/2 for 6.67, 7.5,8.57
                %thresh = 1 for 12,20,30


files = 30:35; %12,20,30 Hz stimuli
freqs = [6.67 7.5 8.57];

%files = 30:35; %6.67,7.5,8.57 Hz stimuli
%freqs = [6.67 7.5 8.57];

load('testFreqs.mat', 'testFreqs'); %testFreqs saved in .mat file

% second order iir high pass filter coefficients for removing dc frequency
b = [0.934176819513501,-1.86835363902700,0.934176819513501];
a = [1,-1.88645575334848,0.893520555714383];


trShift = min(files)-1;


baseScore = @(frequencies,fftMag) relHeight(frequencies,fftMag,1) ;

for elec = 1:15
    baselineCF = ones(1,3);
    for i = 1:3
        baseScore = @(frequencies,fftMag) relHeight(frequencies,fftMag,i) ;
        baselineCF(i) = mean(analyzeFFT(guy,1,dataPath,elec,sampSize,sampInterval,b,a,freqs, baseScore));
    end
    
    scoreFunc = @(frequencies, fftMag) bestFreq(frequencies,fftMag,thresh,baselineCF);
    %file numbers 2- 39 are the tests where a single frequency was viewed
    %Connor's file #2 is missing the trigger, so just looped through files 3 to
    %39
  
    scores = cell(1,length(files));
    trigs = zeros(1,length(files));
    for i = 1:length(files)
        trial = files(i);
        [scores{trial-trShift}, trigs(trial-trShift), electrode]  = analyzeFFT(guy,trial,dataPath,elec,sampSize,sampInterval,b,a,freqs, scoreFunc);
    end
        
    subplot(4,4,elec+1);
    plotData(scores,trigs,sampSize,sampInterval,electrode);

end
legend({'Trigger','No Frequency Detected','6.67 Hz','7.5 Hz', '8.57 Hz'},'FontSize',9);
%map =   [0,0,0;
 %       1,0.753,0.796;
  %      156/255,34/255,93/255;     
   %     1,0.078,0.576 ];
%colormap(map)



function plotData(scores,trigs,sampSize,sampInterval,electrode)
    hold on
    trigs = ceil((trigs-sampSize)./sampInterval+1)*200/500;

    scatter(trigs,30:length(scores)+29,[],'g','filled')

    for i = 1:length(scores)
        data = scores{i};


        %vq1 = interp1(xVals,data,1:maxL);

        %scores{i} = vq1;

        scatter(find(data==0),ones(1,length(data(data ==0)))*(i+29),[],'black','filled');
        scatter(find(data==1),ones(1,length(data(data ==1)))*(i+29),[],[  1,0.753,0.796],'filled');
        scatter(find(data==2),ones(1,length(data(data ==2)))*(i+29),[],[1,0.078,0.576],'filled');
        scatter(find(data==3),ones(1,length(data(data ==3)))*(i+29),[],[156/255,34/255,93/255 ],'filled');

    end    
    scatter(trigs,30:length(scores)+29,[],'g','filled')

    ylim([30 length(scores)+29]);
    yticks(29:35);
    title(electrode)
    xlabel('Time');
    ylabel('Trial');

end

function [score,trig,electrodes] = analyzeFFT(guy,fileNum,path,elec,sampSize,sampInterval,b,a,freqs, scoreFunc)
    
    if fileNum < 10
        num = sprintf('000%i',fileNum);
    else
        num = sprintf('00%i',fileNum);
    end

    hdrFile = strcat(path,guy,num,'.vhdr');
    trigFile = strcat(path,guy,num,'.vmrk');

    eeg = bva_loadeeg(hdrFile);
    [fs, label, meta] = bva_readheader(hdrFile);
    electrodes = {label{elec}};

    %extracting specified electrode data
    idx = cellfun(@(str) find(strcmp(label, str)), electrodes);
    oscData = eeg(idx,:);

    %average all electrode channels together
    in = double(oscData);
    if length(electrodes) > 1
        in = mean(in);
    end

    %we sampled at 500Hz, but plan to use 200 Hz --- resample
    in = resample(in,200,fs);
    fs = 200;

    %read triggers, first trigger indicates the start of the file
    %the second trigger is what we care about
    try
        trig = bva_readmarker(trigFile);
        trig = trig(2);
    catch ME
        trig = 0;
    end

    %all data imported now we can loop through samples
    out = zeros(size(in));
    score = zeros(1,ceil((length(in)-sampSize)/sampInterval));

    %assume initial rest for first two samples
    out(1) = b(1)*in(1);
    out(2) = b(1)* in(2) + b(2)*in(1) - a(2)*out(1);
    for j = 3:length(in)
        %treat the beginning of the loop as a single incoming sample 
        out(j) = b(1)*in(j) + b(2)*in(j-1) + b(3)*in(j-2)-a(2)*out(j-1)-a(3)*out(j-2);

        if j>=sampSize
            if mod((j-sampSize),sampInterval) == 0
                Y = fft(out(j-sampSize+1:j),sampSize*2);

                P2 = abs(Y/sampSize*2);
                P1 = P2(1:sampSize*2/2+1);
                P1(2:end-1) = 2*P1(2:end-1);

                f = fs*(0:(sampSize*2/2))/sampSize/2;

                %idx of fundamental freq of interest
                [~,index11] = min(abs(f-freqs(1)));

                %idx of second harmonic of interest
                [~,index12] = min(abs(f-freqs(1)*2));

                %idx of fundamental freq of interest
                [~,index21] = min(abs(f-freqs(2)));

                %idx of second harmonic of interest
                [~,index22] = min(abs(f-freqs(2)*2));

                %idx of fundamental freq of interest
                [~,index31] = min(abs(f-freqs(3)));

                %idx of second harmonic of interest
                [~,index32] = min(abs(f-freqs(3)*2));

                score((j-sampSize)/sampInterval+1) = scoreFunc([(P1(index11)+P1(index12)) (P1(index21)+P1(index22)) (P1(index31)+P1(index32))], P1);
                
                %%%uncomment to plot fft over time
                %plot(f,P1);
              
                %if j > trig*200/500
                %    title('trigger')
                %end
                %pause   

            end
        end

    end


end

function score = bestFreq(freqMags,fft,thresh,filtCF)
    [fMag ,score] = max(freqMags - filtCF*mean(fft));
     
    if fMag < thresh*mean(freqMags)
        score = 0;
    end


end

function score = relHeight(freqMags,fft,freqIndex)

    score = freqMags(freqIndex)/mean(fft);
end
