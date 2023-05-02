clc
clear
addpath('Funkce')
% for test=1:10
%%%%%%%%%%%%%%%%%%%%%%%%%
% Optimalizované řešení
%%%%%%%%%%%%%%%%%%%%%%%%%
% P =[61.4599   57.5023    0.1000    5.9437    0.1000   62.6488    3.8066]
ModulMatrix =  [1 0 0 0 0 1 0 0 0 0;...
                0 1 1 0 1 0 1 1 0 1;...
                0 0 0 1 0 0 0 0 1 0]; 
%%%%%%%%%%%%%%%%%%
% Původní řešení
%%%%%%%%%%%%%%%%%%
P=[60 60 60];
nom = size(P,2); %number of members
L=[4 5.65685425 5.65685425 4.000 4.000 4 5.65685425 5.65685425 4.000 4.000];
Ldiag=2*5.65685425 + 4;
Lhpasn=4;
Ldpasn=4;
Lmodul(1,1)=Lhpasn;
Lmodul(1,2)=Ldiag;
Lmodul(1,3)=Ldpasn;
past = globalStabTorriModul_3parts(P);
pastEig = min(past( past >=0 ));
sumP=sum(P.*Lmodul);

%%%%%%%%%%%%%%%%%%%%%%%%%
%Omezení
%%%%%%%%%%%%%%%%%%%%%%%%%
radiusMin = 0.1;

%%%%%%%%%%%%%%%%%%%%%%%%%
%Optimalizační parametry
%%%%%%%%%%%%%%%%%%%%%%%%%
Tmax=0.05;
Tmin=0.0000003*Tmax;

succMax=50;
countMax=10*succMax;
iterMax=10000;

Tmult=(Tmin/Tmax)^(succMax/iterMax);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Nastavení hodnot výchozích parametrů
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T=Tmax;
sumREF=sum(P.*Lmodul);
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
       new = globalStabTorriModul_3parts(N);
       newEig = min(new( new>=0 )); 
       %Vypočtení nového "objemu"
       sumN=sum(P.*Lmodul);
       % cílová funkce
       fP = sqrt((1-pastEig)^2) + sumP/sumREF;
       if newEig < 1
            fN = (1/newEig)^2  + sumN/sumREF;
       else
            fN = sqrt((1-newEig)^2) + sumN/sumREF;
       end
       %Pravděpodobnost
       prob=exp((fP-fN)/T);
       if rand < prob
           succ = succ + 1;
           P = N;
           pastEig = newEig;
           if sumN < sumP
           sumREF = sumN;
           end
           sumP = sumN;
       end
    end
    T=T*Tmult;    
    %Kontrola teplot
    disp('---')
    succ
    count
    iter
end

ro=P*ModulMatrix;
ri=0.9*ro;
S=zeros(1,10);
for k=1:10
S(k)=pi()*ro(k)^2-pi()*ri(k)^2;
end
V=0;
for k=1:10
V=V+S(k)*L(k);
end
V=V*0.001;
disp('Kritický součinitel')
lambda=pastEig
disp('Vnější poloměr [mm]')
P
disp('Objem [dm3]')
V
% end
