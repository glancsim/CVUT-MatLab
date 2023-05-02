clear
addpath('Funkce')
%Průřezové parametry
%========================================================================
crossection.ro(1)=40;   %mm  vnější polomer
crossection.ro(2)=40;   %mm  vnější polomer
crossection.ro(3)=40;   %mm  vnější polomer
crossection.ro(4)=40;   %mm  vnější polomer
crossection.ro(5)=40;   %mm  vnější polomer
crossection.ro(6)=40;   %mm  vnější polomer
crossection.thTube=5;   %mm

crossection.id = [1,2,3,4,5,6];

for th=1:size(crossection.id,2)
crossection.ri(th)=crossection.ro(th)-crossection.thTube;
end

for i=1:size(crossection.id,2)
beam.crossection_A(i)=pi()*crossection.ro(i)^2-pi()*crossection.ri(i)^2;%mm2
beam.crossection_Iy(i)=pi()/4*crossection.ro(i)^4-pi()/4*crossection.ri(i)^4; %mm4
beam.crossection_Iz(i)=pi()/4*crossection.ro(i)^4-pi()/4*crossection.ri(i)^4; %mm4
beam.crossection_Ik(i)=pi()/2*(crossection.ro(i)^4-crossection.ri(i)^4); %mm4
end
beam.crossection_A=beam.crossection_A*10^-6;
beam.crossection_Iy=beam.crossection_Iy*10^-12;
beam.crossection_Iz=beam.crossection_Iz*10^-12; 
beam.crossection_Ik=beam.crossection_Ik*10^-12;

%Materiálové parametry
%========================================================================
v=0.3;
E=210*10^9; %Pa

%Parametry konstrukce
%========================================================================
nodes.x = [ 0; 2; 0; 2; 4 ];                        % x coordinates of nodes
nodes.y = [ 0; 0; 2; 2; 2 ];                        % y coordinates of nodes
nodes.z = [ 0; 0; 0; 0; 0 ];                        % z coordinates of nodes
nodes.nnodes = numel(nodes.x);                            % number of nodes 
nodes.dimdofs = 6;
nodes.dofs =    [   0 0 0 0 0 0;...
                    1 1 1 1 1 1;...
                    0 0 0 0 0 0;...
                    1 1 1 1 1 1;...
                    1 1 1 1 1 1;...
                    1 1 1 1 1 1];

beam.nodes1         = [1; 3; 3; 2; 4; 2 ];          % elements starting nodes
beam.nodes2         = [2; 2; 4; 4; 5; 5 ];          % elements ending nodes
beam.disc           = 16;


%Zatížení konstrukce
%========================================================================
load.dir = [14];
load.value = [-1];
load.nload = size(load,2);


%========================================================================
%==========================Výpočet=======================================
%========================================================================
beam.nbeam          = numel(beam.nodes1);
beam.vertex         = beamVertex(beam,nodes);
beam.XY             = beamXY(beam,nodes);
beam.dimdofs        = nodes.dimdofs * 2;
beam.codeNumbers    = codeNumb (beam,nodes);
nodes.ndofs=max(max(beam.codeNumbers));
element.nelement=beam.nbeam*beam.disc; %pocet elementu

%========================================================================
%Parametry průřezů - přidělení průřezů jednotlivým prutům 
%========================================================================
element.crossection_A=prtoel(beam.crossection_A,beam.nbeam,beam.disc,crossection.id);
element.crossection_Iy=prtoel(beam.crossection_Iy,beam.nbeam,beam.disc,crossection.id);
element.crossection_Iz=prtoel(beam.crossection_Iz,beam.nbeam,beam.disc,crossection.id);
element.crossection_Ik=prtoel(beam.crossection_Ik,beam.nbeam,beam.disc,crossection.id);

%========================================================================
%Parametry prutů - vytvoreni kódových čísel a vektorů jednotlivých prutů
%========================================================================
[element.codeNumbers,element.vertex]=diskprut(nodes.ndofs,beam.vertex,beam.codeNumbers,beam.disc,beam.nbeam);
element.ndofs=max(max(element.codeNumbers));
[vektorXY_elem]=XYtoel(beam.nbeam,beam.disc,beam.XY);

%==========================================================================
%Globalni sily ve stycniku
%==========================================================================
f_global=zeros(element.ndofs,1);
for i = 1:load.nload
    f_global(load.dir(i))=load.value(i);
end

%==========================================================================
%Transformacni matice
%==========================================================================
[L_all,T_cell]=transfM(element.vertex,vektorXY_elem,beam.dimdofs,element.nelement);

%==========================================================================
%Matice tuhosti lokalni a globalni
%==========================================================================
[K_local,K_global]=stiffnessM(element.crossection_A,element.crossection_Iy,element.crossection_Iz,element.crossection_Ik,T_cell,L_all,v,E,element.nelement,element.ndofs,element.codeNumbers,beam.dimdofs);

%==========================================================================
%Vypocet vnitrrnich sil
%==========================================================================
[f_local]=EndForces(K_global,K_local,f_global,T_cell,beam.dimdofs,element.nelement,element.ndofs,element.codeNumbers);

%==========================================================================
%Geometricka_matice
%==========================================================================
[Ksigma_local,Ksigma_global]=geometricM(element.crossection_A,element.crossection_Ik,T_cell,L_all,f_local,element.ndofs,element.nelement,element.codeNumbers,beam.dimdofs);

%==========================================================================
%Kriticke bremeno a vlastni tvary
%==========================================================================
[eigVec,eigVal,prvni_vlastni_cislo]=CriticalLoad(K_global,Ksigma_global);  
%==========================================================================
%Tisk výsledků
%==========================================================================
[sorEigVal,sorEigVec] = sortEigVec(eigVal,eigVec);
disp('První kritické břemeno')
disp([num2str(sorEigVal(1)/1000),' kN'])
disp('Druhé kritické břemeno')
disp([num2str(sorEigVal(2)/1000),' kN'])
disp('Třetí kritické břemeno')
disp([num2str(sorEigVal(3)/1000),' kN'])

                              