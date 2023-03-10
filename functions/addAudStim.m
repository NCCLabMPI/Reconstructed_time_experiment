% This function takes the trial matrix as an input. It sorts the rows according
% to the different conditions and adds the different SOAs and pitche. 
% Lastly the rows are shuffled and sorted by blocks again.
% Thereby, the new trial matrix will have three additional columns, the
% trial number trial type (target, non-target, irrelevant),
% the SOAs and the pitch

function [ trial_mat ] = addAudStim(trial_mat)

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

% sort table
trial_mat = sortrows(trial_mat, {'task_relevance','category','orientation','identity'});
%%
% a) Rearrange the duration column according to vector durs
durs = repmat([0.506666666666667,1,1.493333333333330],1,length(trial_mat.block)/3)';
%trial_mat.duration = durs;
trial_mat_copy =  trial_mat;

for i=1:length(durs)
    % pick first line that has duration of loop iteration
    trial_mat_intermediate = trial_mat_copy(trial_mat_copy.duration == durs(i),:);
    if isempty(trial_mat_intermediate)
        break
    end 
    % make it next line in new table
    trial_mat_new(i,:) = trial_mat_intermediate(1,:);
    % remove used line from table
    trial_number_of_row = trial_mat_new.trial(i);
    trial_mat_copy(trial_mat_copy.trial == trial_number_of_row,:) = [];
end

for u = 1:length(trial_mat_copy.trial)
    trial_mat_new(end+1,:) = trial_mat_copy(u,:);
end

trial_mat = trial_mat_new;

% trial_mat = sortrows(trial_mat, {'task_relevance','category'});
% trial_mat.duration = durs;
%%

% b) SOA between visual and auditory stimulus (1-4 for onset, 5-8 for offset)
SOAs = [0,0.116,0.232,0.466];
SOAs_flipped = flip(SOAs); 
trial_mat.SOA = repmat([SOAs, SOAs_flipped],1,length(trial_mat.block)/length([SOAs, SOAs_flipped]))';

SOA_locks = repmat({'onset', 'offset'},1,4);
SOA_locks_flipped = flip(SOA_locks);
SOA_lock_vec = {SOA_locks, SOA_locks_flipped};
trial_mat.SOA_lock = repmat(horzcat(SOA_lock_vec{:}),1,length(trial_mat.block)/length(horzcat(SOA_lock_vec{:})))';

% c) Pitch of auditory stimulus (high pitch = 1100, low pitch = 1000 Hz)
trial_mat.pitch = repmat({'low', 'high'},1,length(trial_mat.block)/2)';

% d) Increase jitter by 300 ms to avoid overlap with pitch of previous trial 
trial_mat.stim_jit = trial_mat.stim_jit + 0.3;

% Sort for trials to restore original order 
trial_mat = sortrows(trial_mat, 'trial');
order = {'trial','block','target_1','target_2','task_relevance','category','duration','SOA','SOA_lock','pitch','orientation','identity','stim_jit'};
trial_mat = trial_mat(:,order);

end
