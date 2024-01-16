% Import JSONu
%
% In: 
% jsonName = 'Soubor.json'
% 
% Out:
% import =  struct with JSON 
%
% (c) S. Glanc, 2024
function import = jsonImportFn(jsonName)
fid = fopen(jsonName); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
import = jsondecode(str);
end


