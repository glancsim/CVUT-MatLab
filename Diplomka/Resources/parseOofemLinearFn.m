function displ = parseOofemLinearFn(filename, nnodes)
% parseOofemLinearFn - Parse OOFEM output file for linear solution displacements
%
% Inputs:
%   filename - Path to OOFEM output file (e.g., 'test.out')
%   nnodes   - Number of original (non-discretized) nodes to extract
%
% Output:
%   displ - (nnodes x 6) matrix of nodal displacements [Ux Uy Uz Rx Ry Rz]
%           displ(node, dof), constrained DOFs = 0

displ = zeros(nnodes, 6);

fid = fopen(filename, 'r');
if fid == -1
    error('parseOofemLinearFn: Cannot open file: %s', filename);
end

inLinearSolution = false;
currentNode = 0;

while ~feof(fid)
    line = fgetl(fid);
    if ~ischar(line), break; end
    line = strtrim(line);

    if ~inLinearSolution
        if contains(line, 'Linear solution')
            inLinearSolution = true;
        end
        continue;
    end

    % Match "Node  N (" line
    tok = regexp(line, '^Node\s+(\d+)', 'tokens');
    if ~isempty(tok)
        currentNode = str2double(tok{1}{1});
        if currentNode > nnodes
            break;  % Done with original nodes
        end
        continue;
    end

    % Match "  dof N   d  VALUE" line
    if currentNode >= 1 && currentNode <= nnodes
        tok = regexp(line, 'dof\s+(\d+)\s+d\s+([-+]?\d+\.?\d*[eE]?[-+]?\d*)', 'tokens');
        if ~isempty(tok)
            dof = str2double(tok{1}{1});
            val = str2double(tok{1}{2});
            if dof >= 1 && dof <= 6
                displ(currentNode, dof) = val;
            end
        end
    end
end

fclose(fid);
end
