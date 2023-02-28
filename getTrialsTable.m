
%%
%%
% -----------------------------------------------------
% Trials parameters
global DEBUG MIN_NUM_OF_TRIALS_PER_MINI_BLOCK FIXATION TRIAL1_STIM_DUR_COL NUM_OF_STIM_TYPE_PER_MINIBLOCK NUM_OF_TARGET_TYPES_PER_MINIBLOCK
global NUM_OF_POSSIBLE_EVENTS_IN_TRIAL NUM_OF_TARGETS_PER_MINIBLOCK LEFT CENTER RIGHT NUM_OF_BLOCKS MAX_NUM_OF_TRIALS_PER_MINI_BLOCK
global CHAR_FALSE_MINIBLOCK FACE_OBJECT_MINIBLOCK NUM_OF_MINIBLOCK_TYPE NUM_OF_MINI_BLOCKS_PER_BLOCK BLANK FALSE_FONT LETTER OBJECT
global FACE NUM_OF_STIMULI_EACH NUM_OF_ORIENTATIONS NUM_OF_CATEGORIES
% -----------------------------------------------------
% Screen parameters
% -----------------------------------------------------
% Pseudorandomization parameters
global NUMBER_OF_NON_TARGET_SETS_PER_CAT NUMBER_OF_TOTAL_TRIALS NUMBER_OF_NON_TARGETS_PER_CAT_PER_MB

%%
% Define which miniblock has how many trials


NUM_OF_MINI_BLOCKS_PER_BLOCK = 4; % number of mini blocks in each block
NUM_OF_BLOCKS = 10; %number of blocks
TOTAL_NUM_MINIBLOCKS = NUM_OF_MINI_BLOCKS_PER_BLOCK * NUM_OF_BLOCKS;

NUM_OF_TARGETS_PER_MINIBLOCK = [2 3 4 5 6]; % possible number of targets to use in miniblock
% Non-targets/irrelevants (holds for both)
% For example for face-object miniblocks:
% (160 (e.g. irrelevant false-fonts)/10 blocks)/ 2 miniblocks ( 2 out
% of 4 mb per block are face-object mb.) This is for the letter-false-font mb.
% The same numbers apply for the lette-false font but then the false-fonts are non-targets.
NUM_OF_STIM_TYPE_PER_MINIBLOCK = 8; % for each type of stimuli (letter, etc)

MIN_NUM_OF_TRIALS_PER_MINI_BLOCK = NUM_OF_STIM_TYPE_PER_MINIBLOCK*NUM_OF_CATEGORIES + min(NUM_OF_TARGETS_PER_MINIBLOCK); % minimum number of stimuli in each miniblock
MAX_NUM_OF_TRIALS_PER_MINI_BLOCK = NUM_OF_STIM_TYPE_PER_MINIBLOCK*NUM_OF_CATEGORIES + max(NUM_OF_TARGETS_PER_MINIBLOCK); % maximum number of stimuli in each miniblock

%% Targets

number_of_targets = repmat(NUM_OF_TARGETS_PER_MINIBLOCK,1,TOTAL_NUM_MINIBLOCKS/length(NUM_OF_TARGETS_PER_MINIBLOCK));
target_category_types = {repmat({'face-object'},1,TOTAL_NUM_MINIBLOCKS/2), repmat({'chars_falses'},1,TOTAL_NUM_MINIBLOCKS/2)};
target_category_types = horzcat(target_category_types{:});
miniblock_num = 1:TOTAL_NUM_MINIBLOCKS;


Trial = 1:NUMBER_OF_TOTAL_TRIALS;
i = NUMBER_OF_NON_TARGET_SETS_PER_CAT;
r =  NUMBER_OF_NON_TARGETS_PER_CAT_PER_MB;

% trial_table_A = 

%% Non-targets and irrelvant

Number_of_trials_without_targets = 1280;

% generate vectors for each experimental variable
% a) SOA between visual and auditory stimulus (1-4 for onset, 5-8 for offset)
SOA_vec = [];
for l = 1:8
    SOA_vec(length(SOA_vec)+1:length(SOA_vec)+160) = repmat(l,1,160);
end

% b) duration visual stimulus
% since total umber of trials without targets can not be divided by 3
% the duration vector needs to be longer first and then croped
dur_vec = repmat(1:3,1,ceil(Number_of_trials_without_targets/3));
dur_vec = dur_vec(1:Number_of_trials_without_targets);

% c) trial type (non-target = 1, irrelevant = 2)
trial_type_vec = repmat(1:2,1,Number_of_trials_without_targets/2);

% d) pitch of auditory stimulus (high pitch = 1100, low pitch = 1000 Hz)
pitch_vec = repmat([1000,1000,1100,1100],1,Number_of_trials_without_targets/4);

% e) category (face, object, chars, falses)
cat_vec = {repmat({'face'},1,4), repmat({'object'},1,4), repmat({'char'},1,4), repmat({'false'},1,4)};
cat_vec = horzcat(cat_vec{:});
cat_vec = repmat(cat_vec,1,Number_of_trials_without_targets/length(cat_vec));

% make table with all variables 
trial_table_B = table;
trial_table_B.SOA = SOA_vec';
trial_table_B.Duration = dur_vec';
trial_table_B.Trial_type = trial_type_vec';
trial_table_B.Pitch = pitch_vec';
trial_table_B.Category = cat_vec';
trial_table_B = ShuffleRows(trial_table_B);

% balance controls
% Since total number of trials without target (1280) cannot be divided by 3
% the duration will be slightly imbalanced to other variables (e.g. SOA or
% category) but this imbalance shoud not be bigger than 1

% SOA to Duration
soa_dur_mat = zeros(8,3);
for soa = 1:8
    for dur = 1:3
        [rows, col] = size(trial_table_B(trial_table_B.SOA == soa & trial_table_B.Duration == dur,:));
        soa_dur_mat(soa,dur) = rows;
    end 
end 

% Category to Duration
cat_dur_mat = zeros(4,3);
for cat_num = 1:4
    cat_name = {'face', 'object', 'char', 'false'};
    cat = cat_name{cat_num};
    for dur = 1:3
        index_vec = strcmp(trial_table_B.Category, cat);
        [rows, col] = size(trial_table_B(strcmp(trial_table_B.Category, cat) & trial_table_B.Duration == dur,:));
        cat_dur_mat(cat_num,dur) = rows;
    end 
end 

