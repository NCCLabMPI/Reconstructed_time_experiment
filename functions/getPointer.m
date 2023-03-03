%GETPOINTERE takes a stimuli ID and reaches into the pre-loaded
%textures and returns the texture pointer.
% input:
% ------
% vis_stim_ID - the visual stimulus ID  (e.g., 'face_01') and orientation for which to get the texture
% pointer.
%
% output:
% -------
% texturePtr - a pointer to the texture of a given stimuli

function [ texture_ptr ] = getPointer(vis_stim_id, orientation)

global texture_struct

vis_stim_num = str2double(extractBetween(vis_stim_id,strlength(vis_stim_id)-1,strlength(vis_stim_id)));
vis_stim_cat = extractBetween(vis_stim_id,1,strlength(vis_stim_id)-3);
texture_ptr = texture_struct.(vis_stim_cat{1}).(orientation)(vis_stim_num);

end