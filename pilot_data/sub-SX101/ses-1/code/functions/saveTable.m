% SAVELOG_TABLE saves a matrix as mat and csv
% input:
% ------
% lof_tbale - the table to be saved
% output:
% -------
% A mat and a csv file containning the data of log_table


function [] = saveTable(input_table, task, blk_num)

global DATA_FOLDER subID session

% Creating the directories if they don't already exist:
dir = string(fullfile(pwd,DATA_FOLDER,['sub-', subID],['ses-',num2str(session)]));
if ~exist(dir, 'dir')
    mkdir(dir);
end
if isnumeric(blk_num)
    if blk_num < 0
        blk_num = 0;
    end
    blk_num = num2str(blk_num);
end
 
fileName_mat  = fullfile(dir, sprintf('sub-%s_ses-%d_run-%s_task-%s_events.mat', subID, session, blk_num, string(task)));
save(fileName_mat,'input_table');
fileName_csv  = fullfile(dir, sprintf('sub-%s_ses-%d_run-%s_task-%s_events.csv', subID, session, blk_num, string(task)));
writetable(input_table,fileName_csv);

end