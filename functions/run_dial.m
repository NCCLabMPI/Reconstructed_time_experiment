function [ iT ] = run_dial(introspec_question)
clearvars -except introspec_question

global DIAL DIAL_SENSITIVITY_FACTOR line_height right_end left_end ScreenHeight ScreenWidth INTRO_UP INTRO_DOWN INTRO_CONFIRM

% line coordinates
line_height = ScreenHeight*(4/5);
left_end = [ScreenWidth*(1/4), line_height];
right_end = [ScreenWidth*(3/4), line_height];
line_length = right_end(1) - left_end(1);
iT = NaN;
% check if dial available
if DIAL
    handle = PsychPowerMate('Open');
    if isempty(handle) || handle == 0
        DIAL = 0;
        showMessage('WARNING!! NO DIAL!!');
        WaitSecs(1);
    end
end
WaitSecs(1);
% if no dial available
if ~DIAL
    % define random x starting position for cursor
    y = line_height;
    x = randi([round(left_end(1)), round(right_end(1))]);
    cursorPosition = x;
    cursorSpeed = DIAL_SENSITIVITY_FACTOR; 
    % Set backspace flag:
    return_ = 0;
    while return_ ~= 1
        
        % Get keyboard input:
        [keyIsDown, ~, keyCode] = KbCheck;
        
        if keyCode(INTRO_CONFIRM)
            return_ = 1;
        end
        % Move the cursor up when the up or down
        if keyCode(INTRO_UP)
            cursorPosition = cursorPosition + cursorSpeed;
        end
        if keyCode(INTRO_DOWN)
            cursorPosition = cursorPosition - cursorSpeed;
        end
        iT = round(((cursorPosition-left_end(1))/line_length)*1000);
        
        % restrict iT value to 0 to 1000
        if iT > 1000
            iT = 1000;
        elseif iT < 0
            iT = 0;
        end
        make_time_estimation_screen(iT, introspec_question)
    end    
    % Wait for the button to be released:
    while keyIsDown
        [keyIsDown, ~, ~] = KbCheck;
    end
else % if dial is available
    % get response parameters from dial
    [button, dialPos] = PsychPowerMate('Get', handle);
    % set reference
    dial_ref = dialPos;
    dial_start = randi(1000);
    while button == 0
        
        [button, dialPos] = PsychPowerMate('Get', handle);
        iT = (dialPos*DIAL_SENSITIVITY_FACTOR - dial_ref)+dial_start;
        
        % restrict iT value to 0 to 1000
        if iT > 1000
            iT = 1000;
            handle = PsychPowerMate('Open');
            dial_start = 1000;
        elseif iT < 0
            iT = 0;
            handle = PsychPowerMate('Open');
            dial_start = 0;
        end
        make_time_estimation_screen(iT, introspec_question);
    end
    
    % wait until button press is over to avoid overlapping responses
    while button == 1
        [button, ~] = PsychPowerMate('Get', handle);
    end
end
end