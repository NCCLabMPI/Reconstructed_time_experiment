function [log_table, performance_struct] = compute_performance(log_table)
%%
disp('WELCOME TO compute_performance');

global LOW_PITCH HIGH_PITCH

performance_struct.misses = 0;
performance_struct.hits = 0;
performance_struct.fa = 0;
performance_struct.cr = 0; % correct rejection

log_table = log_table(~isnan(log_table.texture), :);

for tr = 1:length(log_table.trial)


        % compute correctness visual task
        if strcmp(log_table.task_relevance{tr}, 'target') && log_table.has_response_vis(tr) == 1
            performance_struct.hits = performance_struct.hits + 1;
            log_table.trial_response_vis{tr} ='hit';
        elseif ~strcmp(log_table.task_relevance{tr}, 'target') && log_table.has_response_vis(tr) == 1
            performance_struct.fa = performance_struct.fa + 1;
            log_table.trial_response_vis{tr} ='fa';
        elseif ~strcmp(log_table.task_relevance{tr}, 'target') && log_table.has_response_vis(tr) == 0
            performance_struct.cr = performance_struct.cr + 1;
            log_table.trial_response_vis{tr} ='cr';
        else
            log_table.trial_response_vis{tr} ='miss';
            performance_struct.misses = performance_struct.misses + 1;
        end

        % get RT visual response 
        log_table.RT_vis(tr) = log_table.time_of_resp_vis(tr) - log_table.vis_stim_time(tr);
        % make it a nan when RT is negative 
        if log_table.RT_vis(tr) < 0
            log_table.RT_vis(tr) = nan;
        end


        % extract auditory response
        if log_table.trial_first_button_press(tr) >= 1000 
            log_table.aud_resp(tr) = log_table.trial_first_button_press(tr);
        elseif log_table.trial_second_button_press(tr) >= 1000
            log_table.aud_resp(tr) = log_table.trial_second_button_press(tr);
        else  
            log_table.aud_resp(tr) = 0; % No auditory response was provided
        end 

        % compute correctness auditory task
        if (log_table.aud_resp(tr) == LOW_PITCH && log_table.pitch(tr) == 1000) ||...
                (log_table.aud_resp(tr) == HIGH_PITCH && log_table.pitch(tr) == 1100)
            log_table.trial_accuracy_aud(tr) = 1;

        elseif (log_table.aud_resp(tr) == LOW_PITCH && log_table.pitch(tr) == 1000) ||...
                (log_table.aud_resp(tr) == HIGH_PITCH && log_table.pitch(tr) == 1100)
            log_table.trial_accuracy_aud(tr) = 0;
        else
            log_table.trial_accuracy_aud(tr) = nan;
        end

        % get RT auditory response 
        log_table.RT_aud(tr) = log_table.time_of_resp_aud(tr) - log_table.aud_stim_time(tr);
        % make it a nan when RT is negative 
        if log_table.RT_aud(tr) < 0
            log_table.RT_aud(tr) = nan;
        end

end
performance_struct.aud_mean_accuracy = mean(log_table.trial_accuracy_aud, 'omitnan');
end