% SAFEEXIT runs all commands allowing for a safe exit.
function [] = safeExit()

    global MEEG EYE_TRACKER pahandle DATA_FOLDER subjectNum EXPERIMENT_NAME NO_AUDIO TOBII_EYETRACKER
 
    try
        % Calling the different functions to correctly close the different
        % recording modalities:
        if MEEG endEEG(); end
        if EYE_TRACKER 
            if ~TOBII_EYETRACKER
                endEyeTracker(); 
            else
                endTobiiEyetracker()
            end
        end
        % Close the audio device
        if ~NO_AUDIOy
            PsychPortAudio('Close', pahandle);
        end
        
        % Closing everything
        Priority(0);
        sca;
        ShowCursor;
        ListenChar(0);
        saveCode;
        
        %zip all the output code files to one file
        zipfilename=[pwd,filesep,DATA_FOLDER,filesep,[num2str(subjectNum)],filesep,EXPERIMENT_NAME,'_',[num2str(subjectNum),'_output_code']];
        zipfolder = [pwd,filesep,DATA_FOLDER,filesep,[num2str(subjectNum)],filesep,'code'];
        
        zip([zipfilename,'.zip'], zipfolder);
    catch
        if MEEG saveTrigToHD(); end
        if MEEG endEEG(); end
        if EYE_TRACKER 
            if ~TOBII_EYETRACKER
                endEyeTracker(); 
            else
                endTobiiEyetracker()
            end
        end
        % Close the audio device
        if ~NO_AUDIO
            PsychPortAudio('Close', pahandle);
        end
        
        % Closing everything
        Priority(0);
        sca;
        ShowCursor;
        ListenChar(0);
        saveCode;
        
        %zip all the output code files to one file
        zipfilename=[pwd,filesep,DATA_FOLDER,filesep,[num2str(subjectNum)],filesep,EXPERIMENT_NAME,'_',[num2str(subjectNum),'_output_code']];
        zipfolder = [pwd,filesep,DATA_FOLDER,filesep,[num2str(subjectNum)],filesep,'code'];
        
        zip([zipfilename,'.zip'], zipfolder);
    end
end