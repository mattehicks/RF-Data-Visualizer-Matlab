
% Title:        TF9 AWE Graphing Program
% description: scans local directories for any AWE file, graphs the RF data.
% output: /Graphs/jpg.
% output: Parser_Log.txt.
% Created by:   Matt Hicks
% Company:      ArgonST 2011


MAX_Sample= 1470;
Waveforms_Captured = 15;

fout = fopen('Parser_Log.txt','a+');

d=dir('.');
d=d(~[d.isdir]);
AWE_FILE = '';
for i=1:numel(d);
    filename = d(i).name;
    if (strfind(filename,'_AWE_'));
        AWE_FILE = filename;
        fout = fopen('Log.txt','w');
        fprintf(fout,filename);
        fprintf(fout,'\r\n');
        fclose(fout);
    end
end;

expr1 = '[^\n]*\Parameter\[1] =[^\n]*';         %number of steps.
expr2 = '[^\n]*\Parameter\[2] =[^\n]*';         %power in band.
exp_pass_fail = '[^\n]*testResults =[^\n]*';     %pass fail results.
expr4 = '[^\n]*\Parameter\[4] =[^\n]*';         %center freq.
expr5 = '[^\n]*\Parameter\[5] =[^\n]*';         %peak level.
expr6 = '[^\n]*\"Parameter\[6] =[^\n]*';       %RF samples.

filetext = fileread(AWE_FILE);

found_steps = regexp(filetext, expr1, 'match');
found_powerband = regexp(filetext, expr2, 'match');
found_pass_fail = regexp(filetext, exp_pass_fail, 'match');
found_center = regexp(filetext, expr4, 'match');
found_peak = regexp(filetext, expr5, 'match');
found_samples = regexp(filetext, expr6, 'match');

%Allocate 3 large arrays.
final_params_to_plot = cell(6,Waveforms_Captured); 
temp_cell = cell(MAX_Sample,1);
y_data {1,Waveforms_Captured} = []; 

%%%%%%%%%%%%%%% GET TEST DATE FROM AWE logfile %%%%%%%%%%%%%%%%%%%%
%name the output file by the first string found- the test date.
temp_str_date = textscan(found_samples{1},'%s/', 'bufsize', 500);
str_date = temp_str_date{1};
date = regexprep(str_date{1}, '/', '_');
date = strcat(date, '_TF9');

newdir = strcat('graphs_',date);
error = mkdir(newdir);
halfpath = strcat (pwd,'\',newdir,'\');

%%%%%%%%%%%%%%%%%%%% PLOTTING SAMPLE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%

for temp_i = 1:length(found_samples); %number of waveforms captured.
    
    %% PART 1 - Numerical Waveform Data
    %scanning all numerical RF values from strings, about 1445 samples per waveform.
    y_data(1,temp_i) = textscan(found_samples{temp_i},'%s', 'delimiter', ', "', 'Bufsize', 500);
    y_data{1,temp_i}(1:13) = []; % any non RF data is removed, date, chars, etc.
    y1{1,temp_i} = str2double(y_data{1,temp_i});
    
    %% PART 2 - Telemetry Info
    %temporary variables to store the formatted data.
    
    final_params_to_plot(1,temp_i) = textscan(found_steps{temp_i},'%s', 'delimiter', ', "', 'Bufsize', 100);
    final_params_to_plot(2,temp_i) = textscan(found_powerband{temp_i},'%s', 'delimiter', ', "', 'Bufsize', 100);
    passfailtext = textscan(found_pass_fail{temp_i},'%s', 'delimiter', ', "', 'Bufsize', 400);
    final_params_to_plot(3,temp_i) = passfailtext{1,1}(11);
    final_params_to_plot(4,temp_i) = textscan(found_center{temp_i},'%s', 'delimiter', ', "', 'Bufsize', 100);
    final_params_to_plot(5,temp_i) = textscan(found_peak{temp_i},'%s', 'delimiter', ', "', 'Bufsize', 100);
    
    final_params_to_plot{1,temp_i}= str2double(final_params_to_plot{1,temp_i}(11));  % steps
    final_params_to_plot{2,temp_i}= str2double(final_params_to_plot{2,temp_i}(11));  % power in band
    final_params_to_plot{4,temp_i}= str2double(final_params_to_plot{4,temp_i}(11));  % center
    final_params_to_plot{5,temp_i}= str2double(final_params_to_plot{5,temp_i}(11));  % peak level
    final_params_to_plot{6,temp_i} = str2double(y_data{1,1}(1));  % start
    final_params_to_plot{7,temp_i} = str2double(y_data{1,1}(2));  % step
end

for temp_f = 1:Waveforms_Captured;
    tic
    %data to be used on this pass
    data = y1{1,temp_f}() ;
    %telemetry for this pass
    fprintf(1,'Reading data step...');
    p_steps = final_params_to_plot{1,temp_f};
    p_power = final_params_to_plot{2,temp_f};
    p_pass_fail = final_params_to_plot{3,temp_f};
    p_center = final_params_to_plot{4,temp_f};
    p_peak = final_params_to_plot{5,temp_f};
    p_start = final_params_to_plot{6,temp_f};
    p_stepsize =  final_params_to_plot{7,temp_f};
    
    fout = fopen('Parser_Log.txt','a+');
    fprintf(fout,'[Sample %d] \r\n', temp_f);
   
    if temp_f ==1
        figure;
        fig1 = gcf;
        subplot(2,1,1); %xsize ysize ypos
        grid on;
        hold all;
        xlabel ('Frequency (MHz)');
        ylabel ('Output Power (dBm)');
    end;
    %SMALL STEP CW
    %draw the first five waveforms together
       if temp_f < 5
        plot(1:length(data),data);
        fprintf(1,'Plotting %d steps\n', p_steps);
       end;
       
    if temp_f == 5   
        
        plot(1:length(data),data);
        fprintf(1,'Plotting %d steps\n', p_steps);
        
        %create a data overlay
        axis([-50,1500,-120,0])
        title ('CW Small Step');
        
        annotation(fig1,'textbox',...
            [0.05 0.2 0.34 0.25],...
            'String',{
            'Center Freq:',...
            final_params_to_plot{4,1},...
            final_params_to_plot{4,2},...
            final_params_to_plot{4,3},...
            final_params_to_plot{4,4},...
            final_params_to_plot{4,5}},...
            'FitBoxToText','on', 'Fontsize', 16);
        
        annotation(fig1,'textbox',...
            [0.36 0.2 0.35 0.25],...
            'String',{
            'Power:',...
            final_params_to_plot{2,1},...
            final_params_to_plot{2,2},...
            final_params_to_plot{2,3},...
            final_params_to_plot{2,4},...
            final_params_to_plot{2,5}},...
            'FitBoxToText','on', 'Fontsize', 16);
        
        annotation(fig1,'textbox',...
            [0.56 0.2 0.34 0.25],...
            'String',{
            'Peak:', final_params_to_plot{5,1},...
            final_params_to_plot{5,2},...
            final_params_to_plot{5,3},...
            final_params_to_plot{5,4},...
            final_params_to_plot{5,5}},...
            'FitBoxToText','on', 'Fontsize', 16);
        
        annotation(fig1,'textbox',...
            [0.75 0.2 0.34 0.25],...
            'String',{
            'Result:',...
            final_params_to_plot{3,1},...
            final_params_to_plot{3,2},...
            final_params_to_plot{3,3},...
            final_params_to_plot{3,4},...
            final_params_to_plot{3,5}},...
            'FitBoxToText','on', 'Fontsize', 16);
        timing = toc;
        try
            p_date = strcat( date,'_SmallStep');
            fullpath = strcat(halfpath, p_date);
            saveas(fig1, fullpath, 'jpg');
            fprintf(fout,'Saved. \n');
        catch exception
            error('create file error! \n')
        end;
        fprintf(fout,'Drawing time: %d \n',timing);
    end % is eq5
   
       %WAVEFORM 6 GETS DISCARDED PER THE TF_9 SCRIPT, I DONT KNOW WHY.
       if temp_f == 6
                   fprintf(1,'Skipping #6 \n');
       end;
       
  %FIGURE 2
  %setup figure 2
        if temp_f == 7
        figure;
        fig2 = gcf;
        subplot(2,1,1); %xsize ysize ypos
        grid on;
        hold all;
        xlabel ('Frequency (MHz)');
        ylabel ('Output Power (dBm)');
        title('CW Channel Step');
        
        axis([-50,1500,-120,10])
        annotation(fig2,'textbox',...
            [0.06 0.2 0.34 0.25],...
            'String',{
            'Center Freq:',...
            final_params_to_plot{4,1}},...
            'FitBoxToText','on', 'Fontsize', 16);
        
        annotation(fig2,'textbox',...
            [0.35 0.2 0.34 0.25],...
            'String',{
            'Power:',...
            final_params_to_plot{2,7},...
            final_params_to_plot{2,8},...
            final_params_to_plot{2,9}},...
            'FitBoxToText','on', 'FontSize', 16);
        
        annotation(fig2,'textbox',...
            [0.55 0.2 0.34 0.25],...
            'String',{
            'Peak:',...
            final_params_to_plot{5,7},...
            final_params_to_plot{5,8},...
            final_params_to_plot{5,9}},...
            'FitBoxToText','on', 'FontSize', 16);
        
        annotation(fig2,'textbox',...
            [0.72 0.2 0.34 0.25],...
            'String',{
            'Result:',...
            final_params_to_plot{3,7},...
            final_params_to_plot{3,8},...
            final_params_to_plot{3,9}},...
            'FitBoxToText','on', 'Fontsize', 16);
        end;
        
        tic; 
        if  temp_f ==7 || temp_f == 8 || temp_f == 9
        %subplot(2,1,1); %xsize ysize ypos
        plot(1:length(data),data);
        fprintf(1,'Plotting %d steps\n', p_steps);
        end;
       
        if  temp_f == 9
        try
            p_date = strcat(date,'_ChanStep');
            fullpath = strcat(halfpath, p_date);
            saveas(fig2, fullpath, 'jpg');
            fprintf(fout,'Saved. \n');
        catch exception
            error('create file error! \n')
        end;
        timing = toc;
        fprintf(fout,'Drawing time: %s \n',timing);
     fprintf(fout,'Done \r\n');
        end; 
    
    %SINGLE WAVEFORM SPURIOUS
    if temp_f > 9
        figure;
        figX = gcf;
        subplot(2,1,1); %xsize ysize ypos
        plot(1:length(data),data);
        fprintf(1,'Plotting %d steps\n', p_steps);
        
        switch temp_f
            case {10}
                serenade = 'CW 1kHz spurious';
            case {11}
                serenade = 'CW 10kHz spurious';
            case {12}
                serenade = 'CW 100kHz spurious';
            case {13}
                serenade = 'CW 1mHz spurious';
            case {14}
                serenade = 'CW 10mHz spurious';
            case {15}
                serenade = 'CW 100mHz spurious';
        end;
        title(serenade, 'FontSize', 16);
        grid on;
        xlabel ('Frequency (MHz)');
        ylabel ('Output Power (dBm)');
        axis([-50,1500,-120,10])
        annotation(figX,'textbox',...
            [0.2 0.2 0.34 0.25],...
            'String',{
            'Power:',...
            final_params_to_plot{2,temp_f}},...
            'FitBoxToText','on', 'FontSize', 16);
        
        annotation(figX,'textbox',...
            [0.4 0.2 0.34 0.25],...
            'String',{
            'Peak:',...
            final_params_to_plot{5,temp_f}},...
            'FitBoxToText','on', 'FontSize', 16);
        
        annotation(figX,'textbox',...
            [0.6 0.2 0.34 0.25],...
            'String',{
            'Result:',...
            final_params_to_plot{3,temp_f}},...
            'FitBoxToText','on', 'FontSize', 16);
        try
            p_date = strcat(date,'_',serenade);
            fullpath = strcat(halfpath, p_date);
            saveas(figX, fullpath, 'jpg');
            fprintf(fout,'Saved.\n');
        catch exception
             fprintf(1,'error creating file %s', fullpath);
        end;
        fprintf(fout,'Drawing time: %s \n',timing);
        close(figX);
    end;
    fprintf(fout,'Steps: %d \r\n', p_steps );
    fprintf(fout,'Done \r\n');
    fclose(fout);
end;
        fprintf(1,'Done, Thank You. \n');
