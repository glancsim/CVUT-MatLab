function [macMatrix, passed, details] = macComparisonFn(nodes, beams, kinematic, Results, scia_phi, macThreshold)
% macComparisonFn  Compare MATLAB buckling mode shapes against Scia Engineer.
%
% Extracts the mode shape vectors at the original physical nodes from the
% MATLAB stability analysis result, then computes the MAC (Modal Assurance
% Criterion) matrix against mode shapes imported from Scia Engineer.
%
% The MATLAB eigenvectors (Results.vectors) contain DOFs for ALL nodes,
% including internal discretisation nodes added by stabilitySolverFn.
% Only the rows corresponding to original physical nodes are used here:
%   rows 1 : ndofs_orig,  where  ndofs_orig = max(max(beams.codeNumbers))
%
% INPUTS:
%   nodes     - (struct) Node geometry (.x, .y, .z — original physical nodes).
%   beams     - (struct) Beam topology.  Must include .nodesHead, .nodesEnd,
%               .sections, .angles  (same as passed to stabilitySolverFn).
%               Used to compute beams.codeNumbers via codeNumbersFn.
%   kinematic - (struct) Kinematic boundary conditions (supports).
%   Results   - (struct) Output of stabilitySolverFn.
%     .vectors - (ndofs_total x nmodes) Eigenvectors.
%     .values  - (nmodes x 1) Eigenvalues (critical load multipliers).
%   scia_phi  - (ndofs_orig x nSciaModes) Mode shapes from Scia, in MATLAB
%               DOF ordering.  Produced by sciaImportFn.
%   macThreshold - (scalar, optional) Minimum acceptable MAC value on the
%               diagonal.  Default: 0.90.
%
% OUTPUTS:
%   macMatrix - (nmodes x nSciaModes) MAC matrix.
%               macMatrix(i,j) = MAC between MATLAB mode i and Scia mode j.
%               Values in [0, 1].  Ideally: diag ≈ 1, off-diag ≈ 0.
%   passed    - (logical) true if all diagonal MAC values >= macThreshold.
%   details   - (struct) Diagnostic information.
%     .diagonal_mac  - (nmodes x 1) MAC values for matched mode pairs.
%     .best_match    - (nmodes x 1) Maximum MAC per row (robust to mode reordering).
%     .best_match_idx - (nmodes x 1) Scia mode index giving the best match.
%     .macThreshold  - threshold used.
%     .ndofs_orig    - number of free DOFs at original physical nodes.
%     .eigenvalues   - Results.values for reference.
%
% EXAMPLE:
%   % 1. Run MATLAB stability analysis
%   Results = stabilitySolverFn(sections, nodes, ndisc, kinematic, beams, loads);
%
%   % 2. Import Scia mode shapes (requires scia_modes.csv — see sciaImportFn)
%   scia_phi = sciaImportFn('scia_modes.csv', nodes, kinematic);
%
%   % 3. Compute MAC
%   [mac, ok, det] = macComparisonFn(nodes, beams, kinematic, Results, scia_phi);
%   fprintf('Diagonal MAC: %s\n', mat2str(round(det.diagonal_mac, 3)));
%
%   % 4. Visualise
%   figure; imagesc(mac); colorbar; clim([0 1]);
%   xlabel('Scia mode'); ylabel('MATLAB mode'); title('MAC matrix');
%
% See also: stabilitySolverFn, sciaImportFn, macCriterionFn
%
% (c) S. Glanc, 2026

if nargin < 6, macThreshold = 0.90; end

%--------------------------------------------------------------------------
% Determine ndofs_orig: boundary between original and discretisation DOFs
%--------------------------------------------------------------------------
% Rebuild nodes.dofs from kinematic (mirrors stabilitySolverFn lines 130-136)
nnodes     = numel(nodes.x);
dofs_free  = true(nnodes, 6);
dofs_free(kinematic.x.nodes,  1) = false;
dofs_free(kinematic.y.nodes,  2) = false;
dofs_free(kinematic.z.nodes,  3) = false;
dofs_free(kinematic.rx.nodes, 4) = false;
dofs_free(kinematic.ry.nodes, 5) = false;
dofs_free(kinematic.rz.nodes, 6) = false;

nodes_tmp       = nodes;
nodes_tmp.dofs  = dofs_free;
beams_tmp       = beams;
beams_tmp.nbeams = numel(beams.nodesHead);

codes      = codeNumbersFn(beams_tmp, nodes_tmp);   % (nbeams x 12)
ndofs_orig = max(max(codes));

%--------------------------------------------------------------------------
% Extract MATLAB mode shapes at original physical nodes
%--------------------------------------------------------------------------
nmodes_ml   = size(Results.vectors, 2);
matlab_phi  = full(Results.vectors(1:ndofs_orig, :));   % (ndofs_orig x nmodes_ml)

%--------------------------------------------------------------------------
% Align number of modes
%--------------------------------------------------------------------------
nmodes_scia = size(scia_phi, 2);
nmodes      = min(nmodes_ml, nmodes_scia);

if nmodes_ml ~= nmodes_scia
    warning('macComparisonFn: MATLAB has %d modes, Scia has %d modes — comparing first %d.', ...
            nmodes_ml, nmodes_scia, nmodes);
end

%--------------------------------------------------------------------------
% Compute MAC matrix
%--------------------------------------------------------------------------
macMatrix = macCriterionFn(matlab_phi(:, 1:nmodes), scia_phi(:, 1:nmodes));

%--------------------------------------------------------------------------
% Pass/fail and diagnostics
%--------------------------------------------------------------------------
diagonal_mac               = diag(macMatrix);
[best_match, best_match_idx] = max(macMatrix, [], 2);
passed                     = all(diagonal_mac >= macThreshold);

details.diagonal_mac   = diagonal_mac;
details.best_match     = best_match;
details.best_match_idx = best_match_idx;
details.macThreshold   = macThreshold;
details.ndofs_orig     = ndofs_orig;
details.eigenvalues    = Results.values;

%--------------------------------------------------------------------------
% Console summary
%--------------------------------------------------------------------------
fprintf('\n--- MAC comparison summary (threshold = %.2f) ---\n', macThreshold);
fprintf('  Mode  |  Diagonal MAC  |  Best MAC  |  Best Scia mode\n');
fprintf('  ------|----------------|------------|----------------\n');
for i = 1:nmodes
    flag = '';
    if diagonal_mac(i) < macThreshold, flag = '  <-- below threshold'; end
    fprintf('  %4d  |    %8.4f    |   %6.4f   |      %3d%s\n', ...
            i, diagonal_mac(i), best_match(i), best_match_idx(i), flag);
end
if passed
    fprintf('  Result: PASS — all diagonal MAC values >= %.2f\n\n', macThreshold);
else
    fprintf('  Result: FAIL — %d mode(s) below threshold %.2f\n\n', ...
            sum(diagonal_mac < macThreshold), macThreshold);
end

end
