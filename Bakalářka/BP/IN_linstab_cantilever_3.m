clear
clc

addpath('Funkce')
% addpath('matrix')
%========================================================================
%Průřezové parametry
%========================================================================
A_prut(1)=1;%m2
Iy_prut(1)=0.5; %m4
Iz_prut(1)=0.5; %m4
Ip_prut(1)=2; %m4;
%========================================================================
prurez=[1,1];%prurezove char. dle typu prutu: pozice=cislo prutu -> 1=A_prut(1)atd..
%========================================================================
%========================================================================
%Materiálové parametry
%========================================================================
v=0.5;
E=100; %Pa
%========================================================================
%Parametry konstrukce
%========================================================================
dp=1; %deleni jednotlivych prutu 

vektor_prutu=   [0 10 0 dp;...
                 0 10 0 dp];
vektor_XY= [1 0 0;...
            1 0 0]; 
[pp,nn]=size(vektor_prutu);   %pocet prutu
clear var nn

kc_stycniku=[0 0 0 0 0 0 1 2 3 4 5 6;...
             1 2 3 4 5 6 7 8 9 10 11 12];   
pn_stycniku=max(max(kc_stycniku));
psv=6; %posuny a pootoceni ve stycniku pro 2D=3, pro 3D=6
sv=2*psv; %stupne volnosti prutu
ne=pp*dp; %pocet elementu

%========================================================================
%Parametry průřezů - přidělení průřezů jednotlivým prutům 
%========================================================================
A=prtoel(A_prut,pp,dp,prurez);
Iy=prtoel(Iy_prut,pp,dp,prurez);
Iz=prtoel(Iz_prut,pp,dp,prurez);
Ip=prtoel(Ip_prut,pp,dp,prurez);

%========================================================================
%Parametry prutů - vytvoreni kódových čísel a vektorů jednotlivých prutů
%========================================================================
[kc,vektor_elem]=diskprut(pn_stycniku,vektor_prutu,kc_stycniku,dp,pp);
pn=max(max(kc));
[vektorXY_elem]=XYtoel(pp,dp,vektor_XY);

%==========================================================================
%Globalni sily ve stycniku
%==========================================================================
f_global=zeros(pn,1);
f_global(7)=-1;
f_global(8)=-1;
f_global(9)=-1;
f_global(10)=-1;
f_global(11)=-1;
f_global(12)=-1;
%========================================================================
%Vymazani pameti
%========================================================================
clearvars -except   f_global... 
                    E ... 
                    Ip ... 
                    Iy ... 
                    Iz ... 
                    v ... 
                    A ... 
                    psv ... 
                    vektor_elem... 
                    kc... 
                    pn... 
                    sv... 
                    pp... 
                    ne... 
                    f_global... 
                    vektorXY_elem
%==========================================================================
%Transformacni matice
%==========================================================================
[L_all,T_cell]=transfM(vektor_elem,vektorXY_elem,sv,ne);

%==========================================================================
%Matice tuhosti lokalni a globalni
%==========================================================================
[K_local,K_global]=stiffnessM(A,Iy,Iz,Ip,T_cell,L_all,v,E,ne,pn,kc,sv);

%==========================================================================
%Vypocet vnitrrnich sil
%==========================================================================
[f_local]=EndForces(K_global,K_local,f_global,T_cell,sv,ne,pn,kc);

%==========================================================================
%Geometricka_matice
%==========================================================================
[Ksigma_local,Ksigma_global]=geometricMoofemFn(A,Ip,T_cell,L_all,f_local,pn,ne,kc,sv);

%==========================================================================
%Kriticke bremeno a vlastni tvary
%==========================================================================
[eigVec,eigVal,critLoad]=CriticalLoad(K_global,Ksigma_global);  
%==========================================================================
%Tisk výsledků
%==========================================================================
[sorEigVal,sorEigVec] = sortEigVec(eigVal,eigVec);
disp('První vlastní číslo')
disp([num2str(sorEigVal(1)),' N'])
% disp('Tvar pro první vlastní číslo')
% disp([num2str(sorEigVec(:,1))])

disp('Druhé vlastní číslo')
disp([num2str(sorEigVal(2)),' N'])
% disp('Tvar pro druhé vlastní číslo')
% disp([num2str(sorEigVec(:,1))])

disp('Třetí vlastní číslo')
disp([num2str(sorEigVal(3)),' N'])
% disp('Tvar pro třetí vlastní číslo')
% disp([num2str(sorEigVec(:,2))])
