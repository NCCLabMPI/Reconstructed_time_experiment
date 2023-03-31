%% EYE_TRACKER TRIGGER FUCNTIONS

% The function sends end of block signals to the eyetracker and
% saves it in the data folder.
function [] = saveEyetracker(task, blk)
global edfFile DATA_FOLDER subID session

% Stop the recording:
Eyelink('StopRecording');
%Closing the edf file
Eyelink('CloseFile')

% Generate save dir:
save_dir = fullfile(pwd,DATA_FOLDER,['sub-',subID],['ses-',num2str(session)]);

% Generate file name:
edf_file_name  = fullfile(save_dir, sprintf('sub-%s_ses-%d_run-%d_task-%s_eyetrack.edf', subID, session, blk, task));

%Retrieving the edf file from eyetracker PC
try
    fprintf('Receiving data file ''%s''\n',edfFile);
    status=Eyelink('ReceiveFile',edfFile, edf_file_name);
    if status > 0
        fprintf('ReceiveFile status %d/n',status);
    end
    if 2 == exist(edfFile,'file')
        fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd);
    end
catch rdf
    fprintf('Problem receiving file ''%s''\n',edfFile);
    throw(rdf);
end
end