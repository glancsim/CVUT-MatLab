% Vytvoření lokálních a globálních matic počátečních napětí
% Implementace dle OOFEM: Beam3d::computeInitialStressMatrix (beam3d.C, řádky 831-896)
%
% Klíčové rysy oproti obecné geometrické matici:
%   - Pouze příspěvek axiální síly N (žádné momenty My, Mz, Mx)
%   - Axiální a torzní DOF (1,7 a 4,10) nahrazeny numerickou stabilizací: minVal/1000
%   - minVal = min ze čtyř ohybových diagonálních členů (2,2), (3,3), (5,5), (6,6)
%   - Matice se nejdříve sestaví normalizovaně, pak se vynásobí N/L
%   - kappa = 0 (Euler-Bernoulli, konzistentní s maticí tuhosti)
%
% In:
%   surfaceArea             - plocha průřezu (nepoužívá se přímo, zachováno pro API)
%   polarMomentOfInertiaX   - torzní moment setrvačnosti (nepoužívá se přímo, zachováno pro API)
%   transformationMatrix    - transformační matice pro jednotlivé elementy (cell)
%   elementLength           - délky elementů
%   localEndForces          - lokální vnitřní síly (12 x nelement)
%   numberOfUnknownForces   - počet stupňů volnosti (ndofs)
%   numberOfElements        - počet elementů
%   elementsCodeNumbers     - kódová čísla elementů
%   degreesOfFreedom        - počet DOF na element (12 pro 3D)
%
% Out:
%   localGeometricMatrix    - lokální matice počátečních napětí (cell)
%   globalGeometrixMatrix   - globální matice počátečních napětí
%
% (c) S. Glanc, 2022 — přepracováno dle OOFEM beam3d.C::computeInitialStressMatrix

function [localGeometricMatrix, globalGeometrixMatrix] = geometricMoofemFn(surfaceArea, ...
         polarMomentOfInertiaX, transformationMatrix, elementLength, localEndForces, ...
         numberOfUnknownForces, numberOfElements, elementsCodeNumbers, degreesOfFreedom)

F = localEndForces;
globalGeometrixMatrix = zeros(numberOfUnknownForces, numberOfUnknownForces);
localGeometricMatrix  = cell(1, numberOfElements);

for cp = 1:numberOfElements

    L = elementLength(cp);

    % Axiální síla N — průměr z obou konců, dle OOFEM: N = (-F1 + F7) / 2
    N = (-F(1, cp) + F(7, cp)) / 2;

    % =====================================================================
    % Normalizovaná matice počátečních napětí (bez N/L faktoru)
    % kappa = 0 (Euler-Bernoulli) → denomy = denomz = 1
    % Struktura dle OOFEM computeInitialStressMatrix, řádky 850–875
    % =====================================================================
    Kg = zeros(12, 12);

    % Řádek 2 (transverzální posuv v, osa z)
    Kg(2,  2) =  6/5;
    Kg(2,  6) =  L/10;
    Kg(2,  8) = -6/5;
    Kg(2, 12) =  L/10;

    % Řádek 3 (transverzální posuv w, osa y)
    Kg(3,  3) =  6/5;
    Kg(3,  5) = -L/10;
    Kg(3,  9) = -6/5;
    Kg(3, 11) = -L/10;

    % Řádek 5 (ohybová rotace θ_y)
    Kg(5,  5) =  2*L^2/15;
    Kg(5,  9) =  L/10;
    Kg(5, 11) = -L^2/30;

    % Řádek 6 (ohybová rotace θ_z)
    Kg(6,  6) =  2*L^2/15;
    Kg(6,  8) = -L/10;
    Kg(6, 12) = -L^2/30;

    % Řádek 8 (transverzální posuv v, uzel 2)
    Kg(8,  8) =  6/5;
    Kg(8, 12) = -L/10;

    % Řádek 9 (transverzální posuv w, uzel 2)
    Kg(9,  9) =  6/5;
    Kg(9, 11) =  L/10;

    % Řádek 11, 12 (ohybové rotace, uzel 2)
    Kg(11, 11) =  2*L^2/15;
    Kg(12, 12) =  2*L^2/15;

    % =====================================================================
    % Axiální a torzní DOF — numerická stabilizace (dle OOFEM, řádky 877–887)
    % minVal = min ze čtyř ohybových diagonálních členů
    % =====================================================================
    minVal = min([Kg(2,2), Kg(3,3), Kg(5,5), Kg(6,6)]);

    Kg(1,  1) =  minVal / 1000;
    Kg(1,  7) = -minVal / 1000;
    Kg(7,  7) =  minVal / 1000;

    Kg(4,  4) =  minVal / 1000;
    Kg(4, 10) = -minVal / 1000;
    Kg(10,10) =  minVal / 1000;

    % =====================================================================
    % Symetrizace (dle OOFEM: answer.symmetrized())
    % =====================================================================
    Kg = Kg + triu(Kg, 1)';

    % =====================================================================
    % Násobení N/L (dle OOFEM: answer.times(N / l), řádky 895–896)
    % =====================================================================
    Kg = Kg * (N / L);

    % =====================================================================
    % Transformace do globálního souřadnicového systému
    % =====================================================================
    T      = transformationMatrix{cp};
    Ksigma = T' * Kg * T;
    localGeometricMatrix{cp} = Ksigma;

    % =====================================================================
    % Assemblace do globální matice
    % =====================================================================
    kcisla = elementsCodeNumbers(cp, :);
    for i = 1:degreesOfFreedom
        if kcisla(i) > 0
            for j = 1:degreesOfFreedom
                if kcisla(j) > 0
                    globalGeometrixMatrix(kcisla(i), kcisla(j)) = ...
                        globalGeometrixMatrix(kcisla(i), kcisla(j)) + Ksigma(i, j);
                end
            end
        end
    end

end
end
