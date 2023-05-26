%SHOWSTIMULI - shows a stimuli
% input:
% ------
% miniBlocks - the main data structure of the experiment
% blockNum - mini-block number of the stimuli to be presented
% tr - trial number of the stimuli to be presented
% parctice - in the practice, we don't want to flash the photodiode on. So
% if we are in the practice, let it off
% output:
% -------
% stimuliTiming - the time in which the stimuli was presented

function [ stimuliTiming ] = showStimuli(texture) % miniBlocks, blockNum, tr, Photodiode)
global PHOTODIODE
global stimSizeLength stimSizeHeight % texture
global gray w center  originalHeight originalWidth
stimSizeLength = round((stimSizeHeight/originalHeight) * originalWidth);

Screen('FillRect', w, gray);

drawFrame();

x = transpose(center) - [stimSizeLength/2 stimSizeHeight/2];
y = transpose(center) + [stimSizeLength/2 stimSizeHeight/2];

Screen('DrawTexture',w, texture,[],[x y]);
if PHOTODIODE
    drawPhotodiodBlock('on');
end
drawFixation()
[~,stimuliTiming] = Screen('Flip', w, [], 1);
end
