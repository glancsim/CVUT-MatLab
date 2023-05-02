% Výpočet kritického břemene z matice tuhos ti a matice počátečních napětí
%
% In: 
%   globalGeometricMatrix =   globální matice počátečních napětí       
%   globalStiffnessMatrix =   globální matice tuhosti       
% Out:
%   eigenVectors =      vlastní tvar konstrukce 
%   eigeinValues =      vlastní čísla konstrukce
%   criticalLoad =      kritické břemeno
% 
% (c) S. Glanc, 2022
function [eigenVectors,eigeinValues,criticalLoad]=CriticalLoad(globalStiffnessMatrix,globalGeometricMatrix)
[eigenVectors,eigeinValues]=eig(globalStiffnessMatrix,-globalGeometricMatrix);
eigeinValues=diag(eigeinValues);
[Min,Pos]=min(abs(eigeinValues));
criticalLoad=Min.*sign(eigeinValues(Pos));



            
