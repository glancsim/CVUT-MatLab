function MAC = fnMAC(v1, v2)
% INPUT
%  v1, v2 = vektory vlastních tvarů
% OUTPUT 
%  MAC    = korelační koeficient

% vypočítání skalárního součinu
dot_product = dot(v1, v2);

% vypočítání norm
norm_v1 = norm(v1);
norm_v2 = norm(v2);

% vypočítání koeficientu korelace
MAC = dot_product / (norm_v1 * norm_v2)
end

