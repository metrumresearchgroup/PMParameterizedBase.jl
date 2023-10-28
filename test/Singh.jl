singh = @model Singh begin
    @IVs t [unit = u"hr", description = "Independent variable (time in hours)", tspan = (0.0, 24.0)]
    Dt = Differential(t)

    @constants begin
        mg_to_g = 1E-3, [unit = u"mg/g", description = "convert mg to g"]
        mol_to_nmol = 1E9, [unit = u"mol/nmol", description = "convert mol to nmol"]
        ug_to_g = 1E-6, [unit = u"μg/g", description = "convert ug to g"]
        mL_to_L = 1E-3, [unit = u"mL/L", description = "convert mL to L"]
        um_to_cm = 1E-4, [unit = u"μm/cm", description = "convert um to cm"]
        day_to_h = 24, [unit = u"d/hr", description = "convert day to h"]
        cm3_to_mm3 = 1E3, [unit = u"cm^3/mm^3", description = "convert cm^3 to mm^3"]
        mm3_to_L = 1E-6, [unit = u"L*mm^-3", description = "convert mm^3 to L"]
        MW = 148781, [unit = "g/mol", description = "T-DM1 molecular weight (Scheuher et al 2022)"]
    end


     @parameters begin 
        BW = 70, [unit = u"kg", description = "Body Weight"]
        k_on_ADC = 0.37, [unit = u"(nmol*L^-1)^-1*hr^-1", description = "2nd-order association rate constant between T-DM1 and HER2 antigen"]
        k_off_ADC = 0.097, [unit = u"hr^-1", description = "dissociation rate constant between T-DM1 and HER2 antigen"]
        k_int_ADC = 0.09, [unit=u"hr^-1", description ="internalization rate of the HER2-T-DM1 complex inside the cell"]
        k_deg_ADC = 0.03, [unit=u"hr^-1", description="proteasomal degradation rate of T-DM1 in endosomal/lysosomal space"]
        k_on_Tub = 0.03, [unit=u"(nmol*L^-1)^-1*hr^-1", description ="2nd-order association rate constant between DM1 catabolites and intracellular tubulin protein"]
        k_off_Tub = 0.0285, [unit=u"hr^-1", description="dissociation rate constant between tubulin catabolites and tubulin protein"]
        Tub_total = 65, [unit=u"nmol*L^-1", description ="total concentration of intracellular tubulin protein"]
        k_dec_ADC = 0.0223, [unit=u"hr^-1" description="non-specific deconjugation rate of T-DM1 from the extracellular space"]
        k_diff_Drug = 0.092, [unit=u"hr^-1", description="bidirectional diffusion rate constant for DM1 catabolites in the intracellular and extracellular space"]
        k_out_Drug = 0, [unit=u"hr^-1", description="active efflux rate constant of DM1 catabolites from the intracellular space to extracellular space"]
        Ag_total = 1660, [unit=u"nmol*L^-1", description="(Ag_total_HER2 3+) total antigen expression levels derived using the number of HER2 receptors per cell and the number of cells packed in a liter volume assuming the volume of a cell as 1 pl"]
        # Parameters associated with tumor disposition of T-DM1
        R_Cap = 8.0*um_to_cm, [unit=u"cm", description="radius of the tumor blood capillary"]
        R_Krogh = 75.0*um_to_cm, [unit=u"cm", description="an average distance between two capillaries"]
        P_ADC = 334*um_to_cm/day_to_h, [unit=u"cm*hr^-1", description="rate of permeability of T-DM1 across the blood vessels"]
        P_Drug = 21000*um_to_cm/day_to_h, [unit=u"cm*hr^-1", description="rate of permeability of DM1 catabolites across the blood vessels"]
        D_ADC = 0.022/day_to_h, [unit=u"mm^2*hr^-1", description="rate of diffusion of T-DM1 across the blood vessels"]
        D_Drug = 0.25/day_to_h, [unit=u"mm^2*hr^-1", description="rate of diffusion of DM1 catabolites across the blood vessels"]
        varepsilon_ADC = 0.24,[description="tumor void volume for T-DM1"]
        varepsilon_Drug = 0.44,[description="tumor void volume for DM1 catabolites"]
        # Parameters associated with systemic pharmacokinetics in Human
        CL_ADC = 0.0043/day_to_h , [unit=u"L*hr^-1*kg^-1", description="central clearance of ADC"]
        CLD_ADC = 0.014/day_to_h, [unit=u"L*hr^-1*kg^-1", description="distributional clearance of ADC"]
        V1_ADC = 0.034, [unit=u"L*kg^-1", description="central volume of distribution of ADC"]
        V2_ADC = 0.04, [unit=u"L*kg^-1", description="peripheral volume of distribution of ADC"]
        CL_Drug = 2.23/day_to_h, [unit=u"L*hr^-1*kg^-1", description="central clearance of DM1 catabolites"]
        CLD_Drug = 1.0/day_to_h, [unit=u"L*hr^-1*kg^-1", description="distributional clearance of DM1 catabolites"]
        V1_Drug = 0.034, [unit=u"L*kg^-1", description="central volume of distribution of DM1 catabolites"]
        V2_Drug = 5.0, [unit=u"L*kg^-1", description="peripheral volume of distribution of DM1 catabolites"]
        k_dec_ADC_plasma = 0.241/day_to_h, [unit=u"hr^-1", description="non-specific deconjugation rate constant for T-DM1 in the systemic circulation"]
        # Clinically reported breast cancer-related parameters used to build the translated PK-PD model
        k_growth_exponential = log(2)/(25/day_to_h), [unit=u"hr^-1", description="exponential growth phase of the tumor"]
        k_growth_linear = 621/day_to_h, [unit=u"mm^3*hr^-1", description="linear growth phase of the tumor"]
        Psi = 20.0#,[description="switch between exponential growth and linear growth phases"]
        V_max = 523.8*cm3_to_mm3, [unit=u"mm^3", description="maximum achievable tumor volume"]
        k_kill_max = 0.139/day_to_h, [unit=u"hr^-1" description="linear killing constant (Scheuher et al 2022)"]
        KC_50 = 23.8, [unit = u"nM", description = "concentration of drug (payload) corresponding to a killing rate constant of half maximum value (Scheuher et al 2022)"]
     end

     @variables begin
        (X1_ADC_nmol(t)=BW*KC_50), [unit = u"nmol", description = "amount of T-DM1 in the plasma central compartment,[nmol]"]
        (X2_ADC_nmol(t)=0.0), [unit = u"nmol", description = "amount of T-DM1 in the peripheral compartment"]
        (C_ADC_f_ex_nM(t)=0.0), [unit = u"nmol*L^-1", description = "concentration of T-DM1 in the tumor extracellular space"]
        (C_ADC_b_ex_nM(t)=0.0), [unit = u"nmol*L^-1", description = "concentration of T-DM1 bound to tumor cell surface,[nM]"]
        (C_ADC_endolyso_cell_nM(t)=0.0), [unit = u"nmol*L^-1", description = "concentration of internalized ADC within the lysosomal/endosomal space,[nM]"]
        (C_Drug_f_cell_nM(t)=0.0), [unit = u"nmol*L^-1", description = "concentration of unconjugated intracellular free DM1,[nM]"]
        (C_Drug_b_cell_nM(t)=0.0), [unit = u"nmol*L^-1", description = "concentration of unconjugated intracellular tubulin-bound DM1,[nM]"]
        (C_Drug_f_ex_nM(t)=0.0), [unit = u"nmol*L^-1", description = "concentration of free DM1 in the extracellular space of tumor,[nM]"]
        (C1_Drug_nM(t)=0.0), [unit = u"nmol*L^-1", description = "concentration of DM1 in the plasma central compartment,[nM]"]
        (C2_Drug_nM(t)=0.0), [unit = u"nmol*L^-1", description = "concentration of DM1 in the peripheral compartment,[nM]"]
        (DAR(t)=0.0), [description = "average number of DM1 molecules conjugated to Trastuzumab (unitless)"]
        (TV_mm3(t)=1.0), [unit = u"mm^3", description = "tumor volume [mm^3]"]
     end
          
    R_tumor = (3 * TV_mm3/(4*pi))^(1/3)


    @eq Dt(X1_ADC_nmol) ~ (
        -(CL_ADC/V1_ADC)*X1_ADC_nmol - (CLD_ADC/V1_ADC)*X1_ADC_nmol + (CLD_ADC/V2_ADC)*X2_ADC_nmol - k_dec_ADC_plasma*X1_ADC_nmol 
        - ((2*P_ADC*R_Cap)/(R_Krogh^2))*((X1_ADC_nmol/(V1_ADC*BW))*varepsilon_ADC - C_ADC_f_ex_nM)*(TV_mm3*mm3_to_L)
        - ((6*D_ADC)/((R_tumor)^2))*((X1_ADC_nmol/(V1_ADC*BW))*varepsilon_ADC - C_ADC_f_ex_nM)*(TV_mm3*mm3_to_L)
    )

    @eq Dt(X2_ADC_nmol) ~ (CLD_ADC/V1_ADC)*X1_ADC_nmol - (CLD_ADC/V2_ADC)*X2_ADC_nmol

    @eq Dt(C_ADC_f_ex_nM) ~ (
        ((2*P_ADC*R_Cap)/(R_Krogh^2))*((X1_ADC_nmol/(V1_ADC*BW))*varepsilon_ADC - C_ADC_f_ex_nM)
        + ((6*D_ADC)/((R_tumor)^2))*((X1_ADC_nmol/(V1_ADC*BW))*varepsilon_ADC - C_ADC_f_ex_nM) 
        - k_on_ADC*C_ADC_f_ex_nM*((Ag_total - C_ADC_b_ex_nM)/varepsilon_ADC) + k_off_ADC*C_ADC_b_ex_nM - k_dec_ADC*C_ADC_f_ex_nM
    )

    @eq Dt(C_ADC_b_ex_nM) ~ (
        k_on_ADC*C_ADC_f_ex_nM*((Ag_total - C_ADC_b_ex_nM)/varepsilon_ADC)
        - (k_off_ADC + k_int_ADC + k_dec_ADC)*C_ADC_b_ex_nM
    )

    @eq Dt(C_ADC_endolyso_cell_nM) ~ k_int_ADC*C_ADC_b_ex_nM - k_deg_ADC*C_ADC_endolyso_cell_nM

    @eq Dt(C_Drug_f_cell_nM) ~ (
        k_deg_ADC*DAR*C_ADC_endolyso_cell_nM - k_on_Tub*C_Drug_f_cell_nM*(Tub_total - C_Drug_b_cell_nM)
        + k_off_Tub*C_Drug_b_cell_nM - k_out_Drug*C_Drug_f_cell_nM + k_diff_Drug*(C_Drug_f_ex_nM - C_Drug_f_cell_nM)
    )

    @eq Dt(C_Drug_b_cell_nM) ~ k_on_Tub*C_Drug_f_cell_nM*(Tub_total - C_Drug_b_cell_nM) - k_off_Tub*C_Drug_b_cell_nM

    @eq Dt(C_Drug_f_ex_nM) ~ (
        ((2*P_Drug*R_Cap)/(R_Krogh^2))*(C1_Drug_nM*varepsilon_Drug - C_Drug_f_ex_nM)
        + ((6*D_Drug)/((R_tumor)^2))*(C1_Drug_nM*varepsilon_Drug - C_Drug_f_ex_nM)
        + k_out_Drug*C_Drug_f_cell_nM + k_dec_ADC*DAR*(C_ADC_f_ex_nM + C_ADC_b_ex_nM) - k_diff_Drug*(C_Drug_f_ex_nM - C_Drug_f_cell_nM)
    )

    @eq Dt(C1_Drug_nM) ~ (
        -(CL_Drug/V1_Drug)*C1_Drug_nM - (CLD_Drug/V1_Drug)*C1_Drug_nM
        + (CLD_Drug/V1_Drug)*C2_Drug_nM + (X1_ADC_nmol*DAR*k_dec_ADC_plasma)/(V1_Drug*BW)
        + (CL_ADC*DAR*(X1_ADC_nmol/V1_ADC))/(V1_Drug*BW)
        - ((2*P_Drug*R_Cap)/(R_Krogh^2))*(C1_Drug_nM*varepsilon_Drug - C_Drug_f_ex_nM)
        - ((6*D_Drug)/((R_tumor)^2))*(C1_Drug_nM*varepsilon_Drug - C_Drug_f_ex_nM)
    )
    @eq Dt(C2_Drug_nM) ~ (CLD_Drug/V2_Drug)*C1_Drug_nM - (CLD_Drug/V2_Drug)*C2_Drug_nM

    @eq Dt(DAR) ~ -k_dec_ADC_plasma*DAR

    @eq Dt(TV_mm3) ~ (
        ((k_growth_exponential*(1-(TV_mm3/V_max)))/((1+(k_growth_exponential*TV_mm3/k_growth_linear)^Psi^(1/Psi)))
        - (k_kill_max/(KC_50 + (C_Drug_f_cell_nM + C_Drug_b_cell_nM)))*(C_Drug_f_cell_nM + C_Drug_b_cell_nM))*TV_mm3
    )

    # convert model predicted amount [nmol] of T-DM1 in plasma to concentration [nM] and include in solution output
    @observed C1_ADC_nM = X1_ADC_nmol/(V1_ADC*BW);

    # convert model predicted amount [nmol] of T-DM1 in peripheral to concentration [nM]
    @observed C2_ADC_nM = X2_ADC_nmol/(V2_ADC*BW); # nM

    # convert model predicted tumor volume [mm3] to tumor diameter [cm]
    @observed TumorDiameter = 2*((3*(TV_mm3/cm3_to_mm3)/4*pi).^(1/3)); # cm
end;