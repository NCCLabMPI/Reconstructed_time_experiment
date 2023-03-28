% It takes the practice trial list practic_mat.csv (which is always constant) and makes random two
% pictures from the practice folder in the stimuli folder as targets (always one letter and one false_font).
% Lastly, the order of stimuli is shuffled.

function [practice_mat] = makePractice_mat(practice_type)

% load table
practice_mat = readtable(fullfile(pwd,filesep,'practice_mat.csv')); % <- loads the practice matrix

% for every partice new targets are selected
target_1_num = randi(6); % false_font
target_2_num = randi(6)+6; % letter

% adjust target and identity columns
for tr = 1:length(practice_mat.trial)
    practice_mat.target_1{tr} = {['practice_0', num2str(target_1_num)]}; % random false font
    if target_2_num < 10
        practice_mat.target_2{tr} = ['practice_0', num2str(target_2_num)]; % random letter
    else
        practice_mat.target_2{tr} = ['practice_', num2str(target_2_num)]; % random letter
    end
    if strcmp(practice_mat.task_relevance{tr}, 'target') && strcmp(practice_mat.category{tr}, 'false_font')
        practice_mat.identity{tr} = practice_mat.target_1{tr};
    elseif strcmp(practice_mat.task_relevance{tr}, 'target') && strcmp(practice_mat.category{tr}, 'letter')
        practice_mat.identity{tr} = practice_mat.target_2{tr};
    end

    % add practice type information
    practice_mat.task{tr} = practice_type;

end

% shuffle rows and adjust trial column 
practice_mat = practice_mat(randperm(size(practice_mat,1)), :);
practice_mat.trial(:) = 1:length(practice_mat.trial);

end % end function RunPractice

