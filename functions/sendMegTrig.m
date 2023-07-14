%SENDTRIG
% MEEG trigger function : manages sending triggers and documents them in internal program array "triggers".
function [LTP_State, triggerOnset] = sendMegTrig(trigCode,LPT_OBJECT,LPT_ADDRESS)

% Query the port state:
LTP_State = io64( LPT_OBJECT, LPT_ADDRESS );
% Send error if the port is not on state 0:
if LTP_State ~= 0 && trigCode ~=0
    error('Port occupied! State: %d',LTP_State)
end
% Send the trigger
io64(LPT_OBJECT,LPT_ADDRESS,trigCode);
triggerOnset = GetSecs();
LTP_State = trigCode;
end