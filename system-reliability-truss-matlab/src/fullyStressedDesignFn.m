function [sectionsOut, history] = fullyStressedDesignFn(nodes, members, kinematic, sectionsIn, loads, sigmaAllow, opts)
% fullyStressedDesignFn  Fully-stressed design (stress-ratio) iteration for
% sizing truss cross-section GROUPS so the governing (max |stress|) member
% of every group reaches a target allowable stress under a single
% deterministic load case.
%
% Classic FSD iteration (members.sections groups members sharing ONE area,
% e.g. symmetric pairs or role groups -- same convention as rvSpec.resGroup
% elsewhere in this module):
%
%   A_g^(k+1) = A_g^(k) * max_{i in group g} |N_i^(k)| / (A_g^(k) * sigmaAllow)
%
% repeated until the largest relative change in any group's area drops
% below `opts.tol`. This does NOT check buckling/EN 1993-1-1 (unlike
% en-truss-design-matlab/src/sectionCheckFn) -- sigmaAllow is a single
% gross-stress criterion applied identically in tension and compression,
% appropriate for a "worked demonstration" truss (see
% example_warren_xbrace.m), not a code-compliant design.
%
% INPUTS:
%   nodes, kinematic - truss geometry/BCs, fem-2d-truss-matlab format
%   members  - .nodesHead, .nodesEnd, .nmembers, .sections (GROUP index
%              1..nGroups per member; members sharing a group get ONE
%              shared, jointly-resized area)
%   sectionsIn - .A (nGroups x 1) initial guess, .E (nGroups x 1)
%   loads    - ONE deterministic `loads` struct (fem-2d-truss-matlab
%              format) -- e.g. built from rvSpec.loadMean, NOT a unit case
%   sigmaAllow - (scalar) target allowable stress [Pa]
%   opts     - (struct, optional):
%       .maxIter - default 50
%       .tol     - relative area-change convergence tolerance, default 1e-4
%       .Amin    - floor on area [m^2], guards near-zero-force members
%                  (e.g. an unloaded X-brace diagonal) from collapsing to
%                  A=0 and destabilizing the next iteration's FEM solve,
%                  default 1e-6
%       .verbose - default true
%
% OUTPUTS:
%   sectionsOut - .A (nGroups x 1) converged areas, .E unchanged from sectionsIn
%   history     - ((nIter+1) x nGroups) area at each iteration, row 1 =
%                 initial guess, last row = converged (or final, if
%                 maxIter reached without convergence -- check the
%                 verbose warning)
%
% See also: componentReliabilityFn, systemReliabilityFn
%
% (c) S. Glanc, 2026

if nargin < 7, opts = struct(); end
if ~isfield(opts, 'maxIter'), opts.maxIter = 50;   end
if ~isfield(opts, 'tol'),     opts.tol     = 1e-4; end
if ~isfield(opts, 'Amin'),    opts.Amin    = 1e-6; end
if ~isfield(opts, 'verbose'), opts.verbose = true; end

nGroups = numel(sectionsIn.A);
A = sectionsIn.A(:);
sectionsCur = sectionsIn;

history = zeros(opts.maxIter + 1, nGroups);
history(1, :) = A';

converged = false;
iter = 0;
for iter = 1:opts.maxIter
    [~, endForces] = linearSolverFn(sectionsCur, nodes, kinematic, members, loads);
    N = endForces.local(1, :)';      % axial force per member, tension positive

    Anew = A;
    for g = 1:nGroups
        idx = find(members.sections == g);
        if isempty(idx), continue; end
        sigma_g = max(abs(N(idx))) / A(g);
        Anew(g) = max(A(g) * sigma_g / sigmaAllow, opts.Amin);
    end

    relChange = max(abs(Anew - A) ./ A);
    A = Anew;
    sectionsCur.A = A;
    history(iter + 1, :) = A';

    if opts.verbose
        fprintf('  FSD iter %2d: max relative area change = %.4e\n', iter, relChange);
    end
    if relChange < opts.tol
        converged = true;
        break;
    end
end

history = history(1:iter+1, :);
if ~converged && opts.verbose
    fprintf('  WARNING: fullyStressedDesignFn did NOT converge within %d iterations (last relChange=%.4e)\n', ...
        opts.maxIter, relChange);
end

sectionsOut = sectionsCur;

end
