
% SAVECODE saves the code into the code folder
% output:
% -------
% This code file is saved into the code folder ("/data/code/").
function [ ] = saveCode()

global subjectNum session CODE_FOLDER DATA_FOLDER introspec FUNCTIONS_FOLDER%subject number 

if introspec
    session_type = 'Introspec';
else
    session_type = 'Bev';
end

try
    fileStruct = dir('*.m');

    directory = fullfile(pwd,DATA_FOLDER,['sub-',num2str(subjectNum)],session_type,['ses-',num2str(session)],CODE_FOLDER);

    if ~exist(directory,'dir')
        mkdir(directory);
    end

    % We cannot save the date
    %prf1 = sprintf('%d-%s',subjectNum, date);
    for i = 1 : length(fileStruct)
        k = 0;
        k = strfind(fileStruct(i).name,'.m');
        if (k ~= 0)
            fileName = fileStruct(i).name;
            source = fullfile(pwd,fileName);
            destination = fullfile(directory,fileName);
            copyfile(source,destination);
        end
    end
    % Saving the log file:
    logfileName = 'log_recon_time.txt';
    logsource = fullfile(pwd,logfileName);
    logdestination = fullfile(directory,logfileName);
    copyfile(logsource,logdestination);

    % Saving the helper functions
    helperFunctionFile = fullfile(pwd,FUNCTIONS_FOLDER);
    destination = fullfile(directory,FUNCTIONS_FOLDER);
    copyfile(helperFunctionFile,destination)

catch
    fileStruct = dir('*.m');

    directory = fullfile(pwd,DATA_FOLDER,['sub-',num2str(subjectNum)],session_type,['ses-',num2str(session)],CODE_FOLDER);

    if ~exist(fullfile(directory,'dir'))
        mkdir(fullfile(directory));
    end
    % We cannot save the date
    %prf1 = sprintf('%d-%s',subjectNum, date);
    for i = 1 : length(fileStruct)
        k = 0;
        k = strfind(fileStruct(i).name,'.m');
        if (k ~= 0)
            fileName = fileStruct(i).name;
            source = fullfile(pwd,fileName);
            destination = fullfile(directory,fileName);
            copyfile(source,destination);
        end
    end

    % Saving the log file:
    logfileName = 'log_recon_time.txt';
    logsource = fullfile(pwd,logfileName);
    logdestination = fullfile(directory,logfileName);
    copyfile(logsource,logdestination);

    % Saving the helper functions
    helperFunctionFile = fullfile(pwd,FUNCTIONS_FOLDER);
    destination = fullfile(directory);
    copyfile(helperFunctionFile,helperFunctionFile) % XXX commented out as it crashed
end
end