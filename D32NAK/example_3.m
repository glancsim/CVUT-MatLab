% Další příklad s různými typy podpor
% Define nodes [node_id, x, y]
nodes_example = [
    1, 0, 0;    % Vetknutí
    2, 4, 0;    % Kloubová podpora
    3, 8, 0;    % Posuvná podpora
    4, 2, 2;    % Mezilehlý bod
    5, 6, 2     % Mezilehlý bod
];

% Define elements [elem_id, node1, node2, E, A, I]
elements_example = [
    1, 1, 4, 200e9, 0.008, 6.67e-6;  % První šikmý nosník
    2, 4, 2, 200e9, 0.008, 6.67e-6;  % Druhý šikmý nosník
    3, 2, 5, 200e9, 0.008, 6.67e-6;  % Třetí šikmý nosník
    4, 5, 3, 200e9, 0.008, 6.67e-6;  % Čtvrtý šikmý nosník
    5, 1, 2, 200e9, 0.01, 8.33e-6;   % První spodní nosník
    6, 2, 3, 200e9, 0.01, 8.33e-6;   % Druhý spodní nosník
    7, 4, 5, 200e9, 0.01, 8.33e-6    % Horní nosník
];

% Define constraints [node_id, ux, uy, theta]
constraints_example = [
    1, 1, 1, 1;  % Vetknutí - levá podpora
    2, 1, 1, 0;  % Kloubová podpora - střední podpora
    3, 0, 1, 0   % Posuvná podpora - pravá podpora
];

% Define loads [node_id, Fx, Fy, M]
loads_example = [
    4, 20000, -10000, 30000;  % Svislé zatížení na levém mezilehlém bodu
    5, 0, -10000, 0   % Svislé zatížení na pravém mezilehlém bodu
];

% Vykreslení konstrukce s různými typy podpor
figure;
subplot(2,1,1);
plotStructure(nodes, elements, constraints, loads);
title('Příhradový most s kloubovou a posuvnou podporou');

subplot(2,1,2);
plotStructure(nodes_example, elements_example, constraints_example, loads_example);
title('Konstrukce s vetknutím, kloubovou a posuvnou podporou');