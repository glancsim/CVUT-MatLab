clc
clear
%%%%%%%%%%%%%%%%%%%%%%%%%
% Optimalizované řešení
%%%%%%%%%%%%%%%%%%%%%%%%%
% P =[62   58    0.1000    5    0.1000   62    5]
P =[600   600   0.1    40.87    0.1000   600.18    40.126]


addpath('Funkce')
%%%%%%%%%%%%%%%%%%
% Původní řešení
%%%%%%%%%%%%%%%%%%
% P=[60 60 60 60 60 60 60];
nom = size(P,2); %number of members
L=[4 5.65685425 5.65685425 4.000 4.000 4.000 5.65685425];
past = globalStabTorri(P);
pastEig = min(past( past >=0 ));
ro=P;
ri=0.9*P;
S=zeros(1,7);
for k=1:7
S(k)=pi()*ro(k)^2-pi()*ri(k)^2;
end
V=0;
for k=1:7
V=V+S(k)*L(k);
end
V=V*0.001;
disp('Kritický součinitel')
lambda=pastEig
disp('Vnější poloměr [mm]')
P
disp('Objem [dm3]')
V