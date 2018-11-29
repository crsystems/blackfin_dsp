
%fir_coeff_dec = 0;
format long;
main();





function main()
   
   prompt = 'Choose one action:\nExecute FIR filter: 1\nExecute IIR filter: 2\nUpdate FIR coefficients: 3\nUpdate IIR coefficients: 4\nMeasure filter: 5\nFind endianness of UART transfer: 6\nExit: 7\n';
   r = input(prompt);
   while(r ~= 7)
       switch r
           case 1
               exec_fir()
           case 2
               exec_iir()
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
    
    load('matlab.mat');
    coeffs_fir = Num;
    
    
    output_samples = apply_fir(input_samples, coeffs_fir);
    
    
    %g = 1;
    %while(g <= length(output_samples))
    %    if(input_samples_fixed(g) == 0)
    %       gain(g) = 1;
    %    else
    %        gain(g) = output_samples(g)/input_samples(g);
    %    end
    %end
    
    gain = output_samples./input_samples;
   
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

    dsp_dev = '/dev/ttyUSB0';
    baudrate = 9600;
    blackfin = serial(dsp_dev, 'BaudRate', baudrate);

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
    fir_coeff_dec = 0.5*Num;
    clearvars Num;
end