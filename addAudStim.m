% This function takes the trial matrix as an input. It sorts the rows according
% to the different conditions and adds the different SOAs and pitche. 
% Lastly the rows are shuffled and sorted by blocks again.
% Thereby, the new trial matrix will have three additional columns, the
% trial type (target, non-target, irrelevant), the SOAs and the pitch

function [ trial_mat ] = addAudStim(trial_mat)

% a) get trial type
% trial_mat.trial_type = (1:length(trial_mat.block))';
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

% sort table
trial_mat = sortrows(trial_mat, {'duration', 'category', 'trial_type'});

% b) SOA between visual and auditory stimulus (1-4 for onset, 5-8 for offset)
trial_mat.SOA = repmat(1:8,1,1440/8)';

% c) Pitch of auditory stimulus (high pitch = 1100, low pitch = 1000 Hz)
trial_mat.pitch = repmat([repmat(1000,1,8),repmat(1100,1,8)],1,1440/16)';

% Shuffle vector and then sort for blocks
trial_mat = ShuffleRows(trial_mat);
trial_mat = sortrows(trial_mat, 'block');


%% balance controls
% Since total number of trials without target (1280) cannot be divided by 3
% the duration will be slightly imbalanced to other variables (e.g. SOA or
% category) but this imbalance shoud not be bigger than 1

% SOA to Duration of visual stimulus
soa_dur_mat = zeros(8,3);
for soa = 1:8
    for dur_num = 1:3
        durs = [0.5, 1, 1.5];
        dur = durs(dur_num);
        [rows, ~] = size(trial_mat(trial_mat.SOA == soa & abs(trial_mat.duration - dur) < 0.1,:));
        soa_dur_mat(soa,dur_num) = rows;
    end
end

% Category to Duration of visual stimulus
cat_dur_mat = zeros(4,3);
for cat_num = 1:4
    cats = {'face', 'object', 'letter', 'false_font'};
    cat = cats{cat_num};
    for dur_num = 1:3
        durs = [0.5, 1, 1.5];
        dur = durs(dur_num);
        [rows, ~] = size(trial_mat(strcmp(trial_mat.category, cat) & abs(trial_mat.duration - dur) < 0.1,:));
        cat_dur_mat(cat_num, dur_num) = rows;
    end
end

% pitch to Duration of visual stimulus
pitch_dur_mat = zeros(2,3);
for pitch_num = 1:2
    pitchs = [1000,1100];
    pitch = pitchs(pitch_num);
    for dur_num = 1:3
        durs = [0.5, 1, 1.5];
        dur = durs(dur_num);
        [rows, ~] = size(trial_mat(trial_mat.pitch == pitch & abs(trial_mat.duration - dur) < 0.1,:));
        pitch_dur_mat(pitch_num,dur_num) = rows;
    end
end
end
