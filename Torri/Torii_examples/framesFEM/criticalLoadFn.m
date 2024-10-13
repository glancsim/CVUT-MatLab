% Výpočet kritického břemene z matice tuhosti a matice počátečních napětí
%
% In: 
%   geometricMatrix     .global     =   globální matice počátečních napětí       
%   stiffnesMatrix      .global     =   globální matice tuhosti  
%   n                               =   počet požadovaných tvarů
% Out:
%   Results             .values     = 	kritická břemena;
%   Results             .vectors    =   vlastní tvary deformované konstrukce;
% 
% (c) S. Glanc, 2023
function [Results]=criticalLoadFn(stiffnesMatrix,geometricMatrix,n)
    [eigenVectors,eigeinValues]=eigs(stiffnesMatrix.global,-geometricMatrix.global,n,'smallestabs');
    eigeinValues=diag(eigeinValues);
    Results.values = eigeinValues;
    Results.vectors = eigenVectors;
end




            
