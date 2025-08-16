function InputOpts = defineProbabilisticModels(section, forces, snow)
    
    % Yeild strength
    model.f_y.V_x = 5 / 100; % percent
    model.f_y.ratio = 1.09 ;
    model.f_y.Dist = 'Lognormal';
    model.f_y.nominal = section.f_y;
    model.f_y.variable = createUQVariable(model.f_y, 'fy');
    InputOpts.Marginals(1) = model.f_y.variable;

    % Ultimate tensile strength
    model.f_u.V_x = 5 / 100; % percent
    model.f_u.ratio = 1.09 ;
    model.f_u.Dist = 'Lognormal';
    model.f_u.nominal = section.f_u;
    model.f_u.variable = createUQVariable(model.f_u, 'fu');
    InputOpts.Marginals(2) = model.f_u.variable;
    
    % Geometry
    model.a_s.V_x = 3 / 100; % percent
    model.a_s.ratio = 1.00 ;
    model.a_s.Dist = 'Gaussian';
    model.a_s.nominal = section.A_s;
    model.a_s.variable = createUQVariable(model.a_s, 'As');
    InputOpts.Marginals(3) = model.a_s.variable;
    
    % Self weight load
    model.G_s.V_x = 5 / 100 ;% percent
    model.G_s.ratio = 1.00 ;
    model.G_s.Dist = 'Gaussian';
    model.G_s.nominal = forces.G_s.N_k;
    model.G_s.variable = createUQVariable(model.G_s, 'G');
    InputOpts.Marginals(4) = model.G_s.variable;
    
    % Pernament load
    model.G_p.V_x = 10 / 100 ;% percent
    model.G_p.ratio = 1.00 ;
    model.G_p.Dist = 'Gaussian';
    model.G_p.nominal = forces.G_p.N_k;
    model.G_p.variable = createUQVariable(model.G_p, 'G');
    InputOpts.Marginals(5) = model.G_p.variable;
    
    
    % Resistance model uncertainty yeild stength
    model.theta_Ry.V_x = 5 / 100; % percent
    model.theta_Ry.ratio = 1.00 ;
    model.theta_Ry.Dist = 'Lognormal';
    model.theta_Ry.nominal = 1;
    model.theta_Ry.variable = createUQVariable(model.theta_Ry, 'ThetaR');
    InputOpts.Marginals(6) = model.theta_Ry.variable;

    % Resistance model uncertainty tensile stength
    model.theta_Ru.V_x = 5 / 100; % percent
    model.theta_Ru.ratio = 1.10 ;
    model.theta_Ru.Dist = 'Lognormal';
    model.theta_Ru.nominal = 1;
    model.theta_Ru.variable = createUQVariable(model.theta_Ru, 'ThetaR');
    InputOpts.Marginals(7) = model.theta_Ru.variable;
    
    % Load effect model uncertainty
    model.theta_E.V_x = 7.5 / 100 ;% percent
    model.theta_E.ratio = 1.00 ;
    model.theta_E.Dist = 'Lognormal';
    model.theta_E.nominal = 1;
    model.theta_E.variable = createUQVariable(model.theta_E, 'ThetaE');
    InputOpts.Marginals(8) = model.theta_E.variable;

    % Shape coeficient
    model.C_0.V_x = 20 / 100 ;% percent
    model.C_0.ratio = 0.64 ;
    model.C_0.Dist = 'Lognormal';
    model.C_0.nominal = 0.8;
    model.C_0.variable = createUQVariable(model.C_0, 'C0');
    InputOpts.Marginals(9) = model.C_0.variable;

    % Shape coeficient
    model.S_g.V_x = 50 / 100 ;% percent
    model.S_g.ratio = 0.40 ;
    model.S_g.Dist = 'Gumbel';
    model.S_g.nominal = snow.s_k;
    model.S_g.variable = createUQVariable(model.S_g, 'Sg');
    InputOpts.Marginals(10) = model.S_g.variable;

    
end