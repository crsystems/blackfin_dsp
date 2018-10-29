function serial_plot()

clear all;
delete(instrfind);

SerialPort = '/dev/ttyUSB0';
maxlength = 200;
ymin = 0;
ymax = 10;
baudrate = 9600;

finish = 0;
values = 0;

s = serial(SerialPort,'BaudRate',baudrate);
fopen(s);

figureHandle = figure('NumberTitle','off',...
    'Name','Real Time Serial Plotter',...
    'Color',[1 1 1],...
    'Visible','off',...
    'CloseRequestFcn',@onClose);

axesHandle = axes('Parent',figureHandle,...
    'YGrid','off',...
    'YColor',[0 0 0],...
    'XGrid','off',...
    'XTick',[],...
    'YTick',[],...
    'YLim',[ymin ymax]);

hold on;

plotHandle = plot(axesHandle,values,'LineWidth',3,'Color',[0 0 1]);

%ylabel('Amplitude','FontWeight','bold','FontSize',14,'Color',[0 0 0]);

while(finish ~= 1)
    values = circshift(values,[0 -1]);
    B = fscanf(s,'%s');
    if (size(B) ~= 0)
        val = str2double(B);
        values(maxlength)  = val;
        set(plotHandle,'YData',values);
        set(figureHandle,'Visible','on');
    end
end

delete(figureHandle);
fclose(s);
delete(s);
clear all;

function onClose(src,evnt)
    finish = 1;
end

end

