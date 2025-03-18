clear
addpath('Funkce')
%========================================================================
%Postup:
%       1) Vytvoreni matice tuhosti a transformacni matice
%       2) Vypocet vnitrnich sil od jednotkoveho zatizeni
%       3) Sestaveni matice pocatecnich napeti 
%       4) Vypocet kritickeho bremena a vlastnich tvaru kce
%========================================================================

%========================================================================
%Průřezové parametry
%========================================================================

%========================================================================
% Prurez 1 v mmm
%========================================================================
A_prut(1)=2.5*10^4; %mm2
Iy_prut(1)=6.36*10^8; %mm4
Iz_prut(1)=Iy_prut(1); %mm4
Ip_prut(1)=Iy_prut(1)*2; %mm4
%========================================================================
% Prurez 2 v mm
%========================================================================
A_prut(2)=1.76*10^4; %mm2
Iy_prut(2)=8.61*10^8; %mm4
Iz_prut(2)=Iy_prut(2); %mm4
Ip_prut(2)=Iy_prut(2)*2; %mm4
%========================================================================
% Prurez 3 v mm
%========================================================================
A_prut(3)=1.76*10^4; %mm2
Iy_prut(3)=3.18*10^8; %mm4
Iz_prut(3)=Iy_prut(2); %mm4
Ip_prut(3)=Iy_prut(2)*2; %mm4
%========================================================================
% Prevod jednotek
%========================================================================
A_prut=A_prut.*10^-6;
Iy_prut=Iy_prut.*10^-12;
Iz_prut=Iz_prut.*10^-12;
Ip_prut=Ip_prut.*10^-12;
%========================================================================
prurez=[1,2,3];%prurezove char. dle typu prutu: pozice=cislo prutu -> 1=A_prut(1)atd..
%========================================================================
%========================================================================
%Materiálové parametry
%========================================================================
v=0.3;
E=200*10^9; %Pa

%========================================================================
%Parametry konstrukce
%========================================================================

dp=4; %deleni jednotlivych prutu 

aa=[0 0 0];
bb=[0 5 0];
cc=[4 5 0];
dd=[4 0 0];

vektor_prutu=  [aa-bb dp;...
             bb-cc dp;...
             cc-dd dp]; 
vektor_XY= [-1 0 0;...
            0 1 0;...
           -1 0 0];          
[pp,nn]=size(vektor_prutu);   %pocet prutu
clear var nn

kc_stycniku=[0 0 0 0 0 1 2 3 4 5 6 7;...
             2 3 4 5 6 7 8 9 10 11 12 13;...
             8 9 10 11 12 13 0 0 0 0 0 14];  
         
pn_stycniku=max(max(kc_stycniku));
psv=6; %posuny a pootoceni ve stycniku pro 2D=3, pro 3D=6
sv=2*psv; %stupně volnosti prutu 
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
f_global(3)=-0*1000;
f_global(9)=-2000*1000;



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
[Ksigma_local,Ksigma_global]=geometricM(A,Ip,T_cell,L_all,f_local,pn,ne,kc,sv);

%==========================================================================
%Kriticke bremeno a vlastni tvary
%==========================================================================
[tvar,vl_cisla,prvni_vlastni_cislo]=CriticalLoad(K_global,Ksigma_global);  

%==========================================================================
%Tisk výsledků
%==========================================================================
disp('Součinitel kritického zatížení')
disp([num2str(prvni_vlastni_cislo),' N'])
                    