% SAVELOG_TABLE saves a matrix as mat and csv
% input:
% ------
% lof_tbale - the table to be saved
% output:
% -------
% A mat and a csv file containning the data of log_table
function [] = saveLog_table(log_table)

global DATA_FOLDER subjectNum 

% Creating the directories if they don't already exist:
if ~exist(fullfile(pwd,DATA_FOLDER,num2str(subjectNum)),'dir')
    mkdir(fullfile(pwd,DATA_FOLDER,num2str(subjectNum)));
end

fileName_mat  = sprintf('%s%c%s%c%s%cSub%s_log_table.mat',pwd,filesep,DATA_FOLDER,filesep,num2str(subjectNum),filesep,num2str(subjectNum));
save(fileName_mat,'log_table');
fileName_csv  = sprintf('%s%c%s%c%s%cSub%s_log_table.csv',pwd,filesep,DATA_FOLDER,filesep,num2str(subjectNum),filesep,num2str(subjectNum));
writetable(log_table,fileName_csv);

end