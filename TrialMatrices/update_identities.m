function [new_identities] = update_identities(counter_struct,identities, target)
% This function finds identities that aren't available anymore and removes
% them from the list of identities to avoid picking them:
new_identities = [];
for identity=1:length(identities)
    if counter_struct.(identities(identity)) > 0 && ~strcmp(target, identities(identity))
        new_identities = [new_identities; identities(identity)];
    end 
end
end

