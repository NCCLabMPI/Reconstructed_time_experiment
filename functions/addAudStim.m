% This function takes the trial matrix as an input. It sorts the rows according
% to the different conditions and adds the different SOAs and pitche. 
% Lastly the rows are shuffled and sorted by blocks again.
% Thereby, the new trial matrix will have three additional columns, the
% trial number trial type (target, non-target, irrelevant),
% the SOAs and the pitch

function [ trial_mat ] = addAudStim(trial_mat)

disp('WELCOME TO addAudStim')


% a) get task relevance
for k = 1:length(trial_mat.block)
    if strcmp(trial_mat.target_1{k},trial_mat.identity{k}) ||...
            strcmp(trial_mat.target_2{k},trial_mat.identity{k})
        trial_mat.task_relevance{k} = 'target';
    elseif strcmp(extractBetween(trial_mat.target_1{k},1,3),extractBetween(trial_mat.identity{k},1,3)) ||...
            strcmp(extractBetween(trial_mat.target_2{k},1,3),extractBetween(trial_mat.identity{k},1,3))
        trial_mat.task_relevance{k} = 'non-target';
    else
        trial_mat.task_relevance{k} = 'irrelevant';
    end
end

% add trial number as column 
trial_mat.trial = (1:length(trial_mat.block))';
end
