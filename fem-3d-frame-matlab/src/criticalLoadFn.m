% Výpočet kritického břemene z matice tuhosti a matice počátečních napětí
%
% Řeší zobecněný problém vlastních čísel:   K·φ = λ·Kg·φ
% kde K je matice tuhosti (PD) a Kg je geometrická matice.
%
% Implementace:
%   n ≤ 100  — přímý eig(K, -Kg); rychlý a spolehlivý pro malé problémy
%   n > 100  — Choleskyho transformace na symetrický standardní problém:
%              K = L·Lᵀ,  A = L⁻¹·(-Kg)·L⁻ᵀ  (symetrická)
%              A·w = μ·w  kde μ = 1/λ  →  eigs spolehlivý (Lanczos, ne shift-invert)
%              Zpětná transformace: φ = L⁻ᵀ·w
%
%   Původní eigs(K, -Kg, 10, 'smallestabs') je nespolehlivý pokud -Kg
%   není pozitivně definitní (smíšená tah/tlak konstrukce) — shift-invert
%   mód selhává pro indefinitní B.
%
% In:
%   stiffnesMatrix.global   — globální matice tuhosti
%   geometricMatrix.global  — globální geometrická matice
%
% Out:
%   Results.values           — vlastní čísla (kritická čísla zatížení)
%   Results.vectors          — odpovídající vlastní tvary
%   Results.criticalLoad     — min |λ|
%   Results.criticalModeIndex — index minima
%
% (c) S. Glanc, 2022, přepracováno 2025

function [Results] = criticalLoadFn(stiffnesMatrix, geometricMatrix)

K  = stiffnesMatrix.global;
Kg = geometricMatrix.global;
n  = size(K, 1);

% Počet žádaných vlastních čísel — buffer pro případ záporných λ
nRequest = min(20, n - 2);

if n <= 100
    % ---------------------------------------------------------------
    % Malé problémy: přímá full dekompozice
    % ---------------------------------------------------------------
    [eigenVectors, eigenValues] = eig(full(K), -full(Kg));
    eigenValues = diag(eigenValues);

    % Filtrování Inf/NaN (vznikají z indefinitní -Kg)
    valid = isfinite(eigenValues);
    eigenValues  = eigenValues(valid);
    eigenVectors = eigenVectors(:, valid);

    % Zachovat nRequest hodnot s nejmenším |λ|
    [~, idx] = sort(abs(eigenValues));
    nKeep        = min(nRequest, numel(idx));
    eigenValues  = eigenValues(idx(1:nKeep));
    eigenVectors = eigenVectors(:, idx(1:nKeep));

else
    % ---------------------------------------------------------------
    % Velké problémy: Choleskyho transformace → symetrický eigs
    %
    %   K = L·Lᵀ,  A·w = μ·w  kde A = L⁻¹·(-Kg)·L⁻ᵀ,  λ = 1/μ
    %   Afun = A*x bez sestavování A (O(n²)/iter místo O(n³) sestavení)
    % ---------------------------------------------------------------
    L   = chol(full(K), 'lower');
    Lt  = L';
    KgF = -full(Kg);
    Afun = @(x) L \ (KgF * (Lt \ x));

    opts.tol    = 1e-10;
    opts.maxit  = 500;
    opts.isreal = true;
    opts.issym  = true;

    [W, D] = eigs(Afun, n, nRequest, 'largestabs', opts);
    mu = diag(D);

    % Zpětná transformace φ = L⁻ᵀ·w
    eigenVectors = Lt \ W;
    eigenValues  = 1 ./ mu;

    % Filtrování numericky nulových μ (ochrana před dělením nulou)
    valid        = abs(mu) > 1e-14;
    eigenValues  = eigenValues(valid);
    eigenVectors = eigenVectors(:, valid);
end

[Min, Pos] = min(abs(eigenValues));
Results.values            = eigenValues;
Results.vectors           = eigenVectors;
Results.criticalLoad      = Min;
Results.criticalModeIndex = Pos;

end
