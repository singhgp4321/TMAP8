initial_temp = '${units 300 K}'
dt_init = '${units 0.5 s}'
# dt_max = '${units 2.0 s}'
endtime = '${units 100 s}'

R = '${units 8.31446261815324 J/mol/K}' # ideal gas constant from PhysicalConstants.h
N_a = '${units 6.02214076e23 1/mol}' # Avogadro's number from PhysicalConstants.h
boltzmann_constant = '${units 1.380649e-23 J/K}' # Boltzmann constant from PhysicalConstants.h

density_Y = '${units 48605 mol/m^3}'
initial_pressure_H2_gas = '${units 1e4 Pa}'
initial_concentration_H_gas = '${units ${fparse 2 * initial_pressure_H2_gas / (R * initial_temp)} mol/m^3}'
initial_atomic_fraction = 1.8 # (-)
initial_concentration_H_YHx = '${units ${fparse initial_atomic_fraction * density_Y} mol/m^3}'

# Diffusivity from Majer et al., Journal of Alloys and Compounds 330-332 (2002) 438-442.
diffusivity_Do = '${units 1.e-8 m^2/s}'
diffusivity_Ea = '${units 0.38 eV -> J}'
diffusivity_ratio_gas_YHx = '${fparse initial_concentration_H_YHx / initial_concentration_H_gas * 10}' # this ratio is large and helps InterfaceDiffusion due to the ratio of concentrations

# Surface reaction rate from P. W. Fisher, M. Tanase, Journal of Nuclear Materials 122-123 (1984) 1536-1540.
reaction_rate_0 = '${units 4.95e5 1/s}'
reaction_rate_Ea = '${units 1.52 eV -> J}'

# tau_constant_BC = '${fparse dt_init*2e-2}' # the smaller, the faster the up-ramp for the pressure BC

# Convergence parameters
lower_value_threshold_concentration_gas = 0.0 # -1e-20
lower_value_threshold_concentration_YHx = 0.0 # -1e-20

[GlobalParams]
  outputs = all
  displacements = 'disp_x'
[]

[Mesh]
  coord_type = RZ

  # ============ Sample (r = [0, 0.5] cm) ============
  [sample]
    type = GeneratedMeshGenerator
    dim = 1
    xmin = 0
    xmax = 0.5
    nx = 350
    boundary_name_prefix = 'sample'
  []

  # ============ Chamber (r = [0.5, 0.505] cm) ============
  [chamber]
    type = GeneratedMeshGenerator
    dim = 1
    xmin = 0.5
    xmax = 0.505
    nx = 6
    boundary_name_prefix = 'chamber'
  []

  # ============ Stitch radially ============
  [stitch]
    type = StitchMeshGenerator
    inputs = 'sample chamber'
    stitch_boundaries_pairs = 'sample_right chamber_left'
    clear_stitched_boundary_ids = true
  []

  # ============ Rename boundaries ============
  [rename]
    type = RenameBoundaryGenerator
    input = stitch
    old_boundary = 'sample_left chamber_right'
    new_boundary = 'left outer'
  []

  # ============ Scale to meters ============
  [scale]
    type = TransformGenerator
    input = rename
    transform = SCALE
    vector_value = '0.01 1 1'
  []

  # ============ Assign subdomains ============
  # First assign everything to chamber
  [assign_all_chamber]
    type = SubdomainBoundingBoxGenerator
    input = scale
    bottom_left = '0 -1 -1'
    top_right = '0.006 1 1'
    block_id = 2
    block_name = 'chamber'
  []
  # Then carve out the sample region
  [assign_sample]
    type = SubdomainBoundingBoxGenerator
    input = assign_all_chamber
    bottom_left = '0 -1 -1'
    top_right = '0.00500 1 1'
    block_id = 1
    block_name = 'sample'
  []

  # ============ Interface sideset ============
  [interface_sideset]
    type = SideSetsBetweenSubdomainsGenerator
    input = assign_sample
    primary_block = chamber
    paired_block = sample
    new_boundary = 'interface'
  []
[]

[Variables]
# ===================== VARIABLES ==========================

  [temp]
    initial_condition = '${initial_temp}'
  []
  [h_conc]
    initial_condition = '${initial_concentration_H_YHx}'
    block = sample
  []
  [h_conc_gas]
    initial_condition = '${initial_concentration_H_gas}'
    block = chamber
  []
  [disp_x]
  []
[]

[AuxVariables]
# ================== AUXILIARY VARIABLES ================

  [pressure_H2_gas]
    initial_condition = '${initial_pressure_H2_gas}'
  []
  [bounds_dummy_concentration_H_gas]
    order = FIRST
    family = LAGRANGE
  []
  [bounds_dummy_concentration_H_YHx]
    order = FIRST
    family = LAGRANGE
  []
[]

[Problem]
  type = ReferenceResidualProblem
  extra_tag_vectors = 'ref'
  reference_vector = 'ref'
[]

[Functions]
# ======================= FUNCTIONS ========================

  # -------------- SURFACE TEMPERATURE FUNCTION -----------

  [surface_temperature_function]
    type = ParsedFunction
    expression = '300 + 10.0 * t'
  []

  # ------------- TIMESTEP LIMITING FUNCTION -------------

  [dtmax_function]
    type = PiecewiseLinear
    x = '0     34.0   34.1'
    y = '2.0   2.0    1e-1'
  []

  # ------------- THERMAL EXPANSION FUNCTIONS -------------

  [cte_func_mean_185] # H/Y = 1.85
    type = ParsedFunction
    symbol_names = 'a1 b1 c1 d1 a2 b2 c2 d2 scale'
    symbol_values = '-0.29 0.037 -4.88e-5 3.16e-8 -380.5 1.26 -1.33e-3 4.68e-7 1.0e-6'
    expression = 'cte1 := scale * (a1 + b1*t + c1*t*t + d1*t*t*t);
                  cte2 := scale * (a2 + b2*t + c2*t*t + d2*t*t*t);
                  if(t<900, cte1, cte2)'
  []
[]


[Bounds]
# ======================= BOUNDS ==========================

  [concentration_H_gas_lower_bound]
    type = ConstantBounds
    variable = bounds_dummy_concentration_H_gas
    bounded_variable = h_conc_gas
    bound_type = lower
    bound_value = ${lower_value_threshold_concentration_gas}
  []
  [concentration_H_YHx_lower_bound]
    type = ConstantBounds
    variable = bounds_dummy_concentration_H_YHx
    bounded_variable = h_conc
    bound_type = lower
    bound_value = ${lower_value_threshold_concentration_YHx}
  []
[]

[BCs]
# ====================== HEAT BCs =========================

  [surface_temperature]
    type = ADFunctionDirichletBC
    boundary = 'outer'
    variable = temp
    function = surface_temperature_function
  []

# ====================== DIFFUSION BCs ========================

  [h_conc_gas_outer_fixed]
    type = ADDirichletBC
    boundary = 'outer'
    variable = h_conc_gas
    value = 8.0
  []

  # ===================== MECHANICS BCs ========================

  [symmetry_r]
    type = ADDirichletBC
    boundary = left
    variable = disp_x
    value = 0
  []
[]

[Kernels]
# ====================== HEAT KERNELS =========================

  [heat]
    type = ADHeatConduction
    variable = temp
    extra_vector_tags = 'ref'
  []
  [heat_ie]
    type = ADHeatConductionTimeDerivative
    variable = temp
    extra_vector_tags = 'ref'
  []
  [enthalpy_heat_gen]
    type = ADEnthalpyHeatSource
    variable = temp
    c = h_conc
    block = sample
    extra_vector_tags = 'ref'
  []

# ==================== MECHANICS KERNELS ======================

  [stress_div_x]
    type = ADStressDivergenceRZTensors
    variable = disp_x
    component = 0
    extra_vector_tags = 'ref'
  []

# ==================== DIFFUSION KERNELS ======================

  [time_YHx]
    type = ADTimeDerivative
    variable = h_conc
    block = sample
    extra_vector_tags = 'ref'
  []
  [time_gas]
    type = ADTimeDerivative
    variable = h_conc_gas
    block = chamber
    extra_vector_tags = 'ref'
  []
  [diff_YHx]
    type = ADMatDiffusion
    variable = h_conc
    diffusivity = diffusivity_YHx
    block = sample
    extra_vector_tags = 'ref'
  []
  [diff_gas]
    type = ADMatDiffusion
    variable = h_conc_gas
    diffusivity = diffusivity_gas
    block = chamber
    extra_vector_tags = 'ref'
  []
[]

[AuxKernels]
# ====================== AUXILIARY KERNELS ===================
  [pressure_H2_gas]
    type = ParsedAux
    variable = pressure_H2_gas
    coupled_variables = 'h_conc_gas temp'
    expression = '${R} * temp * h_conc_gas/2'
    block = chamber
    execute_on = 'initial timestep_end'
  []
[]

[Materials]
# ==================== HEAT MATERIALS ========================
  [density]
    type = ADStrainAdjustedDensity
    strain_free_density = 4270
    block = sample
  []
  [density_chamber]
    type = ADGenericConstantMaterial
    prop_names = 'density'
    prop_values = '100.0'
    block = chamber
  []
  # [thermal_sample]
  #   type = ADHeatConductionMaterial
  #   thermal_conductivity = 16.0
  #   specific_heat = 330.0
  #   block = sample
  # []
  [specific_heat_152] # Atomic ratio 1.52
    type = ADParsedMaterial
    property_name = specific_heat_152
    coupled_variables = 'temp'
    constant_names =       'T_thresh scale
                            a_lo b_lo c_lo d_lo
                            a_hi b_hi c_hi d_hi
                            a_tr b_tr c_tr d_tr'
    constant_expressions = '920.0 1000.0
                            0.44 -4.25e-4 1.25e-6 0.0
                            0.97  0.097  -0.097 0.054
                            -4.64e-13 17.91 1321.0 -0.24'
    expression = 'T_tr := a_tr * exp(b_tr * temp) + c_tr * exp(d_tr * temp);
                  a := if(temp < T_thresh, a_lo, a_hi);
                  b := if(temp < T_thresh, b_lo, b_hi);
                  c := if(temp < T_thresh, c_lo, c_hi);
                  d := if(temp < T_thresh, d_lo, d_hi);
                  Cp_poly := (a + b*temp + c*temp*temp + d*temp*temp*temp)*scale;
                  Cp_exp  := (a + b*cos(c*temp) + d*sin(c*temp))*scale;
                  if(temp < T_tr, Cp_poly, Cp_exp)'
    block = sample
    outputs = all
  []
  [specific_heat_188] # Atomic ratio 1.88
    type = ADParsedMaterial
    property_name = specific_heat_188
    coupled_variables = 'temp'
    constant_names =       'T_thresh scale
                            a_lo b_lo c_lo d_lo
                            a_hi b_hi c_hi d_hi
                            a_tr b_tr c_tr d_tr'
    constant_expressions = '648.0 1000.0
                            5.35e-2 1.20e-3 -2.26e-7 0.0
                            2.23e-10 -4.09e-2 0.35 9.88e-4
                            -4.64e-13 17.91 1321.0 -0.24'
    expression = 'T_tr := a_tr * exp(b_tr * temp) + c_tr * exp(d_tr * temp);
                  a := if(temp < T_thresh, a_lo, a_hi);
                  b := if(temp < T_thresh, b_lo, b_hi);
                  c := if(temp < T_thresh, c_lo, c_hi);
                  d := if(temp < T_thresh, d_lo, d_hi);
                  Cp_poly := (a + b*temp + c*temp*temp + d*temp*temp*temp)*scale;
                  Cp_exp  := (a * exp(b*temp) + c * exp(d*temp))*scale;
                  if(temp < T_tr, Cp_poly, Cp_exp)'
    block = sample
    outputs = all
  []
  [specific_heat]
    type = ADParsedMaterial
    property_name = specific_heat
    coupled_variables = 'h_conc'
    material_property_names = 'specific_heat_152 specific_heat_188'
    expression = 'max(400, specific_heat_152 + (h_conc/${density_Y}-1.52)*(specific_heat_188-specific_heat_152)/(1.88-1.52))'
    outputs = all
    block = sample
  []
  # [thermal_conductivity_sample]
  #   type = ADGenericConstantMaterial
  #   prop_names = 'thermal_conductivity'
  #   prop_values = '50.0'
  #   block = sample
  #   outputs = all
  # []
  [thermal_conductivity_152]
    type = ADParsedMaterial
    property_name = tc_152
    coupled_variables = 'temp'
    constant_names = 'a c scale'
    constant_expressions = '0.035 -10.7 1e-4'
    expression = '(a*temp + c)*scale'
    outputs = all
    block = sample
  []
  [thermal_conductivity_188]
    type = ADParsedMaterial
    property_name = tc_188
    coupled_variables = 'temp'
    constant_names = 'a c scale'
    constant_expressions = '0.016 -2.46 1e-4'
    expression = '(a*temp + c)*scale'
    outputs = all
    block = sample
  []
  [thermal_conductivity]
    type = ADParsedMaterial
    property_name = thermal_conductivity
    coupled_variables = 'h_conc'
    material_property_names = 'tc_152 tc_188'
    expression = 'max(5.0, tc_152 + (h_conc/${density_Y}-1.52)*(tc_188-tc_152)/(1.88-1.52))'
    outputs = all
    block = sample
  []
  [thermal_chamber]
    type = ADHeatConductionMaterial
    thermal_conductivity = 50.0
    specific_heat = 100.0
    block = chamber
  []
  [enthalpy]
    type = ADEnthalpyMaterial
    temperature = temp
    concentration = h_conc
    scaling_factor = 1.0
    block = sample
  []
  # ===================== DIFFUSION MATERIALS =====================

  [diffusivity_YHx]
    type = ADDerivativeParsedMaterial
    property_name = diffusivity_YHx
    coupled_variables = 'temp'
    expression = '${diffusivity_Do} * exp(-${fparse diffusivity_Ea*N_a/R}/temp)'
    outputs = exodus
  []
  [diffusivity_gas]
    type = ADDerivativeParsedMaterial
    property_name = diffusivity_gas
    material_property_names = diffusivity_YHx
    expression = '${diffusivity_ratio_gas_YHx} * diffusivity_YHx'
    outputs = exodus
    block = chamber
  []
  [reaction_rate_surface_YHx_1]
    type = ADDerivativeParsedMaterial
    property_name = reaction_rate_surface_YHx
    coupled_variables = 'temp'
    expression = '${reaction_rate_0} * exp(-${fparse reaction_rate_Ea/boltzmann_constant}/temp)' # 1/s
    block = chamber
  []
  [reaction_rate_surface_YHx_2]
    type = ADDerivativeParsedMaterial
    property_name = reaction_rate_surface_YHx
    coupled_variables = 'temp'
    expression = '${reaction_rate_0} * exp(-${fparse reaction_rate_Ea/boltzmann_constant}/temp)' # 1/s
    block = sample
  []

  # ==================== MECHANICS MATERIALS =====================

  [strain_sample]
    type = ADComputeAxisymmetric1DFiniteStrain
    eigenstrain_names = 'swelling thermal_expansion_eigenstrain'
    block = sample
  []
  [strain_chamber]
    type = ADComputeAxisymmetric1DFiniteStrain
    eigenstrain_names = 'thermal_expansion_eigenstrain'
    block = chamber
  []
  [elasticity_tensor_sample]
    type = ADYHElasticityTensor
    youngs_modulus_Y = 66e9
    youngs_modulus_YH = 140e9
    poissons_ratio = 0.27
    hydrogen_concentration = h_conc
    hydrogen_equilibrium_concentration = ${density_Y} # conc of H in YH = conc of Y
    block = sample
  []
  [elasticity_tensor_chamber]
    type = ADComputeIsotropicElasticityTensor
    poissons_ratio = 0.3
    youngs_modulus = 1e9
    block = chamber
  []
  [stress]
    type = ADComputeFiniteStrainElasticStress
  []
  [swelling_eigenstrain]
    type = ADYHVolumetricSwellingEigenstrain
    hydrogen_concentration = h_conc
    hydrogen_equilibrium_concentration = ${initial_concentration_H_YHx}
    y_concentration = ${density_Y}
    eigenstrain_name = swelling
    outputs = all
    block = sample
  []
  [thermal_expansion_strain]
    type = ADComputeMeanThermalExpansionFunctionEigenstrain
    thermal_expansion_function = cte_func_mean_185
    thermal_expansion_function_reference_temperature = 300.0
    stress_free_temperature = 300.0
    temperature = temp
    eigenstrain_name = thermal_expansion_eigenstrain
    outputs = all
  []
[]

[InterfaceKernels]
  [interface_diffusion]
    type = ADInterfaceDiffusion
    variable = h_conc_gas
    neighbor_var = h_conc
    boundary = interface
    D = diffusivity_YHx
    D_neighbor = diffusivity_gas
  []
  [interface_reaction_YHx_PCT]
    type = ADMatInterfaceReactionYHxPCT
    variable = h_conc_gas
    neighbor_var = h_conc
    neighbor_temperature = temp
    density = ${density_Y}
    boundary = interface
    forward_rate = 'reaction_rate_surface_YHx'
    backward_rate = 'reaction_rate_surface_YHx'
  []
[]

[Preconditioning]
  [SMP]
    type = SMP
    full = true
  []
[]

[Debug]
  show_var_residual_norms = true
[]

[Executioner]
  type = Transient
  solve_type = 'NEWTON'

  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type -snes_type'
  petsc_options_value = 'lu superlu_dist vinewtonrsls'

  l_tol = 1e-7
  l_max_its = 100
  nl_max_its = 15
  nl_abs_tol = 1e-4
  nl_rel_tol = 1e-5
  start_time = 0.0

  end_time = ${endtime}

  line_search = bt

  [TimeStepper]
    type = IterationAdaptiveDT
    dt = ${dt_init}
    optimal_iterations = 13
    iteration_window = 1
    growth_factor = 1.5
    cutback_factor = 0.5
    cutback_factor_at_failure = 0.5
    timestep_limiting_postprocessor = dtmax_pp
  []

  n_max_nonlinear_pingpong = 3

  automatic_scaling = true
  compute_scaling_once = false
[]

[Postprocessors]
  [dtmax_pp]
    type = FunctionValuePostprocessor
    function = dtmax_function
    execute_on = 'initial timestep_end'
    outputs = none
  []
[]
[Outputs]
  exodus = true
  csv = false
[]
