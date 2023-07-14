
%SHOWBLOCKBEGINSCREEN shows the block begin screen and returns a timestap
% input:
% ------
% trial_mat - the trial matrix 
% trial_number - number of currrent trial
%
% output:
% -------
% time - the exact time in which it was presented

function [ time ] = showMiniBlockBeginScreen(trial_mat, trial_number)

    global gray PRESS_SPACE ScreenWidth ScreenHeight stimSizeHeight originalWidth originalHeight stimSizeLength  
    global MINIBLOCK_TEXT text fifthStimPosition sixthStimPosition w  fourthStimPosition firstStimPosition secondStimPosition thirdStimPosition PHOTODIODE

    % get pointer for targets
    ptr_target_01 = getPointer(trial_mat.target_01{trial_number}, "center");
    ptr_target_02 = getPointer(trial_mat.target_02{trial_number}, "center");
    
    Screen('FillRect', w, gray);


    % This will scale the stimuli length by the change in height
    stimSizeLength = round((stimSizeHeight/originalHeight) * originalWidth);

    % stimuli location in block splash screen (instruction screen between blocks)
    % firstStimPosition = round([ScreenWidth*(1/4), ScreenHeight*(1/3)] - [stimSizeLength/2 , stimSizeHeight/2]);
    secondStimPosition = round([ScreenWidth*(2/4), ScreenHeight*(1/3)] - [stimSizeLength/2, stimSizeHeight/2]);
    % thirdStimPosition = round([ScreenWidth*(3/4), ScreenHeight*(1/3)] - [stimSizeLength/2, stimSizeHeight/2]);
    % fourthStimPosition = round([ScreenWidth*(1/4), ScreenHeight*(2/3)] - [stimSizeLength/2 , stimSizeHeight/2]);
    fifthStimPosition = round([ScreenWidth*(2/4), ScreenHeight*(2/3)] - [stimSizeLength/2, stimSizeHeight/2]);
    % sixthStimPosition = round([ScreenWidth*(3/4), ScreenHeight*(2/3)] - [stimSizeLength/2, stimSizeHeight/2]);
 
    DrawFormattedText(w, textProcess(MINIBLOCK_TEXT), 'center', round(ScreenHeight*(1/15)), text.Color);
    
    % Screen('DrawTexture',w, ptr_target_01(3),[],[firstStimPosition, firstStimPosition + [stimSizeLength stimSizeHeight]]);
    Screen('DrawTexture',w, ptr_target_01(1),[],[secondStimPosition, secondStimPosition + [stimSizeLength stimSizeHeight]]);
    % Screen('DrawTexture',w, ptr_target_01(2),[],[thirdStimPosition, thirdStimPosition + [stimSizeLength stimSizeHeight]]);
    % Screen('DrawTexture',w, ptr_target_02(3),[],[fourthStimPosition, fourthStimPosition + [stimSizeLength stimSizeHeight]]);
    Screen('DrawTexture',w, ptr_target_02(1),[],[fifthStimPosition, fifthStimPosition + [stimSizeLength stimSizeHeight]]);
    % Screen('DrawTexture',w, ptr_target_02(2),[],[sixthStimPosition, sixthStimPosition + [stimSizeLength stimSizeHeight]]);
        
    DrawFormattedText(w, textProcess(PRESS_SPACE), 'center', round((ScreenHeight*(5/6))), text.Color);
    

if PHOTODIODE
    drawPhotodiodBlock('off');
end
[~, time] = Screen('Flip', w);
end