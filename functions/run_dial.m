function [ iT ] = run_dial(introspec_question)
clearvars -except introspec_question

global DIAL DIAL_SENSITIVITY_FACTOR ScreenWidth line_length right_end left_end

% line coordinates
left_end = ScreenWidth*(1/4);
right_end = ScreenWidth*(3/4);
line_length = right_end - left_end;


% check if dial available
iT = 500;
handle = PsychPowerMate('Open');
if isempty(handle) || handle == 0
    DIAL = 0;
    showMessage('WARNING!! NO DIAL!!');
    KbWait
end

% if no dial available
if ~DIAL
    buttons = [0,0,0];

    ShowCursor('Arrow')
    while buttons(1) ~= 1

        [x,~,buttons,~,~,~] = GetMouse();

        iT = ((x-left_end)/line_length)*1000; 
        
        % restrict iT value to 0 to 1000
        if iT > 1000
            iT = 1000;
        elseif iT < 0
            iT = 0;
        end
        make_time_estimation_screen(iT, introspec_question)
    end
    HideCursor()

else % if dial is available
    % get response parameters from dial
    [button, dialPos] = PsychPowerMate('Get', handle);
    % set reference 
    dial_ref = dialPos;
    dial_start = 500;
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