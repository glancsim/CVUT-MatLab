function [nodes, beams] = trussGeneratorFn(x_bot, x_top, h, varargin)
% trussGeneratorFn  Generate a planar truss frame input for stabilitySolverFn.
%
% Creates a planar truss in the X-Z plane (y = 0) with rigid (frame) joints.
% All members are Euler-Bernoulli beam elements — moment continuity at every
% node. Bottom chord lies at z = 0, top chord at z = h (flat) or z = h(i)
% (variable — e.g. gabled / pitched roof shape).
%
% INPUTS:
%   x_bot     - [m]  x-coordinates of bottom chord nodes          (n_b × 1)
%   x_top     - [m]  x-coordinates of top chord nodes             (n_t × 1)
%   h         - [m]  Top chord height:
%                      scalar  → constant height (flat top chord)
%                      vector  → z-coordinate for each top node   (n_t × 1)
%                                e.g. gabled shape:
%                                  h = h_max*(1 - abs(2*x_top/L - 1))
%
% OPTIONAL name-value pairs:
%   'Topology'  - Web member layout:
%                   'pratt'      — verticals + diagonals leaning toward midspan  (default)
%                   'howe'       — verticals + diagonals leaning toward supports
%                   'warren'     — diagonals only, alternating (no verticals)
%                   'vierendeel' — verticals only (no diagonals)
%   'Sections'  - Section index for all beams (scalar, default: 1)
%   'Angles'    - Cross-section roll angle [deg] for all beams (scalar, default: 0)
%   'Plot'      - Show plotStructureFn after generation (logical, default: false)
%
% OUTPUTS:
%   nodes  - (struct)  .x, .y, .z  node coordinates
%   beams  - (struct)  .nodesHead, .nodesEnd, .sections, .angles
%            beams.nbeams is set; beams.sections defaults to 1 for all beams
%            Assign actual section properties in stabilitySolverFn call.
%
% USAGE EXAMPLE:
%   % 5-panel Pratt truss, 12 m span, flat top (h = 2 m)
%   x = linspace(0, 12, 7);
%   [nodes, beams] = trussGeneratorFn(x, x, 2, 'Topology', 'pratt', 'Plot', true);
%
%   % Sedlová (gabled) příhrada — vrchol uprostřed, h_max = 2 m
%   x = linspace(0, 12, 7);
%   h_vec = 2 * (1 - abs(2*x/12 - 1));     % lineární sedlo: 0→2→0
%   [nodes, beams] = trussGeneratorFn(x, x, h_vec, 'Topology', 'pratt', 'Plot', true);
%
%   sections.A  = 6e-4;  sections.E = 210e9;  sections.v = 0.3;
%   sections.Iy = 5e-8;  sections.Iz = 5e-8;  sections.Ix = 1e-7;
%
%   kinematic.x.nodes = [1; numel(x)];  kinematic.y.nodes = 1:numel(x)*2;
%   kinematic.z.nodes = [1; numel(x)];  kinematic.rx.nodes = [];
%   kinematic.ry.nodes = [];             kinematic.rz.nodes = [];
%
%   loads.z.nodes = round(numel(x)/2+numel(x));  loads.z.value = -10000;
%   ... (fill remaining load fields)
%
%   Results = stabilitySolverFn(sections, nodes, 8, kinematic, beams, loads);
%
% TOPOLOGY DIAGRAMS (Pratt example, 3 panels):
%
%   Pratt / Howe:          Warren:           Vierendeel:
%   T1--T2--T3--T4         T1--T2--T3--T4    T1--T2--T3--T4
%   | \ | \ | \ |           \ /  \ /  \ /    |   |   |   |
%   B1--B2--B3--B4          B1--B2--B3--B4    B1--B2--B3--B4
%
% See also: stabilitySolverFn, plotStructureFn
%
% (c) S. Glanc, 2025

%--------------------------------------------------------------------------
% Parse options
%--------------------------------------------------------------------------
p = inputParser();
addParameter(p, 'Topology',  'pratt', @(x) ischar(x) || isstring(x));
addParameter(p, 'Sections',  1,       @isnumeric);
addParameter(p, 'Angles',    0,       @isnumeric);
addParameter(p, 'Plot',      false,   @islogical);
parse(p, varargin{:});

topology   = lower(char(p.Results.Topology));
secIdx     = p.Results.Sections;
rollAngle  = p.Results.Angles;
doPlot     = p.Results.Plot;

%--------------------------------------------------------------------------
% Validate inputs
%--------------------------------------------------------------------------
x_bot = x_bot(:);
x_top = x_top(:);
h     = h(:);

n_b = numel(x_bot);
n_t = numel(x_top);
if n_b < 2 || n_t < 2
    error('trussGeneratorFn: need at least 2 nodes on each chord.');
end

% Resolve z-coordinates of top chord
if isscalar(h)
    if h <= 0, error('trussGeneratorFn: scalar h must be positive.'); end
    z_top = h * ones(n_t, 1);
else
    if numel(h) ~= n_t
        error('trussGeneratorFn: vector h must have the same length as x_top (%d).', n_t);
    end
    if any(h < 0)
        error('trussGeneratorFn: all h values must be >= 0.');
    end
    z_top = h;
end

%--------------------------------------------------------------------------
% Build node list
%   Nodes 1..n_b      — bottom chord  (z = 0)
%   Nodes n_b+1..end  — top chord     (z = z_top)
%--------------------------------------------------------------------------
n_nodes  = n_b + n_t;
nodes.x  = [x_bot; x_top];
nodes.y  = zeros(n_nodes, 1);
nodes.z  = [zeros(n_b, 1); z_top];

%--------------------------------------------------------------------------
% Chord members
%--------------------------------------------------------------------------
% Bottom chord: consecutive pairs
head_b = (1 : n_b-1)';
end_b  = (2 : n_b)';

% Top chord: consecutive pairs (node indices offset by n_b)
head_t = (n_b+1 : n_b+n_t-1)';
end_t  = (n_b+2 : n_b+n_t)';

%--------------------------------------------------------------------------
% Web members — panel-by-panel approach
%   Build sorted list of all x-positions; iterate over panels.
%   For each panel [x_L, x_R] find which bottom and top nodes sit there.
%--------------------------------------------------------------------------
x_all = unique([x_bot; x_top]);
n_pan = numel(x_all) - 1;

head_w = [];   end_w = [];

% Helper: find index of value v in sorted vector xv (within tolerance)
tol = 1e-10 * (max(x_all) - min(x_all) + 1);
findIdx = @(xv, v) find(abs(xv - v) < tol, 1);

% Track Warren diagonal direction (alternates each panel)
warren_dir = 1;

for ip = 1 : n_pan
    xL = x_all(ip);
    xR = x_all(ip+1);

    % Bottom nodes at left and right boundary of this panel
    iB_L = findIdx(x_bot, xL);   % may be empty
    iB_R = findIdx(x_bot, xR);   % may be empty

    % Top nodes (offset by n_b for global numbering)
    iT_L_loc = findIdx(x_top, xL);
    iT_R_loc = findIdx(x_top, xR);
    iT_L = iT_L_loc + n_b;   % global index (may be empty if iT_L_loc is empty)
    iT_R = iT_R_loc + n_b;

    % Determine which of the 4 corners of this panel exist
    has_BL = ~isempty(iB_L);
    has_BR = ~isempty(iB_R);
    has_TL = ~isempty(iT_L_loc);
    has_TR = ~isempty(iT_R_loc);

    %-- Verticals (only where bottom and top nodes share the same x) ------
    if ~ismember(topology, ["warren"])
        if has_BL && has_TL
            head_w(end+1,1) = iB_L;  end_w(end+1,1) = iT_L;
        end
        if has_BR && has_TR
            % Will be added by the NEXT panel's left-side check — skip
            % unless this is the last panel (right boundary)
            if ip == n_pan
                head_w(end+1,1) = iB_R;  end_w(end+1,1) = iT_R;
            end
        end
    end

    %-- Diagonals ---------------------------------------------------------
    switch topology
        case 'pratt'
            % Diagonal leans toward midspan: bottom-left → top-right
            if has_BL && has_TR
                head_w(end+1,1) = iB_L;  end_w(end+1,1) = iT_R;
            elseif has_TL && has_BR
                head_w(end+1,1) = iT_L;  end_w(end+1,1) = iB_R;
            end

        case 'howe'
            % Diagonal leans toward supports: top-left → bottom-right
            if has_TL && has_BR
                head_w(end+1,1) = iT_L;  end_w(end+1,1) = iB_R;
            elseif has_BL && has_TR
                head_w(end+1,1) = iB_L;  end_w(end+1,1) = iT_R;
            end

        case 'warren'
            % Alternating diagonals (no verticals)
            if warren_dir > 0
                % Bottom-left → top-right
                if has_BL && has_TR
                    head_w(end+1,1) = iB_L;  end_w(end+1,1) = iT_R;
                end
            else
                % Top-left → bottom-right
                if has_TL && has_BR
                    head_w(end+1,1) = iT_L;  end_w(end+1,1) = iB_R;
                end
            end
            warren_dir = -warren_dir;

        case 'vierendeel'
            % No diagonals — verticals only (already handled above)
    end
end

%--------------------------------------------------------------------------
% Merge coincident nodes (e.g. gabled top chord endpoints at z=0)
%
% Build a canonical index map: remap(i) = node to use instead of i.
% Two nodes are coincident when their x,y,z positions match within tol.
%--------------------------------------------------------------------------
pos   = [nodes.x, nodes.y, nodes.z];   % n_nodes × 3
node_tol = 1e-9 * (max(max(pos)) - min(min(pos)) + 1);

% Vectorized coincident-node merging:
% Quantize coordinates using node_tol and group identical rows.
pos_q = round(pos ./ node_tol);
[~, ~, remap] = unique(pos_q, 'rows');
remap = remap(:);                       % ensure column vector

% Apply remap to beam connectivity
all_head = remap([head_b; head_t; head_w]);
all_end  = remap([end_b;  end_t;  end_w]);

% Remove zero-length beams (head == end after merge)
valid    = all_head ~= all_end;
all_head = all_head(valid);
all_end  = all_end(valid);

% Remove duplicate beams (same pair regardless of direction)
beam_pairs = sort([all_head, all_end], 2);
[~, ui]    = unique(beam_pairs, 'rows', 'stable');
all_head   = all_head(ui);
all_end    = all_end(ui);

% Compact node list — remove nodes that were merged away
kept      = unique(remap);           % canonical node indices kept
n_compact = numel(kept);
reindex   = zeros(n_nodes, 1);
reindex(kept) = 1:n_compact;

nodes.x = nodes.x(kept);
nodes.y = nodes.y(kept);
nodes.z = nodes.z(kept);

all_head = reindex(all_head);
all_end  = reindex(all_end);

n_merged = n_nodes - n_compact;
if n_merged > 0
    fprintf('  (merged %d coincident node(s))\n', n_merged);
end

n_beams  = numel(all_head);

beams.nodesHead = all_head;
beams.nodesEnd  = all_end;
beams.sections  = secIdx  * ones(n_beams, 1);
beams.angles    = rollAngle * ones(n_beams, 1);
beams.nbeams    = n_beams;

%--------------------------------------------------------------------------
% Summary
%--------------------------------------------------------------------------
fprintf('trussGeneratorFn: %s truss generated\n', upper(topology));
fprintf('  Nodes  : %d  (%d bottom + %d top)\n', n_nodes, n_b, n_t);
fprintf('  Beams  : %d  (%d bottom chord + %d top chord + %d web)\n', ...
        n_beams, n_b-1, n_t-1, numel(head_w));
fprintf('  Span   : %.3g m   Height: %.3g – %.3g m\n', ...
        max(x_all)-min(x_all), min(z_top), max(z_top));

%--------------------------------------------------------------------------
% Optional plot (needs plotStructureFn on path)
%--------------------------------------------------------------------------
if doPlot
    % Minimal dummy loads/kinematic just for visualization
    loads_dummy.x.nodes=[]; loads_dummy.x.value=[];
    loads_dummy.y.nodes=[]; loads_dummy.y.value=[];
    loads_dummy.z.nodes=[]; loads_dummy.z.value=[];
    loads_dummy.rx.nodes=[]; loads_dummy.rx.value=[];
    loads_dummy.ry.nodes=[]; loads_dummy.ry.value=[];
    loads_dummy.rz.nodes=[]; loads_dummy.rz.value=[];
    plotStructureFn(nodes, beams, loads_dummy);
    title(sprintf('Truss: %s topology | %d nodes | %d beams', ...
          upper(topology), n_nodes, n_beams));
end

end
