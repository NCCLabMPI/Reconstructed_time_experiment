function [high_pitch_buff, low_pitch_buff, pahandle] = init_audio_pitches(pitch_dur, high_pitch_freq, low_pitch_freq)
    
    % Initializing psychtool box sound
    InitializePsychSound(1);
    % Setting a couple of parameters
    device = [];
    mode = 1;
    % This one is going to be important for us @Micha, it controls how 
    % accurate timing is. But there might a bit of a trade off, if we go
    % for super duper accurate sounds latencies, that might mess up visual
    % timing. 
    reqlatencyclass = 1;  
    freq = [];
    channels = 2;
    % Opening the audio port. The padhandle needs to be kept, if you want
    % to play a sound you need to specify that you want to play it through
    % this open port, and that's what the padhandle is
    pahandle = PsychPortAudio('Open', device, mode, reqlatencyclass, freq, channels);
    
    % Extract a couple of info from the audio port:
    status = PsychPortAudio('GetStatus', pahandle);
    % The sampling rate is a very important parameter to be able to display
    % the sound
    sr = status.SampleRate;
    disp(sr)
    % Converting the duration of the pitch in number of samples. If we 
    % have say 48000Hz, that means that within one second, we have 48000
    % samples. So if we want to play a sound for say 1 second, we need the
    % sound to have 48000 samples:
    n_samples = pitch_dur/(1/sr);
    
    % Generate the high and low pitches arrays. You specify the frequency,
    % the duration and PTB takes care of the rest for you:
    high_pitch = repmat(MakeBeep(high_pitch_freq,pitch_dur,sr), 2, 1);
    low_pitch = repmat(MakeBeep(low_pitch_freq,pitch_dur,sr), 2, 1);
    % Adding the square wave to the buffer, i.e. kind of like loading the 
    % images to working memory:
    high_pitch_buff = PsychPortAudio('CreateBuffer', pahandle, high_pitch);
    low_pitch_buff = PsychPortAudio('CreateBuffer', pahandle, low_pitch);
   
end