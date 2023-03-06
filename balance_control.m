
%% balance controls
% Since total number of trials without target (1280) cannot be divided by 3
% the duration will be slightly imbalanced to other variables (e.g. SOA or
% category) but this imbalance shoud not be bigger than 1

% SOA to Duration of visual stimulus (not working with current
% implementation)
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