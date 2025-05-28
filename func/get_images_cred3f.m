function [im1, Texture] = get_images_cred3f(trialmat, win)
imageList   = strcat('../stim/',trialmat.file_name);
%fprintf('\n\nLoad stimuli...\n')
for k = 1:numel(imageList)
    im = imread(imageList{k});
    Texture(k) = Screen('MakeTexture', win, im);
    im1(k).image = im; 
end
end