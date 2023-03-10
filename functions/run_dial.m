function [ iT ] = run_dial(introspec_question)

global spaceBar RightKey LeftKey compKbDevice DIAL

iT = 0;

if ~DIAL
    key = 0;

    while key ~= 1

        [~, ~, Resp1] = KbCheck(compKbDevice);

        if Resp1(spaceBar)
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
    % Response params
    handle = PsychPowerMate('Open');
    [button, dialPos] = PsychPowerMate('Get', handle);

    dial_ref = dialPos;
    while button == 0

        [button, dialPos] = PsychPowerMate('Get', handle);
        iT = dialPos - dial_ref;
        make_introspec_response_screen(iT, introspec_question)

    end
end

end