% SAVELOG_TABLE saves a matrix as mat and csv
% input:
% ------
% lof_tbale - the table to be saved
% output:
% -------
% A mat and a csv file containning the data of log_table


function [] = saveTable(input_table, blk_num)

global DATA_FOLDER subjectNum session introspec

if introspec
    session_type = 'Introspec';
else 
    session_type = 'Bev';
end 

% Creating the directories if they don't already exist:
dir = fullfile(pwd,DATA_FOLDER,['sub-',num2str(subjectNum)],session_type,['ses-',num2str(session)]);
if ~exist(dir, 'dir')
    mkdir(dir);
end
if isnumeric(blk_num)
    blk_num = num2str(blk_num);
end
fileName_mat  = fullfile(dir, sprintf('sub-%d_ses-%d_run-%s_task-%s_events.mat', subjectNum, session, blk_num, session_type));
save(fileName_mat,'input_table');
fileName_csv  = fullfile(dir, sprintf('sub-%d_ses-%d_run-%s_task-%s_events.csv', subjectNum, session, blk_num, session_type));
writetable(input_table,fileName_csv);

end