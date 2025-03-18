function [h,errors] = oofemTestFn(nodes, beams, loads, kinematic, sections, values)
    filename = 'input.mat';
    
    oofem = oofemInputFn(nodes, beams, loads, kinematic, sections, filename)
        
    system('oofem.cmd');
    
    load('eigen.mat', 'eigenvalues');
    
    errors = abs(eigenvalues'-values)./values * 100;
    
    % Vytvoření vektoru pro x-ovou osu
    x = 1:length(errors);
    
    % Vytvoření grafu
    h = figure;  % Otevře nové okno s grafem
    bar(x, errors);  % Vytvoří sloupcový graf
    xlabel('Index');  % Popis x-ové osy
    ylabel('Error (%)');  % Popis y-ové osy
    title('Error Percentage');  % Titulek grafu
    grid on;  % Zapne mřížku pro lepší čitelnost
end