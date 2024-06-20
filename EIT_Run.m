%% Run it after Initiate MATLAB
% run('./EIDORS/eidors/startup.m')

%%
clc; clearvars; close all;

EIT_EIDORS_Model_FER();
EIT_EIDORS_Model_GREIT();

for i=1:6
    run(strcat('./Normal/EIT_LCT_Normal', int2str(i), '_FER.m')
    run(strcat('./Normal/EIT_LCT_Normal', int2str(i), '_GREIT.m')
end

for i=1:3
    run(strcat('./Normal/EIT_LCT_Obese', int2str(i), '_FER.m')
    run(strcat('./Normal/EIT_LCT_Obese', int2str(i), '_GREIT.m')
end

% EIT_LCT_Obese2_FER();     % No use
% EIT_LCT_Obese2_GREIT();   % No use
% I have no idea this shorten code will work
