h_conc_scaling_factor = 1e9

[GlobalParams]
  outputs = all
[]

[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 10
    ny = 10
    nz = 10
    xmin = 0.0
    ymin = 0.0
    zmin = 0.0
    xmax = 1.0e-5
    ymax = 1.0e-5
    zmax = 1.0e-5
    bias_x = 2
  []
[]

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Variables]
  [h_conc]
    initial_condition = ${fparse 1.4 * h_conc_scaling_factor} #0.2
  []
  [temp]
    initial_condition = 298.0
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
  [all]
    strain = FINITE
    incremental = true
    add_variables = true
    generate_output = 'max_principal_stress stress_xx stress_yy stress_zz stress_xy stress_yz stress_xz strain_yy strain_xx strain_zz strain_xy strain_xz strain_yz'
    # eigenstrain_names = 'swelling thermal_expansion_eigenstrain'
    eigenstrain_names = 'thermal_expansion_eigenstrain'
    extra_vector_tags = 'ref'
  []
[]

[Functions]
  [cte_func_mean_185] # H/Y = 1.85
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
[]

# [AuxVariables]
# []

[BCs]
  [surface_hydrogen_conc]
    type = DirichletBC
    boundary = left #10
    variable = h_conc
    value = ${fparse 1.80 * h_conc_scaling_factor} #0.75
  []
  [left_x]
    type = DirichletBC
    boundary = left
    variable = disp_x
    value = 0
  []
  [bottom_y]
    type = DirichletBC
    boundary = bottom
    variable = disp_y
    value = 0
  []
  [back_z]
    type = DirichletBC
    boundary = back
    variable = disp_z
    value = 0
  []
  [bottom_temp]
    type = DirichletBC
    boundary = left
    variable = temp
    value = 300
  []
  [top_heat_flux]
    type = NeumannBC
    boundary = right
    variable = temp
    value = 1e5
  []
  [Pressure]
    [pull_right]
      boundary = right
      function = 1e4
    []
  []
[]

[Constraints]
  [disp_x]
    type = EqualValueBoundaryConstraint
    variable = disp_x
    # primary = '3'
    secondary = 'right'
    penalty = 1e10
  []
  [disp_y]
    type = EqualValueBoundaryConstraint
    variable = disp_y
    # primary = '3'
    secondary = 'top'
    penalty = 1e10
  []
  [disp_z]
    type = EqualValueBoundaryConstraint
    variable = disp_z
    # primary = '5'
    secondary = 'front'
    penalty = 1e10
  []
[]

[Kernels]
  [time]
    type = TimeDerivative
    variable = h_conc
  []
  [diff]
    type = MatDiffusion
    variable = h_conc
    diffusivity = diffusivity
  []
  [heat]
    type = HeatConduction
    variable = temp
  []
  [heat_ie]
    type = HeatConductionTimeDerivative
    variable = temp
  []
  [enthalpy_heat_gen]
    type = EnthalpyHeatSource
    variable = temp
    c = h_conc
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
  [Ea] # Activation Energy (eV) Ref: Lin et al., IJHE, 2025
    type = PiecewiseLinearInterpolationMaterial
    xy_data = '${fparse 1.63*h_conc_scaling_factor} 0.53
               ${fparse 1.81*h_conc_scaling_factor} 0.54
               ${fparse 1.88*h_conc_scaling_factor} 0.60
               ${fparse 1.91*h_conc_scaling_factor} 0.75'
    property = Ea
    variable = h_conc
  []
  [D_o] # Diffusion constant (m2/s) Ref: Lin et al., IJHE, 2025
    type = PiecewiseLinearInterpolationMaterial
    xy_data = '${fparse 1.63*h_conc_scaling_factor} 0.00507e-4
               ${fparse 1.81*h_conc_scaling_factor} 0.00376e-4
               ${fparse 1.88*h_conc_scaling_factor} 0.00735e-4
               ${fparse 1.91*h_conc_scaling_factor} 0.03534e-4'
    property = D_o
    variable = h_conc
  []
  [diffusivity]
    type = ParsedMaterial
    property_name = diffusivity
    coupled_variables = 'temp'
    constant_names = 'k_B'
    constant_expressions = '8.617333262e-5' # eV/K
    material_property_names = 'Ea D_o'
    expression = 'D_o * exp(-Ea/(k_B*temp))'
    outputs = exodus
  []
  [elasticity_tensor]
    type = YHElasticityTensor
    youngs_modulus_Y = 66e9
    youngs_modulus_YH = 140e9
    poissons_ratio = 0.27
    hydrogen_concentration = h_conc
    h_conc_scale_factor = ${fparse 1/h_conc_scaling_factor}
    hydrogen_equilibrium_concentration = 1
  []
  [stress]
    type = ComputeFiniteStrainElasticStress
  []
  # [swelling_eigenstrain]
  #   type = YHVolumetricSwellingEigenstrain
  #   hydrogen_concentration = h_conc
  #   hydrogen_equilibrium_concentration = 1
  #   h_conc_scale_factor = ${fparse 1/h_conc_scaling_factor}
  #   YH_swelling_strain = 0.071
  #   eigenstrain_name = swelling
  #   outputs = all
  # []
  [thermal_expansion_strain]
    type = ComputeMeanThermalExpansionFunctionEigenstrain
    thermal_expansion_function = cte_func_mean_185
    thermal_expansion_function_reference_temperature = 300.0
    stress_free_temperature = 300.0
    temperature = temp
    eigenstrain_name = thermal_expansion_eigenstrain
    outputs = all
  []
  [density]
    type = StrainAdjustedDensity
    strain_free_density = 4270
  []
  [thermal]
    type = HeatConductionMaterial
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
    type = EnthalpyMaterial
    temperature = temp
    concentration = h_conc
    scaling_factor = 0.0
  []
[]

# [Adaptivity]
#   marker = combined
#   max_h_level = 1
#   initial_steps = 1
#   stop_time = 1
#   [Indicators]
#     [grad_pore]
#       type = GradientJumpIndicator
#       variable = pore
#     []
#   []
#   [Markers]
#     [errorfracpore]
#       type = ErrorFractionMarker
#       indicator = grad_pore
#       refine = 0.8 #0.9
#       coarsen = 0.5 # 0.1
#     []
#     [pore_surface_adapt]
#       type = ValueRangeMarker
#       lower_bound = 0.01
#       upper_bound = 0.99
#       third_state = DO_NOTHING
#       variable = pore
#       invert = false
#     []
#     [combined]
#       type = ComboMarker
#       # markers = 'errorfracpore'
#       # markers = 'pore_surface_adapt'
#       markers = 'pore_surface_adapt errorfracpore'
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
  dt = 1

  automatic_scaling = true
  # compute_scaling_once = false
[]

[Postprocessors]
  [total_volume]
    type = ElementIntegralMaterialProperty
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
  [average_u]
    type = ElementAverageValue
    variable = 'h_conc'
    execute_on = 'timestep_end'
  []
[]

[Outputs]
  exodus = true
  csv = true
[]
