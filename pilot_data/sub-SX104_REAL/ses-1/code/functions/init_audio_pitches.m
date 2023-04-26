function [high_pitch_buff, low_pitch_buff] = init_audio_pitches(pitch_dur, high_pitch_freq, low_pitch_freq)
    global padhandle
    
    % Extract a couple of info from the audio port:
    status = PsychPortAudio('GetStatus', padhandle);
    % The sampling rate is a very important parameter to be able to display
    % the sound
    sr = status.SampleRate;
    disp(sr)
    
    % Generate the high and low pitches arrays:
    high_pitch = repmat(MakeBeep(high_pitch_freq,pitch_dur,sr), 2, 1);
    low_pitch = repmat(MakeBeep(low_pitch_freq,pitch_dur,sr), 2, 1);
    % Create audio buffers for each:
    high_pitch_buff = PsychPortAudio('CreateBuffer', padhandle, high_pitch);
    low_pitch_buff = PsychPortAudio('CreateBuffer', padhandle, low_pitch);
   
end