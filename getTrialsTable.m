
%%
%%
% -----------------------------------------------------
% Trials parameters
global DEBUG MIN_NUM_OF_TRIALS_PER_MINI_BLOCK TRIAL1_STIM_DUR_COL NUM_OF_STIM_TYPE_PER_MINIBLOCK NUM_OF_TARGET_TYPES_PER_MINIBLOCK
global NUM_OF_POSSIBLE_EVENTS_IN_TRIAL NUM_OF_TARGETS_PER_MINIBLOCK LEFT CENTER RIGHT NUM_OF_BLOCKS MAX_NUM_OF_TRIALS_PER_MINI_BLOCK
global CHAR_FALSE_MINIBLOCK FACE_OBJECT_MINIBLOCK NUM_OF_MINIBLOCK_TYPE NUM_OF_MINI_BLOCKS_PER_BLOCK BLANK FALSE_FONT LETTER OBJECT
global FACE NUM_OF_STIMULI_EACH NUM_OF_ORIENTATIONS NUM_OF_CATEGORIES
global NON_TARGETS_FACES_PER_MB NON_TARGETS_OBJECTS_PER_MB NON_TARGETS_CHARS_PER_MB NON_TARGETS_FALSES_PER_MB
global NUMBER_OF_NON_TARGET_SETS_PER_CAT NUMBER_OF_TOTAL_TRIALS NUMBER_OF_NON_TARGETS_PER_CAT_PER_MB

%%
% Define which miniblock has how many trials

NUM_OF_MINI_BLOCKS_PER_BLOCK = 4; % number of mini blocks in each block
NUM_OF_BLOCKS = 10; % number of blocks
TOTAL_NUM_MINIBLOCKS = NUM_OF_MINI_BLOCKS_PER_BLOCK * NUM_OF_BLOCKS;

NUM_OF_TARGETS_PER_MINIBLOCK = [2 3 4 5 6]; % possible number of targets to use in miniblock
% Non-targets/irrelevants (holds for both)
% For example for face-object miniblocks:
% (160 (e.g. irrelevant false-fonts)/10 blocks)/ 2 miniblocks ( 2 out
% of 4 mb per block are face-object mb.) This is for the letter-false-font mb.
% The same numbers apply for the lette-false font but then the false-fonts are non-targets.
NUM_OF_STIM_TYPE_PER_MINIBLOCK = 8; % for each type of stimuli (letter, etc)

miniblock_num = 1:TOTAL_NUM_MINIBLOCKS;
total_num_targets = TOTAL_NUM_MINIBLOCKS * mean(NUM_OF_TARGETS_PER_MINIBLOCK);
number_of_trials_without_targets = NUMBER_OF_TOTAL_TRIALS - total_num_targets;


MIN_NUM_OF_TRIALS_PER_MINI_BLOCK = NUM_OF_STIM_TYPE_PER_MINIBLOCK*NUM_OF_CATEGORIES + min(NUM_OF_TARGETS_PER_MINIBLOCK); % minimum number of stimuli in each miniblock
MAX_NUM_OF_TRIALS_PER_MINI_BLOCK = NUM_OF_STIM_TYPE_PER_MINIBLOCK*NUM_OF_CATEGORIES + max(NUM_OF_TARGETS_PER_MINIBLOCK); % maximum number of stimuli in each miniblock

%% Miniblock balance

miniblock_table = table;

% generate vectors for each experimental variable

% a) target_category_types
target_category_vec = {repmat({'face-object'},1,TOTAL_NUM_MINIBLOCKS/2), repmat({'chars_falses'},1,TOTAL_NUM_MINIBLOCKS/2)};
target_category_vec = horzcat(target_category_vec{:});
miniblock_table.Target_category = target_category_vec';

% b) target pairs
face_vec = 1001:1020;
object_vec = 2001:2020;
char_vec = 3001:3020;
false_vec = 4001:4020;

miniblock_table.target_1 = [ShuffleVector(face_vec), ShuffleVector(char_vec)]';
miniblock_table.target_2 = [ShuffleVector(object_vec), ShuffleVector(false_vec)]';

% c) number of targt per miniblock
number_of_targets_in_MB = ShuffleVector(repmat(NUM_OF_TARGETS_PER_MINIBLOCK,1,TOTAL_NUM_MINIBLOCKS/length(NUM_OF_TARGETS_PER_MINIBLOCK)));
miniblock_table.number_of_targets = number_of_targets_in_MB';

% d) assign non targets 
% for g = 1:length(miniblock_table.Target_category)
%     if strcmp(miniblock_table.Target_category{g},'face-object')
%         miniblock_table.non_target(g) = [NON_TARGETS_FACES_PER_MB(num2str(miniblock_table.target_1(g))),...
%             NON_TARGETS_OBJECTS_PER_MB(num2str(miniblock_table.target_2(g)))];
%     elseif strcmp(miniblock_table.Target_category{g},'chars_falses')
%         miniblock_table.non_target(g) = [NON_TARGETS_CHARS_PER_MB(num2str(miniblock_table.target_1(g))),...
%             NON_TARGETS_FALSES_PER_MB(num2str(miniblock_table.target_2(g)))];
%     end
% end


%% Target balance
trial_table_A = table;

%% Non-targets and irrelvant balance
trial_table_B = table;

% generate vectors for each experimental variable
% a) SOA between visual and auditory stimulus (1-4 for onset, 5-8 for offset)
SOA_vec = [];
for l = 1:8
    SOA_vec(length(SOA_vec)+1:length(SOA_vec)+160) = repmat(l,1,160);
end
trial_table_B.SOA = SOA_vec';

% b) duration visual stimulus
% since total umber of trials without targets can not be divided by 3
% the duration vector needs to be longer first and then croped
vis_stim_dur_vec = repmat(1:3,1,ceil(number_of_trials_without_targets/3));
vis_stim_dur_vec = vis_stim_dur_vec(1:number_of_trials_without_targets);
trial_table_B.vis_stim_dur = vis_stim_dur_vec';

% c) trial type (non-target = 1, irrelevant = 2)
trial_type_vec = repmat(1:2,1,number_of_trials_without_targets/2);
trial_table_B.trial_type = trial_type_vec';

% d) pitch of auditory stimulus (high pitch = 1100, low pitch = 1000 Hz)
pitch_vec = repmat([1000,1000,1100,1100],1,number_of_trials_without_targets/4);
trial_table_B.pitch = pitch_vec';

% e) category (face, object, chars, falses)
cate_vec = {repmat({'face'},1,4), repmat({'object'},1,4), repmat({'char'},1,4), repmat({'false'},1,4)};
cate_vec = horzcat(cate_vec{:});
cate_vec = repmat(cate_vec,1,number_of_trials_without_targets/length(cate_vec));
trial_table_B.vis_stim_cate = cate_vec';

% f) jitter
jitter_vec = getJitter(number_of_trials_without_targets);
trial_table_B.jitter = jitter_vec;


% shuffle table with all variables
trial_table_B = ShuffleRows(trial_table_B);

% split in table for non-targets and irrelevant stimuli
trial_table_non_targets = trial_table_B(trial_table_B.trial_type == 1,:);
trial_table_irrelevant = trial_table_B(trial_table_B.trial_type == 2,:);

% split once more by category
trial_table_non_targets_faces = trial_table_non_targets(strcmp(trial_table_non_targets.vis_stim_cate,'face'),:);
trial_table_non_targets_objects = trial_table_non_targets(strcmp(trial_table_non_targets.vis_stim_cate,'object'),:);
trial_table_non_targets_chars = trial_table_non_targets(strcmp(trial_table_non_targets.vis_stim_cate,'char'),:);
trial_table_non_targets_falses = trial_table_non_targets(strcmp(trial_table_non_targets.vis_stim_cate,'false'),:);

trial_table_irrelevant_faces = trial_table_irrelevant(strcmp(trial_table_irrelevant.vis_stim_cate,'face'),:);
trial_table_irrelevant_objects = trial_table_irrelevant(strcmp(trial_table_irrelevant.vis_stim_cate,'object'),:);
trial_table_irrelevant_chars = trial_table_irrelevant(strcmp(trial_table_irrelevant.vis_stim_cate,'char'),:);
trial_table_irrelevant_falses = trial_table_irrelevant(strcmp(trial_table_irrelevant.vis_stim_cate,'false'),:);


%% balance controls
% Since total number of trials without target (1280) cannot be divided by 3
% the duration will be slightly imbalanced to other variables (e.g. SOA or
% category) but this imbalance shoud not be bigger than 1

% SOA to Duration of visual stimulus
soa_dur_mat = zeros(8,3);
for soa = 1:8
    for dur = 1:3
        [rows, col] = size(trial_table_B(trial_table_B.SOA == soa & trial_table_B.vis_stim_dur == dur,:));
        soa_dur_mat(soa,dur) = rows;
    end 
end 

% Category to Duration of visual stimulus
cat_dur_mat = zeros(4,3);
for cat_num = 1:4
    cat_name = {'face', 'object', 'char', 'false'};
    cat = cat_name{cat_num};
    for dur = 1:3
        index_vec = strcmp(trial_table_B.vis_stim_cate, cat);
        [rows, col] = size(trial_table_B(strcmp(trial_table_B.vis_stim_cate, cat) & trial_table_B.vis_stim_dur == dur,:));
        cat_dur_mat(cat_num,dur) = rows;
    end 
end 


% more ... 