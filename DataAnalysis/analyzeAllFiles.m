guy = 'Brian';
dataPath = 'Raw actiCHamp Files\';
electrodes = {'Oz', 'O1','O2'};

for i = 3:40
    if i < 10
        num = sprintf('000%s',i);
    else
        num = sprintf('00%s',i);
    end
    
    hdrFile = strcat(dataPath,guy,num,'.vhdr');
    trigFile = strcat(dataPath,guy,num,'.vmrk');
    
    eeg = bva_loadeeg(hdrFile);
    [fs label meta] = bva_readheader(hdrFile);
    
    %extracting specified electrode data
    idx = cellfun(@(str) find(strcmp(label, str)), electrodes);
    
    
end