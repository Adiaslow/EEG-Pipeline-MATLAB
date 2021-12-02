eeglab

filePath = "C:\Users\admin\Desktop\GitHub Repos\EEG-Pipeline-MATLAB";
% go to folder where data file is, hold shift, right click, click "Copy as path", paste it after the '='
fileName = 'MUAD06022021EOFull2';
fileType = '.xdf';
fullPath = strcat(filePath, filesep, fileName, fileType);
mkdir figures

% load data
if strcmp(fileType, '.set')
    EEG = pop_loadset(fullPath)
elseif strcmp(fileType, '.xdf')
    EEG = pop_loadxdf(fullPath)
elseif strcmp(fileType, '.edf')
    EEG = pop_biosig(fullPath)
end

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

originalEEG = EEG;

% set average reference
EEG.nbchan = EEG.nbchan+1;
EEG.data(end+1,:) = zeros(1, EEG.pnts);
EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
EEG = pop_reref(EEG, []);
EEG = pop_select( EEG,'nochannel',{'initialReference'});

% clean data
% remove artifacts
EEG = clean_rawdata(EEG, 'off', [0.25 0.75], 'off', 'off', 5, 1);
vis_artifacts(EEG, originalEEG);
saveas(gcf, 'figures\first_pass_artifacting.png', 'png');

%{
% remove line noise
signal = struct('data', EEG.data, 'srate', EEG.srate);
lineNoiseIn = struct('lineNoiseMethod', 'clean', 'lineNoiseChannels', 1:EEG.nbchan, 'Fs', EEG.srate, ...
                     'lineFrequencies', [60 120 180 240], 'p', 0.01, 'fScanBandWidth', 2, 'taperBandWidth', 2, ...
                     'taperWindowSize', 4, 'taperWindowStep', 1, 'tau', 100, 'pad', 2, 'fPassBand', [0 EEG.srate/2], ...
                     'maximumIterations', 10);
                 
[clnOutput, lineNoiseOut] = cleanLineNoise(signal, lineNoiseIn);
EEG.data = clnOutput.data;
    
    
vis_artifacts(EEG, EEG2);
saveas(gcf, 'figures\remove_linenoise.png', 'png');
%}

% run AMICA
numprocs = 1;
max_threads = 1;
num_models = 1;
max_iter = 100;

outdir = [ filePath, 'amicaouttmp' filesep ];

[weights,sphere,mods] = runamica15(EEG.data, 'num_models',num_models, 'outdir',outdir, 'numprocs', numprocs, ...
                                   'max_threads', max_threads, 'max_iter',max_iter);

