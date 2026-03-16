% test_input.m - Test 10: 2D portálový rám v rovině XZ
%
% Popis: Portálový rám se dvěma svislými sloupy (podél osy Z) a jednou
%        vodorovnou příčlí (podél osy X). Uzly leží v rovině Y=0.
%        Sloupy jsou vetknuty u základny (uzly 1 a 4).
%        Uzly 2 a 3 jsou vázány v rovině (Uy=0, Rx=0, Rz=0).
%        Svislé tlakové síly na vrcholech sloupů + vodorovná zatížení.

%% PRŮŘEZY
sections.id = [30];  % section id in sectionsSet.mat

%% UZLY
nodes.x = [0.0; 0.0; 6.0; 6.0];  % x coordinates of nodes
nodes.y = [0.0; 0.0; 0.0; 0.0];  % y coordinates of nodes  (rám v rovině XZ)
nodes.z = [0.0; 6.0; 6.0; 0.0];  % z coordinates of nodes

%% DISKRETIZACE
ndisc = 10;  % discretization of beams

%% PODPORY
% Uzly 1 a 4 – plné vetknutí
kinematic.x.nodes  = [1; 4];      % restricted x-displacement
kinematic.y.nodes  = [1; 2; 3; 4];% restricted y-displacement  (rovinný rám)
kinematic.z.nodes  = [1; 4];      % restricted z-displacement
kinematic.rx.nodes = [1; 2; 3; 4];% restricted rx-rotation     (rovinný rám)
kinematic.ry.nodes = [1; 4];      % restricted ry-rotation
kinematic.rz.nodes = [1; 2; 3; 4];% restricted rz-rotation     (rovinný rám)

%% PRVKY
% Beam 1: levý sloup  1 → 2  (vertex = (0,0, 6))
% Beam 2: příčel      2 → 3  (vertex = (6,0, 0))
% Beam 3: pravý sloup 3 → 4  (vertex = (0,0,-6))
beams.nodesHead = [1; 2; 3];   % elements starting nodes
beams.nodesEnd  = [2; 3; 4];   % elements ending nodes
beams.sections  = [1; 1; 1];   % section to beams
beams.angles    = [0; 0; 0];   % angle of section

%% ZATÍŽENÍ
% Svislé tlakové síly na vrcholech sloupů (pro analýzu stability)
loads.x.nodes = [2];                  % node indices with x-direction forces
loads.x.value = [-0.5000];            % vodorovné zatížení (sway)

loads.y.nodes = [];                   % node indices with y-direction forces
loads.y.value = [];

loads.z.nodes = [2; 3];              % node indices with z-direction forces
loads.z.value = [-1.0000; -1.0000];  % svislé tlakové síly na sloupy

loads.rx.nodes = [];                  % node indices with rx-direction moments
loads.rx.value = [];

loads.ry.nodes = [];                  % node indices with ry-direction moments
loads.ry.value = [];

loads.rz.nodes = [];                  % node indices with rz-direction moments
loads.rz.value = [];
