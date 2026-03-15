function [h, errors] = oofemTestFn(nodes, beams, loads, kinematic, sections, values)
    filename = 'input.mat';

    oofem = oofemInputFn(nodes, beams, loads, kinematic, sections, filename); %#ok<NASGU>

    system('C:\Install\Python\python.exe C:\GitHub\python\oofemRunner\oofem.py');

    load('eigen.mat', 'eigenvalues');

    % Porovnání: zachovat pouze kladná MATLAB vlastní čísla (fyzikální vzpěrné módy).
    % MATLAB eigs('smallestabs') vrací i záporná čísla (vzpěr v opačném směru),
    % OOFEM LinearStability vrací vždy kladná. Porovnáváme seřazené kladné hodnoty.
    posValues   = sort(values(values > 0));   posValues   = posValues(:);
    oofemValues = sort(eigenvalues(eigenvalues > 0)); oofemValues = oofemValues(:);
    n = min(length(posValues), length(oofemValues));

    % Chyba vztažená k referenční (OOFEM) hodnotě, vždy kladné jmenovatele
    errors = abs(oofemValues(1:n) - posValues(1:n)) ./ oofemValues(1:n) * 100;

    % Graf
    h = figure;
    bar(1:n, errors);
    xlabel('Mód');
    ylabel('Chyba (%)');
    title('Procentuální chyba oproti OOFEM');
    grid on;
end