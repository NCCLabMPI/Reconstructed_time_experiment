function [ ] = Instructions(task)
global NEXT_SLIDE PREVIOUS_SLIDE
% Select the instructions to display:
instructions_root = fullfile(pwd, "instructions", task);
instructions_files = dir(sprintf("%s%s*.PNG", instructions_root, filesep));

% Setting the slide number to 1 to initiate the while loop
slide_i = 1;
% displays all instruction screens
while slide_i<= size(instructions_files,1) % Looping until we went through all slides:
    % Showing instruction slide
    showInstructions(fullfile(instructions_files(slide_i).folder, instructions_files(slide_i).name));
    CorrectKey = 0; % Setting the CorrectKey to 0 to initiate the loop
    while ~CorrectKey % As long as a non-accepted key is pressed, keep on asking
        [keyIsDown, ~, InstructionsResp] = KbCheck();
        if InstructionsResp(NEXT_SLIDE) % If the participant press the right key, increment by 1 the slide number
            slide_i = slide_i + 1;
            CorrectKey = 1;
        elseif InstructionsResp(PREVIOUS_SLIDE) % Else if the participant pressed the left key:
            if slide_i == 1 % If we are at slide one, that doesn't work
                CorrectKey = 0;
            else % Otherwise, just go back one slide
                slide_i = slide_i - 1;
                CorrectKey = 1;
            end
        else
            CorrectKey = 0;
        end
    end
    % Wait for key release:
    while keyIsDown
        [keyIsDown, ~, ~] = KbCheck;
    end
end
end
