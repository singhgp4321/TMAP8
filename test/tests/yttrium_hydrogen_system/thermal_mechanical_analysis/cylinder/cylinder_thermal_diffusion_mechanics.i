initial_temp = '${units 300 K}'
dt_init = '${units 0.5 s}'
dt_max = '${units 5.0 s}'
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

tau_constant_BC = '${fparse dt_init*2e-2}' # the smaller, the faster the up-ramp for the pressure BC

# Convergence parameters
lower_value_threshold_concentration_gas = -1e-20
lower_value_threshold_concentration_YHx = -1e-20

[GlobalParams]
  outputs = all
  displacements = 'disp_x disp_y disp_z'
[]

[Mesh]
  [circle_mesh]
    type = ConcentricCircleMeshGenerator
    num_sectors = 6
    radii = '0.095 0.18 0.255 0.32 0.375 0.42 0.455 0.48 0.495 0.49595 0.4968 0.49755 0.4982 0.49875 0.4992 0.49955 0.4998 0.49995 0.49998 0.49999 0.5 0.50001 0.50002 0.50005 0.5002 0.50045 0.5008 0.50125 0.5018 0.50245 0.5032 0.50405 0.505'
    rings = '1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1'
    has_outer_square = false #on
    pitch = 1.42063
    preserve_volumes = off
    smoothing_max_it = 3
  []
  [extruder]
    type = AdvancedExtruderGenerator
    input = circle_mesh
    direction = '0 0 1'
    heights    = '0.005  0.5  0.5  0.005'   # bottom cap, lower half, upper half, top cap
    num_layers = '5      10   10   5'
    biases     = '0.5    2    0.5  2'      # caps biased toward interface
    bottom_boundary = 'bottom'
    top_boundary = 'top'
    subdomain_swaps = '1 22 2 22 3 22 4 22 5 22 6 22 7 22 8 22 9 22 10 22 11 22 12 22 13 22 14 22 15 22 16 22 17 22 18 22 19 22 20 22 21 22;
                       ;
                       ;
                       1 22 2 22 3 22 4 22 5 22 6 22 7 22 8 22 9 22 10 22 11 22 12 22 13 22 14 22 15 22 16 22 17 22 18 22 19 22 20 22 21 22'
  []
  [scale]
    type = TransformGenerator
    input = extruder
    transform = SCALE
    vector_value = '0.01 0.01 0.01'  # scale x, y, z independently
  []
  [rename_sample]
    type = RenameBlockGenerator
    input = scale
    old_block = '1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21'
    new_block = 'sample sample sample sample sample sample sample sample sample sample sample sample sample sample sample sample sample sample sample sample sample'
  []
  [rename_chamber]
    type = RenameBlockGenerator
    input = rename_sample
    old_block = '22 23 24 25 26 27 28 29 30 31 32 33'
    new_block = 'chamber chamber chamber chamber chamber chamber chamber chamber chamber chamber chamber chamber'
  []
  [interface_sideset]
    type = SideSetsBetweenSubdomainsGenerator
    input = rename_chamber
    primary_block = chamber
    paired_block = sample
    new_boundary = 'interface'
  []
  [nodes_along_y]
    type = ExtraNodesetGenerator
    nodes = '492 1332'
    new_boundary = nodes_along_y
    input = interface_sideset
  []
  [nodes_along_x]
    type = ExtraNodesetGenerator
    nodes = '912 480'
    new_boundary = nodes_along_x
    input = nodes_along_y
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
  group_variables = 'disp_x disp_y disp_z'
[]

[Physics/SolidMechanics/QuasiStatic]
  [sample]
    strain = FINITE
    incremental = true
    add_variables = true
    use_automatic_differentiation = true
    generate_output = 'max_principal_stress stress_xx stress_yy stress_zz stress_xy stress_yz stress_xz strain_yy strain_xx strain_zz strain_xy strain_xz strain_yz'
    eigenstrain_names = 'swelling thermal_expansion_eigenstrain'
    # eigenstrain_names = 'thermal_expansion_eigenstrain'
    extra_vector_tags = 'ref'
    block = sample
  []
  [chamber]
    strain = FINITE
    incremental = true
    add_variables = true
    use_automatic_differentiation = true
    generate_output = 'max_principal_stress stress_xx stress_yy stress_zz stress_xy stress_yz stress_xz strain_yy strain_xx strain_zz strain_xy strain_xz strain_yz'
    # eigenstrain_names = 'swelling thermal_expansion_eigenstrain'
    eigenstrain_names = 'thermal_expansion_eigenstrain'
    extra_vector_tags = 'ref'
    block = chamber
  []
[]

[Functions]
# ======================= FUNCTIONS ========================

  # ----------------- DIFFUSION BC AT SURFACE -------------

  [function_BC_concentration_H_gas]
    type = ParsedFunction
    expression = 'exp(-${tau_constant_BC}/t)* ${initial_concentration_H_gas}'
  []

  # -------------- SURFACE TEMPERATURE FUNCTION -----------

  [surface_temperature_function]
    type = ParsedFunction
    expression = '300 + 10.0 * t'
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

  # [cte_func_mean_185]
  #   type = ParsedFunction
  #   expression = '1e-6'
  # []
  # [cte_func_mean_161]
  #   type = ParsedFunction
  #   expression = '1e-6'
  # []
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

  # [bottom_temp]
  #   type = DirichletBC
  #   boundary = bottom
  #   variable = temp
  #   value = 300
  # []
  # [input_heat_flux]
  #   type = ADNeumannBC
  #   boundary = 'top bottom outer'
  #   variable = temp
  #   value = 1e5
  # []
  [surface_temperature]
    type = ADFunctionDirichletBC
    boundary = 'outer top bottom'
    variable = temp
    function = surface_temperature_function
  []

# ====================== DIFFUSION BCs ========================

  # [h_conc_gas_outer_fixed]
  #   type = FunctionDirichletBC
  #   variable = h_conc_gas
  #   boundary = 'outer top bottom'
  #   function = 'function_BC_concentration_H_gas'
  # []

  [convective_mass_loss]
    type = ADConvectiveHeatFluxBC
    variable = h_conc_gas
    boundary = 'outer top bottom'
    T_infinity_functor = 8.0        # far-field concentration (mol/m^3)
    heat_transfer_coefficient_functor = 1e-2  # mass transfer coefficient (m/s)
  []

  # ===================== MECHANICS BCs ========================

  [disp_x]
    type = ADDirichletBC
    boundary = nodes_along_y
    variable = disp_x
    value = 0
  []
  [disp_y]
    type = ADDirichletBC
    boundary = nodes_along_x
    variable = disp_y
    value = 0
  []
  [disp_z]
    type = ADDirichletBC
    boundary = 'nodes_along_x nodes_along_y'
    variable = disp_z
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
  []

# ==================== DIFFUSION KERNELS ======================

  [time_YHx]
    type = ADTimeDerivative
    variable = h_conc
    block = sample
  []
  [time_gas]
    type = ADTimeDerivative
    variable = h_conc_gas
    block = chamber
  []
  [diff_YHx]
    type = MatDiffusion
    variable = h_conc
    diffusivity = diffusivity_YHx
    block = sample
  []
  [diff_gas]
    type = MatDiffusion
    variable = h_conc_gas
    diffusivity = diffusivity_gas
    block = chamber
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
  # [density_sample]
  #   type = ADGenericConstantMaterial
  #   prop_names = 'density'
  #   prop_values = '4270.0'
  #   block = sample
  # []
  [density_chamber]
    type = ADGenericConstantMaterial
    prop_names = 'density'
    prop_values = '100.0'
    block = chamber
  []
  [thermal_sample]
    type = ADHeatConductionMaterial
    thermal_conductivity = 16.0
    specific_heat = 330.0
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
    scaling_factor = 0.0
    block = sample
  []
  # ===================== DIFFUSION MATERIALS =====================

  [diffusivity_YHx]
    type = DerivativeParsedMaterial
    property_name = diffusivity_YHx
    coupled_variables = 'temp'
    expression = '${diffusivity_Do} * exp(-${fparse diffusivity_Ea*N_a/R}/temp)'
    outputs = exodus
    # block = sample
  []
  [diffusivity_gas]
    type = DerivativeParsedMaterial
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

  [elasticity_tensor_sample]
    type = ADYHElasticityTensor
    youngs_modulus_Y = 66e9
    youngs_modulus_YH = 140e9
    poissons_ratio = 0.27
    hydrogen_concentration = h_conc
    # h_conc_scale_factor = ${fparse 1/h_conc_scaling_factor}
    hydrogen_equilibrium_concentration = ${initial_concentration_H_YHx}
    block = sample
  []
  [elasticity_tensor_chamber]
    type = ADComputeIsotropicElasticityTensor
    poissons_ratio = 0.3
    youngs_modulus = 1e9 #************************************************
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
    type = InterfaceDiffusion
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

  # petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart -snes_type'
  # petsc_options_value = 'hypre boomeramg 201 vinewtonrsls'

  # petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart'
  # petsc_options_value = 'hypre boomeramg 201'

  petsc_options_iname = '-pc_type -snes_type'
  petsc_options_value = 'lu vinewtonrsls'

  l_tol = 1e-7
  l_max_its = 100
  nl_max_its = 15
  nl_abs_tol = 1e-9
  nl_rel_tol = 1e-7
  start_time = 0.0
  
  # num_steps = 10
  dtmax = ${dt_max}
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
  []

  automatic_scaling = true
  compute_scaling_once = false
[]

[Outputs]
  exodus = true
  csv = false
[]