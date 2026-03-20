% Sestavení geometrické matice počátečních napětí
%
% Implementace dle OOFEM: Beam3d::computeInitialStressMatrix (beam3d.C)
%
% Klíčové rysy:
%   - Pouze příspěvek axiální síly N = (-F1 + F7) / 2
%   - Axiální a torzní DOF (1,7 a 4,10) nahrazeny numerickou stabilizací: minVal/1000
%     (minVal = min ze čtyř ohybových diagonálních členů (2,2),(3,3),(5,5),(6,6))
%   - kappa = 0 (Euler-Bernoulli, konzistentní s maticí tuhosti)
%
% In:
%   elements           - struktura elementů (nelement, ndofs, codeNumbers, sections)
%   transformationMatrix - matice T pro každý element (matrices, lengths)
%   endForces          - struct s .local (12 × nelement), lokální vnitřní síly
%
% Out:
%   geometricMatrix.local   - lokální geometrické matice (cell)
%   geometricMatrix.global  - globální geometrická matice
%
% (c) S. Glanc, 2022 — přepracováno dle OOFEM beam3d.C::computeInitialStressMatrix

function geometricMatrix = geometricMatrixFn(elements, transformationMatrix, endForces)

F                    = endForces.local;
globalGeometrixMatrix = zeros(elements.ndofs, elements.ndofs);
localGeometricMatrix  = cell(1, elements.nelement);

for cp = 1:elements.nelement

    L = transformationMatrix.lengths(cp);

    % Axiální síla — průměr z obou konců (dle OOFEM: N = (-F1 + F7) / 2)
    N = (-F(1, cp) + F(7, cp)) / 2;

    % -----------------------------------------------------------------
    % Normalizovaná geometrická matice (bez faktoru N/L)
    % kappa = 0 → denomy = denomz = 1
    % -----------------------------------------------------------------
    Kg = zeros(12, 12);

    Kg(2,  2) =  6/5;
    Kg(2,  6) =  L/10;
    Kg(2,  8) = -6/5;
    Kg(2, 12) =  L/10;

    Kg(3,  3) =  6/5;
    Kg(3,  5) = -L/10;
    Kg(3,  9) = -6/5;
    Kg(3, 11) = -L/10;

    Kg(5,  5) =  2*L^2/15;
    Kg(5,  9) =  L/10;
    Kg(5, 11) = -L^2/30;

    Kg(6,  6) =  2*L^2/15;
    Kg(6,  8) = -L/10;
    Kg(6, 12) = -L^2/30;

    Kg(8,  8) =  6/5;
    Kg(8, 12) = -L/10;

    Kg(9,  9) =  6/5;
    Kg(9, 11) =  L/10;

    Kg(11, 11) =  2*L^2/15;
    Kg(12, 12) =  2*L^2/15;

    % Numerická stabilizace axiálních a torzních DOFů (dle OOFEM)
    minVal = min([Kg(2,2), Kg(3,3), Kg(5,5), Kg(6,6)]);
    Kg(1,  1) =  minVal / 1000;
    Kg(1,  7) = -minVal / 1000;
    Kg(7,  7) =  minVal / 1000;
    Kg(4,  4) =  minVal / 1000;
    Kg(4, 10) = -minVal / 1000;
    Kg(10,10) =  minVal / 1000;

    % Symetrizace
    Kg = Kg + triu(Kg, 1)';

    % Násobení N/L
    Kg = Kg * (N / L);

    % Transformace do globálního systému
    T      = transformationMatrix.matrices{cp};
    Ksigma = T' * Kg * T;
    localGeometricMatrix{cp} = Ksigma;

    % Assembly
    kcisla = elements.codeNumbers(cp, :);
    for i = 1:12
        if kcisla(i) > 0
            for j = 1:12
                if kcisla(j) > 0
                    globalGeometrixMatrix(kcisla(i), kcisla(j)) = ...
                        globalGeometrixMatrix(kcisla(i), kcisla(j)) + Ksigma(i, j);
                end
            end
        end
    end

end

geometricMatrix.global = globalGeometrixMatrix;
geometricMatrix.local  = localGeometricMatrix;
end
