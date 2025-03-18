for run=1:2
clc
clear
% profile on

cd 'C:\GitHub\CVUT-MatLab\towerOptSA' 
addpath 'C:\GitHub\CVUT-MatLab\Resources'
crossSectionsSet.import = importdata("sectionsSet.mat");
crossSectionsSet.A = cat(1, table2array(crossSectionsSet.import.RHS(:,"A")), table2array(crossSectionsSet.import.L(:,"A")));
crossSectionsSet.Iy = cat(1, table2array(crossSectionsSet.import.RHS(:,"I_y")), table2array(crossSectionsSet.import.L(:,"I_y")));
crossSectionsSet.Iz = cat(1, table2array(crossSectionsSet.import.RHS(:,"I_z")), table2array(crossSectionsSet.import.L(:,"I_z")));
crossSectionsSet.Ip = cat(1, table2array(crossSectionsSet.import.RHS(:,"I_t")), table2array(crossSectionsSet.import.L(:,"I_t")));
nRhs = 9;
nL = 48;
P=[9;6;46];

nom = size(P,1); %number of members
[pastEig,pastVolume] = towerStabFn(P,crossSectionsSet)
%%%%%%%%%%%%%%%%%%%%%%%%%
%Optimalizační parametry
%%%%%%%%%%%%%%%%%%%%%%%%%
Tmax=1;
Tmin=0.01*Tmax;
% succMax=10;
succMax = 5;
countMax=10*succMax;
iterMax=20*countMax;
results = zeros(iterMax,6);

Tmult=(Tmin/Tmax)^(succMax/iterMax);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Nastavení hodnot výchozích parametrů 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    tic
    T=Tmax;
    refVolume=pastVolume;
    iter=0;
    while iter < iterMax
        succ=0;
        count=0;
        while count < countMax && succ < succMax
           iter=iter+1;
           count = count + 1;
           difL = ceil(1 + (iterMax-iter) * (10 - 1) / (iterMax));
           N = P + [randi([-1,1]);randi([-1,1]);randi([-difL,difL])]; % 10 procent - v závisloti na teplotě
           % Omezení na proměnné
           if N(1) > nRhs
               N(1) = nRhs;           
           end
           if N(1) < 1
               N(1) = 1;
           end
           if N(2) > nRhs
               N(2) = nRhs;         
           end
           if N(2) < 1
               N(2) = 1;
           end
           if N(3) > nRhs+nL
               N(3) = nRhs+nL;          
           end
           if N(3) < nRhs+1
               N(3) = nRhs+1;
           end
           % Vypočtení nových vlastních čísel 
           [newEig,newVolume] = towerStabFn(N,crossSectionsSet);
           % cílová funkce
           fP = sqrt((1-abs(pastEig))^2) + pastVolume/refVolume;
           if abs(newEig) < 1
                fN = (1/abs(newEig))^2  + newVolume/refVolume;
           else
                fN = sqrt((1-abs(newEig))^2) + newVolume/refVolume;
           end
           %Pravděpodobnost přijetí řešení
           prob=exp((fP-fN)/T);
           if rand < prob
                    test(iter) = 1;
                   succ = succ + 1;
                   P = N;
                   pastEig = newEig;
                if newVolume < refVolume && newEig >= 1
                   refVolume = newVolume;
                   bestSol = N;
                end
                pastVolume = newVolume;
                results(iter,:) = [N(1), N(2),N(3),refVolume,newVolume,newEig];
                fprintf('Iter: %5i \t S:%5i \t P:%5i \t D:%5.2i \t refVol:%7.3f  \t Vol:%7.3f \t Eig:%7.3f \t cond:%2i\n', iter, N(1),N(2),N(3), refVolume, newVolume, newEig, 1);
           else
               fprintf('Iter: %5i \t S:%5i \t P:%5i \t D:%5.2i \t refVol:%7.3f  \t Vol:%7.3f \t Eig:%7.3f \t cond:%2i\n', iter, N(1),N(2),N(3), refVolume, newVolume, newEig, 0);

           end

        end
        T=T*Tmult; 
        disp( ['Snížení teploty  T=  ', num2str(T), '  ----difL=  ', num2str(difL),'  -------------------'])
        toc
    end

    [bestEig, bestVolume] = towerStabFn(bestSol,crossSectionsSet)
    disp('Kritický součinitel')
    lambda = bestEig
    disp('Objem [dm3]')
    V = bestVolume
    disp('Průřezy')
    bestSol


    results(iter+1,:) = [bestSol(1), bestSol(2),bestSol(3),refVolume,bestVolume,bestEig];
    currentDateTime = datestr(now, 'yyyymmdd_HHMMSS');
    outputFilename = sprintf('SAoptimization_%s.mat', currentDateTime);
    save(outputFilename, 'results');
end