% Vytvoření lokálních a globálních matic tuhosti
%
% In: 
% elements              .sections.A         - plocha průřezu
%                       .sections.Iy        - moment setrvačnosti Iy
%                       .sections.Iz        - moment setrvačnosti Iz
%                       .sections.Ix        - torzní moment setrvačnosti
%                       .sections.v         - Poissonovo číslo
%                       .sections.E         - Youngův modul pružnosti
%                       .nbeams             - počet elementů
%                       .ndofs              - počet neznámých vnitřních sil/posunů
%                       .codeNumbers        - kódová čísla elementů
% transformationMatrix  .matrices           - transoformační matice pro jednotlivé elementy 
%                       .lengths            - délka elementů
% 
% 
% Out:
% stiffnesMatrix        .local              - lokální matice tuhosti - cell
%                   	.global             - globální matice tuhosti       
%
% (c) S. Glanc, 2022

function [stiffnesMatrix]=trussMatrixKFn(beams,transformationMatrix)
%========================================================================
%Příprava paměti počítače
%========================================================================
globalStiffnessMatrix=zeros(beams.ndofs,beams.ndofs);
localStiffnessMatrix={};
%========================================================================
%Výpočet
%========================================================================
psv = 3;
Kzeros = zeros(psv,psv);
for cp=1:beams.nbeams % cislo elementu
A_el=beams.sections.A(cp);
E_el=beams.sections.E(cp);
L=transformationMatrix.lengths(cp);
T=transformationMatrix.matrices{cp};
T_t=T';
%=========================================================================
%Matice tuhosti
%=========================================================================
% Matice K11
K11=Kzeros;
K11(1,1)=A_el/L;

% Matice K22
K22=Kzeros;
K22(1,1)=A_el/L;

% Matice K12
K12=Kzeros;
K12(1,1)=-A_el/L;

% Matice K21
K21=Kzeros;
K21(1,1)=-A_el/L;

K_tuhost=zeros(psv,psv);
% Doplneni matice K11 do matice K
for j = 1:psv
    for  i = 1:psv  
    K_tuhost(i,j)=K11(i,j);
    end
end
% Doplneni matice K22 do matice K
for j = psv+1:2*psv
    k22j=j-psv;
    for  i = psv+1:2*psv
    k22i=i-psv;
    K_tuhost(i,j)=K22(k22i,k22j);
    end
end

% Doplneni matice K12 do matice K
for j = psv+1:2*psv
    k12j=j-psv;
    for  i = 1:psv 
    K_tuhost(i,j)=K12(i,k12j);
    end
end

% Doplneni matice K21 do matice K
for j = 1:psv
    for  i = psv+1:2*psv 
    k21i=i-psv;
    K_tuhost(i,j)=K21(k21i,j);
    end
end

K_tuhost=E_el*K_tuhost;
localStiffnessMatrix{cp}=K_tuhost;
K_tuhost=T_t*K_tuhost*T;

%========================================================================
%Assembly
%========================================================================
kcisla=beams.codeNumbers(cp,:);
for i=1:psv*2
    if kcisla(i)>0
        for j=1:psv*2
            if kcisla(j)>0
            globalStiffnessMatrix(kcisla(i),kcisla(j))=globalStiffnessMatrix(kcisla(i),kcisla(j))+K_tuhost(i,j);
            end
        end
    end
end
end
stiffnesMatrix.global = globalStiffnessMatrix;
stiffnesMatrix.local = localStiffnessMatrix;
end