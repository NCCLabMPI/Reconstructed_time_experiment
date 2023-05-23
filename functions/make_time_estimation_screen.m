function [] = make_time_estimation_screen(iT, introspec_question)

global w ScreenWidth ScreenHeight center text fontSize gray  INTROSPEC_QN_VIS INTROSPEC_QN_AUD line_height right_end left_end 


% line settings
color = [0 0 0];
line_thinkness = 4;
Screen('FillRect', w, gray);
Screen('DrawLine', w ,color, left_end(1), left_end(2), right_end(1), right_end(2), line_thinkness);

% make ticks and values
tick_center = linspace(left_end(1),right_end(1),11);
time_on_ticks = {'  0',' 100',' 200',' 300',' 400',' 500',' 600',' 700',' 800',' 900','1000'};
Screen('TextSize', w, round(ScreenHeight/50));

for l = 1:11
    tick_top = [tick_center(l), line_height +  ScreenHeight/80];
    tick_bottom = [tick_center(l), line_height -  ScreenHeight/80];
    Screen('DrawLine', w ,color, tick_top(1), tick_top(2), tick_bottom(1), tick_bottom(2), line_thinkness);
    DrawFormattedText(w, textProcess(time_on_ticks{l}), (tick_center(l) - ScreenWidth/50), (line_height  - ScreenHeight/60), text.Color);
end

% Display selection pointer
% get position
line_distance = right_end(1) - left_end(1);
relative_poistion = iT/1000;
pointer_position = line_distance*relative_poistion;

% make triangle
pointer_head = [(left_end(1) + pointer_position), (line_height  - ScreenHeight/10)]; 
pointer_width = ScreenWidth/100; % size of triangle
pointer_coordinates = [pointer_head-[pointer_width,0]
    pointer_head+[pointer_width,0]
    pointer_head+[0,pointer_width*2]];

% draw pointer
Screen('FillPoly', w, color, pointer_coordinates);
    
% Display question
Screen('TextSize', w, fontSize);
if strcmp(introspec_question, 'vis')
    question = INTROSPEC_QN_VIS;
elseif strcmp(introspec_question, 'aud')
    question = INTROSPEC_QN_AUD;
else % calibration
    question = 'Duration of tone?';
end
message = [question, ' ms \n\n press knob to confirm'];
DrawFormattedText(w, textProcess(message), 'center' , ScreenHeight*(1/5), text.Color);

% Flip to the screen
Screen('Flip', w);

end 