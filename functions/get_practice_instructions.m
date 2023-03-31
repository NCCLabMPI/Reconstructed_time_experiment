function [msg] = get_practice_instructions(practice_type)

global RESPONSE_BOX subjectNum

if RESPONSE_BOX
    if mod(subjectNum, 2) == 0
        high_pitch_repsonse_button = 'green button';
        low_pitch_repsonse_button = 'blue button';
        vis_target_respnse_button = 'red button';

    else
        high_pitch_repsonse_button = 'red button';
        low_pitch_repsonse_button = 'yellow button';
        vis_target_respnse_button = 'green button';
    end

else
    high_pitch_repsonse_button = '2';
    low_pitch_repsonse_button = '1';
    vis_target_respnse_button = 'space bar';
end


% Practice start message
if strcmp(practice_type, 'auditory')
    msg = sprintf('We will start with the pratice \n\n of the auditory task. \n\n Press %s for low tone \n\n and %s for high tones \n\n Press space to continue...', ...
        low_pitch_repsonse_button, high_pitch_repsonse_button);
elseif strcmp(practice_type, 'visual')
    msg = sprintf('We will continue with the pratice \n\n of the visual task. \n\n Press %s when you see the target \n\n Press space to continue...', ...
        vis_target_respnse_button);
elseif strcmp(practice_type, 'auditory_and_visual')
    msg = 'We will continue with the pratice \n\n of both tasks at the same time. \n\n Press space to continue...';
elseif strcmp(practice_type, 'introspection')
    msg = 'We will continue with the \n\n estimation of reaction time. \n\n Use the dial to provide your repsonses \n\n Press space to continue...';
end

end

