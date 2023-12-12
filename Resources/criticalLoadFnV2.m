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
function [sorted_values]=criticalLoadFn(stiffnesMatrix,geometricMatrix)
    values=eigs(stiffnesMatrix.global,geometricMatrix.global.*-10,5,'smallestabs');
    [~, index] = sort(abs(values));
    sorted_values = values(index);
end




            
