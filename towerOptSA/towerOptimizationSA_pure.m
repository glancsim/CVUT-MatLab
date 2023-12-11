clc
clear
% profile on

cd 'C:\GitHub\CVUT-MatLab\towerOptSA' 
addpath 'C:\GitHub\CVUT-MatLab\Resources'
disp(['i      ','A1     ', 'A2      ', 'A3      ','refV          ','newV          ','eig          ','OK',])
nRhs = 9;
nL = 54;
P=[nRhs;nRhs+nL;nRhs+nL];

nom = size(P,1); %number of members
[pastEig,pastVolume] = towerStabFn(P);

%%%%%%%%%%%%%%%%%%%%%%%%%
%Optimalizační parametry
%%%%%%%%%%%%%%%%%%%%%%%%%
Tmax=0.5;
Tmin=0.01*Tmax;

succMax=100;
% succMax = 5;
countMax=10*succMax;
iterMax=20*countMax;

Tmult=(Tmin/Tmax)^(succMax/iterMax);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Nastavení hodnot výchozích parametrů 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T=Tmax;
refVolume=pastVolume;
iter=0;
while iter < iterMax
    tic
    succ=0;
    count=0;
    while count < countMax && succ < succMax
       iter=iter+1;
       count = count + 1;
       N = P + [randi([-1,1]);randi([-2,2]);randi([-2,2])];
       % Omezení na proměnné
       if N(1) > nRhs
           N(1) = nRhs;           
       end
       if N(1) < 1
           N(1) = 1;
       end
       if N(2) > nRhs+nL
           N(2) = nRhs+nL;         
       end
       if N(2) < nRhs+1
           N(2) = nRhs+1;
       end
       if N(3) > nRhs+nL
           N(3) = nRhs+nL;          
       end
       if N(3) < nRhs+1
           N(3) = nRhs+1;
       end
       % Vypočtení nových vlastních čísel 
       [newEig,newVolume] = towerStabFn(N);
       % cílová funkce
       fP = sqrt((1-abs(pastEig))^2) + pastVolume/refVolume;
       if abs(newEig) < 1
            fN = (1/abs(newEig))^2  + newVolume/refVolume;
       else
            fN = sqrt((1-abs(newEig))^2) + newVolume/refVolume;
       end
       %Pravděpodobnos
       prob=exp((fP-fN)/T);
       if rand < prob
               succ = succ + 1;
               P = N;
               pastEig = newEig;
            if newVolume < refVolume && abs(newEig) >=1
               refVolume = newVolume;
               bestSol = N;
            end
            pastVolume = newVolume;
            results(iter,:) = [N(1), N(2),N(3),refVolume,newVolume,newEig];
            disp([num2str(iter), '      ', num2str(N(1)), '      ', num2str(N(2)), '      ', num2str(N(3)), '      ', num2str(refVolume), '      ', num2str(newVolume), '      ', num2str(newEig), '      ', 'OK']);

       else
            disp([num2str(iter), '      ', num2str(N(1)), '      ', num2str(N(2)), '      ', num2str(N(3)), '      ', num2str(refVolume), '      ', num2str(newVolume), '      ', num2str(newEig), '      ', 'X']);
       end

    end
    T=T*Tmult; 
    disp( ['Snížení teploty  T=', num2str(T), '-----------------------------------------------------'])
    %Kontrola teplot
%     disp('---')
%     succ
%     count
%     iter
       toc
end

[bestEig, bestVolume] = towerStabFn(bestSol)
disp('Kritický součinitel')
lambda = bestEig
disp('Objem [dm3]')
V = bestVolume
% profile viewer
results(iter+1,:) = [bestSol(1), bestSol(2),bestSol(3),refVolume,bestVolume,bestEig];
% end