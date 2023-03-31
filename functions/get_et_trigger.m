function [trigger_str] = get_et_trigger(event_type, task_relevance, duration, category, orientation, vis_stim_id, SOA, locking, pitch)
% Convert all num to strings:
duration = num2str(duration);
SOA = num2str(SOA);
pitch = num2str(pitch);
trigger_str = join([event_type, task_relevance, duration,category,orientation, vis_stim_id, SOA, locking, pitch], "/");
end

