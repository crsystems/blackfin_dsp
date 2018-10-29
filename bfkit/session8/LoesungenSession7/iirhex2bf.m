% iirhex2bf(SOS,G,'whatever') generiert ein Textfile namens "iirwhatever.txt" 
% und drei Labels "whateverb" (b Koeffizienten), "whatevera" (a Koeffizienten) und 
% "whateverG" (Skalierungswerte) mit den entsprechenden Werten in Hexdarstellung. 
% Wichtig hier, die Koeffizienten werden bereits mit dem Faktor 1/2 skaliert.

function iirhex2bf(SOS, G, labelName)
filename = strcat('iir', labelName, '.txt');
fileID = fopen(filename,'w');

[m,n] = size(SOS);

fprintf(fileID, '%sb:\n', labelName);
for k=1:m
    for i=1:3
        hexFilterCoeff = hex(fi(SOS(k,i)*0.5, 1, 16, 15));
        fprintf(fileID, '\t.short 0x%s\n', hexFilterCoeff);
    end    
end

fprintf(fileID, '%sa:\n', labelName);
for k=1:m
    for i=4:n
        hexFilterCoeff = hex(fi(SOS(k,i)*0.5, 1, 16, 15));
        fprintf(fileID, '\t.short 0x%s\n', hexFilterCoeff);
    end    
end

fprintf(fileID, '%sG:\n', labelName);
for i=1:(m+1)
    hexFilterCoeff = hex(fi(G(i), 1, 16, 15));
    fprintf(fileID, '\t.short 0x%s\n', hexFilterCoeff);
end  

fclose(fileID);
end
