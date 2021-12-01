eeglab

filePath = "C:\Users\admin\Desktop\GitHub Repos\EEG-Pipeline-MATLAB"; % go to folder where data file is, hold shift, right click, click "Copy as path", paste it after the '='
fileName = 'MUAD06022021EOFull';
fileType = '.xdf';
fullPath = strcat(filePath, "\", fileName, fileType);
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
EEG = pop_chanedit(EEG, 'lookup','C:\\eeglab2021.1\\plugins\\dipfit4.3\\standard_BEM\\elec\\standard_1005.elc','changefield',{1 'labels' 'FP1'},'changefield',{2 'labels' 'FP2'},'changefield',{3 'labels' 'F3'},'changefield',{4 'labels' 'F4'},'changefield',{5 'labels' 'C3'},'changefield',{6 'labels' 'C4'},'changefield',{7 'labels' 'P3'},'changefield',{8 'labels' 'P4'},'changefield',{9 'labels' 'O1'},'changefield',{10 'labels' 'O2'},'changefield',{11 'labels' 'F7'},'changefield',{12 'labels' 'F8'},'changefield',{13 'labels' 'T3'},'changefield',{14 'labels' 'T4'},'changefield',{15 'labels' 'T5'},'changefield',{16 'labels' 'T6'},'changefield',{17 'labels' 'Fz'},'changefield',{18 'labels' 'Cz'},'changefield',{19 'labels' 'Pz'});
EEG = eeg_checkset( EEG );
EEG = pop_chanedit(EEG, 'lookup','C:\\eeglab2021.1\\plugins\\dipfit4.3\\standard_BEM\\elec\\standard_1005.elc');
EEG = eeg_checkset( EEG );

originalEEG = EEG;

%{
% remove DC offset
removeDC = true;
freqHP = 0.5;
freqLP = 10;
sRate = EEG.srate();
filtOrder = 3*fix(sRate/freqHP);

if removeDC == true
    EEG = pop_eegfiltnew( EEG, 'locutoff',  freqHP, 'hicutoff', freqLP, 'filtorder', filtOrder);
end
%}

cleanEEG = clean_rawdata(EEG, -1, [0.25 0.75], -1, -1, 5, 0.25);
 cleaned1 = vis_artifacts(cleanEEG,EEG);
 saveas(gcf, 'figures\firstPassArtifacting.png', 'png');
    
% set average reference
EEG.nbchan = EEG.nbchan+1;
EEG.data(end+1,:) = zeros(1, EEG.pnts);
EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
EEG = pop_reref(EEG, []);
EEG = pop_select( EEG,'nochannel',{'initialReference'});

% rawHPAveRef = pop_eegplot(EEG);

% run ICA
EEG = pop_runica(EEG);
