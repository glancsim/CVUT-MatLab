for run=1:10
clc
clear
% profile on

cd 'C:\GitHub\CVUT-MatLab\towerOptSA' 
addpath 'C:\GitHub\CVUT-MatLab\Resources'
crossSectionsSet.import = importdata("sectionsSetRHS.mat");
crossSectionsSet.A = cat(1, table2array(crossSectionsSet.import(:,"A")));
crossSectionsSet.Iy = cat(1, table2array(crossSectionsSet.import(:,"I_y")));
crossSectionsSet.Iz = cat(1, table2array(crossSectionsSet.import(:,"I_z")));
crossSectionsSet.Ip = cat(1, table2array(crossSectionsSet.import(:,"I_t")));
nRhs = numel(crossSectionsSet.A);
P=[9;9;9];

nom = size(P,1); %number of members
[pastEig,pastVolume] = towerStabFn_vol3(P,crossSectionsSet)
%%%%%%%%%%%%%%%%%%%%%%%%%
%Optimalizační parametry
%%%%%%%%%%%%%%%%%%%%%%%%%
Tmax=3;
Tmin=0.01*Tmax;
succMax=10;
% succMax = 5;
countMax=10*succMax;
% iterMax=10*countMax;
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
           difL = ceil(1 + (T-Tmin) * (nRhs/3 - 1) / (Tmax));
           N = P + [randi([-difL,difL]);...
                    randi([-difL,difL]);...
                    randi([-difL,difL]);...
                    randi([-difL,difL]);...
                    randi([-difL,difL]);...
                    randi([-difL,difL]);...
                    randi([-difL,difL]);...
                    randi([-difL,difL]);...
                    randi([-difL,difL]);...
                    randi([-difL,difL]);...
                    randi([-difL,difL]);...
                    randi([-difL,difL])]; % 10 procent - v závisloti na teplotě
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
           if N(3) > nRhs
               N(3) = nRhs;          
           end
           if N(3) < 1
               N(3) = 1;
           end
           % Vypočtení nových vlastních čísel 
           [newEig,newVolume] = towerStabFn_vol3(N,crossSectionsSet);
           % cílová funkce
           fP = sqrt((1-abs(pastEig))^2) + (pastVolume/refVolume)^2;;
           if abs(newEig) < 1
                fN = (1/abs(newEig))^2  + (newVolume/refVolume)^2;
           else
                fN = sqrt((1-abs(newEig))^2) + (newVolume/refVolume)^2;
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
                fprintf('Iter: %5i \t A:%5i %5i %5i \t refVol:%7.3f  \t Vol:%7.3f \t Eig:%7.3f \t cond:%2i\n', iter, N(1),N(2),N(3), refVolume, newVolume, newEig, 1);
           else
               fprintf('Iter: %5i \t A:%5i %5i %5i \t refVol:%7.3f  \t Vol:%7.3f \t Eig:%7.3f \t cond:%2i\n', iter, N(1),N(2),N(3), refVolume, newVolume, newEig, 0);

           end

        end
        T=T*Tmult; 
        disp( ['Snížení teploty  T=  ', num2str(T), '  ----difL=  ', num2str(difL),'  -------------------'])
        toc
    end

    [bestEig, bestVolume] = towerStabFn_vol3(bestSol,crossSectionsSet)
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