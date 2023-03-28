function [blk_add] = get_practice_feedback(block_mat, practice_type)
global RestartKey spaceBar compKbDevice

% Set the button press message:
button_press_msg = sprintf('\n\n Press %s if you wish to continue \n\n press %s if you wish to repeat this practice', 'space', 'r');

% Compute the scores of the practice block based on the block matrix:
[~, perf] = compute_performance(block_mat);

if strcmp(practice_type, 'visual')
    feedback_msg = sprintf('You correctly detected %d out of %d visual targets \n\n You incorrectly pressed a button to %d out of %d non-targets', ...
        perf.hits, perf.hits + perf.misses, perf.fa, perf.fa + perf.cr);
elseif strcmp(practice_type, 'auditory')
    feedback_msg = ['Your auditory score is ', num2str(round(perf.aud_mean_accuracy*100)), '%'];
elseif strcmp(practice_type, 'auditory_and_visual')
    feedback_msg = sprintf("Your auditory score is %d \n\n You correctly detected %d out of %d visual targets \n\n You incorrectly pressed a button to %d out of %d non-targets", ...
        round(perf.aud_mean_accuracy*100), perf.hits, perf.hits + perf.misses, perf.fa, perf.fa + perf.cr);
end
% Concatenate teh feedback message with the button press one:
feedback_msg = [feedback_msg, button_press_msg];
% Show the message:
showMessage( feedback_msg );

% Get the response feedback:
accepted_key = 0;
while ~accepted_key
    [~, practice_feedback_key, ~] =KbWait(compKbDevice,3);
    % Get the feedback:
    if practice_feedback_key(RestartKey)
        blk_add=0;
        accepted_key = 1;
    elseif practice_feedback_key(spaceBar)
        blk_add=1;
        accepted_key = 1;
    else
        accepted_key = 0;
    end
end
end

