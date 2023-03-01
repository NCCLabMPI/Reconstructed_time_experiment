for h = 1:length(trial_mat.vis_stim_cate)
    if strcmp(trial_mat.vis_stim_cate{h}, 'letter')
        trial_mat.vis_stim_cate{h} = 'char';
    elseif strcmp(trial_mat.vis_stim_cate{h}, 'false_font')
        trial_mat.vis_stim_cate{h} = 'false';
    end 
end 
writetable(trial_mat,fullfile(MatFolderName, 'reconstructed_time_trial_mat.csv'))  