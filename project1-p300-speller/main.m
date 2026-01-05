% With the given file structure, the code should run as is,
% however, there are some caveats. 
% 
% to that end, here is a brief file structure tree:
% 
% ├── group-2-data/                 %our group
% │   ├── train1_group2_Tuesday.mat
% │   ├── train2_group2_Tuesday.mat
% │   ├── test1_group2_Tuesday.mat
% │   └── test2_group2_Tuesday.mat
% │
% ├── other-group-data/             % All of the other groups’ training/testing data
% │   ├── train1_group1_Tuesday.mat
% │   ├── train2_group1_Tuesday.mat
% │   ├── ...
% │   └── test2_groupN_Tuesday.mat
% │
% ├── BCI.locs  
% 
% it is necessary to run eeglab in order to use the topoplot features, I do
% this by adding the path with my eeglab folder and then typing eeglab in the 
% CLI. 
% 
% This was originally 2 livescripts, one for part1 and one for part2, merged 
% into one .m file. 





% First, using the train1.mat data collected by your group, calculate and plot
% the average ERP, averaged over electrodes, for target and non-target flashes
%     from 100ms before to 600ms after each flash (same as HW). Mark the ERP
%     components visible in the average ERP plots.
%%lets take the average ERP from our train1 data
load('group-2-data/train1_group2_Tuesday.mat');
fs = 256;  %freq
t = y(1,:); % time v
EEG = y(2:9,:); % EEG channels Fz–PO8
flash = y(10,:); % flash ID (either 1–12)
target = y(11,:); % this will be our target indicator (with 1=target flash)

% Restrict to clean portion of the recording just to test and see if things
% change, but usually keep out 
%keep = (t >= 70 & t <= 380);
%t = t(keep);
%EEG = EEG(:, keep);
%flash = flash(keep);
%target = target(keep);

% Define the epoch window per instructions in the project thing 
win_pre  = 0.1; % pre flash
win_post = 0.6;% post flash
nPre  = round(win_pre * fs);
nPost = round(win_post * fs);

% Then we ahve to find the onset indices where the flash changes from 0 to
% something nonzero
flash_shift = [0 flash(1:end-1)];
onsets = find((flash ~= 0) & (flash_shift == 0));

% now we should segment intothe  target and the non-target trials
epochs_target = {};
epochs_nontarget = {};
for i = 1:length(onsets)
    idx = onsets(i);
    if idx - nPre < 1 || idx + nPost > length(t)
        continue
    end
    seg = EEG(:, idx - nPre : idx + nPost);
    if target(idx) == 1
        epochs_target{end+1} = seg;
    else
        epochs_nontarget{end+1} = seg;
    end
end

% convert to 3d M
EEG_target = cat(3, epochs_target{:});
EEG_nontarget = cat(3, epochs_nontarget{:});
t_epoch = (-nPre:nPost) / fs;  %should be our epoch time vector in seconds 

fprintf('Cut %d total flashes: %d target, %d non-target epochs.\n', ...
    numel(onsets), size(EEG_target,3), size(EEG_nontarget,3));

% now should Compute the average ERPs. 
ERP_target = mean(EEG_target, 3);
ERP_nontarget = mean(EEG_nontarget, 3);
grand_target = mean(ERP_target, 1);
grand_nontarget = mean(ERP_nontarget, 1);

% now we should be able to plot average ERP across all of our electrodess
figure('Color','w');
plot(t_epoch*1000, grand_target, 'r', 'LineWidth', 1.8); hold on;
plot(t_epoch*1000, grand_nontarget, 'b', 'LineWidth', 1.8);
xline(0, '--k'); yline(0, ':k');
xlabel('Time (ms)'); ylabel('Amplitude (µV)');
title('Average ERP Across Electrodes (train1)');
legend({'Target','Non-Target'}, 'Location','best');
grid on;

% then as told in hw make sure to mark thge expected ERP components
xline(100, '--', 'N1 (~100 ms)', 'LabelOrientation','horizontal');
xline(200, '--', 'P2 (~200 ms)', 'LabelOrientation','horizontal');
xline(300, '--', 'P3 (~300 ms)', 'LabelOrientation','horizontal');

% Plot the scalp map of the signal at 0, 100, 200, and 300ms after the onset of
% the flash. Use topoplot.m from EEGLAB and BCI.locs on Courseworks
%addpath('C:\Users\Alexander Speer\Desktop\Columbia Fall 2025\BCI Lab\miniproject\eeglab14_1_2b')

%another thing: make sure that you type 'eeglab' in the CLI as well before
%running this cell. You need both.

%it is important that you run addpath('C:\Users\Alexander
%Speer\Desktop\Columbia Fall 2025\BCI Lab\Lab 6\eeglab14_1_2b') in the CLI before you
%run this code cell. 

load('group-2-data/train1_group2_Tuesday.mat');

fs = 256;                                   
t = y(1,:);                                  
EEG = y(2:9,:);                             
flash = y(10,:);
target = y(11,:);

%keep = (t >= 70 & t <= 380);
%t = t(keep);
%EEG = EEG(:, keep);
%flash = flash(keep);
%target = target(keep);


win_pre  = 0.1; %all same code as before 
win_post = 0.6;
nPre  = round(win_pre * fs);
nPost = round(win_post * fs);

flash_shift = [0 flash(1:end-1)];
onsets = find((flash ~= 0) & (flash_shift == 0));

epochs_target = {};
for i = 1:length(onsets)
    idx = onsets(i);
    if idx - nPre < 1 || idx + nPost > length(t), continue; end
    if target(idx) == 1
        seg = EEG(:, idx - nPre : idx + nPost);
        epochs_target{end+1} = seg;
    end
end
EEG_target = cat(3, epochs_target{:});
ERP_target = mean(EEG_target, 3);  %channels x time
t_epoch = (-nPre:nPost) / fs; 

% now for the super tricky part, selecting the 8-channel subset from the .locs file
locs_path = 'BCI.locs';
chanNames = {'Fz','Cz','P3','Pz','P4','PO7','Oz','PO8'};
selLocIdx = [1 6 13 11 12 15 16 14];         % make sure you change from prev labs 
chanlocs = readlocs(locs_path);
chanlocs = chanlocs(selLocIdx);

% changed to include 400ms bc our data is shifted 0, 100, 200, 300, and 400 ms
times_to_plot = [0 0.1 0.2 0.3 0.4]; 
figure('Color','w','Name','ERP scalp maps at key time points');
for i = 1:length(times_to_plot)
    [~, idx] = min(abs(t_epoch - times_to_plot(i)));
    subplot(2,3,i); 
    topoplot(ERP_target(:,idx), chanlocs, ...
        'electrodes','on','numcontour',6,'style','map','plotrad',0.5);
    title(sprintf('%.0f ms', times_to_plot(i)*1000));
    colorbar;
end
sgtitle('Target ERP scalp distribution (train1)');


% Produce these plots (average ERPs, marked components, topoplots) again,
% this time using the train2.mat data collected by your group. Do these plots
% differ from the train1.mat plots? If so, how do they differ and why do you
% think they differ in that way? If not, what makes them so consistent?
load('group-2-data/train2_group2_Tuesday.mat');

fs = 256;                                    
t = y(1,:);                                  
EEG = y(2:9,:);                      
flash = y(10,:);
target = y(11,:);


%keep = (t >= 70 & t <= 380);
%t = t(keep);
%EEG = EEG(:, keep);
%flash = flash(keep);
%target = target(keep);


win_pre  = 0.1;      
win_post = 0.6;     
nPre  = round(win_pre * fs);
nPost = round(win_post * fs);

flash_shift = [0 flash(1:end-1)];
onsets = find((flash ~= 0) & (flash_shift == 0));

epochs_target = {};
epochs_nontarget = {};
for i = 1:length(onsets)
    idx = onsets(i);
    if idx - nPre < 1 || idx + nPost > length(t), continue; end
    seg = EEG(:, idx - nPre : idx + nPost);
    if target(idx) == 1
        epochs_target{end+1} = seg;
    else
        epochs_nontarget{end+1} = seg;
    end
end

EEG_target = cat(3, epochs_target{:});
EEG_nontarget = cat(3, epochs_nontarget{:});
t_epoch = (-nPre:nPost) / fs;

% copmute the erps
ERP_target = mean(EEG_target, 3);
ERP_nontarget = mean(EEG_nontarget, 3);
grand_target = mean(ERP_target, 1);
grand_nontarget = mean(ERP_nontarget, 1);

fprintf('train2: %d target and %d non-target trials.\n', ...
    size(EEG_target,3), size(EEG_nontarget,3));

% then we should plot the average ERP (over all of the electrodes
figure('Color','w');
plot(t_epoch*1000, grand_target, 'r', 'LineWidth', 1.8); hold on;
plot(t_epoch*1000, grand_nontarget, 'b', 'LineWidth', 1.8);
xline(0, '--k'); yline(0, ':k');
xline(100, '--', 'N1 (~100 ms)', 'LabelOrientation','horizontal');
xline(200, '--', 'P2 (~200 ms)', 'LabelOrientation','horizontal');
xline(300, '--', 'P3 (~300 ms)', 'LabelOrientation','horizontal');
xline(400, '--', 'Late P3 (~400 ms)', 'LabelOrientation','horizontal');
xlabel('Time (ms)'); ylabel('Amplitude (µV)');
title('Average ERP Across Electrodes (train2)');
legend({'Target','Non-Target'}, 'Location','best');
grid on;

%all the same as last time. 
locs_path = 'BCI.locs';
selLocIdx = [1 6 13 11 12 15 16 14];
chanlocs = readlocs(locs_path);
chanlocs = chanlocs(selLocIdx);

times_to_plot = [0 0.1 0.2 0.3 0.4];
figure('Color','w','Name','ERP scalp maps at key time points (train2)');
for i = 1:length(times_to_plot)
    [~, idx] = min(abs(t_epoch - times_to_plot(i)));
    subplot(2,3,i);
    topoplot(ERP_target(:,idx), chanlocs, ...
        'electrodes','on','numcontour',6,'style','map','plotrad',0.5);
    title(sprintf('%.0f ms', times_to_plot(i)*1000));
    colorbar;
end
sgtitle('Target ERP scalp distribution (train2)');

% Organize each of your datasets (train1/2, test1/2) into a data matrix, in which the rows are trials (individual flash events) and the columns are the time-domain features of the ERP from all channels. Each trial should capture approximately 100 ms before to 600 ms after the flash. How many features are there? Write an equation for the number of features based on the start time relative to the flash (tmin), the end time relative to the flash (tmax), the sampling rate (fs), and the number of channels (Nch).
%not really needed I think, but another way to check the features in MATLAB
% Parameters
tmin = -0.1;     
tmax = 0.6;
fs = 256;        
Nch = 8; 

% this should calculate number of features
nPre  = round(abs(tmin) * fs);
nPost = round(tmax * fs);
Ntime = nPre + nPost + 1;
Nfeatures = Nch * Ntime;
%fprint
fprintf('Each trial has %d features (%d samples × %d channels)\n', ...
        Nfeatures, Ntime, Nch);

% Train three models: one using just the train1 data (Model 1), one using just the train2 data (Model 2), and one using both train1 and train2 data (Model 1+2). Test each of these models on just the test1 data, just the test2 data, and both the test1 and test2 data together. Fill in the table below with the accuracy of each model on each test dataset.
% now to Train/Test Linear Classifiers

fs = 256; tmin = -0.1; tmax = 0.6; Nch = 8;
nPre = round(abs(tmin)*fs);
nPost = round(tmax*fs);
Ntime = nPre + nPost + 1;

%here we have a helper function in order to load and then prepare a dataset into feature matrix
function [X, Y] = makeFeatureMatrix(filename, fs, tmin, tmax)
    load(filename);
    t = y(1,:); EEG = y(2:9,:); flash = y(10,:); target = y(11,:);
    %keep = (t >= 70 & t <= 380); again %only if we want to see clean data 
    %t = t(keep); EEG = EEG(:,keep); flash = flash(keep); target = target(keep);

    nPre = round(abs(tmin)*fs);
    nPost = round(tmax*fs);
    flash_shift = [0 flash(1:end-1)];
    onsets = find((flash ~= 0) & (flash_shift == 0));

    trials = {}; labels = [];
    for i = 1:length(onsets)
        idx = onsets(i);
        if idx-nPre<1 || idx+nPost>length(t), continue; end
        seg = EEG(:, idx-nPre:idx+nPost);
        trials{end+1} = seg(:)';             % flatten ch × time
        labels(end+1) = target(idx);
    end
    X = cell2mat(trials');  % trials × features
    Y = labels';            % trials × 1
end

%load all of the datasets. 
[X1,Y1] = makeFeatureMatrix('group-2-data/train1_group2_Tuesday.mat',fs,tmin,tmax);
[X2,Y2] = makeFeatureMatrix('group-2-data/train2_group2_Tuesday.mat',fs,tmin,tmax);
[Xt1,Yt1] = makeFeatureMatrix('group-2-data/test1_group2_Tuesday.mat',fs,tmin,tmax);
[Xt2,Yt2] = makeFeatureMatrix('group-2-data/test2_group2_Tuesday.mat',fs,tmin,tmax);

%actually train all of the models 
Mdl1   = fitclinear(X1,Y1);
Mdl2   = fitclinear(X2,Y2);
Mdl12  = fitclinear([X1;X2],[Y1;Y2]);

%and the predict on the test sets that we have. 
Yp1_t1  = predict(Mdl1,Xt1);   acc1_t1  = mean(Yp1_t1==Yt1);
Yp1_t2  = predict(Mdl1,Xt2);   acc1_t2  = mean(Yp1_t2==Yt2);
Yp1_t12 = predict(Mdl1,[Xt1;Xt2]); acc1_t12 = mean(Yp1_t12==[Yt1;Yt2]);

Yp2_t1  = predict(Mdl2,Xt1);   acc2_t1  = mean(Yp2_t1==Yt1);
Yp2_t2  = predict(Mdl2,Xt2);   acc2_t2  = mean(Yp2_t2==Yt2);
Yp2_t12 = predict(Mdl2,[Xt1;Xt2]); acc2_t12 = mean(Yp2_t12==[Yt1;Yt2]);

Yp12_t1  = predict(Mdl12,Xt1);   acc12_t1  = mean(Yp12_t1==Yt1);
Yp12_t2  = predict(Mdl12,Xt2);   acc12_t2  = mean(Yp12_t2==Yt2);
Yp12_t12 = predict(Mdl12,[Xt1;Xt2]); acc12_t12 = mean(Yp12_t12==[Yt1;Yt2]);

%then finally lets see our results in a table format. 
Accuracies = table(...
    [acc1_t1; acc2_t1; acc12_t1], ...
    [acc1_t2; acc2_t2; acc12_t2], ...
    [acc1_t12; acc2_t12; acc12_t12], ...
    'VariableNames', {'Test_Set_1','Test_Set_2','Test_Set_1plus2'}, ...
    'RowNames', {'Model_1','Model_2','Model_1plus2'})

disp(Accuracies)

% Based on your knowledge of the P300 and the average ERPs you observed
% before, select a new time range captured by each trial. What range did you
% choose, and why? Describe how your results changed after changing the (thiws one_)
% time range. Continue to use your time range for the rest of this section.

fs = 256;
tmin_new = -0.1; %this is the signal that was chosen bnased on all of the data that we had,
tmax_new = 0.8;   %same start, but since delayed, include more of the end of the erp 
Nch = 8;

nPre = round(abs(tmin_new)*fs);
nPost = round(tmax_new*fs);
Ntime = nPre + nPost + 1;

% reuse the same helper to create feature matrices
[X1_new,Y1_new] = makeFeatureMatrix('group-2-data/train1_group2_Tuesday.mat',fs,tmin_new,tmax_new);
[X2_new,Y2_new] = makeFeatureMatrix('group-2-data/train2_group2_Tuesday.mat',fs,tmin_new,tmax_new);
[Xt1_new,Yt1_new] = makeFeatureMatrix('group-2-data/test1_group2_Tuesday.mat',fs,tmin_new,tmax_new);
[Xt2_new,Yt2_new] = makeFeatureMatrix('group-2-data/test2_group2_Tuesday.mat',fs,tmin_new,tmax_new);

%rain the same three models again now using the refined window
Mdl1_new  = fitclinear(X1_new,Y1_new);
Mdl2_new  = fitclinear(X2_new,Y2_new);
Mdl12_new = fitclinear([X1_new;X2_new],[Y1_new;Y2_new]);

% now we should evaluate the accuracy on the test sets
acc1_t1_new  = mean(predict(Mdl1_new,Xt1_new)==Yt1_new);
acc1_t2_new  = mean(predict(Mdl1_new,Xt2_new)==Yt2_new);
acc1_t12_new = mean(predict(Mdl1_new,[Xt1_new;Xt2_new])==[Yt1_new;Yt2_new]);

acc2_t1_new  = mean(predict(Mdl2_new,Xt1_new)==Yt1_new);
acc2_t2_new  = mean(predict(Mdl2_new,Xt2_new)==Yt2_new);
acc2_t12_new = mean(predict(Mdl2_new,[Xt1_new;Xt2_new])==[Yt1_new;Yt2_new]);

acc12_t1_new  = mean(predict(Mdl12_new,Xt1_new)==Yt1_new);
acc12_t2_new  = mean(predict(Mdl12_new,Xt2_new)==Yt2_new);
acc12_t12_new = mean(predict(Mdl12_new,[Xt1_new;Xt2_new])==[Yt1_new;Yt2_new]);

%accuracy table
Accuracies_NewRange = table(...
    [acc1_t1_new; acc2_t1_new; acc12_t1_new], ...
    [acc1_t2_new; acc2_t2_new; acc12_t2_new], ...
    [acc1_t12_new; acc2_t12_new; acc12_t12_new], ...
    'VariableNames', {'Test_Set_1','Test_Set_2','Test_Set_1plus2'}, ...
    'RowNames', {'Model_1','Model_2','Model_1plus2'});

disp(Accuracies_NewRange)

% Analyze Within-Subject Decoding Models
% Use Mdl.Beta to get the weights of your best model. Reshape the weights to a matrix of shape Nch x T, where T is the number of time samples. Square the weights to get the power in the weights. This allows you to average over channels or over time without worrying about whether the weights are positive or negative. Average the squared weights over time, and create a topoplot of the average squared weights at each electrode. How does this compare to the topoplot of the average ERP 300 ms after flash onset? Average the squared weights over electrodes, and plot the average squared weights over time. How does this compare with the corresponding time window of the average ERP plots?
bestModel = Mdl12;   % here is our cross-session model

fs = 256;
tmin = -0.1;
tmax = 0.8;
Nch = 8;

nPre  = round(abs(tmin)*fs);
nPost = round(tmax*fs);
Ntime = nPre + nPost + 1;

W = bestModel.Beta;
Nfeatures = numel(W);
Ntime = Nfeatures / Nch;

%sanity, make sure that we are doing the correct thing. 
if rem(Nfeatures, Nch) ~= 0
    error('Cannot reshape: feature count not divisible by number of channels.');
end

W = reshape(W, Nch, Ntime);


% now we have to compute squared weights or the power 
Wpow = W.^2;

% now we have to take the average across time to ifnd the spectral pattern
Wmean_ch = mean(Wpow, 2);

locs_path = 'BCI.locs';
selLocIdx = [1 6 13 11 12 15 16 14];
chanlocs = readlocs(locs_path);
chanlocs = chanlocs(selLocIdx);

figure('Color','w');
topoplot(Wmean_ch, chanlocs, 'electrodes','on','style','map','numcontour',6);
colorbar;
title('Topoplot of Average Squared Model Weights (Model_{1+2})');

% this is for theaverage across all the elctrodes electrodes for the
% temporal profile 
Wmean_time = mean(Wpow, 1);
t_epoch = linspace(tmin, tmax, size(W,2));

figure('Color','w');
plot(t_epoch*1000, Wmean_time, 'k', 'LineWidth', 1.8);
xlabel('Time (ms)');
ylabel('Average Squared Weight');
title('Temporal Profile of Squared Model Weights');
xline(300, '--r', '300 ms');
grid on;

size(W)
size(X1_new,2)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%PART 2 

% ERP Response to Target and Non-Target Flashes
% Using the complete set of training data from all groups, calculate and plot the grand average ERP, averaged over electrodes, for target and non-target flashes from 100 ms before to 600 ms after each flash. Mark the ERP components visible in the average ERP plots.
%     Plot the scalp map of the signal at 0, 100, 200, and 300 ms 400ms  after the onset of the flash. As before, use topoplot.m and BCI.locs.

fs    = 256;
tmin  = -0.1; %now we are using the new time range that we defined in part 1
tmax  = 0.8; 
Nch   = 8;
nPre  = round(abs(tmin)*fs);
nPost = round(tmax*fs);
t_epoch = (-nPre:nPost) / fs;

% new block that collects allof teh training files: our group and then other groups
files_group  = dir(fullfile('group-2-data','train*.mat'));
files_others = dir(fullfile('other-group-data','train*.mat'));
allFiles = [files_group; files_others];

% here we haev the containers: with dim. channels x time x trials
targetEpochs    = [];
nontargetEpochs = [];

for f = 1:numel(allFiles)
    S = load(fullfile(allFiles(f).folder, allFiles(f).name));
    y = S.y;

    t      = y(1,:);
    EEG    = y(2:9,:);      % Fz Cz P3 Pz P4 PO7 Oz PO8
    flash  = y(10,:);
    target = y(11,:);

    % same cleaning as before
    %keep   = (t >= 70 & t <= 380);
    %t      = t(keep);
    %EEG    = EEG(:,keep);
    %flash  = flash(keep);
    %target = target(keep);

    % flash onsets: 0 -> nonzero
    flash_shift = [0 flash(1:end-1)];
    onsets = find((flash ~= 0) & (flash_shift == 0));

    for i = 1:length(onsets)
        idx = onsets(i);
        if idx-nPre < 1 || idx+nPost > length(t)
            continue
        end
        seg = EEG(:, idx-nPre : idx+nPost);

        if target(idx) == 1
            targetEpochs(:,:,end+1) = seg;
        else
            nontargetEpochs(:,:,end+1) = seg;
        end
    end
end

% so basically the same but now finding the Grand-average ERPs across all of the groups
ERP_target    = mean(targetEpochs, 3); % W Nch x T
ERP_nontarget = mean(nontargetEpochs, 3);  % same

grand_target    = mean(ERP_target,    1); % taking the average over channels
grand_nontarget = mean(ERP_nontarget, 1);

%% grand-average ERP (same thing with targets vs non-targets)
figure('Color','w');
plot(t_epoch*1000, grand_target, 'r', 'LineWidth', 1.8); hold on;
plot(t_epoch*1000, grand_nontarget, 'b', 'LineWidth', 1.8);
xline(0,   '--k');
xline(100, '--', 'N1/P1 (~100 ms)', 'LabelOrientation','horizontal');
xline(200, '--', 'P2/N2 (~200 ms)', 'LabelOrientation','horizontal');
xline(300, '--', 'P3 (~300 ms)',    'LabelOrientation','horizontal');
xline(400, '--', 'Late P3 (~400 ms)','LabelOrientation','horizontal');
yline(0, ':k');
xlabel('Time (ms)');
ylabel('Amplitude (\muV)');
title('Grand-Average ERP Across All Groups (Train1+Train2)');
legend({'Target','Non-Target'}, 'Location','best');
grid on;

%% Scalp maps although including 400ms this time,. 
locs_path  = 'BCI.locs';
selLocIdx  = [1 6 13 11 12 15 16 14];   % Fz Cz P3 Pz P4 PO7 Oz PO8
chanlocs   = readlocs(locs_path);
chanlocs   = chanlocs(selLocIdx);

times_to_plot = [0 0.1 0.2 0.3 0.4];

figure('Color','w','Name','Grand-average Target ERP scalp maps');
for i = 1:length(times_to_plot)
    [~, idx] = min(abs(t_epoch - times_to_plot(i)));
    subplot(2,3,i);
    topoplot(ERP_target(:,idx), chanlocs, ...
        'electrodes','on','style','map','numcontour',6,'plotrad',0.5);
    title(sprintf('%.0f ms', times_to_plot(i)*1000));
    colorbar;
end
sgtitle('Grand-average Target ERP Scalp Distribution (All Groups)');

% Training and Testing Cross-Subject Decoding Models
% Train a new model using both sessions of training data from all groups, except your own. This is referred to as the cross-subject model. Select a time range that is captured by each trial in your data matrix. Did you use the same time range as before? Why or why not?
% Test the cross-subject model on your group’s test data (test1 and test2) and on the test data from all other groups. How does the cross-subject model perform on a held-out subject (your group) compared to test data from subjects included in the training set? Also test your within-subject model on the test data from all other groups. How does the within-subject model perform on many held-out subjects compared to within-subject test data?
fs = 256;
tmin = -0.1;
tmax = 0.6; %using the normal specificed one now since that makes more sense for this in this instance .

%commented out bc there can only be one instance of a funcction in a .m
%file <- previously were 2 seprate things. 
% % Helper function
% function [X, Y] = makeFeatureMatrix(filename, fs, tmin, tmax)
%     load(filename);
%     t = y(1,:); EEG = y(2:9,:); flash = y(10,:); target = y(11,:);
%     %keep = (t >= 70 & t <= 380);
%     %t = t(keep); EEG = EEG(:,keep); flash = flash(keep); target = target(keep);
% 
%     nPre  = round(abs(tmin)*fs);
%     nPost = round(tmax*fs);
%     flash_shift = [0 flash(1:end-1)];
%     onsets = find((flash ~= 0) & (flash_shift == 0));
% 
%     trials = {}; labels = [];
%     for i = 1:length(onsets)
%         idx = onsets(i);
%         if idx-nPre < 1 || idx+nPost > length(t), continue; end
%         seg = EEG(:, idx-nPre:idx+nPost);
%         trials{end+1} = seg(:)'; 
%         labels(end+1) = target(idx);
%     end
%     X = cell2mat(trials'); 
%     Y = labels';
% end

train_files = dir(fullfile('other-group-data','train*.mat'));
train_files = train_files(~contains({train_files.name}, 'group2'));

X_train_all = []; Y_train_all = [];
for f = 1:length(train_files)
    [X_tmp,Y_tmp] = makeFeatureMatrix(fullfile(train_files(f).folder,train_files(f).name),fs,tmin,tmax);
    X_train_all = [X_train_all; X_tmp];
    Y_train_all = [Y_train_all; Y_tmp];
end

%trainig the actual model
CrossSubj_Mdl = fitclinear(X_train_all, Y_train_all);

%preparing the test sets 
[Xt1_self,Yt1_self] = makeFeatureMatrix('group-2-data/test1_group2_Tuesday.mat',fs,tmin,tmax);
[Xt2_self,Yt2_self] = makeFeatureMatrix('group-2-data/test2_group2_Tuesday.mat',fs,tmin,tmax);

test_files = dir(fullfile('other-group-data','test*.mat'));
test_files = test_files(~contains({test_files.name}, 'group2'));
X_test_all = []; Y_test_all = [];
for f = 1:length(test_files)
    [X_tmp,Y_tmp] = makeFeatureMatrix(fullfile(test_files(f).folder,test_files(f).name),fs,tmin,tmax);
    X_test_all = [X_test_all; X_tmp];
    Y_test_all = [Y_test_all; Y_tmp];
end

%evaulate on the test-cross subject model
acc_cross_self   = mean(predict(CrossSubj_Mdl,[Xt1_self;Xt2_self]) == [Yt1_self;Yt2_self]);
acc_cross_others = mean(predict(CrossSubj_Mdl,X_test_all) == Y_test_all);

fprintf('Cross-Subject Model Accuracy (decimal):\n');
fprintf('  Held-out subject (our group): %.4f\n', acc_cross_self);
fprintf('  Subjects included in training: %.4f\n\n', acc_cross_others);

%% and then eval. within-subject model on all of the other groups
acc_within_on_others = mean(predict(Mdl12, X_test_all) == Y_test_all);

fprintf('Within-Subject Model Accuracy (decimal):\n');
fprintf('  On other groups (held-out subjects): %.4f\n', acc_within_on_others);


% Analyze Cross-Subject Decoding Models
% Use the cross-subject model weights to create a topoplot of the average squared weights at each electrode and a plot of the average squared weights over time. How do these plots of your cross-subject model compare to the equivalent plots of your within-subject model?

bestModel = CrossSubj_Mdl;   % the given cross-subject model

fs = 256;
tmin = -0.1;
tmax = 0.6; %same normal
Nch = 8;

nPre  = round(abs(tmin)*fs);
nPost = round(tmax*fs);
Ntime = nPre + nPost + 1;

W = bestModel.Beta;
Nfeatures = numel(W);
Ntime = Nfeatures / Nch;

if rem(Nfeatures, Nch) ~= 0
    error('Cannot reshape: feature count not divisible by number of channels.');
end

W = reshape(W, Nch, Ntime);

Wpow = W.^2;
%same as last instance of the topoplot
Wmean_ch = mean(Wpow, 2);

locs_path = 'BCI.locs';
selLocIdx = [1 6 13 11 12 15 16 14];
chanlocs = readlocs(locs_path);
chanlocs = chanlocs(selLocIdx);

figure('Color','w');
topoplot(Wmean_ch, chanlocs, 'electrodes','on','style','map','numcontour',6);
colorbar;
title('Topoplot of Average Squared Model Weights (Cross-Subject Model)');

% the take the average across all of the electrodes with the temporal
% profile. 
Wmean_time = mean(Wpow, 1);
t_epoch = linspace(tmin, tmax, size(W,2));

figure('Color','w');
plot(t_epoch*1000, Wmean_time, 'k', 'LineWidth', 1.8);
xlabel('Time (ms)');
ylabel('Average Squared Weight');
title('Temporal Profile of Squared Model Weights (Cross-Subject Model)');
xline(300, '--r', '300 ms');
grid on;


