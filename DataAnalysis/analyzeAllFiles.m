close all;
clear all;

guy = 'Brian';
dataPath = 'Raw actiCHamp Files\';
%electrodes = {'Oz', 'O1','O2'};
sampSize = 512;
sampInterval = 60;

load('testFreqs.mat', 'testFreqs'); %testFreqs saved in .mat file

% second order iir notch filter coefficients for removing dc frequency
b = [0.934176819513501,-1.86835363902700,0.934176819513501];
a = [1,-1.88645575334848,0.893520555714383];

for elec = 1:15
    %file numbers 2- 39 are the tests where a single frequency was viewed
    %Connor's file #2 is missing the trigger, so just looped through files 3 to
    %39
  
    scores = cell(1,39);
    trigs = zeros(1,39);
        for trial = 3:39

            if trial < 10
                num = sprintf('000%i',trial);
            else
                num = sprintf('00%i',trial);
            end

            hdrFile = strcat(dataPath,guy,num,'.vhdr');
            trigFile = strcat(dataPath,guy,num,'.vmrk');

            eeg = bva_loadeeg(hdrFile);
            [fs label meta] = bva_readheader(hdrFile);
            electrodes = {label{elec}};

            %extracting specified electrode data
            idx = cellfun(@(str) find(strcmp(label, str)), electrodes);
            oscData = eeg(idx,:);

            %average all electrode channels together
            in = double(oscData);

            %we sampled at 500Hz, but plan to use 200 Hz --- resample
            in = resample(in,200,500);
            fs = 200;

            %read triggers, first trigger indicates the start of the file
            %the second trigger is what we care about
            trig = bva_readmarker(trigFile);
            trigs(trial) = trig(2);

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
                        [~,index1] = min(abs(f-testFreqs(trial-2)));

                        %idx of second harmonic of interest
                        [~,index2] = min(abs(f-testFreqs(trial-2)*2));
                        

                        score((j-sampSize)/sampInterval+1) = (P1(index1)+P1(index2))/mean(P1);

                    end
                end

            end
            scores(trial) = {score}; 
        end
        
    subplot(4,4,elec+1);
    plotData(scores,trigs,sampSize,sampInterval,electrodes);

end


%colormap(map)
colormap jet
colorbar

function plotData(scores,trigs,sampSize,sampInterval,electrode)
    hold on
    trigs = ceil((trigs-sampSize)./sampInterval+1)*200/500;

    scatter(trigs(3:39),3:39,[],'g','filled')

    for i = 3:length(scores)
        data = scores{i}./max(scores{i});


        %vq1 = interp1(xVals,data,1:maxL);

        %scores{i} = vq1;

        scatter(find(data<0.6),ones(1,length(data(data <0.6)))*(i),[],'black','filled');
        scatter(find(data>=0.6),ones(1,length(data(data >=0.6)))*(i),[],[1,0.078,0.576],'filled');

    end    

    scatter(trigs(3:39),3:39,[],'g','filled')


    ylim([3 length(scores)+2]);
    yticks(2:4:40);
    title(electrode)
    xlabel('time');
    ylabel('trial');

end


