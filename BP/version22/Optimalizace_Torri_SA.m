clc
clear
%Původní zadání
% ro(1)=69.3747;
% ro(2)=51.0872;
% ro(3)=1.6177;
% ro(4)=6.0485;
% ro(5)=0.3833;
% ro(6)=65.3047;
% ro(7)=4.9856;
ro(1)=50;
ro(2)=50;
ro(3)=50;
ro(4)=50;
ro(5)=50;
ro(6)=50;
ro(7)=50;
addpath('Funkce')
past = globalStabTorri(ro);
pastEig = min(past( past>=0 ));
%Délka prutů
L=zeros(7);    
vektor_prutu=[4,0,0;4,4,0;4,-4,0;4,0,0;0,4,0;4,0,0;4,-4,0];
for k=1:7
L(k)=sqrt(vektor_prutu(k,1)^2+vektor_prutu(k,2)^2+vektor_prutu(k,3)^2)*1000;
end

%Optimalizace
tic

P=[60 60 60 60 60 60 60];
Tmax=0.02;
Tmin=0.0001*Tmax;
T=Tmax;
succMax=50;
countMax=10*succMax;
count=0;
sumAll = sum(sum(P.*L));
succ=0
iter=0
iterMax = 10000
Tmult=(Tmin/Tmax)^(succMax/iterMax);
while iter < iterMax
    count=0;
    succ=0;
    while count<countMax && succ<succMax
        iter=iter+1 ;
        count=count+1;
        N = P-randn(1,7);
        %If N is lower than 0.1, change the value to 0.1--------------------
        Return_to_domain = N < 1;
        SumDomain=sum(Return_to_domain);
        DimDomain = size(Return_to_domain,2);
        if SumDomain > 0
            for k = 1:DimDomain
                if Return_to_domain(k) <= 0 
                    N(k) = 1 ;
                end
            end
        end
        %------------------------------------------------------------------
        sumN = sum(sum(N.*L));
        sumP = sum(sum(P.*L));
        sumREF = min(sumAll);
        new = globalStabTorri(N);
        newEig = min(new( new>=0 ));  
        past = globalStabTorri(P);
        pastEig = min(past( past>=0 ));
        pokusEig(iter)=newEig;
        if newEig < 1
            n=(1/newEig)^2+ sumN/(sumREF+sumN);
            sumAll(iter) = sumP;
        else
            n=sqrt((1-newEig)^2) + sumN/(sumREF+sumN) ;
            sumAll(iter) = sumN;
        end
        q=sqrt((1-pastEig)^2) + sumP/(sumREF+sumP) ;
        p=exp((q-n)/T);        
        if rand < p
            succ=succ+1;
            P=N;
        end
    end
    T=T*Tmult;
    disp('---')
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
P
for k=1:7
V=V+S(k)*L(k);
end

VResult=V*0.001
% Pokus= pokusEig < 1;
% sum(Pokus)
toc
