%% example_scia_frame_shs_columns.m
% 3D frame — same geometry as example_scia_frame, columns upgraded to SHS
%
% Purpose: by stiffening the columns the critical buckling mode shifts from
%          the columns to the diagonal braces (L-section members).
%
% Geometry:   5 m × 5 m × 10 m box frame  (identical to example_scia_frame)
% Beams:      160 total
%               B1–B40   CS1 SHS 240×240×15,  L = 1.000 m  (columns)
%               B41–B80  CS3 IPE240,           L = 1.000 m  (ring/floor beams)
%               B81–B160 CS2 L 300×200×20×25,  L = 1.414 m  (diagonal braces)
% Nodes:      140 (N1–N140, same coordinates as example_scia_frame)
% Supports:   pinned at N1, N12, N23, N34  (fixed xyz, free rotations)
% Loads:      same as example_scia_frame
%   Fz = −1 kN at top corners  N11, N22, N33, N44
%   Fy = −1 kN at mid/top nodes N28, N33, N39, N44
%
% Section properties
%   CS1  SHS 240×240×15, S235:
%          A  = 135.00 cm²,  Iy = 11441 cm⁴,  Iz = 11441 cm⁴
%          IT = 17086 cm⁴  (closed section, Bredt)
%   CS2  L 300×200×20×25, S235  (same as example_scia_frame):
%          A  = 105 cm²,  Iy = 9384 cm⁴,  Iz = 3789 cm⁴,  IT = 184 cm⁴
%   CS3  IPE240, S235  (same as example_scia_frame):
%          A  = 39.12 cm², Iy = 3892 cm⁴,  Iz = 284 cm⁴,   IT = 12.88 cm⁴
%
% (c) S. Glanc 2026

%% -----------------------------------------------------------------------
%  ADD SRC TO PATH
% -----------------------------------------------------------------------
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

%% -----------------------------------------------------------------------
%  SECTION PROPERTIES
%  sec 1 = SHS 240×240×15  |  sec 2 = L 300×200×20×25  |  sec 3 = IPE240
% -----------------------------------------------------------------------
%                           CS1 SHS        CS2 L-sec      CS3 IPE240
sections.A  = [1.350e-2;   1.050e-2;   3.912e-3];   % [m²]
sections.Iy = [1.1441e-4;  9.384e-5;   3.892e-5];   % [m⁴]
sections.Iz = [1.1441e-4;  3.789e-5;   2.840e-6];   % [m⁴]
sections.Ix = [1.7086e-4;  1.842e-6;   1.288e-7];   % [m⁴]  (Bredt for SHS)
sections.E  = [210e9;      210e9;      210e9];       % [Pa]
sections.v  = [0.3;        0.3;        0.3];         % [-]

%% -----------------------------------------------------------------------
%  DISCRETISATION
% -----------------------------------------------------------------------
ndisc = 4;

%% -----------------------------------------------------------------------
%  NODES   (row i = node Ni, columns: x  y  z  [m])
%  Identical to example_scia_frame — see that file for full comments.
% -----------------------------------------------------------------------
xyz = [
%  x      y      z
   0,     0,     0;   %  N1
   0,     0,     1;   %  N2
   0,     0,     2;   %  N3
   0,     0,     3;   %  N4
   0,     0,     4;   %  N5
   0,     0,     5;   %  N6
   0,     0,     6;   %  N7
   0,     0,     7;   %  N8
   0,     0,     8;   %  N9
   0,     0,     9;   %  N10
   0,     0,    10;   %  N11
   5,     0,     0;   %  N12
   5,     0,     1;   %  N13
   5,     0,     2;   %  N14
   5,     0,     3;   %  N15
   5,     0,     4;   %  N16
   5,     0,     5;   %  N17
   5,     0,     6;   %  N18
   5,     0,     7;   %  N19
   5,     0,     8;   %  N20
   5,     0,     9;   %  N21
   5,     0,    10;   %  N22
   5,     5,     0;   %  N23
   5,     5,     1;   %  N24
   5,     5,     2;   %  N25
   5,     5,     3;   %  N26
   5,     5,     4;   %  N27
   5,     5,     5;   %  N28
   5,     5,     6;   %  N29
   5,     5,     7;   %  N30
   5,     5,     8;   %  N31
   5,     5,     9;   %  N32
   5,     5,    10;   %  N33
   0,     5,     0;   %  N34
   0,     5,     1;   %  N35
   0,     5,     2;   %  N36
   0,     5,     3;   %  N37
   0,     5,     4;   %  N38
   0,     5,     5;   %  N39
   0,     5,     6;   %  N40
   0,     5,     7;   %  N41
   0,     5,     8;   %  N42
   0,     5,     9;   %  N43
   0,     5,    10;   %  N44
   1,     0,    10;   %  N45
   2,     0,    10;   %  N46
   3,     0,    10;   %  N47
   4,     0,    10;   %  N48
   1,     5,    10;   %  N49
   2,     5,    10;   %  N50
   3,     5,    10;   %  N51
   4,     5,    10;   %  N52
   0,     1,    10;   %  N53
   0,     2,    10;   %  N54
   0,     3,    10;   %  N55
   0,     4,    10;   %  N56
   5,     1,    10;   %  N57
   5,     2,    10;   %  N58
   5,     3,    10;   %  N59
   5,     4,    10;   %  N60
   0,     1,     5;   %  N61
   0,     2,     5;   %  N62
   0,     3,     5;   %  N63
   0,     4,     5;   %  N64
   5,     1,     5;   %  N65
   5,     2,     5;   %  N66
   5,     3,     5;   %  N67
   5,     4,     5;   %  N68
   2,     0,     5;   %  N69
   3,     0,     5;   %  N70
   4,     0,     5;   %  N71
   1,     0,     5;   %  N72
   2,     5,     5;   %  N73
   3,     5,     5;   %  N74
   4,     5,     5;   %  N75
   1,     5,     5;   %  N76
   5,     1,     1;   %  N77
   5,     2,     2;   %  N78
   5,     3,     3;   %  N79
   5,     4,     4;   %  N80
   0,     4,     4;   %  N81
   0,     1,     1;   %  N82
   0,     2,     2;   %  N83
   0,     3,     3;   %  N84
   5,     1,     4;   %  N85
   5,     2,     3;   %  N86
   5,     3,     2;   %  N87
   5,     4,     1;   %  N88
   0,     1,     4;   %  N89
   0,     2,     3;   %  N90
   0,     3,     2;   %  N91
   0,     4,     1;   %  N92
   0,     1,     9;   %  N93
   0,     2,     8;   %  N94
   0,     3,     7;   %  N95
   0,     4,     6;   %  N96
   5,     1,     9;   %  N97
   5,     2,     8;   %  N98
   5,     3,     7;   %  N99
   5,     4,     6;   %  N100
   5,     4,     9;   %  N101
   5,     3,     8;   %  N102
   5,     2,     7;   %  N103
   5,     1,     6;   %  N104
   0,     4,     9;   %  N105
   0,     3,     8;   %  N106
   0,     2,     7;   %  N107
   0,     1,     6;   %  N108
   1,     0,     1;   %  N109
   2,     0,     2;   %  N110
   3,     0,     3;   %  N111
   4,     0,     4;   %  N112
   1,     0,     6;   %  N113
   2,     0,     7;   %  N114
   3,     0,     8;   %  N115
   4,     0,     9;   %  N116
   1,     5,     6;   %  N117
   2,     5,     7;   %  N118
   3,     5,     8;   %  N119
   4,     5,     9;   %  N120
   1,     5,     1;   %  N121
   2,     5,     2;   %  N122
   3,     5,     3;   %  N123
   4,     5,     4;   %  N124
   1,     0,     4;   %  N125
   2,     0,     3;   %  N126
   3,     0,     2;   %  N127
   4,     0,     1;   %  N128
   1,     0,     9;   %  N129
   2,     0,     8;   %  N130
   3,     0,     7;   %  N131
   4,     0,     6;   %  N132
   1,     5,     9;   %  N133
   2,     5,     8;   %  N134
   3,     5,     7;   %  N135
   4,     5,     6;   %  N136
   1,     5,     4;   %  N137
   2,     5,     3;   %  N138
   3,     5,     2;   %  N139
   4,     5,     1;   %  N140
];
nodes.x = xyz(:,1);
nodes.y = xyz(:,2);
nodes.z = xyz(:,3);

%% -----------------------------------------------------------------------
%  KINEMATIC — pinned at base corners (fixed xyz, rotations free)
% -----------------------------------------------------------------------
support_nodes = [1; 12; 23; 34];
kinematic.x.nodes  = support_nodes;
kinematic.y.nodes  = support_nodes;
kinematic.z.nodes  = support_nodes;
kinematic.rx.nodes = zeros(0,1);
kinematic.ry.nodes = zeros(0,1);
kinematic.rz.nodes = zeros(0,1);

%% -----------------------------------------------------------------------
%  BEAMS   [nodesHead, nodesEnd, section, angle]
%  sec 1 = SHS (columns)  |  sec 2 = L-sec (diagonals)  |  sec 3 = IPE240 (ring beams)
% -----------------------------------------------------------------------
beam_data = [
%  head  end   sec  angle   beam
    1,    2,    1,   0;  % B1   column
    2,    3,    1,   0;  % B2
    3,    4,    1,   0;  % B3
    4,    5,    1,   0;  % B4
    5,    6,    1,   0;  % B5
    6,    7,    1,   0;  % B6
    7,    8,    1,   0;  % B7
    8,    9,    1,   0;  % B8
    9,   10,    1,   0;  % B9
   10,   11,    1,   0;  % B10
   12,   13,    1,   0;  % B11  column
   13,   14,    1,   0;  % B12
   14,   15,    1,   0;  % B13
   15,   16,    1,   0;  % B14
   16,   17,    1,   0;  % B15
   17,   18,    1,   0;  % B16
   18,   19,    1,   0;  % B17
   19,   20,    1,   0;  % B18
   20,   21,    1,   0;  % B19
   21,   22,    1,   0;  % B20
   23,   24,    1,   0;  % B21  column
   24,   25,    1,   0;  % B22
   25,   26,    1,   0;  % B23
   26,   27,    1,   0;  % B24
   27,   28,    1,   0;  % B25
   28,   29,    1,   0;  % B26
   29,   30,    1,   0;  % B27
   30,   31,    1,   0;  % B28
   31,   32,    1,   0;  % B29
   32,   33,    1,   0;  % B30
   34,   35,    1,   0;  % B31  column
   35,   36,    1,   0;  % B32
   36,   37,    1,   0;  % B33
   37,   38,    1,   0;  % B34
   38,   39,    1,   0;  % B35
   39,   40,    1,   0;  % B36
   40,   41,    1,   0;  % B37
   41,   42,    1,   0;  % B38
   42,   43,    1,   0;  % B39
   43,   44,    1,   0;  % B40
   11,   45,    3,   0;  % B41  ring/floor beam (IPE240)
   45,   46,    3,   0;  % B42
   46,   47,    3,   0;  % B43
   47,   48,    3,   0;  % B44
   48,   22,    3,   0;  % B45
   44,   49,    3,   0;  % B46
   49,   50,    3,   0;  % B47
   50,   51,    3,   0;  % B48
   51,   52,    3,   0;  % B49
   52,   33,    3,   0;  % B50
   11,   53,    3,   0;  % B51
   53,   54,    3,   0;  % B52
   54,   55,    3,   0;  % B53
   55,   56,    3,   0;  % B54
   56,   44,    3,   0;  % B55
   22,   57,    3,   0;  % B56
   57,   58,    3,   0;  % B57
   58,   59,    3,   0;  % B58
   59,   60,    3,   0;  % B59
   60,   33,    3,   0;  % B60
    6,   61,    3,   0;  % B61
   61,   62,    3,   0;  % B62
   62,   63,    3,   0;  % B63
   63,   64,    3,   0;  % B64
   64,   39,    3,   0;  % B65
   17,   65,    3,   0;  % B66
   65,   66,    3,   0;  % B67
   66,   67,    3,   0;  % B68
   67,   68,    3,   0;  % B69
   68,   28,    3,   0;  % B70
   72,   69,    3,   0;  % B71
   69,   70,    3,   0;  % B72
   70,   71,    3,   0;  % B73
   71,   17,    3,   0;  % B74
    6,   72,    3,   0;  % B75
   76,   73,    3,   0;  % B76
   73,   74,    3,   0;  % B77
   74,   75,    3,   0;  % B78
   75,   28,    3,   0;  % B79
   39,   76,    3,   0;  % B80
   12,   77,    2,   21.84;  % B81   diagonal brace (L-section)
   77,   78,    2,   21.84;  % B82
   78,   79,    2,   21.84;  % B83
   79,   80,    2,   21.84;  % B84
   80,   28,    2,   21.84;  % B85
   84,   81,    2,   21.84;  % B86
   81,   39,    2,   21.84;  % B87
    1,   82,    2,   21.84;  % B88
   82,   83,    2,   21.84;  % B89
   83,   84,    2,   21.84;  % B90
   17,   85,    2,   21.84;  % B91
   85,   86,    2,   21.84;  % B92
   86,   87,    2,   21.84;  % B93
   87,   88,    2,   21.84;  % B94
   88,   23,    2,   21.84;  % B95
    6,   89,    2,   21.84;  % B96
   89,   90,    2,   21.84;  % B97
   90,   91,    2,   21.84;  % B98
   91,   92,    2,   21.84;  % B99
   92,   34,    2,   21.84;  % B100
   11,   93,    2,   21.84;  % B101
   93,   94,    2,   21.84;  % B102
   94,   95,    2,   21.84;  % B103
   95,   96,    2,   21.84;  % B104
   96,   39,    2,   21.84;  % B105
   22,   97,    2,   21.84;  % B106
   97,   98,    2,   21.84;  % B107
   98,   99,    2,   21.84;  % B108
   99,  100,    2,   21.84;  % B109
  100,   28,    2,   21.84;  % B110
  101,   33,    2,   21.84;  % B111
  102,  101,    2,   21.84;  % B112
  103,  102,    2,   21.84;  % B113
  104,  103,    2,   21.84;  % B114
   17,  104,    2,   21.84;  % B115
  105,   44,    2,   21.84;  % B116
  106,  105,    2,   21.84;  % B117
  107,  106,    2,   21.84;  % B118
  108,  107,    2,   21.84;  % B119
    6,  108,    2,   21.84;  % B120
    1,  109,    2,   21.84;  % B121
  109,  110,    2,   21.84;  % B122
  110,  111,    2,   21.84;  % B123
  111,  112,    2,   21.84;  % B124
  112,   17,    2,   21.84;  % B125
    6,  113,    2,   21.84;  % B126
  113,  114,    2,   21.84;  % B127
  114,  115,    2,   21.84;  % B128
  115,  116,    2,   21.84;  % B129
  116,   22,    2,   21.84;  % B130
   39,  117,    2,   21.84;  % B131
  117,  118,    2,   21.84;  % B132
  118,  119,    2,   21.84;  % B133
  119,  120,    2,   21.84;  % B134
  120,   33,    2,   21.84;  % B135
   34,  121,    2,   21.84;  % B136
  121,  122,    2,   21.84;  % B137
  122,  123,    2,   21.84;  % B138
  123,  124,    2,   21.84;  % B139
  124,   28,    2,   21.84;  % B140
    6,  125,    2,   21.84;  % B141
  125,  126,    2,   21.84;  % B142
  126,  127,    2,   21.84;  % B143
  127,  128,    2,   21.84;  % B144
  128,   12,    2,   21.84;  % B145
   11,  129,    2,   21.84;  % B146
  129,  130,    2,   21.84;  % B147
  130,  131,    2,   21.84;  % B148
  131,  132,    2,   21.84;  % B149
  132,   17,    2,   21.84;  % B150
   44,  133,    2,   21.84;  % B151
  133,  134,    2,   21.84;  % B152
  134,  135,    2,   21.84;  % B153
  135,  136,    2,   21.84;  % B154
  136,   28,    2,   21.84;  % B155
   39,  137,    2,   21.84;  % B156
  137,  138,    2,   21.84;  % B157
  138,  139,    2,   21.84;  % B158
  139,  140,    2,   21.84;  % B159
  140,   23,    2,   21.84;  % B160
];

beams.nodesHead = beam_data(:,1);
beams.nodesEnd  = beam_data(:,2);
beams.sections  = beam_data(:,3);
beams.angles    = beam_data(:,4);

%% -----------------------------------------------------------------------
%  LOADS  [N]  — same reference loads as example_scia_frame
% -----------------------------------------------------------------------
loads.z.nodes  = [11; 22; 33; 44];
loads.z.value  = [-1000; -1000; -1000; -1000];

loads.y.nodes  = [28; 33; 39; 44];
loads.y.value  = [-1000; -1000; -1000; -1000];

loads.x.nodes  = zeros(0,1);  loads.x.value  = zeros(0,1);
loads.rx.nodes = zeros(0,1);  loads.rx.value = zeros(0,1);
loads.ry.nodes = zeros(0,1);  loads.ry.value = zeros(0,1);
loads.rz.nodes = zeros(0,1);  loads.rz.value = zeros(0,1);

%% Optional: visualise structure
% plotStructureFn(nodes, beams, loads, kinematic);

%% -----------------------------------------------------------------------
%  RUN STABILITY ANALYSIS
% -----------------------------------------------------------------------
Results = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads);
% plotModeShapeFn(nodes, beams, kinematic, Results, 2);

fprintf('\n=== Critical load multipliers (first 10 modes) ===\n');
for i = 1:length(Results.values)
    lam = Results.values(i);
    % if lam > 0
        fprintf('  Mode %2d:  lambda_cr = %10.4f   =>  F_cr = %.2f kN\n', ...
                i, lam, lam * 1);
    % end
end

%% -----------------------------------------------------------------------
%  MAC COMPARISON — MATLAB vs. Scia Engineer
%
%  Export buckling modes from Scia (SHS column variant) and save as
%  scia_modes_shs.csv next to this file, then uncomment below.
%
%  Scia section used in Scia model: SHS 240×240×15
% -----------------------------------------------------------------------
scia_csv = fullfile(fileparts(mfilename('fullpath')), 'scia_modes_shs.csv');
% If stored elsewhere:
%   scia_csv = 'C:/Users/simon/Downloads/scia_modes_shs.csv';

if exist(scia_csv, 'file')
    [scia_phi, ~] = sciaImportFn(scia_csv, nodes, kinematic);

    [macMatrix, passed, details] = macComparisonFn( ...
        nodes, beams, kinematic, Results, scia_phi);

    figure('Name', 'MAC matrix — MATLAB vs. Scia (SHS columns)');
    imagesc(macMatrix);
    colorbar;
    clim([0 1]);
    colormap(flipud(gray));
    xlabel('Scia mód');
    ylabel('MATLAB mód');
    title('MAC matice — sloupy SHS 240×240×15');
    xticks(1:size(macMatrix,2));
    yticks(1:size(macMatrix,1));
    axis square;

    for r = 1:size(macMatrix,1)
        for c = 1:size(macMatrix,2)
            if macMatrix(r,c) > 0.5
                clr = 'w';
            else
                clr = 'k';
            end
            text(c, r, sprintf('%.3f', macMatrix(r,c)), ...
                 'HorizontalAlignment', 'center', ...
                 'FontSize', 9, 'Color', clr);
        end
    end

    if passed
        fprintf('MAC výsledek: PASS\n');
    else
        fprintf('MAC výsledek: FAIL — %d mód(y) pod prahem\n', ...
                sum(details.diagonal_mac < details.macThreshold));
    end
else
    fprintf('scia_modes_shs.csv nenalezen — přeskočeno MAC porovnání.\n');
    fprintf('Očekávaná cesta: %s\n', scia_csv);
end
