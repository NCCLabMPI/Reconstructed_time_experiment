function [trial_mat] = prepare_log(trial_mat)
% This function adds column to the trial matrix for each event we might
% want to log:
trial_mat.texture = nan(height(trial_mat), 1);  % Texture being presented
trial_mat.trial_start_time = nan(height(trial_mat), 1);  % Time stamp of the trial onset. Depending on the task, that might be the visual or auditory stimulus onset
trial_mat.vis_stim_time = nan(height(trial_mat), 1);  % Time stamp of the visual stimulus onset
trial_mat.time_of_resp_vis = nan(height(trial_mat), 1);  % Time stamp of response to visual stimulus
trial_mat.has_response_vis = zeros(height(trial_mat), 1);  % Whether there was a response
trial_mat.trial_response_vis = repmat("empty", height(trial_mat), 1);  % Correctness of vis repsonse (hit, miss, ...)
trial_mat.aud_stim_buff = nan(height(trial_mat), 1);  % ID of the audio stim presented
trial_mat.aud_stim_time = nan(height(trial_mat), 1);  % Time stamp of the auditory stim onset
trial_mat.aud_resp = nan(height(trial_mat), 1);  % Response key to the auditory stimulus
trial_mat.trial_accuracy_aud = nan(height(trial_mat), 1);  % Whether the response to the auditory stim is correct
trial_mat.time_of_resp_aud = nan(height(trial_mat), 1);  % Time stamp of the auditory stim response
trial_mat.trial_first_button_press = zeros(height(trial_mat), 1);  % First button pressed
trial_mat.trial_second_button_press = zeros(height(trial_mat), 1);  % Second button pressed
trial_mat.fix_time = nan(height(trial_mat), 1);  % Time stamp of fixation onset
trial_mat.JitOnset = nan(height(trial_mat), 1);  % Time stamp of the jitter onset
trial_mat.trial_end = nan(height(trial_mat), 1);  % Time stamp of trial end
trial_mat.wrong_key =  nan(height(trial_mat), 1);  % Wrong key being pressed during the trial
trial_mat.wrong_key_timestemp =  nan(height(trial_mat), 1);  % Time stamp of wrong key press
trial_mat.TargetScreenOnset = nan(height(trial_mat), 1); % Time stamp of the target kez
end

