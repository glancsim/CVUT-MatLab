function codeNumbers = codeNumb (beam,nodes)
    p = 0 ;
    for n = 1:nodes.nnodes                
        for k = 1:nodes.dimdofs
            if nodes.dofs(n,k) == 1
                nodes.codeDofs(n,k) = p+1;
                p = p+1;
                else
                nodes.codeDofs(n,k) = 0;   
            end
        end
    end
    for b = 1:beam.nbeam
        codeNumbers(b,1:nodes.dimdofs) = nodes.codeDofs(beam.nodes1(b),:);
        codeNumbers(b,nodes.dimdofs+1:2*nodes.dimdofs) = nodes.codeDofs(beam.nodes2(b),:)    ;    
    end
    
end

