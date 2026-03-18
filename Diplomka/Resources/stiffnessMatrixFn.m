% Vytvoření lokálních a globálních matic tuhosti
%
% In: 
% elements.sections.A =             plocha průřezu
% elements.sections.Iy =        moment setrvačnosti Iy
% elements.sections.Iz =        moment setrvačnosti Iz
% elements.sections.Ix =   torzní moment setrvačnosti
% transformationMatrix.matrices =    transoformační matice pro jednotlivé elementy 
% transformationMatrix.lengths =           délka elementů
% elements.sections.v =           Poissonovo číslo
% elements.sections.E =           Youngův modul pružnosti
% elements.nelement =        počet elementů
% elements.ndofs =   počet neznámých vnitřních sil/posunů
% elements.codeNumbers =     kódová čísla elementů
% 
% 
% Out:
% stiffnesMatrix.local =    lokální matice tuhosti - cell
% stiffnesMatrix.global =   globální matice tuhosti       
%
% (c) S. Glanc, 2022

function [stiffnesMatrix]=stiffnessMatrixFn(elements,transformationMatrix)
%========================================================================
%Příprava paměti počítače
%========================================================================
globalStiffnessMatrix=zeros(elements.ndofs,elements.ndofs);
localStiffnessMatrix={};
%========================================================================
%Výpočet
%========================================================================
psv = 6;
Kzeros = zeros(psv,psv);
for cp=1:elements.nelement % cislo elementu
A_el=elements.sections.A(cp);
Iy_el=elements.sections.Iy(cp);
Iz_el=elements.sections.Iz(cp);
J_el=elements.sections.Ix(cp);
E_el=elements.sections.E(cp);
v_el=elements.sections.v(cp);
L=transformationMatrix.lengths(cp);
T=transformationMatrix.matrices{cp};
T_t=T';
%=========================================================================
%Matice tuhosti
%=========================================================================
% Matice K11
K11=Kzeros;
K11(1,1)=A_el/L;
K11(2,2)=12*Iz_el/(L^3);
K11(2,6)=6*Iz_el/(L^2);
K11(3,3)=12*Iy_el/(L^3);
K11(3,5)=-6*Iy_el/(L^2);
K11(4,4)=J_el/(2*(1+v_el)*L);
K11(5,3)=-6*Iy_el/(L^2);
K11(5,5)=4*Iy_el/L;
K11(6,2)=6*Iz_el/(L^2);
K11(6,6)=4*Iz_el/L;

% Matice K22
K22=Kzeros;
K22(1,1)=A_el/L;
K22(2,2)=12*Iz_el/(L^3);
K22(2,6)=-6*Iz_el/(L^2);
K22(3,3)=12*Iy_el/(L^3);
K22(3,5)=6*Iy_el/(L^2);
K22(4,4)=J_el/(2*(1+v_el)*L);
K22(5,3)=6*Iy_el/(L^2);
K22(5,5)=4*Iy_el/L;
K22(6,2)=-6*Iz_el/(L^2);
K22(6,6)=4*Iz_el/L;

% Matice K12
K12=Kzeros;
K12(1,1)=-A_el/L;
K12(2,2)=-12*Iz_el/(L^3);
K12(2,6)=6*Iz_el/(L^2);
K12(3,3)=-12*Iy_el/(L^3);
K12(3,5)=-6*Iy_el/(L^2);
K12(4,4)=-J_el/(2*(1+v_el)*L);
K12(5,3)=6*Iy_el/(L^2);
K12(5,5)=2*Iy_el/L;
K12(6,2)=-6*Iz_el/(L^2);
K12(6,6)=2*Iz_el/L;

% Matice K21
K21=Kzeros;
K21(1,1)=-A_el/L;
K21(2,2)=-12*Iz_el/(L^3);
K21(2,6)=-6*Iz_el/(L^2);
K21(3,3)=-12*Iy_el/(L^3);
K21(3,5)=6*Iy_el/(L^2);
K21(4,4)=-J_el/(2*(1+v_el)*L);
K21(5,3)=-6*Iy_el/(L^2);
K21(5,5)=2*Iy_el/L;
K21(6,2)=6*Iz_el/(L^2);
K21(6,6)=2*Iz_el/L;

K_tuhost=zeros(12,12);
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
if isfield(elements,'releases') && any(elements.releases(cp,:))
    K_tuhost=releaseCondenseFn(K_tuhost,elements.releases(cp,:));
end
localStiffnessMatrix{cp}=K_tuhost;
K_tuhost=T_t*K_tuhost*T;

%========================================================================
%Assembly
%========================================================================
kcisla=elements.codeNumbers(cp,:);
for i=1:12
    if kcisla(i)>0
        for j=1:12
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

function K = releaseCondenseFn(K, rel)
% Statická kondenzace uvolněných rotačních DOFů (kloubový konec).
%   rel(1) = true → kloub na hlavě (DOFy 4,5,6 lokálně)
%   rel(2) = true → kloub na patě  (DOFy 10,11,12 lokálně)
    r = [];
    if rel(1), r = [r, 4, 5, 6];    end
    if rel(2), r = [r, 10, 11, 12]; end
    s = setdiff(1:12, r);
    K_cond = K(s,s) - K(s,r) * (K(r,r) \ K(r,s));
    K = zeros(12,12);
    K(s,s) = K_cond;
end