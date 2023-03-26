function [trigger_str] = get_et_trigger(event_type, task_relevance, duration, category, orientation, vis_stim_id, onset_SOA, pitch)
% Convert all num to strings:
duration = num2str(duration);
onset_SOA = num2str(onset_SOA);
pitch = num2str(pitch);
trigger_str = join([event_type, task_relevance, duration,category,orientation, vis_stim_id, onset_SOA, pitch], "/");
end

