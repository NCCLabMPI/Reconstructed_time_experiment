function [cali_log] = calibration(number_of_cali_trails)

disp('WELCOME TO calibration')


global CALIBRATION_PITCH_FREQ ScreenHeight text w compKbDevice abortKey CLEAN_EXIT_MESSAGE padhandle EYE_TRACKER
introspec_question = 'cali';

% make the durations of tones 
cali_ms = round(linspace(20,1000,number_of_cali_trails));

% set up the log table
cali_log = table;
cali_log.cali_ms = ShuffleVector(cali_ms)';
cali_log.iT = nan(1,number_of_cali_trails)';
cali_log.estimation_error = nan(1,number_of_cali_trails)';

for c = 1:length(cali_ms)

    % show gray screen
    DrawFormattedText(w, textProcess('Wait for tone'), 'center' , ScreenHeight*(1/5), text.Color);
    Screen('Flip', w);
    WaitSecs(1);

    % make tone
    tone_length = cali_log.cali_ms(c)/1000;
    [cali_pitch_buff, ~] = init_audio_pitches(tone_length, CALIBRATION_PITCH_FREQ,  CALIBRATION_PITCH_FREQ); % auditory
    PsychPortAudio('FillBuffer', padhandle, cali_pitch_buff);


    if EYE_TRACKER
        trigger_str = get_et_trigger('cali_tone_on','-',tone_length,'-','-','-', c,'-',1);
        Eyelink('Message',trigger_str);
    end

    % And then you play the buffer:
    PsychPortAudio('Start',padhandle, 1, 0);
    WaitSecs(1.5);

    cali_log.iT(c) = run_dial(introspec_question);
    WaitSecs(0.2);

    if EYE_TRACKER
        trigger_str = get_et_trigger('cali_resp','-',tone_length,'-','-','-', c,'-',1);
        Eyelink('Message',trigger_str);
    end

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

    elapsedTime = 0;
    start_time = GetSecs;

    while elapsedTime < 2

        % to abort press ESC
        [~, ~, Resp1] = KbCheck(compKbDevice);
        if Resp1(abortKey)
            error(CLEAN_EXIT_MESSAGE);
        end

        elapsedTime = GetSecs - start_time;
    end

end
end
