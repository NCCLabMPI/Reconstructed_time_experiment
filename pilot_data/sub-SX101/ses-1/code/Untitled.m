wait_resp = 0;
while wait_resp == 0
    [~, ~, wait_resp] = KbCheck();
end