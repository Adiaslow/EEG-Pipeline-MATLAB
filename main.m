% EEG Preprocessing Pipeline
% by Adam Murray
% 11/2021 - Present

% Inspiration from Nick, Makoto Miyakoshi,

% This script is an automated pipeline for preprocessing EEG data
% Steps: Load Data, Set Channel Locations, Remove DC Offset, Clean Data,
% Set Average Reference, Run AMICA, Fit Dipoles to ICs, Visualize Data

%% Main Function
function main ()

%% Set Paths and Create Directories
function [ FILE_PATH, FILE_NAME, FILE_TYPE, FILE_FULL ] = setPatsAndDirs()
    
    tic
    fprintf( '\n' )
    disp( '*************************************************************' )
    disp( '*               Setting Paths and Directories               *' )
    disp( '*************************************************************' )
    fprintf( '\n ')
    
    addpath( 'C:\Users\admin\Desktop\GitHub-Repos\EEG-Pipeline-MATLAB' );
    cd( 'C:\Users\admin\Desktop\GitHub-Repos\EEG-Pipeline-MATLAB' );

    % go to folder where data file is, hold shift, right click, click 
    % "Copy as path", paste it after the '=' and replace the (")s with (')s
    FILE_PATH = ( 'C:\Users\admin\Desktop\GitHub-Repos\EEG-Pipeline-MATLAB' );
    FILE_NAME = ( 'MUAD06022021EOFull2' );
    FILE_TYPE =  ( '.xdf' );
    FILE_FULL = strcat( FILE_PATH, filesep, FILE_NAME, FILE_TYPE );
    
    if ( exist( 'figures', 'dir' ) == 0 )
       
        mkdir figures;
        
    else
    end
    
    disp( strcat("Execution Time = ", string( toc ), ' seconds' ) )
end

%% Load Data
function [ EEG ] = loadData( FILE_TYPE, FILE_FULL )
    
    tic
    fprintf( '\n' )
    disp( '*************************************************************' )
    disp( '*                        Loading Data                       *' )
    disp( '*************************************************************' )
    fprintf( '\n' )
    
    switch FILE_TYPE
        
        case '.set'
        
            EEG = pop_loadset( FILE_FULL );
            dsip( 'File Format is .SET' )
        
        case '.xdf'
        
            EEG = pop_loadxdf( FILE_FULL );
            dsip( 'File Format is .XDF' )
            
        case '.edf'
        
            EEG = pop_biosig( FILE_FULL );
            dsip( 'File Format is .EDF' )
            
        otherwise
            disp( 'File Format is INVALID' )
        
    end
    
    eeglab redraw
    
    disp( strcat("Execution Time = ", string( toc ), ' seconds' ) )
end

%% Set Channel Locations
function [ EEG ] = setChanLocs ( EEG )
    
    fprintf( '\n' )
    disp( '*************************************************************' )
    disp( '*                 Setting Channel Locations                 *' )
    disp( '*************************************************************' )
    fprintf( '\n' )
    
    EEG = pop_chanedit( EEG, 'lookup', 'C:\\eeglab2021.1\\plugins\\dipfit4.3\\standard_BEM\\elec\\standard_1005.elc', ...
                        'changefield', { 1  'labels' 'FP1' }, ...
                        'changefield', { 2  'labels' 'FP2' }, ...
                        'changefield', { 3  'labels' 'F3'  }, ...
                        'changefield', { 4  'labels' 'F4'  }, ...
                        'changefield', { 5  'labels' 'C3'  }, ...
                        'changefield', { 6  'labels' 'C4'  }, ...
                        'changefield', { 7  'labels' 'P3'  }, ...
                        'changefield', { 8  'labels' 'P4'  }, ...
                        'changefield', { 9  'labels' 'O1'  }, ...
                        'changefield', { 10 'labels' 'O2'  }, ...
                        'changefield', { 11 'labels' 'F7'  }, ...
                        'changefield', { 12 'labels' 'F8'  }, ...
                        'changefield', { 13 'labels' 'T3'  }, ...
                        'changefield', { 14 'labels' 'T4'  }, ...
                        'changefield', { 15 'labels' 'T5'  }, ...
                        'changefield', { 16 'labels' 'T6'  }, ...
                        'changefield', { 17 'labels' 'Fz'  }, ...
                        'changefield', { 18 'labels' 'Cz'  }, ...
                        'changefield', { 19 'labels' 'Pz'  } );
                   
    EEG = eeg_checkset( EEG );
    
    EEG = pop_chanedit( EEG, 'lookup', 'C:\\eeglab2021.1\\plugins\\dipfit4.3\\standard_BEM\\elec\\standard_1005.elc' );
    
    EEG = eeg_checkset( EEG );

    eeglab redraw;
end

%% remove DC offset
function [ EEG, origEEG ] = removeDC ( EEG )
    
    fprintf( '\n' )    
    disp( '*************************************************************' )
    disp( '*                    Removing DC Offset                     *' )
    disp( '*************************************************************' )
    fprintf( '\n' )
    
    freqHP = 0.5;
    freqLP = 70;
    sRate = 256;
    filtOrder = (5 * fix( sRate/freqHP ) );
    
    EEG = pop_eegfiltnew( EEG,                   ...
                          'locutoff',  freqHP,    ...
                          'hicutoff',  freqLP,    ...
                          'filtorder', filtOrder, ...
                          'plotfreqz', 0 );


    origEEG = EEG;

    eeglab redraw;
end

%% Clean Data
function [ EEG ] = cleanData ( EEG )

    fprintf( '\n' )
    disp( '*************************************************************' )
    disp( '*                       Cleaning Data                       *' )
    disp( '*************************************************************' )
    fprintf( '\n' )
    
    % remove artifacts
    EEG = clean_rawdata( EEG, -1, -1, -1, -1, 5, 0.25 );
    vis_artifacts( EEG, originalEEG );
    saveas( gcf, 'figures\first_pass_artifacting.png', 'png' );

    eeglab redraw;
end

%% Set Average Reference
function [ EEG ] = setAveRef ( EEG )

    fprintf( '\n' )
    disp( '*************************************************************' )
    disp( '*                 Setting Average Reference                 *' )
    disp( '*************************************************************' )
    fprintf( '\n' )
    
    EEG.nbchan = EEG.nbchan+1;
    EEG.data( end+1, : ) = zeros( 1, EEG.pnts );
    EEG.chanlocs( 1,EEG.nbchan ).labels = 'initialReference';
    EEG = pop_reref(EEG, []);
    EEG = pop_select( EEG, 'nochannel', { 'initialReference' } );
    disp( [ 'Number of channels = ', EEG.nbchan ] )
    EEGset = pop_saveset( EEG, [ filePath, filesep, fileName, '.set' ] );

    eeglab redraw;
end

%%Run AMICA
function runAMICA ()

    fprintf( '\n' )
    disp( '*************************************************************' )
    disp( '*                       Running AMICA                       *' )
    disp( '*************************************************************' )
    fprintf( '\n' )
    
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
end

%% Run Dipole Fitting
function runDipoFit ()

    fprintf( '\n' )
    disp( '*************************************************************' )
    disp( '*                  Running Dipole Fitting                   *' )
    disp( '*************************************************************' )
    fprintf( '\n' )
    
end

%% Run Pipeline
function runPipe ()
    tic
    fprintf( '\n' )
    disp( '*************************************************************' )
    disp( '*              Running Preprocessing Pipeline               *' )
    disp( '*************************************************************' )
    fprintf( '\n' )
    
    eeglab; % Open EEGLAB
    out = setPatsAndDirs(); % Set Paths and Create Directories
    out = loadData( out ); % Load Data
    setChanLocs( out ); % Set Channel Locations
    removeDC(); % remove DC offset
    cleanData(); % Clean Data
    setAveRef(); % Set Average Reference
    runAMICA(); % Run AMICA
    runDipoFit(); % Run Dipole Fitting
    
    disp('Pipeline: ', toc )
end

runPipe ()

end