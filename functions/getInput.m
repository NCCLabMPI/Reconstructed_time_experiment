
% GETINPUT a single iteration of input seeking, returns the RT and address of key pressed
% Input:
% -------
% key - the identity of the key pressed by the user
% Resp_Time - the RT of the user's key press
% PauseTime - If the pause key is pressed, the duration of the pause is
% recorded to make sure we account for it when starting again!
function [ key, Resp_Time ] = getInput()

global abortKey VIS_RESPONSE_KEY VIS_TARGET_KEY
global AUD_RESPONSE_KEY_HIGH HIGH_PITCH_KEY AUD_RESPONSE_KEY_LOW LOW_PITCH_KEY
global NO_KEY ABORT_KEY
key = NO_KEY;

[KeyIsDown, Resp_Time, Resp1] = KbCheck();

if KeyIsDown
    if Resp1(VIS_RESPONSE_KEY)
        key = VIS_TARGET_KEY;
    elseif Resp1(AUD_RESPONSE_KEY_HIGH)
        key = HIGH_PITCH_KEY;
    elseif Resp1(AUD_RESPONSE_KEY_LOW)
        key = LOW_PITCH_KEY;
    elseif Resp1(abortKey)
        key = ABORT_KEY;
    else
        key = Resp1;
    end
end
if key == NO_KEY
    Resp_Time = [];
end
end