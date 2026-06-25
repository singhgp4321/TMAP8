# h_conc_scaling_factor = 1e9
density_Y = '${units 48605 mol/m^3}'

R = '${units 8.31446261815324 J/mol/K}' # ideal gas constant from PhysicalConstants.h
N_a = '${units 6.02214076e23 1/mol}' # Avogadro's number from PhysicalConstants.h
boltzmann_constant = '${units 1.380649e-23 J/K}' # Boltzmann constant from PhysicalConstants.h

initial_temp = '${units 1200 K}'
initial_pressure_H2_gas = '${units 1e4 Pa}'
initial_concentration_H_gas = '${units ${fparse 2 * initial_pressure_H2_gas / (R * initial_temp)} mol/m^3}'
initial_atomic_fraction = 1.8 # (-)
initial_concentration_H_YHx = '${units ${fparse initial_atomic_fraction * density_Y} mol/m^3}'

# diffusivity from Majer et al., Journal of Alloys and Compounds 330-332 (2002) 438-442.
diffusivity_Do = '${units 1.e-8 m^2/s}'
diffusivity_Ea = '${units 0.38 eV -> J}'
diffusivity_ratio_gas_YHx = '${fparse initial_concentration_H_YHx / initial_concentration_H_gas * 10}' # this ratio is large and helps InterfaceDiffusion due to the ratio of concentrations

# Surface reaction rate from P. W. Fisher, M. Tanase, Journal of Nuclear Materials 122-123 (1984) 1536-1540.
reaction_rate_0 = '${units 4.95e5 1/s}'
reaction_rate_Ea = '${units 1.52 eV -> J}'

dt_init = '${units 1e-3 s}'
tau_constant_BC = '${fparse dt_init*2e-2}' # the smaller, the faster the up-ramp for the pressure BC

[GlobalParams]
  outputs = all
[]

[Mesh]
  file = "./regenerable_moderator_model.e"
[]

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Variables]
  [h_conc]
    initial_condition = '${initial_concentration_H_YHx}'
    #'${fparse initial_concentration_H_gas/10.0}' # ${fparse 1.4 * h_conc_scaling_factor} #0.2
    block = sample
  []
  [h_conc_gas]
    initial_condition = '${initial_concentration_H_gas}' # ${fparse 1.4 * h_conc_scaling_factor} #0.2
    block = chamber
  []
  [temp]
    initial_condition = '${initial_temp}'
  []
[]

# [Problem]
#   material_coverage_check = false
# []

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
  [cte_func_mean_185] # H/Y = 1.85k
    type = ParsedFunction
    symbol_names = 'a1 b1 c1 d1 a2 b2 c2 d2 scale'
    symbol_values = '-0.29 0.037 -4.88e-5 3.16e-8 -380.5 1.26 -1.33e-3 4.68e-7 1.0e-6'
    expression = 'cte1 := scale * (a1 + b1*t + c1*t*t + d1*t*t*t);
                  cte2 := scale * (a2 + b2*t + c2*t*t + d2*t*t*t);
                  if(t<900, cte1, cte2)'
  []
  [cte_func_mean_161] # H/Y = 1.61
    type = ParsedFunction
    symbol_names = 'a1 b1 c1 d1 scale'
    symbol_values = '4.64 6.74e-3 1.32e-5 -1.06e-8 1.0e-6'
    expression = 'scale * (a1 + b1*t + c1*t*t + d1*t*t*t)'
  []
  [function_BC_concentration_H_gas]
    type = ParsedFunction
    expression = 'exp(-${tau_constant_BC}/t)* ${initial_concentration_H_gas}'
  []
[]

[AuxVariables]
  [pressure_H2_gas]
    initial_condition = '${initial_pressure_H2_gas}'
  []
[]

[BCs]
  # [surface_hydrogen_conc]
  #   type = ADDirichletBC
  #   boundary = outer #10
  #   variable = h_conc
  #   value = ${fparse 1.80 * h_conc_scaling_factor} #0.75
  # []
  [disp_x]
    type = ADDirichletBC
    boundary = chamber_negx
    variable = disp_x
    value = 0
  []
  [disp_y]
    type = ADDirichletBC
    boundary = chamber_negy
    variable = disp_y
    value = 0
  []
  [disp_z]
    type = ADDirichletBC
    boundary = chamber_negz
    variable = disp_z
    value = 0
  []
  # [bottom_temp]
  #   type = DirichletBC
  #   boundary = bottom
  #   variable = temp
  #   value = 300
  # []
  # [input_heat_flux]
  #   type = ADNeumannBC
  #   boundary = chamber_posx
  #   variable = temp
  #   value = 1e7
  # []
  # [Pressure]
  #   [pull_right]
  #     boundary = right
  #     function = 0 #1e6
  #   []
  # []
  [concentration_H_chamber_fixed]
    type = FunctionDirichletBC
    variable = h_conc_gas
    boundary = 'chamber_posx chamber_negx chamber_posy chamber_negy chamber_posz chamber_negz'
    function = 'function_BC_concentration_H_gas'
  []
[]

# [Constraints]
#   [disp_x]
#     type = EqualValueBoundaryConstraint
#     variable = disp_x
#     # primary = '3'
#     secondary = 'right'
#     penalty = 1e10
#   []
#   [disp_y]
#     type = EqualValueBoundaryConstraint
#     variable = disp_y
#     # primary = '3'
#     secondary = 'top'
#     penalty = 1e10
#   []
#   [disp_z]
#     type = EqualValueBoundaryConstraint
#     variable = disp_z
#     # primary = '5'
#     secondary = 'front'
#     penalty = 1e10
#   []
# []

[AuxKernels]
  [pressure_H2_gas]
    type = ParsedAux
    variable = pressure_H2_gas
    coupled_variables = 'h_conc_gas temp'
    expression = '${R} * temp * h_conc_gas/2'
    block = chamber
    execute_on = 'initial timestep_end'
  []
[]

[Kernels]
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
  [heat]
    type = ADHeatConduction
    variable = temp
  []
  [heat_ie]
    type = ADHeatConductionTimeDerivative
    variable = temp
  []
  [enthalpy_heat_gen]
    type = ADEnthalpyHeatSource
    variable = temp
    c = h_conc
    block = sample
    # h_conc_scale_factor = ${h_conc_scale_factor}
  []

  # [null]
  #   type = NullKernel
  #   variable = h_conc
  #   # block = 1
  # []
  # [null_x]
  #   type = Diffusion
  #   variable = h_conc #'disp_x'
  # []
  # [null_y]
  #   type = Diffusion
  #   variable = 'disp_y'
  # []
  # [null_z]
  #   type = Diffusion
  #   variable = 'disp_z'
  # []
[]

[Materials]
  # [mat_prop]
  #   type = ArrheniusDiffusionCoef
  #   arrhenius_prpty_name = 'diffusivity'
  #   d1 = 0.9e-8
  #   q1 = 8.49154e-20
  #   temperature = 1000
  # []

  #====================================================================
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
    expression = '${diffusivity_ratio_gas_YHx}*diffusivity_YHx'
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
  #====================================================================

  # [Ea] # Activation Energy (eV) Ref: Lin et al., IJHE, 2025
  #   type = ADPiecewiseLinearInterpolationMaterial
  #   xy_data = '${fparse 1.63*h_conc_scaling_factor} 0.53
  #              ${fparse 1.81*h_conc_scaling_factor} 0.54
  #              ${fparse 1.88*h_conc_scaling_factor} 0.60
  #              ${fparse 1.91*h_conc_scaling_factor} 0.75'
  #   property = Ea
  #   variable = h_conc
  # []
  # [D_o] # Diffusion constant (m2/s) Ref: Lin et al., IJHE, 2025
  #   type = ADPiecewiseLinearInterpolationMaterial
  #   xy_data = '${fparse 1.63*h_conc_scaling_factor} 0.00507e-4
  #              ${fparse 1.81*h_conc_scaling_factor} 0.00376e-4
  #              ${fparse 1.88*h_conc_scaling_factor} 0.00735e-4
  #              ${fparse 1.91*h_conc_scaling_factor} 0.03534e-4'
  #   property = D_o
  #   variable = h_conc
  # []
  # [diffusivity_YHx]
  #   type = ADParsedMaterial
  #   property_name = diffusivity_YHx
  #   coupled_variables = 'temp'
  #   constant_names = 'k_B'
  #   constant_expressions = '8.617333262e-5' # eV/K
  #   material_property_names = 'Ea D_o'
  #   expression = 'D_o * exp(-Ea/(k_B*temp))'
  #   outputs = exodus
  # []
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
    youngs_modulus = 1e9 # 10e9
    block = chamber
  []
  [stress]
    type = ADComputeFiniteStrainElasticStress
  []
  [swelling_eigenstrain]
    type = ADYHVolumetricSwellingEigenstrain
    hydrogen_concentration = h_conc
    hydrogen_equilibrium_concentration = ${initial_concentration_H_YHx}
    # h_conc_scale_factor = ${fparse 1/h_conc_scaling_factor}
    YH_swelling_strain = 0.071
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
  [density]
    type = ADStrainAdjustedDensity
    strain_free_density = 4270
  []
  [thermal]
    type = ADHeatConductionMaterial
    thermal_conductivity = 16.0
    specific_heat = 330.0
  []
  # [specific_heat]
  #   type = ParsedMaterial
  #   property_name = specific_heat
  #   coupled_variables = 'temp h_conc'
  #   constant_names = 'a1 b1 c1 d1 a2 b2 c2 d2 scale'
  #   constant_expressions = '0.035 0.0 -10.7 0.0 0.016 0.0 -2.46 0.0 1.0'
  #   expression = 'specific_heat_152 := scale * (a1 + b1*temp + c1*temp*temp + d1*temp*temp*temp) * 1e3;
  #                 specific_heat_188 := scale * (a2 + b2*temp + c2*temp*temp + d2*temp*temp*temp) * 1e3;
  #                 specific_heat_152 + (h_conc/${h_conc_scaling_factor}-1.52)*(specific_heat_188-specific_heat_152)/(1.88-1.52)'

  #   outputs = exodus
  # []
  # [thermal_conductivity]
  #   type = ParsedMaterial
  #   property_name = thermal_conductivity
  #   coupled_variables = 'temp h_conc'
  #   constant_names = 'a1 b1 c1 d1 a2 b2 c2 d2 scale'
  #   constant_expressions = '0.44 -4.25e-4 1.25e-6 0.0 5.35e-2 1.20e-3 -2.27e-7 0.0 1.0'
  #   material_property_names = 'density specific_heat'
  #   expression = 'therm_diff_152 := scale * (a1 + b1*temp + c1*temp*temp + d1*temp*temp*temp);
  #                 therm_diff_188 := scale * (a2 + b2*temp + c2*temp*temp + d2*temp*temp*temp);
  #                 therm_diff := therm_diff_152 + (h_conc/${h_conc_scaling_factor}-1.52)*(therm_diff_188-therm_diff_152)/(1.88-1.52);
  #                 therm_diff * density * specific_heat'
  #   outputs = exodus
  # []
  [enthalpy]
    type = ADEnthalpyMaterial
    temperature = temp
    concentration = h_conc
    scaling_factor = 0.0
    block = sample
  []
[]

[InterfaceKernels]
  [interface_diffusion]
    type = InterfaceDiffusion
    variable = h_conc_gas
    neighbor_var = h_conc
    boundary = sample_curved
    D = diffusivity_YHx
    D_neighbor = diffusivity_gas
  []
  [interface_reaction_YHx_PCT]
    type = ADMatInterfaceReactionYHxPCT
    variable = h_conc_gas
    neighbor_var = h_conc
    neighbor_temperature = temp
    density = ${density_Y}
    boundary = sample_curved
    forward_rate = 'reaction_rate_surface_YHx'
    backward_rate = 'reaction_rate_surface_YHx'
  []
[]

# [Adaptivity]
#   marker = combined
#   max_h_level = 1
#   initial_steps = 1
#   stop_time = 1
#   [Indicators]
#     [temp_grad_jump]
#       type = GradientJumpIndicator
#       variable = temp
#     []
#     [temp_value_jump]
#       type = ValueJumpIndicator
#       variable = temp
#     []
#     [conc_grad_jump]
#       type = GradientJumpIndicator
#       variable = conc_H
#     []
#     [conc_value_jump]
#       type = ValueJumpIndicator
#       variable = conc_H
#     []
#   []

#   [Markers]
#     [temp_value_marker]
#       type = ErrorToleranceMarker
#       indicator = temp_value_jump
#       coarsen = 0.1
#       refine = 0.1
#     []
#     [temp_grad_marker]
#       type = ErrorToleranceMarker
#       indicator = temp_grad_jump
#       coarsen = 0.1
#       refine = 0.1
#     []
#     [combined]
#       type = ComboMarker
#       # markers = 'errorfracpore'
#       # markers = 'pore_surface_adapt'
#       markers = 'temp_value_marker temp_grad_marker'
#     []
#   []
# []

[Preconditioning]
  [SMP]
    type = SMP
    full = true
  []
[]

# It converges faster if all the residuals are at the same magnitude
[Debug]
  show_var_residual_norms = true
[]

[Executioner]
  type = Transient
  # scheme = 'bdf2'
  solve_type = 'NEWTON'

  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart'
  petsc_options_value = 'hypre boomeramg 201'

  #  petsc_options_iname = '-ksp_type -pc_type -sub_pc_type -snes_max_it -sub_pc_factor_shift_type -pc_asm_overlap -snes_atol -snes_rtol -snes_type'
  #  petsc_options_value = 'gmres asm ilu 100 NONZERO 2 1E-14 1E-12 vinewtonrsls'

  l_tol = 1.0e-4
  l_max_its = 30
  nl_max_its = 30
  nl_rel_tol = 1.0e-5
  start_time = 0.0
  num_steps = 100
  line_search = none
  dt = ${dt_init} # 1e-2
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

[Postprocessors]
  [total_volume]
    type = ADElementIntegralMaterialProperty
    mat_prop = 1
    use_displaced_mesh = true
    execute_on = 'timestep_end'
  []
  [max_principal_stress]
    type = ElementExtremeValue
    variable = 'max_principal_stress'
    value_type = max
    execute_on = 'timestep_end'
  []
  [min_max_principal_stress]
    type = ElementExtremeValue
    variable = 'max_principal_stress'
    value_type = min
    execute_on = 'timestep_end'
  []
  [average_principal_stress]
    type = ElementAverageValue
    variable = 'max_principal_stress'
    execute_on = 'timestep_end'
  []
  # [average_u]
  #   type = ElementAverageValue
  #   variable = 'h_conc'
  #   execute_on = 'timestep_end'
  #   block = chamber
  # []
[]

[Outputs]
  exodus = true
  csv = true
[]
