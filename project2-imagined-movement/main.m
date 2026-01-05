%% main.m
%okay, this is the single run script that will produce all of the plots
%that are visible in the report.pdf file for project 2. This was originally
%adopted from a MATLAB livescript, which may explain the ordering of
%certain code blocks. 

%some changes that were made in the .m file:
%the script will only clear clc clear all once at the top of the script. 
%should handle the EEGLAB import appropriately
%preserves all of the variable dependancies, such as 'Fcsp_L/Fcsp_R' that
%were produced before the LDA blocks in the previous .mlx file.
% all of the local functions are now at the bottom of the script as opossed
% to being interspersed. 


clear; close all; clc; %once 

%% 
%This is the raw eeg overlay with the DC removed, only included to catch any significant artifacts in the raw waveform. 
%first 15s removed. (using one figure per file)
files = {
    'MotorImageryCSP_Data_Run1.mat'
    'MotorImageryCSP_Data_Run1_Day2.mat'
    'MotorImageryCSP_Data_Run2.mat'
    'MotorImageryCSP_Data_Run2_Day2.mat'
    'MotorImageryCSP_Data_Run3.mat'
    'MotorImageryCSP_Data_Run3_Day2.mat'
    'MotorImageryCSP_Data_Run4.mat'
    'MotorImageryCSP_Data_Run4_Day2.mat'
};

electrodes = {'Fz','FC2','FC1','FC6','FC5','Cz','CP1','CP2','CP5','CP6',...
              'Pz','P4','P3','PO8','PO7','Oz'};

eeg_idx = 2:17;% this is only the EEG channels
remove_T = 15;% variable that controlls how many seconds to remove from the start

for i = 1:numel(files)
    S  = load(files{i});
    Y  = double(S.y(eeg_idx,:));
    fs = double(S.SR);

    % this line is going to remove any of the DC offset in the channels
    Y = Y - mean(Y,2);

    %remove the first 15 seconds
    start_idx = round(remove_T * fs) + 1;
    Y = Y(:, start_idx:end);

    t = (0:size(Y,2)-1) / fs;

    figure('Color','w','Name',files{i});
    plot(t, Y', 'LineWidth', 0.5);%overlay all electrodes, no DC offset. 
    grid on;
    xlabel('Time (s)');
    ylabel('Amplitude');
    title([strrep(files{i},'_','\_') '  (first 15 s removed)']);
    legend(electrodes, 'Location','eastoutside');
end


%% This second section is going to be counting all of the trials per file using trigger rising edges. 

trigger_ch = 18;
remove_T_count = 0; % will keep 0, should keep zero, since the experimental conditions account for the startup artifacts

fprintf('\nTrial counts (using the trigger rising edges):\n');

for i = 1:numel(files)
    S  = load(files{i});
    Y  = double(S.y);
    fs = double(S.SR);

    trig = Y(trigger_ch,:);

    % if you want to
    start_idx = round(remove_T_count*fs) + 1;
    trig2 = trig(start_idx:end);

    % and this is the code corresponding to the rising edge detection:
    thr = (min(trig2) + max(trig2))/2;
    trig_bin = trig2 > thr;

    rising_idx = find(diff(trig_bin) == 1) + 1;
    rising_times = (rising_idx - 1) / fs; % the seconds following the start_idx

    % since the cue onset is at 2s into the trial, 
    %trial onset is 2s before the rising edge
    trial_onsets = rising_times - 2;

    % lets keep only the plausible trials (still comes out to 40 per)
    trial_onsets = trial_onsets(trial_onsets >= 0);

    fprintf('%-35s  %3d trials\n', files{i}, numel(trial_onsets));

end


%% The third section is the CSP (using the eig(A,B)) with a clear reporting and a quantitative summary
run_files = {
    'MotorImageryCSP_Data_Run1.mat'
    'MotorImageryCSP_Data_Run1_Day2.mat'
    'MotorImageryCSP_Data_Run2.mat'
    'MotorImageryCSP_Data_Run2_Day2.mat'
    'MotorImageryCSP_Data_Run3.mat'
    'MotorImageryCSP_Data_Run3_Day2.mat'
    'MotorImageryCSP_Data_Run4.mat'
    'MotorImageryCSP_Data_Run4_Day2.mat'
};

%% the cue files are the same for both of the recording days 
cue_files = {
    'Homework/classrun1.mat'
    'Homework/classrun2.mat'
    'Homework/classrun3.mat'
    'Homework/classrun4.mat'
};

%% some parameters
eeg_idx = 2:17; % our 16 EEG channels
trig_ch = 18;% the trigger channel count
fs = 256;
cue_time = 2.0;% the trigger marks the cue at the 2s makr
twin = [4.5 8.0];% the imagery window were using
bp = [8 30];%and the band for the CSP extraction
[b,a] = butter(4,bp/(fs/2),'bandpass'); %extra

X_left  = {};
X_right = {};

%% collect the trials 
for f = 1:numel(run_files)

    S = load(run_files{f});
    Y = double(S.y);

    run_id = mod(f-1,4) + 1;  %repeats for Day2
    C = load(cue_files{run_id});
    z = C.(sprintf('z%d',run_id));
    z = z(1,:);

    trig = Y(trig_ch,:);
    thr = (min(trig) + max(trig))/2;
    trig_bin = trig > thr;
    rising_idx = find(diff(trig_bin)==1) + 1;
    cue_times = (rising_idx-1)/fs;
    trial_onsets = cue_times - cue_time;

    nTrials = min(numel(trial_onsets), numel(z));

    for j = 1:nTrials
        t0 = trial_onsets(j);
        i1 = round((t0 + twin(1))*fs);
        i2 = round((t0 + twin(2))*fs);

        if i1 < 1 || i2 > size(Y,2) || i2 <= i1
            continue;
        end

        X = Y(eeg_idx,i1:i2);
        X = X - mean(X,2); % remove the DC withinthe  window
        X = filtfilt(b,a,X')';% the bandpass filter 

        if z(j) == 1
            X_left{end+1} = X;
        else
            X_right{end+1} = X;
        end
    end
end

fprintf('Trials used: LEFT=%d, RIGHT=%d\n', numel(X_left), numel(X_right));

if isempty(X_left) || isempty(X_right)
    error('No trials collected thats unfortunate.');
end

%% here are the covariance matrices A (the feft) and B (the right)
nCh = numel(eeg_idx);
A = zeros(nCh);
B = zeros(nCh);

for k = 1:numel(X_left)
    Ck = X_left{k}*X_left{k}';
    A = A + Ck/trace(Ck);
end
A = A/numel(X_left);

for k = 1:numel(X_right)
    Ck = X_right{k}*X_right{k}';
    B = B + Ck/trace(Ck);
end
B = B/numel(X_right);

%% this is the CSP using the eig(A,B) ( --> ascending eigen)
[V,D] = eig(A,B);
lambda = diag(D);

idx_low  = 1:3;
idx_high = (length(lambda)-2):length(lambda);
idx_all  = [idx_low idx_high];
W = V(:, idx_all);

%% and then this will just make sure to print the lowest and highest eigenvalues clearly
fprintf('\nCSP eigenvalues (eig(A,B)) are ascending.\n');
fprintf('Lowest 3 eigenvalues:\n');
for k = 1:3
    fprintf('  LOW %d: idx=%d, lambda=%.6g\n', k, idx_low(k), lambda(idx_low(k)));
end
fprintf('Highest 3 eigenvalues:\n');
for k = 1:3
    fprintf('  HIGH %d: idx=%d, lambda=%.6g\n', k, idx_high(k), lambda(idx_high(k)));
end

%% this block is going to be projectting the trials into the CSP space
T = size(X_left{1},2);
t = linspace(twin(1), twin(2), T);

ZL = zeros(6,T,numel(X_left));
ZR = zeros(6,T,numel(X_right));

for k = 1:numel(X_left)
    ZL(:,:,k) = W' * X_left{k};
end
for k = 1:numel(X_right)
    ZR(:,:,k) = W' * X_right{k};
end

avgL = mean(ZL,3);
avgR = mean(ZR,3);

%% quant. summary that aligns to the plots
metrics = zeros(6,2);
for c = 1:6
    d = avgL(c,:) - avgR(c,:);
    metrics(c,1) = sqrt(mean(d.^2));% the RMS diff
    metrics(c,2) = mean(abs(d)); %mean absolute difference
end

fprintf('\nQuantitative separation:\n');
fprintf('Component   Type   eig_idx   lambda       RMSdiff     MeanAbsDiff\n');
fprintf('------------------------------------------------------------------\n');

comp_labels = strings(1,6);
for c = 1:6
    if c <= 3
        type = "LOW ";
        eig_i = idx_low(c);
        lab = sprintf('LOW%d', c);
    else
        type = "HIGH";
        eig_i = idx_high(c-3);
        lab = sprintf('HIGH%d', c-3);
    end
    comp_labels(c) = lab;
    fprintf('%-9s  %-4s   %-6d  %-10.6g  %-10.6g  %-10.6g\n', ...
        lab, type, eig_i, lambda(eig_i), metrics(c,1), metrics(c,2));
end

%% just make the plots larger plots and with clear labeling of the low vs high
figure('Color','w','Position',[100 80 1200 900]);
tiledlayout(3,2,'TileSpacing','compact','Padding','compact');

for c = 1:6
    nexttile;
    plot(t, avgL(c,:), 'LineWidth', 1.6); hold on;
    plot(t, avgR(c,:), 'LineWidth', 1.6);
    grid on;

    xlabel('Time (in s) from trial onset');
    ylabel('Projected amplitude');

    if c <= 3
        eig_i = idx_low(c);
        ttl = sprintf('CSP %s (eig idx=%d, \\lambda=%.3g)', comp_labels(c), eig_i, lambda(eig_i));
    else
        eig_i = idx_high(c-3);
        ttl = sprintf('CSP %s (eig idx=%d, \\lambda=%.3g)', comp_labels(c), eig_i, lambda(eig_i));
    end
    title(ttl);

    legend({'Left','Right'}, 'Location','best');
end

sgtitle('Average CSP-Projected Responses (First 3 LOW and Last 3 HIGH eigenvectors from eig(A,B))');


%% this is for the topoplot + separability before and after the CSP (also recomputes trials and the csp inside the section)
%%    (will be producing the Fcsp_L and Fcsp_R that is going to be used by the next LDA classification block)

% EEGLAB path, has to be added, will produce errors, will be fine. 
addpath('/Users/alexanderspeer/Desktop/BCI lab/eeglab14_1_2b');
eeglab;  %will initilize the topoplot/readlocs

% Electrode labels correspond to BCI.locs
electrodes = {'Fz','FC2','FC1','FC6','FC5','Cz','CP1','CP2','CP5','CP6',...
              'Pz','P4','P3','PO8','PO7','Oz'};

eeg_idx   = 2:17; 
trig_ch   = 18;  
fs        = 256;
cue_time  = 2.0; 
twin      = [4.5 8.0];
bp        = [8 30];%bpf for csp
[b,a]     = butter(4, bp/(fs/2), 'bandpass');

%% find right locs path 
locs_path = 'BCI.locs';
chanlocs_full = readlocs(locs_path);
loc_labels = {chanlocs_full.labels};
[tf, selLocIdx] = ismember(electrodes, loc_labels);
if any(~tf)
    missing = electrodes(~tf);
    error('you have to try again bro - no electrodesfound in %s: %s', locs_path, strjoin(missing, ', '));
end
chanlocs = chanlocs_full(selLocIdx);

%%collect the trials for the left and right
X_left  = {};
X_right = {};

for f = 1:numel(run_files)
    S = load(run_files{f});
    Y = double(S.y);

    run_id = mod(f-1,4) + 1;
    C = load(cue_files{run_id});
    z = C.(sprintf('z%d',run_id));
    z = z(1,:);

    trig = Y(trig_ch,:);
    thr = (min(trig) + max(trig))/2;
    trig_bin = trig > thr;
    rising_idx = find(diff(trig_bin)==1) + 1;

    cue_times = (rising_idx-1)/fs;
    trial_onsets = cue_times - cue_time;

    nTrials = min(numel(trial_onsets), numel(z));

    for j = 1:nTrials
        t0 = trial_onsets(j);

        i1 = round((t0 + twin(1))*fs);
        i2 = round((t0 + twin(2))*fs);

        if i1 < 1 || i2 > size(Y,2) || i2 <= i1
            continue;
        end

        X = Y(eeg_idx, i1:i2);
        X = X - mean(X,2);
        X = filtfilt(b,a, X')';

        if z(j) == 1
            X_left{end+1} = X;
        else
            X_right{end+1} = X;
        end
    end
end
%sanity check
fprintf('Trials used: LEFT=%d, RIGHT=%d\n', numel(X_left), numel(X_right));

%% this block is for the CSP: will attampet to build A (Left), B (Right), and then the eig(A,B)
nCh = numel(eeg_idx);
A = zeros(nCh); B = zeros(nCh);

for k = 1:numel(X_left)
    Ck = X_left{k}*X_left{k}';
    A = A + Ck/trace(Ck);
end
A = A/max(1,numel(X_left));

for k = 1:numel(X_right)
    Ck = X_right{k}*X_right{k}';
    B = B + Ck/trace(Ck);
end
B = B/max(1,numel(X_right));

[V,D] = eig(A,B);
lambda = diag(D);          % ascending

idx_low  = 1:3;
idx_high = (length(lambda)-2):length(lambda);
idx_all  = [idx_low idx_high];

W = V(:, idx_all);         % 16 x 6 CSP filters

fprintf('\nSelected the eigenvalues (ascending eig(A,B)):\n');
for k = 1:3
    fprintf('  LOW%d  idx=%d  lambda=%.6g\n', k, idx_low(k),  lambda(idx_low(k)));
end
for k = 1:3
    fprintf('  HIGH%d idx=%d  lambda=%.6g\n', k, idx_high(k), lambda(idx_high(k)));
end

%% this is going to correspond to the STD that removes the time dimension
nL = numel(X_left);
nR = numel(X_right);

Fraw_L = zeros(nL, nCh);
Fraw_R = zeros(nR, nCh);

Fcsp_L = zeros(nL, 6);
Fcsp_R = zeros(nR, 6);

for k = 1:nL
    X = X_left{k};% 16 x T
    Fraw_L(k,:) = std(X, 0, 2)'; % 1 x 16

    Z = W' * X; % 6 x T
    Fcsp_L(k,:) = std(Z, 0, 2)';% 1 x 6
end

for k = 1:nR
    X = X_right{k};
    Fraw_R(k,:) = std(X, 0, 2)';

    Z = W' * X;
    Fcsp_R(k,:) = std(Z, 0, 2)';
end

Xraw = [Fraw_L; Fraw_R];
Xcsp = [Fcsp_L; Fcsp_R];
y    = [ones(nL,1); -ones(nR,1)]; %+1 for the right -1 for the left 

%% this is for the 1D separability through the LDA projection (also this is before and after the CSP). 
muL_raw = mean(Fraw_L,1)'; muR_raw = mean(Fraw_R,1)';
Sw_raw = cov(Fraw_L) + cov(Fraw_R);
w_raw = Sw_raw \ (muL_raw - muR_raw);
proj_raw_L = Fraw_L * w_raw;
proj_raw_R = Fraw_R * w_raw;

muL_csp = mean(Fcsp_L,1)'; muR_csp = mean(Fcsp_R,1)';
Sw_csp = cov(Fcsp_L) + cov(Fcsp_R);
w_csp = Sw_csp \ (muL_csp - muR_csp);
proj_csp_L = Fcsp_L * w_csp;
proj_csp_R = Fcsp_R * w_csp;

sep_raw = (mean(proj_raw_L) - mean(proj_raw_R))^2 / (var(proj_raw_L) + var(proj_raw_R));
sep_csp = (mean(proj_csp_L) - mean(proj_csp_R))^2 / (var(proj_csp_L) + var(proj_csp_R));

fprintf('\nSeparability summary using 1D LDA projection of STD-features:\n');
fprintf('  Before the CSP (electrode-STD, 16D -> 1D): FisherSep = %.6g\n', sep_raw);
fprintf('  After the CSP (CSP-STD,       6D  -> 1D): FisherSep = %.6g\n', sep_csp);

%% this is our PLOTS: the distributions before and after the CSP
figure('Color','w','Position',[100 100 1200 450]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

nexttile;
histogram(proj_raw_L, 30); hold on;
histogram(proj_raw_R, 30);
grid on; title('Before CSP: STD per electrode into the LDA projection');
xlabel('1D LDA score'); ylabel('Count');
legend({'Left','Right'}, 'Location','best');

nexttile;
histogram(proj_csp_L, 30); hold on;
histogram(proj_csp_R, 30);
grid on; title('After CSP: STD per CSP component into the LDA projection');
xlabel('1D LDA score'); ylabel('Count');
legend({'Left','Right'}, 'Location','best');

%% this will plot the CSP filters on the scalp. 
labels = {'LOW1','LOW2','LOW3','HIGH1','HIGH2','HIGH3'};

figure('Color','w','Position',[100 80 1200 800]);
tiledlayout(2,3,'TileSpacing','compact','Padding','compact');

mx = max(abs(W(:)));

for c = 1:6
    nexttile;
    topoplot(W(:,c), chanlocs, 'electrodes','on', 'numcontour', 6, 'style','map');
    title(sprintf('%s (eig idx %d, lambda %.4g)', labels{c}, idx_all(c), lambda(idx_all(c))));
    caxis([-mx mx]);
    colorbar;
end

sgtitle('CSP spatial filters (columns of W the spatial filter matrix) shown on scalp');

%% this chuck is for the CSP and the LDA classification using the stratified 90/10 splits for (DAY1, DAY2, and ALL)
%will not mess anything up, since the training and testing data is
%recomputed for each of the conditions. 

day1_files = {
    'MotorImageryCSP_Data_Run1.mat'
    'MotorImageryCSP_Data_Run2.mat'
    'MotorImageryCSP_Data_Run3.mat'
    'MotorImageryCSP_Data_Run4.mat'
};

day2_files = {
    'MotorImageryCSP_Data_Run1_Day2.mat'
    'MotorImageryCSP_Data_Run2_Day2.mat'
    'MotorImageryCSP_Data_Run3_Day2.mat'
    'MotorImageryCSP_Data_Run4_Day2.mat'
};

cue_files = {
    'Homework/classrun1.mat'
    'Homework/classrun2.mat'
    'Homework/classrun3.mat'
    'Homework/classrun4.mat'
};

eeg_idx   = 2:17;
trig_ch   = 18;
fs        = 256;
cue_time  = 2.0;
twin      = [4.5 8.0];
bp        = [8 30];
[b,a]     = butter(4, bp/(fs/2), 'bandpass');

nTests = 10;
testFrac = 0.10;
rng(0);

results_day1 = run_eval(day1_files, cue_files, eeg_idx, trig_ch, fs, cue_time, twin, b, a, nTests, testFrac, "DAY 1");
results_day2 = run_eval(day2_files, cue_files, eeg_idx, trig_ch, fs, cue_time, twin, b, a, nTests, testFrac, "DAY 2");
results_all  = run_eval([day1_files; day2_files], cue_files, eeg_idx, trig_ch, fs, cue_time, twin, b, a, nTests, testFrac, "ALL DATA");

print_summary(results_day1);
print_summary(results_day2);
print_summary(results_all);


%% here are the loca F(X)S functions (since they have to be at the end of the main.m file)

function out = run_eval(run_files, cue_files, eeg_idx, trig_ch, fs, cue_time, twin, b, a, nTests, testFrac, label)
    [X_left, X_right] = collect_trials(run_files, cue_files, eeg_idx, trig_ch, fs, cue_time, twin, b, a);

    nL = numel(X_left);
    nR = numel(X_right);
    if nL < 10 || nR < 10
        error('%s: Not enough trials after the segmentation (LEFT=%d, RIGHT=%d).', label, nL, nR);
    end

    nTestL = max(1, round(testFrac * nL));
    nTestR = max(1, round(testFrac * nR));

    acc = zeros(nTests,1);

    for t = 1:nTests
        idxL = randperm(nL);
        idxR = randperm(nR);

        teL = idxL(1:nTestL);  trL = idxL(nTestL+1:end);
        teR = idxR(1:nTestR);  trR = idxR(nTestR+1:end);

        XtrL = X_left(trL);
        XtrR = X_right(trR);

        [W, lambda, idx_all] = compute_csp_from_trials(XtrL, XtrR); %#ok<ASGLU>

        Ftr = [features_std_proj(XtrL, W); features_std_proj(XtrR, W)];
        ytr = [ones(numel(XtrL),1); -ones(numel(XtrR),1)];

        XteL = X_left(teL);
        XteR = X_right(teR);
        Fte = [features_std_proj(XteL, W); features_std_proj(XteR, W)];
        yte = [ones(numel(XteL),1); -ones(numel(XteR),1)];

        yhat = lda_predict(Ftr, ytr, Fte);

        acc(t) = mean(yhat == yte);
    end

    out.label = label;
    out.nLeft = nL;
    out.nRight = nR;
    out.acc_pct = 100*acc;
    out.mean_acc = mean(out.acc_pct);
    out.std_acc  = std(out.acc_pct);
    out.SE       = out.std_acc / sqrt(nTests);
end

function [X_left, X_right] = collect_trials(run_files, cue_files, eeg_idx, trig_ch, fs, cue_time, twin, b, a)
    X_left  = {};
    X_right = {};

    for r = 1:numel(run_files)
        S = load(run_files{r});
        Y = double(S.y);

        run_id = mod(r-1,4) + 1; % 1..4
        C = load(cue_files{run_id});
        z = C.(sprintf('z%d',run_id));
        z = z(1,:);

        trig = Y(trig_ch,:);
        thr = (min(trig) + max(trig))/2;
        trig_bin = trig > thr;
        rising_idx = find(diff(trig_bin)==1) + 1;

        cue_times = (rising_idx-1)/fs;
        trial_onsets = cue_times - cue_time;

        nTrials = min(numel(trial_onsets), numel(z));

        for j = 1:nTrials
            t0 = trial_onsets(j);
            i1 = round((t0 + twin(1))*fs);
            i2 = round((t0 + twin(2))*fs);

            if i1 < 1 || i2 > size(Y,2) || i2 <= i1
                continue;
            end

            X = Y(eeg_idx, i1:i2);
            X = X - mean(X,2);
            X = filtfilt(b,a, X')';

            if z(j) == 1
                X_left{end+1} = X;
            else
                X_right{end+1} = X;
            end
        end
    end
end

function [W, lambda, idx_all] = compute_csp_from_trials(X_left, X_right)
    nCh = size(X_left{1},1);

    A = zeros(nCh); B = zeros(nCh);

    for k = 1:numel(X_left)
        X = X_left{k};
        C = X*X';
        A = A + C/trace(C);
    end
    A = A/max(1,numel(X_left));

    for k = 1:numel(X_right)
        X = X_right{k};
        C = X*X';
        B = B + C/trace(C);
    end
    B = B/max(1,numel(X_right));

    [V,D] = eig(A,B);
    lambda = diag(D);

    idx_low  = 1:3;
    idx_high = (length(lambda)-2):length(lambda);
    idx_all  = [idx_low idx_high];

    W = V(:, idx_all);
end

function F = features_std_proj(Xcell, W)
    nT = numel(Xcell);
    F = zeros(nT, size(W,2));

    for k = 1:nT
        Z = W' * Xcell{k};
        F(k,:) = std(Z,0,2)';
    end
end

function yhat = lda_predict(Xtr, ytr, Xte)
    muL = mean(Xtr(ytr==1,:),1)';
    muR = mean(Xtr(ytr==-1,:),1)';

    SL = cov(Xtr(ytr==1,:));
    SR = cov(Xtr(ytr==-1,:));
    Sw = SL + SR;

    eps = 1e-6;
    Sw = Sw + eps*eye(size(Sw));

    w = Sw \ (muL - muR);
    b = -0.5 * w' * (muL + muR);

    scores = Xte*w + b;
    yhat = sign(scores);
    yhat(yhat==0) = 1;
end

function print_summary(out)
    fprintf('\n%s: LDA in CSP space (10 stratified 90/10 splits)\n', out.label);
    fprintf('Trials: LEFT=%d, RIGHT=%d\n', out.nLeft, out.nRight);
    fprintf('Accuracies (%%):\n');
    disp(out.acc_pct');
    fprintf('Mean accuracy: %.2f %%\n', out.mean_acc);
    fprintf('Std deviation: %.2f %%\n', out.std_acc);
    fprintf('Standard error: %.2f %% (SD/sqrt(10))\n', out.SE);
end
