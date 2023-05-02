% Globalni stabilita
%
% In: 
%   ro - vnější průměr prutu
%
% Out:
%   elementVectorXY - vektor v rovině XY pro jednotlivé elementy     
%
% (c) S. Glanc, 2022

function [vl_cisla]=globalStabTorriModul_3parts(ro)
% addpath('Funkce')
%========================================================================
%Průřezové parametry
%========================================================================
prurez=[1,2,2,3,2,1,2,2,3,2];%prurezove char. dle typu prutu: pozice=cislo prutu -> 1=A_prut(1)atd..
sizePrurez=max(prurez);

for th=1:sizePrurez
ri(th)=ro(th)*0.9;
end

%========================================================================
% Prurez 1 v mmm
%========================================================================
for prz=1:sizePrurez
A_prut(prz)=pi()*ro(prz)^2-pi()*ri(prz)^2;%mm2
Iy_prut(prz)=pi()/4*ro(prz)^4-pi()/4*ri(prz)^4; %mm4
Iz_prut(prz)=pi()/4*ro(prz)^4-pi()/4*ri(prz)^4; %mm4
Ip_prut(prz)=pi()/2*(ro(prz)^4-ri(prz)^4); %mm4
end
%========================================================================
% Prevod jednotek
%========================================================================
A_prut=A_prut*10^-6;
Iy_prut=Iy_prut*10^-12;
Iz_prut=Iz_prut*10^-12;
Ip_prut=Ip_prut*10^-12;


%========================================================================
%Materiálové parametry
%========================================================================
v=0.3;
E=210*10^9; %Pa

%========================================================================
%Parametry konstrukce
%========================================================================

dp=2; %deleni jednotlivych prutu 
pointA=[0,4,0];
pointB=[4,4,0];
pointC=[0,0,0];
pointD=[4,0,0];
pointE=[8,0,0];

vektor_prutu=   [pointD-pointC, dp;...
                pointB-pointC, dp;...
                pointD-pointA, dp;...%vektor prutů
                pointB-pointA, dp;...
                pointB-pointD, dp;...
                pointE-pointD, dp;...
                pointE-pointB, dp];
        
vektor_XY= [0 1 0;...
            0 1 0;...
            0 1 0;...%vektor prutů
            0 1 0;...
            -1 0 0;...
            0 1 0;...
            0 1 0];      
[pp,nn]=size(vektor_prutu);   %pocet prutu

kc_stycniku=[   0 0 0 0 0 0 1 2 3 4 5 6;...
                0 0 0 0 0 0 7 8 9 10 11 12;...%kódová čísla prutů
                0 0 0 0 0 0 1 2 3 4 5 6;...
                0 0 0 0 0 0 7 8 9 10 11 12;...
                1 2 3 4 5 6 7 8 9 10 11 12;...
                1 2 3 4 5 6 13 14 15 16 17 18;...
                7 8 9 10 11 12 13 14 15 16 17 18];
                
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
f_global(14)=-150*1000;

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
% disp('Součinitel kritického zatížení')
% disp([num2str(prvni_vlastni_cislo),' N'])
end
                              
