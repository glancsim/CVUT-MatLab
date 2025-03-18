% Výpočet vnitřních sil
%
% In: 
% globalStiffnessMatrix =   globální matice tuhosti 
% localStiffnessMatrix =    lokální matice tuhosti - cell
% globalJointEndforces =    globální zatížení ve styčníkách
% transformationMatrix =    transoformační matice pro jednotlivé elementy 
% degreesOfFreedom =        počet stupňů volnosti jednotlivého elementu, 
%                           pro 3D=12
% numberOfElements =        počet elementů
% numberOfUnknownForces =   počet neznámých vnitřních sil/posunů
% elementsCodeNumbers =     kódová čísla elementů
% 
% 
% Out:
%  localEndForces =         lokální vnitřní síly na elementech      
%
% (c) S. Glanc, 2021

function [localEndForces]=EndForces(globalStiffnessMatrix,localStiffnessMatrix,globalJointEndforces,transformationMatrix,degreesOfFreedom,numberOfElements,numberOfUnknownForces,elementCodeNumbers)
%==========================================================================
%Globalni posun stycniku
%==========================================================================
r_global=zeros(numberOfUnknownForces,1);
r_global(:,1)= globalStiffnessMatrix\globalJointEndforces;
    
%==========================================================================
%Lokalni posun stycniku
%==========================================================================
r_local=zeros(degreesOfFreedom,numberOfElements);
for j=1:numberOfElements
    kcisla=elementCodeNumbers(j,:);
        for i=1:degreesOfFreedom
            if kcisla(i)==0;
            r_local(i,j)=0;
            else
            r_local(i,j)=r_global(kcisla(i));   
            end
        end
end

for i=1:numberOfElements
    T=transformationMatrix{i}; 
    r=r_local(:,i);
    r_local(:,i)=T*r;
end
%==========================================================================
%Lokalni sily ve stycniku
%==========================================================================
for i=1:numberOfElements
    K_l=localStiffnessMatrix{i};
    r=r_local(:,i);
    localEndForces(:,i)=K_l*r;
end
end