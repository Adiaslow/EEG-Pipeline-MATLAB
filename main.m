% EEG Preprocessing Pipeline
% By Adam Murray
% 11/2021 - Present

% Inspiration from Nick, Makoto Miyakoshi, and others.

% This script is an automated pipeline for preprocessing EEG data
% Steps: Load Data, Set Channel Locations, Remove DC Offset, Clean Data,
% Set Average Reference, Run AMICA, Fit Dipoles to ICs, Visualize Data

%% Main Function
function main ()

    %% Set Paths and Create Directories
    function [ FILE_PATH, FILE_NAME , FILE_TYPE, FILE_FULL ] = setPatsAndDirs()
        
        tic
        fprintf( "\n" )
        disp( "*********************************************************" )
        disp( "*             Setting Paths and Directories             *" )
        disp( "*********************************************************" )
        fprintf( "\n ")

        % go to folder where data file is, hold shift, right click, click 
        % "Copy as path", paste it after the '=' and replace the (")s with
        % (')s in the parentheses below.
        
        % Initializes the path in which the file to be processed exists
        FILE_PATH = ( "C:\Users\admin\Desktop\GitHub-Repos\EEG-Pipeline-MATLAB" );
        
            % Adds the initialized file path to path in MATLAB
            addpath( FILE_PATH );
            
            % Sets the current directory as the file path
            cd( FILE_PATH );
        
            disp( strcat( "Using path: ", FILE_PATH ) )
        
        % Type the file name without the extention and without any spaces
        % in between the parentheses below.
        
        % Initializes the file
        FILE_NAME = ( "MUAD06022021EOFull2" );
        
            disp( strcat( "Using EEG file: ", FILE_NAME ) )
        
        % Sets the file type
        FILE_TYPE = ( ".xdf" );
        
        % Combines the above variables to create the full file path
        FILE_FULL = strcat( FILE_PATH, filesep, FILE_NAME, FILE_TYPE );

        % Creates a directory called figures
        mkdir figures
        
        fprintf( "\n" )
        disp( strcat( "Execution Time = ", string( toc ), " seconds" ) )
        
    end

    %% Load Data
    function [ EEG ] = loadData( FILE_TYPE, FILE_FULL )

        tic
        fprintf( "\n" )
        disp( "*********************************************************" )
        disp( "*                      Loading Data                     *" )
        disp( "*********************************************************" )
        fprintf( "\n" )
        
        % Checks what type of file is present and loads the data as such.
        switch FILE_TYPE

            case ".set" % Check if file is .set

                EEG = pop_loadset( FILE_FULL ); % Load data as .set
                disp( "File Format is .SET" )

            case ".xdf" % Check if file is .xdf

                EEG = pop_loadxdf( FILE_FULL ); % Load data as .edf
                disp( "File Format is .XDF" )

            case ".edf" % Check if file is .edf

                EEG = pop_biosig( FILE_FULL ); % Load data as .edf
                disp( "File Format is .EDF" )

            otherwise % If is none of the above, throws error
                disp( "File Format is INVALID" )
                disp( "Stopping Script" )

        end
        
        % Reloads EEGLAB
        eeglab redraw

        fprintf( "\n" )
        disp( strcat( "Execution Time = ", string( toc ), " seconds" ) )
        
    end

    %% Set Channel Locations
    function [ EEG ] = setChanLocs ( EEG )

        tic
        fprintf( "\n" )
        disp( "*********************************************************" )
        disp( "*               Setting Channel Locations               *" )
        disp( "*********************************************************" )
        fprintf( '\n' )

        % Sets channel locations (Credit to Nick)
        EEG = pop_chanedit( EEG, 'lookup', ...
                            'C:\\eeglab2021.1\\plugins\\dipfit4.3\\standard_BEM\\elec\\standard_1005.elc', ...
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

        EEG = pop_chanedit( EEG, 'lookup', ...
                            'C:\\eeglab2021.1\\plugins\\dipfit4.3\\standard_BEM\\elec\\standard_1005.elc' );

        EEG = eeg_checkset( EEG );
        
        % Reloads EEGLAB
        eeglab redraw;
        
        fprintf( "\n" )
        disp( strcat( "Execution Time = ", string( toc ), " seconds" ) )
        
    end

    %% remove DC offset
    function [ EEG, origEEG ] = removeDC ( EEG )

        tic
        fprintf( "\n" )    
        disp( "*********************************************************" )
        disp( "*                  Removing DC Offset                   *" )
        disp( "*********************************************************" )
        fprintf( "\n" )

        % Filter Parameters
        locutoff  = 0.5; % High-pass filter cutoff
        hicutoff  = 70; % Low-pass filter cutoff
        sRate     = 256; % Sample rate of the data
        filtOrder = ( 5 * fix( sRate / locutoff ) ); % Filter order

        % Filters data to remover DC offset and slow drift
        EEG = pop_eegfiltnew( EEG,                    ...
                              'locutoff',  locutoff,  ...
                              'hicutoff',  hicutoff,  ...
                              'filtorder', filtOrder, ...
                              'plotfreqz', 0 );
        
        % Saves the original EEG                  
        origEEG = EEG;

        % Reloads EEGLAB
        eeglab redraw;
        
        
        fprintf( "\n" )
        disp( strcat( "Execution Time = ", string( toc ), " seconds" ) )
        
    end

    %% Clean Data
    function [ EEG ] = cleanData ( EEG , origEEG )

        tic
        fprintf( "\n" )
        disp( "*********************************************************" )
        disp( "*                     Cleaning Data                     *" )
        disp( "*********************************************************" )
        fprintf( "\n" )

        % clean_rawdata() parameters
        arg_flatline = -1;
        arg_highpass = -1;
        arg_channel  = -1;
        arg_noisy    = -1;
        arg_burst    = 5;
        arg_window   = 0.25;
        
        EEG = clean_rawdata( EEG,         arg_flatline, arg_highpass, ...
                             arg_channel, arg_noisy,    arg_burst,    ...
                             arg_window );
        
        vis_artifacts( EEG, origEEG );
        
        saveas( gcf, "figures\first_pass_artifacting.png", 'png' );

        eeglab redraw;
        
        fprintf( "\n" )
        disp( strcat( "Execution Time = ", string( toc ), " seconds" ) )
        
    end

    %% Set Average Reference
    function [ EEG ] = setAveRef ( EEG, FILE_PATH, FILE_NAME )

        tic
        fprintf( "\n" )
        disp( "*********************************************************" )
        disp( "*               Setting Average Reference               *" )
        disp( "*********************************************************" )
        fprintf( "\n" )

        % (Credit to Makoto Mikyakoshi)
        EEG.nbchan = EEG.nbchan+1;
        
        EEG.data( end+1, : ) = zeros( 1, EEG.pnts );
        
        EEG.chanlocs( 1,EEG.nbchan ).labels = 'initialReference';
        
        EEG = pop_reref(EEG, []);
        
        EEG = pop_select( EEG, 'nochannel', { 'initialReference' } );
        
        disp( strcat( "Number of channels = ", string( EEG.nbchan ) ) )

        eeglab redraw;
        
        fprintf( "\n" )
        disp( strcat( "Execution Time = ", string( toc ), " seconds" ) )
        
    end
    
    %% Run ICA
    function [ EEG ] = runICA( EEG )
        
        tic
        fprintf( "\n" )
        disp( "*********************************************************" )
        disp( "*                      Running ICA                      *" )
        disp( "*********************************************************" )
        fprintf( "\n" )
        
        pop_runica(EEG, 'extended', 1, 'interupt', 'on');
        
        disp( strcat( "Execution Time = ", string( toc ), " seconds" ) )
        
    end
    
    %% Run AMICA
    function runAMICA ()
        
        tic
        fprintf( "\n" )
        disp( "*********************************************************" )
        disp( "*                     Running AMICA                     *" )
        disp( "*********************************************************" )
        fprintf( "\n" )
        
        
        
       
        eeglab redraw;
        
        fprintf( "\n" )
        disp( strcat( "Execution Time = ", string( toc ), " seconds" ) )
        
    end

    %% Run Dipole Fitting
    function runDipoFit ( EEG )

        tic
        fprintf( "\n" )
        disp( "*********************************************************" )
        disp( "*                Running Dipole Fitting                 *" )
        disp( "*********************************************************" )
        fprintf( "\n" )

        % (Credit to Nick)
        EEG = pop_dipfit_settings( EEG, 'hdmfile', ...
                                   'C:\\eeglab2021.1\\plugins\\dipfit4.3\\standard_BEM\\standard_vol.mat', ...
                                   'coordformat','MNI','mrifile', ...
                                   'C:\\eeglab2021.1\\plugins\\dipfit4.3\\standard_BEM\\standard_mri.mat', ...
                                   'chanfile','C:\\eeglab2021.1\\plugins\\dipfit4.3\\standard_BEM\\elec\\standard_1005.elc', ...
                                   'coord_transform', [0 0 0 0 0 -1.5708 1 1 1], ...
                                   'chansel', [1:19] );
                               
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        
        EEG = pop_multifit(EEG, [1:18], 'threshold', 100, ...
                           'plotopt', {'normlen' 'on'});
                       
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        
        eeglab redraw;
        
        fprintf( "\n" )
        disp( strcat( "Execution Time = ", string( toc ), " seconds" ) )
        
    end

    %% Run Pipeline
    function runPipe ()
        
        pipeTic = tic;
        fprintf( "\n" )
        disp( "*********************************************************" )
        disp( "*            Running Preprocessing Pipeline             *" )
        disp( "*********************************************************" )
        fprintf( "\n" )
        
        % Open EEGLAB
        eeglab;
        
        % Set Paths and Create Directories
        [ FILE_PATH, FILE_NAME , FILE_TYPE, FILE_FULL ] = setPatsAndDirs();
        
        % Load Data
        EEG = loadData( FILE_TYPE, FILE_FULL );
        
        % Set Channel Locations
        EEG = setChanLocs( EEG );
        
        % remove DC offset
        [ EEG, origEEG ] = removeDC( EEG );
        
        % Clean Data
        EEG = cleanData( EEG, origEEG );
        
        % Set Average Reference
        [ EEG ] = setAveRef( EEG, FILE_PATH, FILE_NAME );
        
        % Run ICA
        runICA( EEG );
        
        % Run AMICA
        % runAMICA( EEG );
        
        % Run Dipole Fitting
        runDipoFit( EEG );
        
        fprintf( "\n" )
        disp( strcat( "Execution Time = ", string( toc( pipeTic ) ), ...
              ' seconds' ) )
        
    end

    runPipe ()

end