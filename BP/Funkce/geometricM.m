% Vytvoření lokálních a globálních matic počátečních napětí
%
% In: 
% surfaceArea =             plocha průřezu
% polarMomentOfInertiaX =   torzní moment setrvačnosti
% transformationMatrix =    transoformační matice pro jednotlivé elementy 
% elementLength =           délka elementů
% localEndForces =          lokální vnitřní síly
% numberOfUnknownForces =   počet neznámých vnitřních sil/posunů
% numberOfElements =        počet elementů
% elementsCodeNumbers =     kódová čísla elementů
% degreesOfFreedom =        počet stupňů volnosti jednotlivého elementu, 
%                           pro 3D=12
% 
% 
% Out:
% localGeometricMatrix =    lokální matice počátečních napětí - cell
% globalGeometricMatrix =   globální matice počátečních napětí       
%
% (c) S. Glanc, 2022

function [localGeometricMatrix,globalGeometrixMatrix]=geometricM(surfaceArea,...
         polarMomentOfInertiaX,transformationMatrix,elementLength,localEndForces,numberOfUnkownForces,...
         numberOfElements,elementsCodeNumbers,degreesOfFreedom)
%========================================================================
F=localEndForces;
globalGeometrixMatrix=zeros(numberOfUnkownForces,numberOfUnkownForces);
%========================================================================

for cp=1:numberOfElements
A_el=surfaceArea(cp);
Ip_el=polarMomentOfInertiaX(cp);
L=elementLength(cp);%m   
%========================================================================
%Stycnikove zatizeni
%========================================================================
Fx1=-F(1,cp);
Fy1=-F(2,cp);
Fz1=-F(3,cp);
Mx1=-F(4,cp);
My1=-F(5,cp);
Mz1=-F(6,cp);
Fx2=F(7,cp)
Fy2=F(8,cp);
Fz2=F(9,cp);
Mx2=F(10,cp);
My2=F(11,cp);
Mz2=F(12,cp);

%========================================================================
%Lokalni matice pocatecnich napeti
%========================================================================
Kg=zeros(12,12);
% 1.řádek
Kg(1,1)=Fx2/L;
Kg(1,7)=-Fx2/L;
% 2.řádek
Kg(2,2)=6*Fx2/(5*L);
Kg(2,4)=My1/L;
Kg(2,5)=Mx2/L;
Kg(2,6)=Fx2/10;
Kg(2,8)=-6*Fx2/(5*L);
Kg(2,10)=My2/L;
Kg(2,11)=-Mx2/L;
Kg(2,12)=Fx2/10;
% 3.řádek
Kg(3,3)=6*Fx2/(5*L);
Kg(3,4)=Mz1/L;
Kg(3,5)=-Fx2/10;
Kg(3,6)=Mx2/L;
Kg(3,9)=-6*Fx2/(5*L);
Kg(3,10)=Mz2/L;
Kg(3,11)=-Fx2/10;
Kg(3,12)=-Mx2/L;
% 4.řádek
Kg(4,4)=Fx2*Ip_el/(A_el*L);
Kg(4,5)=-(2*Mz1-Mz2)/6;
Kg(4,6)=-(2*My1-My2)/6;
Kg(4,8)=-My1/L;
Kg(4,9)=-Mz1/L;
Kg(4,10)=-Fx2*Ip_el/(A_el*L);
Kg(4,11)=(Mz1+Mz2)/6;
Kg(4,12)=(My1+My2)/6;
% 5.řádek
Kg(5,5)=2*Fx2*L/15;
Kg(5,8)=-Mx2/L;
Kg(5,9)=Fx2/10;
Kg(5,10)=-(Mz1+Mz2)/6;
Kg(5,11)=-Fx2*L/30;
Kg(5,12)=Mx2/2;
% 6.řádek
Kg(6,6)=2*Fx2*L/15;
Kg(6,8)=-Fx2/10;
Kg(6,9)=-Mx2/L;
Kg(6,10)=(My1+My2)/6;
Kg(6,11)=-Mx2/2;
Kg(6,12)=-Fx2*L/30;
% 7.řádek
Kg(7,7)=Fx2/L;
% 8.řádek
Kg(8,8)=6*Fx2/(5*L);
Kg(8,10)=-My2/L;
Kg(8,11)=Mx2/L;
Kg(8,12)=-Fx2/10;
% 9.řádek
Kg(9,9)=6*Fx2/(5*L);
Kg(9,10)=-Mz2/L;
Kg(9,11)=Fx2/10;
Kg(9,12)=Mx2/L;
% 10.řádek
Kg(10,10)=Fx2*Ip_el/(A_el*L);
Kg(10,11)=(Mz1-2*Mz2)/6;
Kg(10,12)=-(My1-2*My2)/6;
% 11.řádek
Kg(11,11)=2*Fx2*L/15;
% 12.řádek
Kg(12,12)=2*Fx2*L/15;
B1=Kg';
B = triu(B1.',1) + tril(B1);
Ksigma=B;
T=transformationMatrix{cp};
T_t=T';
Ksigma=T_t*Ksigma*T;
localGeometricMatrix{cp}=Ksigma;
%========================================================================
%Assembly
%========================================================================
kcisla=elementsCodeNumbers(cp,:);
for i=1:degreesOfFreedom
    if kcisla(i)>0
        for j=1:degreesOfFreedom
            if kcisla(j)>0
            globalGeometrixMatrix(kcisla(i),kcisla(j))=globalGeometrixMatrix(kcisla(i),kcisla(j))+Ksigma(i,j);
            end
        end
    end
end
end
end