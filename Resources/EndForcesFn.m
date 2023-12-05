% Výpočet vnitřních sil
%
% In: 
% stiffnesMatrix.global =   globální matice tuhosti 
% stiffnesMatrix.local =    lokální matice tuhosti - cell
% endForces.global =    globální zatížení ve styčníkách
% transformationMatrix.matrices =    transoformační matice pro jednotlivé elementy 
% 12 =        počet stupňů volnosti jednotlivého elementu, 
%                           pro 3D=12
% elements.nelement =        počet elementů
% elements.ndofs =   počet neznámých vnitřních sil/posunů
% elements.codeNumbers =     kódová čísla elementů
% 
% 
% Out:
%  localEndForces =         lokální vnitřní síly na elementech      
%
% (c) S. Glanc, 2021

function [localEndForces,displacements]=EndForcesFn(stiffnesMatrix,endForces,transformationMatrix,elements)
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
                if kcisla(i)==0;
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