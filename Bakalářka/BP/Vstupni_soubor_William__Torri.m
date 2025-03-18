clear
addpath('Funkce')
%========================================================================
%Průřezové parametry
%========================================================================
ro(1)=40; %mm  vnější polomer
ro(2)=40; %mm  vnější polomer
ro(3)=40; %mm  vnější polomer
ro(4)=40; %mm  vnější polomer
ro(5)=40; %mm  vnější polomer
ro(6)=40; %mm  vnější polomer

thTube=5

prurez=[1,2,3,4,5,6];%prurezove char. dle typu prutu: pozice=cislo prutu -> 1=A_prut(1)atd..
sizePrurez=size(prurez,2);

for th=1:sizePrurez
ri(th)=ro(th)-thTube;
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

dp=16; %deleni jednotlivych prutu 

vektor_prutu= [2 0 0 dp;...
            2 -2 0 dp;...
            2 0 0 dp;...%vektor prutů
            0 2 0 dp;...
            2 0 0 dp;...
            2 2 0 dp];
        
vektor_XY= [0 1 0;...
            0 1 0;...
            0 1 0;...%vektor prutů
            -1 0 0;...
            0 1 0;...
            0 1 0];      
[pp,nn]=size(vektor_prutu);   %pocet prutu
clear var nn

kc_stycniku=[0 0 0 0 0 0 1 2 3 4 5 6;...
            0 0 0 0 0 0 1 2 3 4 5 6;...
            0 0 0 0 0 0 7 8 9 10 11 12;...%kódová čísla prutů
            1 2 3 4 5 6 7 8 9 10 11 12;...
            7 8 9 10 11 12 13 14 15 16 17 18;...
            1 2 3 4 5 6 13 14 15 16 17 18;];
                
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
f_global(14)=-1;

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
                    vektorXY_elem...
                    ro
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
sortedEigenValues = sortVectorAbs(vl_cisla);
disp('První kritické břemeno')
disp([num2str(sortedEigenValues(1)/1000),' kN'])
disp('Druhé kritické břemeno')
disp([num2str(sortedEigenValues(2)/1000),' kN'])
disp('Třetí kritické břemeno')
disp([num2str(sortedEigenValues(3)/1000),' kN'])

%==========================================================================
%Tisk výsledků
%==========================================================================
% disp('Součinitel kritického zatížení')
% disp([num2str(prvni_vlastni_cislo),' N'])
% pos = find(vl_cisla==prvni_vlastni_cislo) 
% vlastni_tvar=tvar(:,pos)
% neznama_premisteni=vlastni_tvar(1:18,:)
                              