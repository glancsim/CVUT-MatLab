clear
close all
clc
addpath 'C:\GitHub\CVUT-MatLab\grant\functions\'
addpath 'C:\GitHub\CVUT-MatLab\Torri\trussFEM\'

%%%%%%%%%%%%%%%%%%
% Původní řešení
%%%%%%%%%%%%%%%%%%
P=[60;60;60;60;60;60;60];
nom = size(P,2); %number of members
[pastEig,pastVolume] = towerStabTorri_ex1Fn(P);

pastVolume=sum(P.*L);

%%%%%%%%%%%%%%%%%%%%%%%%%
%Omezení
%%%%%%%%%%%%%%%%%%%%%%%%%
radiusMin = 0.1;

%%%%%%%%%%%%%%%%%%%%%%%%%
%Optimalizační parametry
%%%%%%%%%%%%%%%%%%%%%%%%%
Tmax=0.01;
Tmin=0.01*Tmax;

succMax=50;
countMax=10*succMax;
iterMax=10000;

Tmult=(Tmin/Tmax)^(succMax/iterMax);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Nastavení hodnot výchozích parametrů
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T=Tmax;
refVolume=pastVolume/6;
iter=0;
while iter < iterMax
    succ=0;
    count=0;
    while count < countMax && succ < succMax
       iter=iter+1;
       count = count + 1;
       N = P + randn(1,nom);
       minNCnd = N < radiusMin;
       %If N is lower than radiusMin, then N=radiusMin
       if sum(minNCnd) > 0
           for i=1:nom
                if minNCnd(i) == 1
                    N(i) = radiusMin;
                end
           end
       end
       % Vypočtení nových vlastních čísel 
       new = globalStabTorri(N);
       newEig = min(new( new>=0 )); 
       %Vypočtení nového "objemu"
       newVolume=sum(N.*L);
       % cílová funkce
       fP = sqrt((1-pastEig)^2) + pastVolume/refVolume;
       if newEig < 1
            fN = (1/newEig)^2  + newVolume/refVolume;
       else
            fN = sqrt((1-newEig)^2) + newVolume/refVolume;
       end
       %Pravděpodobnos
       prob=exp((fP-fN)/T);
       if rand < prob
           succ = succ + 1;
           P = N;
           pastEig = newEig;
           if newVolume < refVolume
           refVolume = newVolume;
           end
           pastVolume = newVolume;
       end
    end
    T=T*Tmult;    
    %Kontrola teplot
%     disp('---');
    succ
    count
    iter
end

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
toc

