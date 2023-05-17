% Clear the workspace and the screen
sca;
close all;
clear;

function_folder = [pwd,filesep,'functions\'];
addpath(function_folder)
subjectNum = 118;
introspec_question = 'vis';
initRuntimeParameters
initConstantsParameters(); % defines all constants and initilizes parameters of the program
initPsychtooblox();
key = 0;
number_of_cali_trails = 10;
% [iT] = run_dial(introspec_question);

calibration(5)

% while key ~= 1
% 
% [KeyIsDown, Resp_Time, Resp1] = KbCheck(compKbDevice);
% 
% if Resp1(spaceBar)
%     key = 1;
% elseif Resp1(RightKey)
%     iRT = iRT + 5; 
% elseif Resp1(LeftKey)
%     iRT = iRT - 5;
% end
% 
% if iRT > 1000
%     iRT = 1000;
% elseif iRT < 0
%     iRT = 0;
% end 
% 
% make_introspec_response_screen(iRT, introspec_question)
% end 


% Clear the screen
sca;