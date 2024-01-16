% Výpočet vnitřních sil
%
% In: 
%   stiffnesMatrix          .global         - globální matice tuhosti 
%                           .local          - lokální matice tuhosti - cell
%   endForces               .global     	- globální zatížení ve styčníkách
%   transformationMatrix    .matrices       - transoformační matice pro jednotlivé elementy 
%   elements                .codeNumbers    - kódová čísla elementů
%                           .vertex         - směrový vektor pro jednotlivé elementy
%                           .nelement       - počet elementů
%                           .ndofs          - počet neznámých přemístění
% 
% Out:
%   localEndForces                          - lokální koncové síly na elementech      
%   displacements           .local          - lokální posuny na elementech
% 
% (c) S. Glanc, 2023

function [localEndForces,displacements]=endForcesFn(stiffnesMatrix,endForces,transformationMatrix,elements)
    localEndForces = zeros(12,elements.nelement);
    psv = 6;
    psv2 = psv*2;
    %==========================================================================
    %Globalni posun stycniku
    %==========================================================================
    r_global=zeros(elements.ndofs,1);
    r_global(:,1)= stiffnesMatrix.global\endForces.global;
    displacements.global = r_global;

    %==========================================================================
    %Lokalni posun stycniku
    %==========================================================================
    r_local=zeros(psv2,elements.nelement);
    for j=1:elements.nelement
        kcisla=elements.codeNumbers(j,:);
            for i=1:psv2
                if kcisla(i)==0
                r_local(i,j)=0;
                else
                r_local(i,j)=r_global(kcisla(i));   
                end
            end
    end

    for i=1:elements.nelement
        T=transformationMatrix.matrices{i}; 
        r=r_local(:,i);
        r_local(:,i)=T*r;
    end
    %==========================================================================
    %Lokalni sily ve stycniku
    %==========================================================================
    for i=1:elements.nelement
        K_l=stiffnesMatrix.local{i};
        r=r_local(:,i);

        localEndForces(:,i)=K_l*r;
    end
    displacements.local = r_local;
end