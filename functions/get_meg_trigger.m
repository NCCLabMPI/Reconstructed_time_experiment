function [trigCode] = get_meg_trigger(event)

switch event
    case "visual"
        trigCode = 1;
    case "audio"
        trigCode = 2;
    case "fixation"
        trigCode = 3;
    case "jitter"
        trigCode = 4;
    case "response"
        trigCode = 5;
end