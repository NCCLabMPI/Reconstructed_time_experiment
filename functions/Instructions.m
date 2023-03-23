function [ ] = Instructions()
global INSTRUCTIONS1 INSTRUCTIONS2 INSTRUCTIONS3 INSTRUCTIONS4 INSTRUCTIONS5 INSTRUCTIONS6 INSTRUCTIONS7
global compKbDevice
global RightKey LeftKey introspec

if introspec
    InstructionsPaths = [INSTRUCTIONS1;INSTRUCTIONS2;INSTRUCTIONS3;INSTRUCTIONS5;INSTRUCTIONS6;INSTRUCTIONS7];
else
    InstructionsPaths = [INSTRUCTIONS1;INSTRUCTIONS2;INSTRUCTIONS3;INSTRUCTIONS4];
end

% Setting the slide number to 1 to initiate the while loop
InstructionSlideNum = 1;
% displays all instruction screens
while InstructionSlideNum<= size(InstructionsPaths,1) % Looping until we went through all slides:
    % Showing instruction slide
    showInstructions(InstructionsPaths(InstructionSlideNum,:));
    CorrectKey = 0; % Setting the CorrectKey to 0 to initiate the loop
    while ~CorrectKey % As long as a non-accepted key is pressed, keep on asking
        [~, InstructionsResp, ~] =KbWait(compKbDevice,3);
        if InstructionsResp(RightKey) % If the participant press the right key, increment by 1 the slide number
            InstructionSlideNum = InstructionSlideNum + 1;
            CorrectKey = 1;
        elseif InstructionsResp(LeftKey) % Else if the participant pressed the left key:
            if InstructionSlideNum == 1 % If we are at slide one, that doesn't work
                CorrectKey = 0;
            else % Otherwise, just go back one slide
                InstructionSlideNum = InstructionSlideNum - 1;
                CorrectKey = 1;
            end
        else
            CorrectKey = 0;
        end
    end
end
end
