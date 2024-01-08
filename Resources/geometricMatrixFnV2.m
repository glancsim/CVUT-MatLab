% Vytvoření lokálních a globálních matic počátečních napětí
%
% In: 
% elements.sections.A =             plocha průřezu
% elements.sections.Ix =   torzní moment setrvačnosti
% transformationMatrix.matrices =    transoformační matice pro jednotlivé elementy 
% transformationMatrix.lengths =           délka elementů
% endForces.local =          lokální vnitřní síly
% elements.nelement =        počet elementů
% elements.codeNumbers =     kódová čísla elementů
% 
% 
% Out:
% localGeometricMatrix =    lokální matice počátečních napětí - cell
% globalGeometricMatrix =   globální matice počátečních napětí       
%
% (c) S. Glanc, 2022

function [geometricMatrix]=geometricMatrixFnV2(elements,transformationMatrix,endForces)
%========================================================================
F=endForces.local;
globalGeometrixMatrix=zeros(elements.ndofs,elements.ndofs);
%========================================================================
localGeometricMatrix{elements.nelement} = 0;
for cp=1:elements.nelement
A_el=elements.sections.A(cp);
Ip_el=elements.sections.Ix(cp);
L=transformationMatrix.lengths(cp);%m  
v = elements.sections.v(cp);
E = elements.sections.E(cp);
%========================================================================
%Stycnikove zatizeni
%========================================================================
Fx1=-F(1,cp);
Fy1=-F(2,cp);
Fz1=-F(3,cp);
Mx1=-F(4,cp);
My1=-F(5,cp);
Mz1=-F(6,cp);
Fx2=F(7,cp);
Fy2=F(8,cp);
Fz2=F(9,cp);
Mx2=F(10,cp);
My2=F(11,cp);
Mz2=F(12,cp);

%========================================================================
%Lokalni matice pocatecnich napeti
%========================================================================
%Constitutive Matrix
D=sparse(6,6);
D(1,1) = 1-v;
D(1,2) = v;
D(1,3) = v;
D(2,2) = 1-v;
D(2,3) = v;
D(3,3) = 1-v;
D(4,4) = (1-2*v)/2;
D(5,5) = (1-2*v)/2;
D(6,6) = (1-2*v)/2;
D1=D';
D = triu(D1.',1) + tril(D1);
D = D .* (E / ((1+v)*(1-2*v)));

if ( D(3, 3) ~= 0 )
    kappay = 6 * D(5, 5) / ( D(3, 3) * L * L );
else
    kappay = 0;
end

if ( D(2, 2) ~= 0 ) 
    kappaz = 6 * D(6, 6) / ( D(2, 2) * L * L );
else
    kappaz = 0;
end

Kg=zeros(12,12);
kappay2 = kappay * kappay;
kappaz2 = kappaz * kappaz;
denomy = ( 1. + 2. * kappay ) * ( 1. + 2. * kappay ); 
denomz = ( 1. + 2. * kappaz ) * ( 1. + 2. * kappaz );


Kg(2, 2) = ( 4. * kappaz2 + 4. * kappaz + 6. / 5. ) / denomz;
Kg(2, 6) = ( L / 10. ) / denomz;
Kg(2, 8) = ( -4. * kappaz2 - 4. * kappaz - 6. / 5. ) / denomz;
Kg(2, 12) = ( L / 10. ) / denomz;

Kg(3, 3) = ( 4. * kappay2 + 4. * kappay + 6. / 5. ) / denomy;
Kg(3, 5) = ( -L / 10. ) / denomy;
Kg(3, 9) = ( -4. * kappay2 - 4. * kappay - 6. / 5. ) / denomy;
Kg(3, 11) = ( -L / 10. ) / denomy;

Kg(5, 5) = L * L * ( kappay2 / 3. + kappay / 3. + 2. / 15. ) / denomy;
Kg(5, 9) = ( L / 10. ) / denomy;
Kg(5, 11) = -L * L * ( kappay2 / 3. + kappay / 3. + 1. / 30. ) / denomy;

Kg(6, 6) = L * L * ( kappaz2 / 3. + kappaz / 3. + 2. / 15. ) / denomz;
Kg(6, 8) = ( -L / 10. ) / denomz;
Kg(6, 12) = -L * L * ( kappaz2 / 3. + kappaz / 3. + 1. / 30. ) / denomz;

Kg(8, 8) = ( 4. * kappaz2 + 4. * kappaz + 6. / 5. ) / denomz;
Kg(8, 12) = ( -L / 10. ) / denomz;

Kg(9, 9) = ( 4. * kappay2 + 4. * kappay + 6. / 5. ) / denomy;
Kg(9, 11) = ( L / 10. ) / denomy;

Kg(11, 11) = L * L * ( kappay2 / 3. + kappay / 3. + 2. / 15. ) / denomy;
Kg(12, 12) = L * L * ( kappaz2 / 3. + kappaz / 3. + 2. / 15. ) / denomz;

minVal = min([Kg(2,2),Kg(3,3),Kg(5,5),Kg(6,6)])/1000;
Kg(1,1) = minVal;
Kg(1,7) = minVal;
Kg(7,7) = minVal;
Kg(4,4) = minVal;
Kg(4,10) = minVal;
Kg(10,10) = minVal;
Kg = Kg .* Fx2/L;



B1=Kg';
B = triu(B1.',1) + tril(B1);
Ksigma=B;
T=transformationMatrix.matrices{cp};
T_t=T';
Ksigma=T_t*Ksigma*T;
localGeometricMatrix{cp}=Ksigma;
%========================================================================
%Assembly
%========================================================================
kcisla=elements.codeNumbers(cp,:);
for i=1:12
    if kcisla(i)>0
        for j=1:12
            if kcisla(j)>0
            globalGeometrixMatrix(kcisla(i),kcisla(j))=globalGeometrixMatrix(kcisla(i),kcisla(j))+Ksigma(i,j);
            end
        end
    end
end
end
geometricMatrix.global =globalGeometrixMatrix;
geometricMatrix.local = localGeometricMatrix;
end