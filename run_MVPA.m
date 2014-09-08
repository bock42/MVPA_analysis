function run_MVPA(subject,dataDir,toolboxDir,conditions,nruns,pairwise,classifier)
%   Runs MVPA, based on instructions found here:
%   https://code.google.com/p/princeton-mvpa-toolbox/wiki/TutorialIntro#The_easy-like-sunday-morning_tutorial
%
%   Usage:
%   run_MVPA(subject,dataDir,fsDir,toolboxDir,conditions,nruns)
%
%   Defaults:
%   subject = no default, must provide subject
%   dataDir = '/Users/abock/data/Semantic_Decoding/';
%   SUBJECTS_DIR = '/Applications/freesurfer/subjects/';
%   toolboxDir = '/Users/Shared/'; % path to afni and Matlab_toolboxes
%   conditions = 3; % 3=aud,tactile,visual; 4=aud,tac,vis,rev
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
if ~exist('toolboxDir','var')
    toolboxDir = '/Users/Shared/';
end
if ~exist('conditions','var')
    conditions = 3; 
end
if ~exist('nruns','var')
    nruns = 4; % number of runs
end
if ~exist('pairwise','var')
    pairwise = ''; % default is not pairwise
end
if ~exist('classifier','var')
    classifier = 'bp'; % backpropagation
end
subjDir = fullfile(dataDir,subject);
cd(subjDir); % This appears to be key for the MVPA toolbox, strange bugs otherwise
%% Add files/folders to path
toolboxPath = genpath(toolboxDir);
addpath(toolboxPath);
dataPath = genpath(dataDir);
addpath(dataPath);
%% Create subject structure, specifying the experiment name and subject name
% e.g. subj = init_subj('<experiment_name>','<subject_name>')
subj = init_subj('Semantic_Decoding',subject); % initializes the subject structure
%% Create a grey matter mask to restrict the voxels for later analysis
% e.g. subj = load_afni_mask(subj,'<mask_name>','<filename>')
subj = load_afni_mask(subj,'gm_mask',fullfile(subjDir,'gm_mask+orig'));
%% Load in the EPI data
% e.g. subj = load_afni_pattern(subj,'beta','<mask_name>','<raw_filenames>');
for i=1:nruns
    if conditions == 2
        if strcmp(pairwise,'aud_tac')
            beta_files{i} = sprintf(fullfile(subjDir,'run%i_aud_tac+orig'),i);
        elseif strcmp(pairwise,'aud_vis')
            beta_files{i} = sprintf(fullfile(subjDir,'run%i_aud_vis+orig'),i);
        elseif strcmp(pairwise,'tac_vis')
            beta_files{i} = sprintf(fullfile(subjDir,'run%i_tac_vis+orig'),i);
        end
    elseif conditions == 3
        beta_files{i} = sprintf(fullfile(subjDir,'run%i_aud_tac_vis+orig'),i);
    elseif conditions == 4
        beta_files{i} = sprintf(fullfile(subjDir,'run%i_aud_tac_vis_rev+orig'),i);
    end
end
subj = load_afni_pattern(subj,'beta','gm_mask',beta_files);
%% Load in regressors
subj = init_object(subj,'regressors','conds');
% Conds will be a 4x16 matrix, for the 4 conditions, and 16 total volumes
% (4 runs x 4 betas)
conds = zeros(conditions,conditions*nruns);
regress = zeros(1,conditions);
for i = 1:conditions
    tmp = regress; tmp(i) = 1;
    conds(i,:) = repmat(tmp,1,nruns);
    conds(i,:) = repmat(tmp,1,nruns);
    
end
subj = set_mat(subj,'regressors','conds',conds);
if conditions == 2
    if strcmp(pairwise,'aud_tac')
        condnames = {'auditory' 'tactile'};
    elseif strcmp(pairwise,'aud_vis')
        condnames = {'auditory' 'visual'};
    elseif strcmp(pairwise,'tac_vis')
        condnames = {'tactile' 'visual'};
    end
elseif conditions == 3
    condnames = {'auditory' 'tactile' 'visual'};
elseif conditions == 4
    condnames = {'auditory' 'tactile' 'visual' 'reverse'};
end
subj = set_objfield(subj,'regressors','conds','condnames',condnames);
%% Store information about the runs
% e.g. subj = init_object(subj,'selector','runs');
subj = init_object(subj,'selector','runs');
runs = repmat(1:nruns,conditions,1); runs = runs(:)';
subj = set_mat(subj,'selector','runs',runs);
%% Z-scoring
subj = zscore_runs(subj,'beta','runs');
%% Create cross-validation indicies
subj = create_xvalid_indices(subj,'runs');
%summarize(subj); % display the contents of the subject structure
%% Create adjacency matrix for each voxel
subj.adj_sphere = create_adj_list(subj,'gm_mask','radius',3);
% Initialize new mask for each spotlight
subj = load_afni_mask(subj,'ROI_mask',fullfile(subjDir,'gm_mask+orig'));
results = cell(length(subj.adj_sphere),1);
% Cross-validation classification, using a basic backprop classifier with no hidden layer
class_args.train_funct_name = ['train_' classifier];
class_args.test_funct_name = ['test_' classifier];
class_args.nHidden = 0;
if strcmp(classifier,'svm')
    class_args.kernel_type = 0;
    class_args.ignore_1ofn = 'false';
end
%% Searchlight
progBar = ProgressBar(length(subj.adj_sphere),'searchlight...');
for v = 1:length(subj.adj_sphere)
    % Create a mask to restrict the voxels
    subj.masks{2}.mat = zeros(size(subj.masks{2}.mat));
    tmpind = subj.adj_sphere(v,:); tmpind = tmpind(tmpind>0); 
    gmind = find(subj.masks{1}.mat);
    tmpind = gmind(tmpind);
    subj.masks{2}.mat(tmpind) = 1;
    % run classification
    [subj,results{v}] = cross_validation(subj,'beta_z','conds','runs_xval','ROI_mask',class_args);
    if ~mod(v,10);progBar(v);end
end
%% Save the output
for v = 1:length(subj.adj_sphere)
    searchlight_results(v).total_perf = results{v}.total_perf;
    for i = 1:4
        searchlight_results(v).iterations(i).perfmet = results{v}.iterations(i).perfmet;
    end
end
ind.adj_sphere = subj.adj_sphere;
nii = load_nifti(fullfile(subjDir,'fgm.nii.gz'));
ind.gm = find(nii.vol);
nii.vol(ind.gm) = cat(1,searchlight_results(:).total_perf);
if conditions == 2
    save_nifti(nii,fullfile(subjDir,['searchlight_results_' num2str(conditions) ...
        '_conditions_' pairwise '.nii.gz']));
    save(fullfile(subjDir,['searchlight_results_' num2str(conditions) ...
        '_conditions_' pairwise]),'searchlight_results','ind');
else
    save_nifti(nii,fullfile(subjDir,['searchlight_results_' num2str(conditions) ...
        '_conditions.nii.gz']));
    save(fullfile(subjDir,['searchlight_results_' num2str(conditions) ...
        '_conditions']),'searchlight_results','ind');
end