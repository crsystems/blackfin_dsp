% firhex2bf(filterCoeffs, 'whatever') generiert ein Textfile namens "firwhatever.txt" 
% und einem Label "whatever" mit den entsprechenden Koeffizienten in Hexdarstellung.

function firhex2bf(filterCoeffs, labelName)
filename = strcat('fir', labelName, '.txt');
fileID = fopen(filename,'w');
fprintf(fileID, '%s:\n', labelName);

for i=1:length(filterCoeffs)
    hexFilterCoeff = hex(fi(filterCoeffs(i), 1, 16, 15));
    fprintf(fileID, '\t.short 0x%s\n', hexFilterCoeff);
end

fclose(fileID);
end
