%% Subjects
Control = {'A111907G';'D030208S';'L030208D';'R030308W';'S102907D';
    'W021808H';'M042507D'; 'R042507M';'S042507C';'S042507H'};
Blind = {'C111507D';'C111907L';'D010908G';'E011108K';'E122007P';'M012108K';
    'M032408K';'M110707N';'V020808H';'V061908W';'V020408W'};
subjects = [Control; Blind];
hemi = {'lh' 'rh'};
datadir = '/jet/aguirre/abock/Semantic_Decoding';
%% Plot on surface
progBar = ProgressBar(length(subjects),'plotting on surface');
for s = 1:length(subjects)
    dir = fullfile(datadir,subjects{s});
    cd(dir)
    if exist('./searchlight_results_2_conditions_aud_tac.mat','file')
            for hh = 1:length(hemi)
                [~,~] = system(['mri_vol2surf --mov ./searchlight_results.nii.gz ' ...
                    '--reg ./bbreg.dat --hemi ' hemi{hh} ' --projfrac 0.5 ' ...
                    '--o ./' hemi{hh} '_searchlight_total_perf_surf.nii.gz']);
                [~,~] = system(['mri_surf2surf --srcsubject ' subjects{s} ...
                    ' --sval ./' hemi{hh} '_searchlight_total_perf_surf.nii.gz' ...
                    ' --trgsubject fsaverage_sym --hemi ' hemi{hh} ' --tval ./' ...
                    hemi{hh} '_searchlight_total_perf_fssymsurf.nii.gz']);
            end
    end
    progBar(s);
end
%% Average across groups
progBar = ProgressBar(length(hemi),'averaging...');
for hh = 1:length(hemi)
    % Controls
    clear tmp
    tmp_surf = [];
    for c = 1:length(Control)
        dir = fullfile(datadir,Control{c});
        cd(dir)
        if exist('./searchlight_results_2_conditions_aud_tac.mat','file')
            tmp = load_nifti(['./' hemi{hh} '_searchlight_total_perf_fssymsurf.nii.gz']);
            tmp_surf = [tmp_surf tmp.vol];
        end
    end
    avg_surf = mean(tmp_surf,2);
    tmp.vol = avg_surf;
    save_nifti(tmp,fullfile(datadir,[hemi{hh} '_total_perf_avg_Control.nii.gz'])); % Control
    % Blind
    clear tmp
    tmp_surf = [];
    for b = 1:length(Blind)
        dir = fullfile(datadir,Blind{b});
        cd(dir)
        if exist('./searchlight_results_2_conditions_aud_tac.mat','file')
            tmp = load_nifti(['./' hemi{hh} '_searchlight_total_perf_fssymsurf.nii.gz']);
            tmp_surf = [tmp_surf tmp.vol];
        end
    end
    avg_surf = mean(tmp_surf,2);
    tmp.vol = avg_surf;
    save_nifti(tmp,fullfile(datadir,[hemi{hh} '_total_perf_avg_Blind.nii.gz'])); % Blind
    progBar(hh);
end
%%
for s = 1:length(subjects)
    clear searchlight_results ind
    dir = fullfile(datadir,subjects{s});
    cd(dir)
    if exist('./searchlight_results_2_conditions_aud_tac.mat','file')
        load ./searchlight_results_2_conditions_aud_tac.mat
        foo = [];
        for i = 1:length(searchlight_results)
            for j=1:4
                %foo = [foo searchlight_results(i).iterations(j).perfmet.guesses];
                foo = [foo searchlight_results(i).total_perf];
            end
        end
        figure;hist(foo);max(foo)
    end
end


