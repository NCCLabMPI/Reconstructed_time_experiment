function [cali_log] = calibration(number_of_cali_trails)

disp('WELCOME TO calibration')


global CALIBRATION_PITCH_FREQ ScreenHeight text w
introspec_question = 'cali';
durations = [20,100,200,300,400,500,600,700,800,900,1000];
cali_ms = repmat(durations,1,ceil(number_of_cali_trails/length(durations)));
cali_ms = cali_ms(1:number_of_cali_trails);
cali_log = table;
cali_log.cali_ms = ShuffleVector(cali_ms)';
cali_log.iT = nan(1,number_of_cali_trails)';
cali_log.estimation_error = nan(1,number_of_cali_trails)';

for c = 1:length(cali_ms)

    % show gray screen
    DrawFormattedText(w, textProcess('Wait for tone'), 'center' , ScreenHeight*(1/5), text.Color);
    Screen('Flip', w);
    WaitSecs(1)

    % make tone
    [cali_pitch_buff, ~, aud_pahandle] = init_audio_pitches((cali_log.cali_ms(c)/1000), CALIBRATION_PITCH_FREQ,  CALIBRATION_PITCH_FREQ); % auditory
    PsychPortAudio('FillBuffer', aud_pahandle, cali_pitch_buff);

    % And then you play the buffer. The function returns a time stamp.
    % Here I don't use it but for our purpose we will want to log it:
    PsychPortAudio('Start',aud_pahandle, 1, 0);
    WaitSecs(1.5)

    cali_log.iT(c) = run_dial(introspec_question);
    WaitSecs(0.2)
    
    % Deliver feddback
    actual_time = ['The true duration: ', num2str(round(cali_log.cali_ms(c))), ' ms'];
    estimated_time = ['Estimated duration: ', num2str(cali_log.iT(c)), ' ms'];

    cali_log.estimation_error(c) = cali_log.cali_ms(c) - cali_log.iT(c);
    if cali_log.estimation_error(c) > 20
        cali_feedback = 'Your estimated time was too short!';
    elseif cali_log.estimation_error(c) < -20
        cali_feedback = 'Your estimated time was too long!';
    else
        cali_feedback = 'Well done!';
    end
    DrawFormattedText(w, textProcess(actual_time), 'center' , ScreenHeight*(1/5), text.Color);
    DrawFormattedText(w, textProcess(estimated_time), 'center' , ScreenHeight*(2/5), text.Color);
    DrawFormattedText(w, textProcess(cali_feedback), 'center' , ScreenHeight*(3/5), text.Color);

    % Flip to the screen
    Screen('Flip', w);

    WaitSecs(2)

end
end