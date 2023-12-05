clc;clear
jsonName = 'DiscreteMechanicalModelExportModelML0.json'; 
fid = fopen(jsonName); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
import = jsondecode(str)



