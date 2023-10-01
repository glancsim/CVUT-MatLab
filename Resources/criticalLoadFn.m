% Výpočet kritického břemene z matice tuhos ti a matice počátečních napětí
%
% In: 
%   geometricMatrix.global =   globální matice počátečních napětí       
%   stiffnesMatrix.global =   globální matice tuhosti       
% Out:
%   eigenVectors =      vlastní tvar konstrukce 
%   eigeinValues =      vlastní čísla konstrukce
%   criticalLoad =      kritické břemeno
% 
% (c) S. Glanc, 2022
function [Results]=criticalLoadFn(stiffnesMatrix,geometricMatrix)
[eigenVectors,eigeinValues]=eig(stiffnesMatrix.global,-geometricMatrix.global);
eigeinValues=diag(eigeinValues);
[Min,Pos]=min(abs(eigeinValues));
Results.values = eigeinValues;
Results.vectors = eigenVectors;




            
