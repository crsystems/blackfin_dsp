
format long;

global blackfin;

dsp_dev = '/dev/ttyUSB0';
baudrate = 9600;
blackfin = serial(dsp_dev, 'BaudRate', baudrate);

main();

function main()
   prompt = 'Choose one action:\nExecute FIR filter: 1\nExecute IIR filter: 2\nUpdate FIR coefficients: 3\nUpdate IIR coefficients: 4\nMeasure filter: 5\nFind endianness of UART transfer: 6\nExit: 7\n';
   r = input(prompt);
   while(r ~= 7)
       switch r
           case 1
               exec_filter('f')
           case 2
               exec_filter('i')
           case 3
               update_fir()
           case 4
               update_iir()
           case 5
               measure_filter()
           case 6
               find_endianness()
       end
       r = input(prompt);
   end


end


function exec_filter(filter)
    global blackfin;
    fopen(blackfin);
    
    fprintf(blackfin, '%s%s', filter, '\n');
    
    fclose(blackfin);
end


function measure_filter()
    freq = 1;                                   % start frequency
    bound = 20000;                              % end frequency
    resolution = 120;                           % # of samples per frequency
    sample_time = 1/48000;                      % period length of one samle
    input_samples = zeros(1,resolution*bound);  % array of samples of sweep
    output_samples = zeros(1, resolution*bound);
    bode_plot = zeros(1,bound);                 % initializing bode_plot array with zeros
    while(freq <= bound)                        % for every frequency
        i = 1;
        while(i <= resolution)                  % for resolution times
            input_samples((freq-1)*resolution+i)=cos(2*pi*freq*i*sample_time);  % find value of sine with desired frequency at time i*sample_time
            i = i+1;
        end
        freq = freq + 1;
    end
    
    
    input_samples_fixed = fi(input_samples, true, 16, 15);  % converting long double to fixed length fix point fraction
    
    %communicate with dsp...
    
    global blackfin;
    fopen(blackfin);
    
    fprintf(blackfin, '%s', 'm\n');
    
    i = 1;
    while(i <= length(input_samples))
        fwrite(blackfin, hex2dec(hex(fi(input_samples(i), true, 16, 15))));
        
        output_samples(i) = str2double(fscanf(blackfin, '%s'));
        
        i = i + 1;
    end
    
    fprintf(blackfin, '%s', 'e\n');
    
    fclose(blackfin);
    
    %load('matlab.mat');
    %coeffs_fir = Num;
    
    %output_samples = apply_fir(input_samples, coeffs_fir);
    
    gain = zeros(1, bound*resolution);
    g = 1;
    while(g <= length(output_samples))
        if(input_samples_fixed(g) == 0)
            if(fi(output_samples(g), true, 16, 15) ~= 0)
                gain(g) = output_samples(g);
            else
                gain(g) = 1;
            end
        else
            gain(g) = output_samples(g)/input_samples(g);
        end
        
        if(g == 0.25*(bound*resolution))
            disp("25% finished");
        elseif(g == 0.5*(bound*resolution))
            disp("50% finished");
        elseif(g == 0.75*(bound*resolution))
            disp("75% finished");
        elseif(g == bound*resolution)
            disp("Done.");
        end
        g = g + 1;
    end
   
    j = 1;
    while(j <= bound)                                           % for every frequency
        l=1;
        tmp = 0;
        while(l <= resolution)                                  % for every sample in that frequency
            tmp = tmp + gain((j-1)*resolution + l);             % add all the obtained gains
            l = l + 1;
        end
        bode_plot(j) = 20*log(abs(tmp/resolution));             % divide by the number of samples and convert it to the dB scale
        j = j + 1;
    end
    plot(bode_plot);
    
end

function out = apply_fir(input, coeffs)
    offset = zeros(1,19);
    input_double = cast(input, 'double');
    final_input_signal = cat(2, offset, input_double);
    
    i = 20;
    while(i <= length(final_input_signal))
        k = 0;
        tmp = 0;
        while(k < 20)
            tmp = tmp + final_input_signal(i-k)*coeffs(k+1);
            k = k+1;
        end
        out(i-19) = tmp;
        i = i + 1;
    end
end
        

function find_endianness()

    global blackfin;

    fopen(blackfin);
    fprintf(blackfin, "%s", "m\n");
    
    fwrite(blackfin, 256);
    
    fprintf(blackfin, "%s", "\n");
    s = fscanf(blackfin, "%s");
    
    if(s == 'l')
        disp("Endianness is little endian");
    else
        disp("Endianness is big endian");
    end
    
    fclose(blackfin);
end


function update_fir()
    file = input("Which file should the coefficients be loaded from: ");
    load(file, 'Num');
    fir_coeff_dec = 0.5*Num;
    clearvars Num;
    
    global blackfin;
    fopen(blackfin);
    
    fprintf(blackfin, "%s", "F");
    
    i = 1;
    while(i <= length(fir_coeff_dec))
        fwrite(blackfin, hex2dec(hex(fi(fir_coeff_dec(i),1,16,15))));
        fprintf(blackfin, "%s", "\n");
    
        %disp(hex2dec(hex(fi(fir_coeff_dec(i),1,16,15))));
        
        i = i + 1;
    end
    
    fclose(blackfin);
end


function update_iir()
    file = input("Which file should the coefficients be loaded from: ");
    load(file, 'G', 'SOS');
    
    %iir_coeff_dec = 0.5
    clearvars();
end