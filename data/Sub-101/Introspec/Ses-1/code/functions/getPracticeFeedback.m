function [ ] = getPracticeFeedback(practice_type)
global compKbDevice RestartKey YesKey
global RUN_PRACTICE MaxPracticeHits PracticeHits PracticeFalseAlarms TotalScore practice_aud_score warning_response_order 
global PRACTICE_FEEDBACK_MESSAGES RESTART_PRACTICE_MESSAGE restart_practice_message EXTRA_PRACTICE RESP_ORDER_WARNING_MESSAGE


% Practice start message
if strcmp(practice_type, 'auditory')
    pracitce_start_message = 'We will start with the pratice \n\n of the auditory task. \n\n Press space to continue...';
elseif strcmp(practice_type, 'visual')
    pracitce_start_message = 'We will continue with the pratice \n\n of the visual task. \n\n Press space to continue...';
elseif strcmp(practice_type, 'auditory_and_visual')
    pracitce_start_message = 'We will continue with the pratice \n\n of both tasks at the same time. \n\n Press space to continue...';
elseif strcmp(practice_type, 'introspection')
    pracitce_start_message = 'We will continue with the \n\n estimation of reaction time. \n\n Press space to continue...';
end

showMessage(pracitce_start_message);
KbWait(compKbDevice,3);
warning_response_order = 0;

while RUN_PRACTICE
    RestartPracticeFlag=1;
    runPractice(practice_type);

    if strcmp(practice_type, 'visual')
        aud_feedback_message = [];
    else
        aud_feedback_message = ['Your auditory score is ', num2str(round(practice_aud_score*100)), '%'];
    end

    if RUN_PRACTICE
        if (isempty(PRACTICE_FEEDBACK_MESSAGES)) && strcmp(practice_type, 'auditory')
            restart_practice_message=strcat(aud_feedback_message,RESTART_PRACTICE_MESSAGE);
        elseif (isempty(PRACTICE_FEEDBACK_MESSAGES))
            restart_practice_message=sprintf(strcat('Your visual score is ', ' %s\n\n%s\n\\n%s'),strcat(num2str(round(TotalScore)),'%'),aud_feedback_message,RESTART_PRACTICE_MESSAGE);
        elseif (length(PRACTICE_FEEDBACK_MESSAGES)==1)
            splitted_message=strsplit(PRACTICE_FEEDBACK_MESSAGES{1},{'x'});
            if (isempty(strfind(PRACTICE_FEEDBACK_MESSAGES{1},'missed')))
                restart_practice_message=sprintf(strcat('Your visual score is ', ' %s\n\n%s %s %s \n\n\n %s \n%s'),strcat(num2str(round(TotalScore)),'%'),splitted_message{1},num2str(PracticeFalseAlarms),splitted_message{2},aud_feedback_message,RESTART_PRACTICE_MESSAGE);
            else
                restart_practice_message=sprintf(strcat('Your visual score is ', ' %s\n\n%s %s %s \n\n\n %s \n%s'),strcat(num2str(round(TotalScore)),'%'),splitted_message{1},num2str(MaxPracticeHits-PracticeHits),splitted_message{2},aud_feedback_message,RESTART_PRACTICE_MESSAGE);
            end
        else
            splitted_message1=strsplit(PRACTICE_FEEDBACK_MESSAGES{1},{'x'});
            splitted_message2=strsplit(PRACTICE_FEEDBACK_MESSAGES{2},{'x'});
            restart_practice_message=sprintf(strcat('Your visual score is ', ' %s\n\n%s %s %s \n\n%s %s %s\n\n %s \n%s'),strcat(num2str(round(TotalScore)),'%'),splitted_message1{1},num2str(MaxPracticeHits-PracticeHits),splitted_message1{2},splitted_message2{1},num2str(PracticeFalseAlarms),splitted_message2{2},aud_feedback_message, RESTART_PRACTICE_MESSAGE);
        end

        showMessage(restart_practice_message);
        % Wait for answer
        [~, RestartPracticeResp, ~] =KbWait(compKbDevice,3);

        while RestartPracticeFlag
            if RestartPracticeResp(RestartKey)
                RestartPracticeFlag=0;
                RUN_PRACTICE = 1;
            elseif RestartPracticeResp(YesKey)
                    RestartPracticeFlag=0;
                    RUN_PRACTICE = 0;
            else
                [~, RestartPracticeResp, ~] =KbWait(compKbDevice,3);
                RestartPracticeFlag=1;
            end
        end
    end


    if warning_response_order == 1
        showMessage(RESP_ORDER_WARNING_MESSAGE);
        WaitSecs(3)
        warning_response_order = 0;
    end

end

showMessage('This practice part is over. \n\n Well done! \n\n press any key to start next part.');
KbWait(compKbDevice,3)

end   