% This function takes the trial matrix as an input. It sorts the rows according
% to the different conditions and adds the different SOAs and pitche. 
% Lastly the rows are shuffled and sorted by blocks again.
% Thereby, the new trial matrix will have three additional columns, the
% trial number trial type (target, non-target, irrelevant),
% the SOAs and the pitch

function [ trial_mat ] = addAudStim(trial_mat)


% a) get trial type
for k = 1:length(trial_mat.block)
    if strcmp(trial_mat.target_1{k},trial_mat.identity{k}) ||...
            strcmp(trial_mat.target_2{k},trial_mat.identity{k})
        trial_mat.trial_type{k} = 'target';
    elseif strcmp(extractBetween(trial_mat.target_1{k},1,3),extractBetween(trial_mat.identity{k},1,3)) ||...
            strcmp(extractBetween(trial_mat.target_2{k},1,3),extractBetween(trial_mat.identity{k},1,3))
        trial_mat.trial_type{k} = 'non-target';
    else
        trial_mat.trial_type{k} = 'irrelevant';
    end
end

% add trial number as column 
trial_mat.trial = (1:length(trial_mat.block))';

% sort table
trial_mat = sortrows(trial_mat, {'duration', 'category', 'trial_type', 'orientation'});

% b) SOA between visual and auditory stimulus (1-4 for onset, 5-8 for offset)
trial_mat.SOA = repmat([0,0.116,0.232,0.466],1,1440/4)';

SOA_lock_vec = repmat({[repmat({'onset'},1,4), repmat({'offset'},1,4)]},1,1440/8);
trial_mat.SOA_lock = horzcat(SOA_lock_vec{:})';

% c) Pitch of auditory stimulus (high pitch = 1100, low pitch = 1000 Hz)
trial_mat.pitch = repmat([repmat({'low'},1,8),repmat({'high'},1,8)],1,1440/16)';

% Shuffle vector and then sort for trials to restore original order 
trial_mat = ShuffleRows(trial_mat);
trial_mat = sortrows(trial_mat, 'trial');
order = {'trial','block','target_1','target_2','trial_type','category','duration','SOA','SOA_lock','pitch','orientation','identity','stim_jit'};
trial_mat = trial_mat(:,order);

end
