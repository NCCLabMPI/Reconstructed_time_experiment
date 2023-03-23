function [msg] = get_practice_instructions(practice_type)

% Practice start message
if strcmp(practice_type, 'auditory')
    msg = 'We will start with the pratice \n\n of the auditory task. \n\n Press space to continue...';
elseif strcmp(practice_type, 'visual')
    msg = 'We will continue with the pratice \n\n of the visual task. \n\n Press space to continue...';
elseif strcmp(practice_type, 'auditory_and_visual')
    msg = 'We will continue with the pratice \n\n of both tasks at the same time. \n\n Press space to continue...';
elseif strcmp(practice_type, 'introspection')
    msg = 'We will continue with the \n\n estimation of reaction time. \n\n Press space to continue...';
end

end

