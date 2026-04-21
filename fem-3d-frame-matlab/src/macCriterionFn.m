function macMatrix = macCriterionFn(Phi_A, Phi_B)
% macCriterionFn  Modal Assurance Criterion (MAC) matrix.
%
% Computes the MAC matrix between two sets of mode shapes. Each MAC value
% measures the correlation between a mode shape from set A and one from set B.
% MAC = 1 indicates perfectly correlated shapes; MAC = 0 indicates orthogonal
% (uncorrelated) shapes.
%
% The absolute value is used in the numerator so that the result is
% independent of the sign convention used to normalize each eigenvector.
%
% INPUTS:
%   Phi_A - Mode shape matrix A.  Each column is one mode shape. (ndof x nA)
%   Phi_B - Mode shape matrix B.  Each column is one mode shape. (ndof x nB)
%           ndof must match between A and B.
%
% OUTPUTS:
%   macMatrix - MAC matrix.  macMatrix(i,j) is the MAC value between the
%               i-th mode of Phi_A and the j-th mode of Phi_B. (nA x nB)
%
% FORMULA:
%   MAC(i,j) = |Phi_A(:,i)' * Phi_B(:,j)|^2
%              ──────────────────────────────────────
%              (Phi_A(:,i)'*Phi_A(:,i)) * (Phi_B(:,j)'*Phi_B(:,j))
%
% EXAMPLE:
%   % Two identical sets of 3 modes with 4 DOFs each
%   Phi = rand(4, 3);
%   MAC = macCriterionFn(Phi, Phi);
%   % MAC should be the identity matrix (diag = 1, off-diag ≈ 0)
%
% See also: macComparisonFn, sciaImportFn
%
% (c) S. Glanc, 2026

num      = abs(Phi_A' * Phi_B).^2;
normA    = sum(Phi_A.^2, 1)';            % (nA x 1)
normB    = sum(Phi_B.^2, 1);             % (1 x nB)
den      = normA * normB;                % outer product (nA x nB)
macMatrix = num ./ den;

end
