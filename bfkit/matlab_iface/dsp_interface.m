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
    
    fprintf(blackfin, '%s', filter);

    fprintf(blackfin, '%s', '\n');
    
    fclose(blackfin);
end


function measure_filter()
    freq = 1;                                   % start frequency
    bound = 200;                              % end frequency
    resolution = 20;                           % # of samples per frequency
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
    
    %disp(length(input_samples));
    %communicate with dsp...
    
    global blackfin;
    fopen(blackfin);
    
    fprintf(blackfin, '%s', 'm\n');
    
    i = 1;
       
    fixed_point_convert = fi([], true, 16, 15);
    
    while(i <= length(input_samples))
        current = input_samples_fixed(i);
        fwrite(blackfin, current.dec);
        fprintf(blackfin, '%s', '\n');
        
        derp = fscanf(blackfin, '%s');
        if(isnan(str2double(derp)))
            output_samples(i) = 0;
            i = i + 1;
            continue;
        end
        fixed_point_convert.dec = derp;
        output_samples(i) = fixed_point_convert.double;
        %disp(derp);
        %disp(output_samples(i));
        i = i + 1;
    end
    
    fprintf(blackfin, '%s', 'e\n');
    
    fclose(blackfin);
    
    load('iir.mat');
    load('fir.mat');
    coeffs_iir = G(1)*SOS;
    coeffs_fir = Num;
    
    output_samples_sim_fir = apply_fir(input_samples, coeffs_fir);
    output_samples_sim_iir = apply_iir(input_samples, coeffs_iir);    
    
    gain = zeros(1, bound*resolution);
    gain_sim_fir = zeros(1, bound*resolution);
    gain_sim_iir = zeros(1, bound*resolution);
    g = 1;
    while(g <= length(output_samples))
        if(output_samples(g)/input_samples(g) >= 2)
            gain(g) = 2;
            
        elseif(output_samples(g)/input_samples(g) <= 0.01)
            gain(g) = 0.01;
        else
            gain(g) = output_samples(g)/input_samples(g);
        end
        g = g + 1;
    end
    g = 1;
    while(g <= length(output_samples))
        if(output_samples_sim_fir(g)/input_samples(g) >= 2)
            gain_sim_fir(g) = 2;
            
        elseif(output_samples_sim_fir(g)/input_samples(g) <= 0.01)
            gain_sim_fir(g) = 0.01;
        else
            gain_sim_fir(g) = output_samples_sim_fir(g)/input_samples(g);
        end
        g = g + 1;
    end
    g = 1;
    while(g <= length(output_samples))
        if(output_samples_sim_iir(g)/input_samples(g) >= 2)
            gain_sim_iir(g) = 2;
            
        elseif(output_samples_sim_iir(g)/input_samples(g) <= 0.01)
            gain_sim_iir(g) = 0.01;
        else
            gain_sim_iir(g) = output_samples_sim_iir(g)/input_samples(g);
        end
        g = g + 1;
    end
    
    j = 1;
    while(j <= length(input_samples)/resolution)                                           % for every frequency
        l=1;
        tmp = 0;
        while(l <= resolution)                                  % for every sample in that frequency
            tmp = tmp + gain((j-1)*resolution + l);             % add all the obtained gains
            l = l + 1;
        end
        bode_plot(j) = 20*log10(abs(tmp/resolution));             % divide by the number of samples and convert it to the dB scale
        j = j + 1;
    end
    
    j = 1;
    while(j <= length(input_samples)/resolution)                                           % for every frequency
        l=1;
        tmp = 0;
        while(l <= resolution)                                  % for every sample in that frequency
            tmp = tmp + gain_sim_fir((j-1)*resolution + l);             % add all the obtained gains
            l = l + 1;
        end
        bode_plot_sim_fir(j) = 20*log10(abs(tmp/resolution));             % divide by the number of samples and convert it to the dB scale
        j = j + 1;
    end
    
    j = 1;
    while(j <= length(input_samples)/resolution)                                           % for every frequency
        l=1;
        tmp = 0;
        while(l <= resolution)                                  % for every sample in that frequency
            tmp = tmp + gain_sim_iir((j-1)*resolution + l);             % add all the obtained gains
            l = l + 1;
        end
        bode_plot_sim_iir(j) = 20*log10(abs(tmp/resolution));             % divide by the number of samples and convert it to the dB scale
        j = j + 1;
    end
    
    hold on;
    meas = plot(bode_plot); M1 = "Measured response";
    
    sim_fir = plot(bode_plot_sim_fir); M2 = "Simulated FIR filter";
    
    sim_iir = plot(bode_plot_sim_iir); M3 = "Simulated IIR filter";
    
    legend([meas; sim_fir; sim_iir], [M1; M2; M3]);

    xlabel('Frequency');
    ylabel('Damping in dezibels');

end

function out = apply_fir(input, coeffs)
    offset = zeros(1,20);
    out = zeros(1, length(input));
    final_input_signal = cat(2, offset, input);
    
    i = 21;
    while(i <= length(final_input_signal))
        k = 0;
        tmp = 0;
        while(k < 21)
            tmp = tmp + final_input_signal(i-k)*coeffs(k+1);
            k = k+1;
        end
        out(i-20) = tmp;
        i = i + 1;
    end
end


function out = apply_iir(input, coeffs)
    out = zeros(1, length(input));
    offset = zeros(1, 2);
    final_input_signal = cat(2, offset, input);
    
    tmp(1) = 0;
    tmp(2) = 0;
    
    k = 3;
    while(k < length(final_input_signal))
        tmp(k) = (final_input_signal(k)*coeffs(1)+final_input_signal(k-1)*coeffs(2)+final_input_signal(k-2)*coeffs(3)+tmp(k-1)*coeffs(5)+tmp(k-2)*coeffs(6))*coeffs(4);
        out(k-2) = tmp(k);
        k = k + 1;
    end
end


        

function find_endianness()

    global blackfin;
    
    
    fopen(blackfin);
    fprintf(blackfin, "%s", "e\n");
    
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
    prompt = 'Which file should the coefficients be loaded from: ';
    file = input(prompt);
    load(file, 'Num');
    fir_coeff_dec = 0.5*Num;
    
    global blackfin;
    fopen(blackfin);
    
    fprintf(blackfin, "%s", "F\n");
    
    
    i = 1;
    while(i <= length(fir_coeff_dec))
        fwrite(blackfin, hex2dec(hex(fi(fir_coeff_dec(i),1,16,15))));
        fprintf(blackfin, "%s", "\n");
        i = i + 1;
    end
    
    fclose(blackfin);
end


function update_iir()
    prompt = 'Which file should the coefficients be loaded from: ';
    file = input(prompt);
    load(file, 'G', 'SOS');
    
    iir_coeff_dec = 0.5*G(1)*SOS;
    
    global blackfin;
    fopen(blackfin);
    
    fprintf(blackfin, "%s", "I\n");
    
    fwrite(blackfin, hex2dec(hex(fi(iir_coeff_dec(1),1,16,15))));
    fprintf(blackfin, "%s", "\n");
    fwrite(blackfin, hex2dec(hex(fi(iir_coeff_dec(2),1,16,15))));
    fprintf(blackfin, "%s", "\n");
    fwrite(blackfin, hex2dec(hex(fi(iir_coeff_dec(3),1,16,15))));
    fprintf(blackfin, "%s", "\n");
    fwrite(blackfin, hex2dec(hex(fi(iir_coeff_dec(5),1,16,15))));
    fprintf(blackfin, "%s", "\n");
    fwrite(blackfin, hex2dec(hex(fi(iir_coeff_dec(6),1,16,15))));
    fprintf(blackfin, "%s", "\n");
    fwrite(blackfin, hex2dec(hex(fi(iir_coeff_dec(4),1,16,15))));
    fprintf(blackfin, "%s", "\n");
    
    fclose(blackfin);
end