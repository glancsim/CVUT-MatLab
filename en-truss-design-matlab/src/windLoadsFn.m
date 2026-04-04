function wind = windLoadsFn(v_b, terrain_cat, h, slope)
% windLoadsFn  Compute design wind pressure for a saddle-roof hall truss.
%
% Calculates peak velocity pressure q_p and pressure coefficients c_pe
% for transverse (Wt) and longitudinal (Wl) wind per EN 1991-1-4.
%
% INPUTS:
%   v_b          [m/s]    Basic wind speed (before directional/seasonal adj.)
%   terrain_cat  string   Terrain category: '0','I','II','III','IV'
%   h            [m]      Reference height = ridge height above ground
%   slope        [-]      Roof slope (rise/run, e.g. 0.05 = 5%)
%
% OUTPUTS:
%   wind  - struct with fields:
%     .q_b      [kN/m²]  Basic velocity pressure
%     .q_p      [kN/m²]  Peak velocity pressure at height h
%     .c_e      [-]      Exposure coefficient  q_p = c_e * q_b
%     .c_pe_Wt  [-]      c_pe,10 Zone H, transverse wind (θ = 0°) — suction
%     .c_pe_Wl  [-]      c_pe,10 Zone H, longitudinal wind (θ = 90°) — suction
%     .q_Wt     [kN/m²]  Design wind uplift, transverse  (> 0 = upward)
%     .q_Wl     [kN/m²]  Design wind uplift, longitudinal (> 0 = upward)
%     .alpha_deg [deg]   Roof pitch angle (for reference)
%
% Theory (EN 1991-1-4, §4.3–4.5):
%   k_r   = 0.19 * (z_0 / z_0,II)^0.07          roughness factor coefficient
%   c_r(z) = k_r * ln(max(z, z_min) / z_0)       roughness factor
%   v_m(z) = c_r * c_0 * v_b                     mean wind speed
%   I_v(z) = k_r / (c_0 * c_r)                   turbulence intensity
%   q_p(z) = (1 + 7*I_v) * 0.5 * ρ * v_m²  =  q_b * c_e(z)
%   c_e(z) = c_r(z)^2 + 7 * k_r * c_r(z)        (c_0 = 1 assumed)
%
% c_pe,10 for Zone H (Duopitch roof, θ=0°, Table 7.4a EN 1991-1-4):
%   interpolated linearly between tabulated pitches.
%
% (c) S. Glanc, 2026

%% --- Terrain parameters (EN 1991-1-4 Table 4.1) --------------------------
switch upper(strtrim(terrain_cat))
    case '0'
        z_0 = 0.003;   z_min = 1;
    case 'I'
        z_0 = 0.01;    z_min = 1;
    case 'II'
        z_0 = 0.05;    z_min = 2;
    case 'III'
        z_0 = 0.3;     z_min = 5;
    case 'IV'
        z_0 = 1.0;     z_min = 10;
    otherwise
        error('windLoadsFn: unknown terrain_cat ''%s''. Use ''0'',''I'',''II'',''III'',''IV''.', ...
              terrain_cat);
end
z_0_II = 0.05;   % reference roughness for category II

%% --- Roughness and turbulence (EN 1991-1-4 §4.3–4.4) --------------------
k_r  = 0.19 * (z_0 / z_0_II)^0.07;
z_e  = max(h, z_min);
c_r  = k_r * log(z_e / z_0);                    % roughness factor
c_0  = 1.0;                                      % orography factor (flat)
I_v  = k_r / (c_0 * c_r);                        % turbulence intensity

%% --- Velocity pressures (EN 1991-1-4 §4.5) ------------------------------
rho  = 1.25;                                       % air density [kg/m³]
q_b  = 0.5 * rho * v_b^2 * 1e-3;                 % [kN/m²]
c_e  = c_r^2 * c_0^2 + 7 * k_r * c_r * c_0;     % exposure coefficient
q_p  = c_e * q_b;                                 % [kN/m²]

%% --- Roof pitch ----------------------------------------------------------
alpha_deg = atan(slope) * 180 / pi;   % degrees

%% --- c_pe,10 Zone H, transverse wind θ=0° (EN 1991-1-4 Table 7.4a) -----
% Duopitch — suction coefficients for Zone H (valid for entire central span).
% Values for negative c_pe (suction dominant for uplift check):
%   α [deg]:  <=5    10     15     20     25    >=30
%   c_pe,H:  -0.60 -0.60  -0.50  -0.30  -0.20  -0.20
alpha_tbl = [5,   10,   15,   20,   25,   30];
cpe_H_tbl = [-0.60, -0.60, -0.50, -0.30, -0.20, -0.20];
c_pe_Wt   = interp1(alpha_tbl, cpe_H_tbl, ...
                    max(5, min(30, alpha_deg)), 'linear');

%% --- c_pe,10 Zone H, longitudinal wind θ=90° (EN 1991-1-4 §7.2.5) ------
% For θ=90°, Zone H is the main body of the roof; c_pe is approximately
% -0.6 across the full pitch range (Table 7.4b, θ=90°).
c_pe_Wl = -0.60;

%% --- Design wind uplift (positive = upward) ------------------------------
wind.q_b       = q_b;
wind.q_p       = q_p;
wind.c_e       = c_e;
wind.c_pe_Wt   = c_pe_Wt;
wind.c_pe_Wl   = c_pe_Wl;
wind.q_Wt      = -c_pe_Wt * q_p;   % suction → positive (upward); c_pe < 0
wind.q_Wl      = -c_pe_Wl * q_p;
wind.alpha_deg = alpha_deg;

fprintf('Vítr (EN 1991-1-4):  v_b = %.1f m/s,  terén %s,  h = %.1f m\n', ...
    v_b, terrain_cat, h);
fprintf('  q_b = %.3f kN/m²,  c_e = %.2f,  q_p = %.3f kN/m²\n', q_b, c_e, q_p);
fprintf('  α = %.1f°:  c_pe,Wt = %.2f  →  q_Wt = %.3f kN/m²\n', ...
    alpha_deg, c_pe_Wt, wind.q_Wt);
fprintf('           c_pe,Wl = %.2f  →  q_Wl = %.3f kN/m²\n', ...
    c_pe_Wl, wind.q_Wl);

end
