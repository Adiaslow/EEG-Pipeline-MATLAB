eeglab;

addpath ('C:\Users\admin\Desktop\GitHub-Repos\EEG-Pipeline-MATLAB');
cd('C:\Users\admin\Desktop\GitHub-Repos\EEG-Pipeline-MATLAB');

filePath = 'C:\Users\admin\Desktop\GitHub-Repos\EEG-Pipeline-MATLAB';
% go to folder where data file is, hold shift, right click, click "Copy as
% path", paste it after the '=' and replace the (")s with (')s
fileName = 'MUAD06022021EOFull2';
fileType = '.xdf';
fullPath = strcat(filePath, filesep, fileName, fileType);
mkdir figures;

disp('*********************************************************************')
disp('Loading Data')
disp('*********************************************************************')

% load data
if strcmp(fileType, '.set')
    EEG = pop_loadset(fullPath);
elseif strcmp(fileType, '.xdf')
    EEG = pop_loadxdf(fullPath);
elseif strcmp(fileType, '.edf')
    EEG = pop_biosig(fullPath);
end

disp('*********************************************************************')
disp('Setting Channel Locations')
disp('*********************************************************************')

% set channel locations
EEG = pop_chanedit(EEG, 'lookup','C:\\eeglab2021.1\\plugins\\dipfit4.3\\standard_BEM\\elec\\standard_1005.elc', ...
                   'changefield',{1 'labels' 'FP1'},'changefield',{2 'labels' 'FP2'},'changefield',{3 'labels' 'F3'}, ...
                   'changefield',{4 'labels' 'F4'},'changefield',{5 'labels' 'C3'},'changefield',{6 'labels' 'C4'}, ...
                   'changefield',{7 'labels' 'P3'},'changefield',{8 'labels' 'P4'},'changefield',{9 'labels' 'O1'}, ...
                   'changefield',{10 'labels' 'O2'},'changefield',{11 'labels' 'F7'},'changefield',{12 'labels' 'F8'}, ...
                   'changefield',{13 'labels' 'T3'},'changefield',{14 'labels' 'T4'},'changefield',{15 'labels' 'T5'}, ...
                   'changefield',{16 'labels' 'T6'},'changefield',{17 'labels' 'Fz'},'changefield',{18 'labels' 'Cz'}, ...
                   'changefield',{19 'labels' 'Pz'});
EEG = eeg_checkset( EEG );
EEG = pop_chanedit(EEG, 'lookup','C:\\eeglab2021.1\\plugins\\dipfit4.3\\standard_BEM\\elec\\standard_1005.elc');
EEG = eeg_checkset( EEG );

eeglab redraw;

disp('*********************************************************************')
disp('Removing DC Offset')
disp('*********************************************************************')

% remove DC offset
freqHP = 0.5;
freqLP = 70;
sRate = 256;
filtOrder = 5 * fix(sRate/freqHP)
EEG = pop_eegfiltnew( EEG, 'locutoff',  freqHP, 'hicutoff', freqLP, 'filtorder', filtOrder, 'plotfreqz', 0);


originalEEG = EEG;

eeglab redraw;

disp('*********************************************************************')
disp('Cleaning Data')
disp('*********************************************************************')

% clean data
% remove artifacts
EEG = clean_rawdata(EEG, -1, -1, -1, -1, 5, 0.25);
% EEG = clean_rawdata(EEG, arg_flatline, arg_highpass, arg_channel, arg_noisy, arg_burst, arg_window)
vis_artifacts(EEG, originalEEG);
saveas(gcf, 'figures\first_pass_artifacting.png', 'png');

eeglab redraw;

disp('*********************************************************************')
disp('Setting Average Reference')
disp('*********************************************************************')

% set average reference
EEG.nbchan = EEG.nbchan+1;
EEG.data(end+1,:) = zeros(1, EEG.pnts);
EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
EEG = pop_reref(EEG, []);
EEG = pop_select( EEG,'nochannel',{'initialReference'});
disp(['Number of channels = ', EEG.nbchan])
EEGset = pop_saveset(EEG,[filePath, filesep, fileName, '.set']);

eeglab redraw;

disp('*********************************************************************')
disp('Running AMICA')
disp('*********************************************************************')

% run AMICA

setName = [fileName, '.set'];
EEG = pop_loadset(setName);

    % define parameters
    numprocs = 1;       % # of nodes (default = 1)
    max_threads = 1;    % # of threads per node
    num_models = 1;     % # of models of mixture ICA
    max_iter = 2000;    % max number of learning steps

    % run amica
    outdir = [ pwd filesep 'amicaouttmp' filesep ];
    [weights,sphere,mods] = runamica15(EEG.data, 'outdir',outdir);
                               % save the data and fill datfile field in EEG

EEG = pop_saveset(EEG,[pwd '/mydata.set']);

%{
% run amica with blocksize optimization and rejection
outdir = [ filePath, filesep, 'amicaout', filesep ];
numChans = EEG.nbchan;
arglist = {'outdir', outdir, 'num_chans',  numChans, 'pcakeep', numChans, 'max_threads', 2};
[weights, sphere, mods] = runamica15(EEG.data(:,:), arglist{:});
EEG.icaweights = W; EEG.icasphere = S(1:size(W,1),:);
EEG.icawinv = mods.A(:,:,1); EEG.mods = mods;

% load the amica results into EEG

EEG = eeg_loadamica(EEG,'.\amicaout');
%}
