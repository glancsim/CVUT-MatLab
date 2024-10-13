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
iter = 1;
for A1 = 1:9
    for A2 = 1:9
        for A3 = 1:9
            P=[A1;A2;A3];
            [eigValue,volume] = towerStabFn_vol2(P,crossSectionsSet);
            results(iter,:) = [A1, A2, A3,volume,eigValue];
            fprintf('Iter: %5i \t A:%5i %5i %5i \t Vol:%7.3f \t Eig:%7.3f\n', iter, A1, A2, A3, volume, eigValue);
            iter = iter + 1;
        end
    end
end
currentDateTime = datestr(now, 'yyyymmdd_HHMMSS');
outputFilename = sprintf('HS_%s.mat', currentDateTime);
save(outputFilename, 'results');
