function [] = loadStimuli()
global texture_struct w

% path to stimuli folder
PreFolderName = [pwd,filesep,'stimuli\'];
cate_names = {'letter', 'face', 'false_font', 'object'};
ori_names = {'center', 'left', 'right'};
gender_names = {'male', 'female'};
% stimulus_id = {"face_1", "face_2"}

cat_struct = struct('center', 1:20, 'left', 1:20, 'right', 1:20);
texture_struct = struct('letter', cat_struct, 'face', cat_struct, 'false_font', cat_struct, 'object', cat_struct);

% loops through the folders an loads all stimuli
for j = 1:length(cate_names)
    for jj = 1:length(ori_names)
        if j == 2 % 3rd for loop only for faces
            for jjj = 1:length(gender_names)
                FolderName = fullfile(PreFolderName, cate_names{j},ori_names{jj}, gender_names{jjj});
                new_textures = getTexturesFromHD(FolderName, w);
                texture_struct.(cate_names{j}).(ori_names{jj})(10*jjj-9:10*jjj) = new_textures;
            end
        else
            FolderName = fullfile(PreFolderName, cate_names{j}, ori_names{jj});
            new_textures = getTexturesFromHD(FolderName, w);
            texture_struct.(cate_names{j}).(ori_names{jj})(1:20) = new_textures;
        end
    end
end
end