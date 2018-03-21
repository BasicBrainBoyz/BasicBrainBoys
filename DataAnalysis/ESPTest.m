close all;
clear all;

espName = 'Neurotransmitter';
espPort = 2;

bytesPerPacket = 166;
sampFreq = 250;
secToPlot = 1;

esp = Bluetooth(espName, espPort);

fopen(esp);
fwrite(esp, uint8('M'));

data = [];
figure()
while(1)
    newDataBytes = uint8(fread(esp, bytesPerPacket,'uint8'));
    newData = ((single(typecast(fliplr(newDataBytes'), 'int16'))/2^15)*3.3*2-3.3/2)';


    data = [data; flipud(newData)];
    figure(1)
    if length(data) > secToPlot*sampFreq
        plot(data(end-secToPlot*sampFreq:end)');
    else 
        plot(data')
    end
    title('Last one second of data')
    
    figure(2)
    plot(data)
    title('All the datas')
    drawnow
end
