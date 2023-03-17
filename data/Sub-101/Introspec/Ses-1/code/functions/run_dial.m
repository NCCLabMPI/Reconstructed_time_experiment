function [ iT ] = run_dial(introspec_question)
clearvars -except introspec_question

global RightKey LeftKey compKbDevice DIAL ValidationKey

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
    key = 0;

    while key ~= 1
        [~, ~, Resp1] = KbCheck(compKbDevice);
        if Resp1(ValidationKey)
            key = 1;
        elseif Resp1(RightKey)
            iT = iT + 5;
        elseif Resp1(LeftKey)
            iT = iT - 5;
        end
        
        if iT > 1000
            iT = 1000;
        elseif iT < 0
            iT = 0;
        end
        make_time_estimation_screen(iT, introspec_question)
    end

else % if dial is available
    % get response parameters from dial
    [button, dialPos] = PsychPowerMate('Get', handle);
    % set reference 
    dial_ref = dialPos + 500;
    while button == 0

        [button, dialPos] = PsychPowerMate('Get', handle);
        iT = dialPos - dial_ref;

        if iT > 1000
            iT = 1000;
            dial_ref = 1000;
        elseif iT < 0
            iT = 0;
            dial_ref = 0;
        end
        make_time_estimation_screen(iT, introspec_question);
    end

    % wait until button press is over to avoid overlapping responses
    while button == 1
        [button, ~] = PsychPowerMate('Get', handle);
    end
end

end