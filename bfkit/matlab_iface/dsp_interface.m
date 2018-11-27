%dsp_dir = '/dev/USBtty0';
%fir_coeff_dec = 0;

main();

function main()
   %dsp_desc = fopen(dsp_dir);
   
   prompt = "Choose one action:\nExecute FIR filter: 1\nExecute IIR filter: 2\nUpdate FIR coefficients: 3\nUpdate IIR coefficients: 4\nMeasure filter: 5\nExit: 6\n";
   r = input(prompt);
   while(r ~= 6)
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
       end
       r = input(prompt);
   end


end

function measure_filter()
    input_samples = [];
    output_samples = [];
    bode_plot = [];
    freq = 1;
    bound = 20000;
    resolution = 120;
    sample_time = 1/48000;
    while(freq <= bound)
        i = 1;
        while(i <= resolution)
            input_samples((freq-1)*resolution+i)=sin(2*pi*freq*i*sample_time);
            i = i+1;
        end
        freq = freq + 1;
    end
    %plot(input_samples);
    
    %communicate with dsp...
    
    output_samples = input_samples;
    
    gain = output_samples./input_samples;
    
    j = 1;
    while(j <= bound)
        l=1;
        tmp = 0;
        while(l <= resolution)
            tmp = tmp + gain((j-1)*resolution + l);
            l = l + 1;
        end
        bode_plot(j) = 20*log(tmp/resolution);
        j = j + 1;
    end
    plot(bode_plot);
    
    
end


function update_fir()
    fir_coeff_dec = 0.5*Num;
    clearvars Num;
end