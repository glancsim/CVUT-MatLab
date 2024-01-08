for run=1:10
tic
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
P=[7;	6;  6;	7;	6;	6;	7;	6;	6;	7;	6;	6];
% P=[6;	9;	7;	8;	3;	5;	6;	4;	4;	3;	1;	5];
nom = size(P,1); %number of members
[pastEig,pastVolume] = towerStabFn_vol3(P,crossSectionsSet)
%%%%%%%%%%%%%%%%%%%%%%%%%
%Optimalizační parametry
%%%%%%%%%%%%%%%%%%%%%%%%%
Tmax=4;
Tmin=0.01*Tmax;
% succMax=2;
succMax = 5;
countMax=10*succMax;
% iterMax=10*countMax;
iterMax=20*countMax;
results = zeros(iterMax,15);

Tmult=(Tmin/Tmax)^(succMax/iterMax);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Nastavení hodnot výchozích parametrů 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    tic
    T=Tmax;
    refVolume=pastVolume;
    iter=0;
fP = (1/abs(pastEig))^2 + pastVolume/refVolume;
    while iter < iterMax
        succ=0;
        count=0;
        while count < countMax && succ < succMax
           iter=iter+1;
           count = count + 1;
           difL = floor(1 + (T-Tmin) * (3 - 1) / (Tmax));
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
            [sizeN,~] = size(N);
           for k = 1:sizeN
               if N(k) > nRhs
                   N(k) = nRhs;           
               end
               if N(k) < 1
                   N(k) = 1;           
               end
           end

           % Vypočtení nových vlastních čísel 
           [newEig,newVolume] = towerStabFn_vol3(N,crossSectionsSet);
           % cílová funkce
           if abs(newEig) < 1
                fN = (1/abs(newEig))^2  + newVolume/refVolume;
           else
                fN = sqrt((1-abs(newEig))^2) + newVolume/refVolume;
           end
           %Pravděpodobnost přijetí řešení
           prob=exp((fP-fN)/T);
           if rand < prob
%                    test(iter) = 1;
                   succ = succ + 1;
                   P = N;
%                    pastEig = newEig;
                   fP = fN;
                if newVolume < refVolume && newEig >= 1
                   refVolume = newVolume;
                   bestSol = N;
                end
                pastVolume = newVolume;
                results(iter,:) = [ N(1),N(2),N(3),N(4),N(5),N(6),N(7),N(8),N(9),N(10),N(11),N(12),refVolume,newVolume,newEig];
                fprintf('Iter: %5i \t A:%5i %5i %5i %5i %5i %5i %5i %5i %5i %5i %5i %5i \t refVol:%7.3f  \t Vol:%7.3f \t Eig:%7.3f \t cond:%2i\n', iter, N(1),N(2),N(3),N(4),N(5),N(6),N(7),N(8),N(9),N(10),N(11),N(12), refVolume, newVolume, newEig, 1);
           else
               fprintf('Iter: %5i \t A:%5i %5i %5i %5i %5i %5i %5i %5i %5i %5i %5i %5i \t refVol:%7.3f  \t Vol:%7.3f \t Eig:%7.3f \t cond:%2i\n', iter, N(1),N(2),N(3),N(4),N(5),N(6),N(7),N(8),N(9),N(10),N(11),N(12), refVolume, newVolume, newEig, 0);

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


    results(iter+1,:) = [bestSol(1),bestSol(2),bestSol(3),bestSol(4),bestSol(5),bestSol(6),bestSol(7),bestSol(8),bestSol(9),bestSol(10),bestSol(11),bestSol(12),refVolume,bestVolume,bestEig];
    currentDateTime = datestr(now, 'yyyymmdd_HHMMSS');
    outputFilename = sprintf('SAoptimization_%s.mat', currentDateTime);
    save(outputFilename, 'results');
    toc
end