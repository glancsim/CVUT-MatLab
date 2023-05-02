% Vytvoření lokálních a globálních matic tuhosti
%
% In: 
% surfaceArea =             plocha průřezu
% momentOfInertiaY =        moment setrvačnosti Iy
% momentOfInertiaZ =        moment setrvačnosti Iz
% polarMomentOfInertiaX =   torzní moment setrvačnosti
% transformationMatrix =    transoformační matice pro jednotlivé elementy 
% elementLength =           délka elementů
% poissonsRatio =           Poissonovo číslo
% youngsModulus =           Youngův modul pružnosti
% numberOfElements =        počet elementů
% numberOfUnknownForces =   počet neznámých vnitřních sil/posunů
% elementsCodeNumbers =     kódová čísla elementů
% degreesOfFreedom =        počet stupňů volnosti jednotlivého elementu, 
%                           pro 3D=12
% 
% 
% Out:
% localStiffnessMatrix =    lokální matice tuhosti - cell
% globalStiffnessMatrix =   globální matice tuhosti       
%
% (c) S. Glanc, 2022

function [localStiffnessMatrix,globalStiffnessMatrix]=stiffnessM(surfaceArea,momentOfInertiaY,momentOfInertiaZ,polarMomentOfInertiaX,...
                                                                trasnformationMatrix,elementLength,poissonsRatio,youngsModulus,numberOfElements,...
                                                                numberOfUnknownForces,elementsCodeNumbers,degreesOfFreedom)
%========================================================================
%Příprava paměti počítače
%========================================================================
globalStiffnessMatrix=zeros(numberOfUnknownForces,numberOfUnknownForces);
localStiffnessMatrix={};
%========================================================================
%Výpočet
%========================================================================
psv=degreesOfFreedom/2;
for cp=1:numberOfElements % cislo elementu
A_el=surfaceArea(cp);
Iy_el=momentOfInertiaY(cp);
Iz_el=momentOfInertiaZ(cp);
J_el=polarMomentOfInertiaX(cp);
L=elementLength(cp);
T=trasnformationMatrix{cp};
T_t=T';
%=========================================================================
%Matice tuhosti
%=========================================================================
% Matice K11
K11=zeros(psv,psv);
K11(1,1)=A_el/L;
K11(2,2)=12*Iz_el/(L^3);
K11(2,6)=6*Iz_el/(L^2);
K11(3,3)=12*Iy_el/(L^3);
K11(3,5)=-6*Iy_el/(L^2);
K11(4,4)=J_el/(2*(1+poissonsRatio)*L);
K11(5,3)=-6*Iy_el/(L^2);
K11(5,5)=4*Iy_el/L;
K11(6,2)=6*Iz_el/(L^2);
K11(6,6)=4*Iz_el/L;

% Matice K22
K22=zeros(6,6);
K22(1,1)=A_el/L;
K22(2,2)=12*Iz_el/(L^3);
K22(2,6)=-6*Iz_el/(L^2);
K22(3,3)=12*Iy_el/(L^3);
K22(3,5)=6*Iy_el/(L^2);
K22(4,4)=J_el/(2*(1+poissonsRatio)*L);
K22(5,3)=6*Iy_el/(L^2);
K22(5,5)=4*Iy_el/L;
K22(6,2)=-6*Iz_el/(L^2);
K22(6,6)=4*Iz_el/L;

% Matice K12
K12=zeros(6,6);
K12(1,1)=-A_el/L;
K12(2,2)=-12*Iz_el/(L^3);
K12(2,6)=6*Iz_el/(L^2);
K12(3,3)=-12*Iy_el/(L^3);
K12(3,5)=-6*Iy_el/(L^2);
K12(4,4)=-J_el/(2*(1+poissonsRatio)*L);
K12(5,3)=6*Iy_el/(L^2);
K12(5,5)=2*Iy_el/L;
K12(6,2)=-6*Iz_el/(L^2);
K12(6,6)=2*Iz_el/L;

% Matice K21
K21=zeros(6,6);
K21(1,1)=-A_el/L;
K21(2,2)=-12*Iz_el/(L^3);
K21(2,6)=-6*Iz_el/(L^2);
K21(3,3)=-12*Iy_el/(L^3);
K21(3,5)=6*Iy_el/(L^2);
K21(4,4)=-J_el/(2*(1+poissonsRatio)*L);
K21(5,3)=-6*Iy_el/(L^2);
K21(5,5)=2*Iy_el/L;
K21(6,2)=6*Iz_el/(L^2);
K21(6,6)=2*Iz_el/L;

K_tuhost=zeros(degreesOfFreedom,degreesOfFreedom);
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

K_tuhost=youngsModulus*K_tuhost;
localStiffnessMatrix{cp}=K_tuhost;
K_tuhost=T_t*K_tuhost*T;

%========================================================================
%Assembly
%========================================================================
kcisla=elementsCodeNumbers(cp,:);
for i=1:degreesOfFreedom
    if kcisla(i)>0
        for j=1:degreesOfFreedom
            if kcisla(j)>0
            globalStiffnessMatrix(kcisla(i),kcisla(j))=globalStiffnessMatrix(kcisla(i),kcisla(j))+K_tuhost(i,j);
            end
        end
    end
end
end
end