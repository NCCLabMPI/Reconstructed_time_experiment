function [  ] = calibration(number_of_cali_trails)

global CALIBRATION_PITCH_FREQ ScreenHeight text w
cali_ms = linspace(20,1000,number_of_cali_trails);
cali_ms = ShuffleVector(cali_ms);
introspec_question = 'cali';

for c = length(cali_ms)
    [cali_pitch_buff, ~, aud_pahandle] = init_audio_pitches(cali_ms(c), CALIBRATION_PITCH_FREQ,  CALIBRATION_PITCH_FREQ); % auditory
    PsychPortAudio('FillBuffer', aud_pahandle, cali_pitch_buff);

    % And then you play the buffer. The function returns a time stamp.
    % Here I don't use it but for our purpose we will want to log it:
    PsychPortAudio('Start',aud_pahandle, 1, 0);

    [ iT ] = run_dial(introspec_question);
    WaitSecs(0.2)

    % Deliver feddback
    actual_time = ['The true duration of the tone was: ', num2str(cali_ms(c)), ' ms'];
    estimated_time = ['Your estimated duration of the tone was: ', num2str(iT), ' ms'];

    if (cali_ms(c) - iT) > 50
        cali_feedback = 'Your estimated time was too short!';
    elseif (cali_ms(c) - iT) < 50
        cali_feedback = 'Your estimated time was too long!';
    else
        cali_feedback = 'Well done!';
    end
    DrawFormattedText(w, textProcess(actual_time), 'center' , ScreenHeight*(1/5), text.Color);
    DrawFormattedText(w, textProcess(estimated_time), 'center' , ScreenHeight*(2/5), text.Color);
    DrawFormattedText(w, textProcess(cali_feedback), 'center' , ScreenHeight*(2/5), text.Color);

    WaitSecs(1)

end
end