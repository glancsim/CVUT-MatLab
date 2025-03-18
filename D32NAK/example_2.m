% Define nodes [node_id, x, y]
nodes = [
    1, 0, 0;     % Levá podpora
    2, 5, 0;     % Pravá podpora
    3, 2.5, 2;   % Vrchol příhrady
    4, 1.25, 1;  % Mezilehlý bod levé části
    5, 3.75, 1   % Mezilehlý bod pravé části
];

% Define elements [elem_id, node1, node2, E, A, I]
elements = [
    1, 1, 4, 200e9, 0.005, 4.17e-6;  % Levá dolní diagonála
    2, 4, 3, 200e9, 0.005, 4.17e-6;  % Levá horní diagonála
    3, 3, 5, 200e9, 0.005, 4.17e-6;  % Pravá horní diagonála
    4, 5, 2, 200e9, 0.005, 4.17e-6;  % Pravá dolní diagonála
    5, 1, 2, 200e9, 0.008, 6.67e-6;  % Spodní horizontální nosník
    6, 4, 5, 200e9, 0.005, 4.17e-6   % Střední horizontální nosník
];

% Define constraints [node_id, ux, uy, theta]
constraints = [
    1, 1, 1, 1;  % Kloubová podpora vlevo (pouze posuvy omezeny)
    2, 0, 1, 0   % Posuvná kloubová podpora vpravo (pouze svislý posuv omezen)
];

% Define loads [node_id, Fx, Fy, M]
loads = [
    3, 0, -20000, 0;  % Svislé zatížení na vrcholu
    4, 0, -5000, 0;   % Svislé zatížení na levém mezilehlém bodu
    5, 0, -5000, 0    % Svislé zatížení na pravém mezilehlém bodu
];

% Vykreslení konstrukce před analýzou
plotStructure(nodes, elements, constraints, loads);

% Volání funkce analýzy
[displacements, reactions, element_forces] = frame2D_FEM(nodes, elements, constraints, loads);

% Zobrazení výsledků
disp('Posunutí uzlů [ux, uy, rotace]:');
disp(displacements);

disp('Reakce:');
disp([reactions(1:3); reactions(4:6)]);  % Reakce v uzlech 1 a 2

disp('Vnitřní síly v prvcích [N1 V1 M1 N2 V2 M2]:');
disp(element_forces);