%% Run It after Initiate MATLAB
% run('./EIDORS/eidors/startup.m')

%%
clc; clearvars; close all;

EIT_EIDORS_Model_FER();
EIT_EIDORS_Model_GREIT();
EIT_LCT_Normal1_FER();
EIT_LCT_Normal1_GREIT();
EIT_LCT_Normal2_FER();
EIT_LCT_Normal2_GREIT();
EIT_LCT_Normal3_FER();
EIT_LCT_Normal3_GREIT();
EIT_LCT_Obese1_FER();
EIT_LCT_Obese1_GREIT();
% EIT_LCT_Obese2_FER();     % No use
% EIT_LCT_Obese2_GREIT();   % No use
EIT_LCT_Obese3_FER();
EIT_LCT_Obese3_GREIT();
