
% MEEG trigger function trigger hardware intilization
function [ Object,LPT_address ] = init_LPT()
    global EEG_MACHINE_HEX
    LPT_address = hex2dec(EEG_MACHINE_HEX); %Machine specific address

    Object=io64;
    status=io64(Object);
    if status
        disp ('fail')
        Object = [];
    end
    % Set to state 0:
    io64(Object,LPT_address,0);
end