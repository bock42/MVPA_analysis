function setup_MVPA(subject,dataDir,SUBJECTS_DIR,toolboxDir,nruns)
%   Runs MVPA, based on instructions found here:
%   https://code.google.com/p/princeton-mvpa-toolbox/wiki/TutorialIntro#The_easy-like-sunday-morning_tutorial
%
%   Usage:
%   run_MVPA(subject,dataDir,SUBJECTS_DIR,toolboxDir,nruns)
%
%   Defaults:
%   subject = no default, must provide subject
%   dataDir = '/Users/abock/data/Semantic_Decoding/';
%   SUBJECTS_DIR = '/Applications/freesurfer/subjects/';
%   toolboxDir = '/Users/Shared/'; % path to afni and Matlab_toolboxes
%   nruns = 4; % number of runs
%
%   Written by Andrew S Bock August 2014
%% Set up initial variables
if ~exist('subject','var')
    error('"subject" not defined')
end
if ~exist('dataDir','var')
    dataDir = '/Users/abock/data/Semantic_Decoding/';
end
if ~exist('SUBJECTS_DIR','var')
    SUBJECTS_DIR = '/Applications/freesurfer/subjects/';
end
if ~exist('toolboxDir','var')
    toolboxDir = '/Users/Shared/';
end
if ~exist('nruns','var')
    nruns = 4; % number of runs
end
subjDir = fullfile(dataDir,subject);
%% Add files/folders to path
toolboxPath = genpath(toolboxDir);
addpath(toolboxPath);
%% Pull out individual runs and conditions, as well as anatomical volume
% individual functional runs
for i=1:nruns
    [~,~] = system(['fslroi ' sprintf(fullfile(subjDir,'beta_%i.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_aud.nii.gz'),i) ' 0 1']); % auditory
    [~,~] = system(['fslroi ' sprintf(fullfile(subjDir,'beta_%i.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_rev.nii.gz'),i) ' 1 1']); % reverse
    [~,~] = system(['fslroi ' sprintf(fullfile(subjDir,'beta_%i.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_tac.nii.gz'),i) ' 2 1']); % tactile
    [~,~] = system(['fslroi ' sprintf(fullfile(subjDir,'beta_%i.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_vis.nii.gz'),i) ' 3 1']); % visual
end
% anatomical volume
[~,~] = system(['mri_convert ' fullfile(SUBJECTS_DIR,subject,'mri','ribbon.mgz') ...
    ' ' fullfile(subjDir,'ribbon.nii.gz')]);
nii = load_nifti(fullfile(subjDir,'ribbon.nii.gz'));
ribbon.gm_lh = nii.vol == 3;
ribbon.gm_rh = nii.vol == 42;
ribbon.gm = ribbon.gm_lh + ribbon.gm_rh;ribbon.gm = find(ribbon.gm>0);
nii.vol = zeros(size(nii.vol));
nii.vol(ribbon.gm) = 1;
save_nifti(nii,fullfile(subjDir,'gm.nii.gz'));
%% Transform anatomical volume to functional space
[~,~] = system(['mri_vol2vol --targ ' fullfile(subjDir,'gm.nii.gz') ' --mov ' ...
    fullfile(subjDir,'Func_for_reg.nii.gz') ' --o ' ...
    fullfile(subjDir,'fgm.nii.gz') ' --reg ' fullfile(subjDir,'bbreg.dat')...
    ' --inv']);
[~,~] = system(['fslmaths ' fullfile(subjDir,'fgm.nii.gz') ' -bin ' ...
    fullfile(subjDir,'fgm.nii.gz')]);
% convert to afni format
[~,~] = system(['3dcopy ' fullfile(subjDir,'fgm.nii.gz') ' ' fullfile(subjDir,'gm_mask')]);
%% Concatentate images for 2-way (pairwise), 3-way (auditory,visual,tactile) and 4-way (reverse vs 3-forward) classification
for i=1:nruns
    [~,~] = system(['fslmerge -t ' sprintf(fullfile(subjDir,'run%i_aud_tac.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_aud.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_tac.nii.gz'),i)]);
    [~,~] = system(['fslmerge -t ' sprintf(fullfile(subjDir,'run%i_aud_vis.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_aud.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_vis.nii.gz'),i)]);
    [~,~] = system(['fslmerge -t ' sprintf(fullfile(subjDir,'run%i_tac_vis.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_tac.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_vis.nii.gz'),i)]);
    [~,~] = system(['fslmerge -t ' sprintf(fullfile(subjDir,'run%i_aud_tac_vis.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_aud.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_tac.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_vis.nii.gz'),i)]);
    [~,~] = system(['fslmerge -t ' sprintf(fullfile(subjDir,'run%i_aud_tac_vis_rev.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_aud.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_tac.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_vis.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_rev.nii.gz'),i)]);
end
%% Convert the EPI data
% e.g. subj = load_afni_pattern(subj,'beta','<mask_name>','<raw_filenames>');
for i=1:nruns
    [~,~] = system(['3dcopy ' sprintf(fullfile(subjDir,'run%i_aud_tac.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_aud_tac'),i)]);
    [~,~] = system(['3dcopy ' sprintf(fullfile(subjDir,'run%i_aud_vis.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_aud_vis'),i)]);
        [~,~] = system(['3dcopy ' sprintf(fullfile(subjDir,'run%i_tac_vis.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_tac_vis'),i)]);
        [~,~] = system(['3dcopy ' sprintf(fullfile(subjDir,'run%i_aud_tac_vis.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_aud_tac_vis'),i)]);
    [~,~] = system(['3dcopy ' sprintf(fullfile(subjDir,'run%i_aud_tac_vis_rev.nii.gz'),i) ' ' ...
        sprintf(fullfile(subjDir,'run%i_aud_tac_vis_rev'),i)]);
end