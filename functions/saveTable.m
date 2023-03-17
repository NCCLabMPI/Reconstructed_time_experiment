% SAVELOG_TABLE saves a matrix as mat and csv
% input:
% ------
% lof_tbale - the table to be saved
% output:
% -------
% A mat and a csv file containning the data of log_table


function [] = saveTable(input_table, table_name)

global DATA_FOLDER subjectNum session introspec

if introspec
    session_type = 'Introspec';
else 
    session_type = 'Bev';
end 

% Creating the directories if they don't already exist:
dir = fullfile(pwd,DATA_FOLDER,['Sub-',num2str(subjectNum)],session_type,['Ses-',num2str(session)]);
if ~exist(dir, 'dir')
    mkdir(dir);
end

fileName_mat  = sprintf('%s%cSub-%s_Ses-%s_%s.mat',dir,filesep,num2str(subjectNum),num2str(session),table_name);
save(fileName_mat,'input_table');
fileName_csv  = sprintf('%s%cSub-%s_Ses-%s_%s.csv',dir,filesep,num2str(subjectNum),num2str(session),table_name);
writetable(input_table,fileName_csv);

end