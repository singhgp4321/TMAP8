endtime = 20000

# scale = 1e19

# temperature = 703 # K

length_unit = 1e6 # number of length units in a meter
conc_unit = 1e16

[Mesh]
  [cmg]
    type = CartesianMeshGenerator
    dim = 1
    # dx = '1.0e-9 4.0e-9 4.0e-9 4.0e-9 4.0e-9 4.0e-9 1e-8 1e-7 1e-6 1e-5 5.4319e-5 5.4319e-5 5.4319e-5 5.4319e-5 5.4319e-5 5.4319e-5 5.4319e-5 5.4319e-5 5.4319e-5' # in meters

    # dx = '1e-3 4.0e-3 4.0e-3 4.0e-3 4.0e-3 4.0e-3 1e-2 1e-1 1.0 10.0 54.319 54.319 54.319 54.319 54.319 54.319 54.319 54.319 54.319' # in microns
    # subdomain_id = '0 1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1'

    dx = '2.0e-4 2.0e-4 2.0e-4 2.0e-4 2.0e-4 4.0e-3 4.0e-3 4.0e-3 4.0e-3 4.0e-3 1e-2 1e-1 1.0 10.0 54.319 54.319 54.319 54.319 54.319 54.319 54.319 54.319 54.319' # in microns
    subdomain_id = '0 0 0 0 0 1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1'
  []

  # [interface]
  #   type = SideSetsBetweenSubdomainsGenerator
  #   input = cmg
  #   primary_block = '0' # Implantation zone
  #   paired_block = '1' # Rest of the sample
  #   new_boundary = 'interface'
  # []
  # [interface_other_side]
  #   type = SideSetsBetweenSubdomainsGenerator
  #   input = interface
  #   primary_block = '1' # Rest of the sample
  #   paired_block = '0' # Implantation zone
  #   new_boundary = 'interface_other'
  # []
[]

[Functions]
  [implantation_flux]
    type = PiecewiseLinear
    x = '0'
    y = '4.9e19'
    # x = '0 5820 5820.1 9060 9060.1 12160 12160.1 14472 14472.1 17678 17678.1 20000'
    # y = '4.9e19 4.9e19 0 0 4.9e19 4.9e19 0 0 4.9e19 4.9e19 0 0'
    scale_factor = '${fparse 1/conc_unit}'
  []
  [enclosure_pressure]
    type = PiecewiseLinear
    # x = '0.0 '
    # y = '1.0'
    x = '0 5820 5820.1 9060 9060.1 12160 12160.1 14472 14472.1 17678 17678.1 20000'
    y = '4e-5 4e-5 9e-6 9e-6 4e-5 4e-5 9e-6 1.9e-6 4e-5 4e-5 9e-6 9e-6'
  []
  [Kd_func_left]
    type = ADParsedFunction
    expression = '8.959e18*(1.0-0.999997*exp(-1.2e-4*t))/${conc_unit}' # '0.8959*(1.0-0.999997*exp(-1.2e-4*t))'
  []
  [Kr_func_left]
    type = ADParsedFunction
    expression = '7.0e-27*(1.0-0.999997*exp(-1.2e-4*t))*${conc_unit}'
  []
  [Kd_func_right]
    type = ADParsedFunction
    expression = '1.7918e15/${conc_unit}'
  []
  [Kr_func_right]
    type = ADParsedFunction
    expression = '2.0e-31*${conc_unit}'
  []
  [max_time_step_size_func]
    type = ParsedFunction
    expression = 'if(t < 10000, 100, 200)'
  []
[]

[AuxVariables]
  [u2]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [u2_aux]
    type = FunctionAux
    variable = u2
    function = enclosure_pressure
  []
[]

[Variables]
  [u]
  []
[]

[Kernels]
  [species_source]
    type = ADBodyForce
    function = implantation_flux
    variable = u
    block = 0
  []
  [diff_u]
    type = ADMatDiffusion
    variable = u
    diffusivity = '${fparse 3.0e-10*length_unit^2}'
  []
  [time_u]
    type = ADTimeDerivative
    variable = u
  []
[]

[Materials]
  [Function_materials]
    type = ADGenericFunctionMaterial
    prop_names = 'Kd_left Kr_left Kd_right Kr_right'
    prop_values = 'Kd_func_left Kr_func_left Kd_func_right Kr_func_right'
    outputs = all
  []
[]

[BCs]
  [u_recombination_left]
    type = BinaryRecombinationBC
    variable = 'u'
    v = 'u'
    Kr = Kr_left
    boundary = 'left'
  []
  [u_recombination_right]
    type = BinaryRecombinationBC
    variable = 'u'
    v = 'u'
    Kr = Kr_right
    boundary = 'right'
  []
  [u2_dissociation_left]
    type = DissociationFluxBC
    variable = 'u'
    v = 'u2'
    Kd = Kd_left
    boundary = 'left'
  []
  [u2_dissociation_right]
    type = DissociationFluxBC
    variable = 'u'
    v = 'u2'
    Kd = Kd_right
    boundary = 'right'
  []

  # [right]
  #   type = ADNeumannBC
  #   variable = u
  #   boundary = 'right'
  #   value = 0
  # []
  # [left]
  #   type = ADDirichletBC
  #   variable = u
  #   boundary = 'left'
  #   value = 10
  # []
[]

[Postprocessors]
  [outflux_left]
    type = ADSideDiffusiveFluxAverage
    boundary = 'left'
    diffusivity = '${fparse 3.0e-10*length_unit^2}'
    variable = u
    outputs = none
  []
  [scaled_outflux_left]
    type = ScalePostprocessor
    value = outflux_left
    scaling_factor = '${fparse -1.0*conc_unit}'
  []
  [outflux_right]
    type = ADSideDiffusiveFluxAverage
    boundary = 'right'
    diffusivity = '${fparse 3.0e-10*length_unit^2}'
    variable = u
    outputs = none
  []
  [scaled_outflux_right]
    type = ScalePostprocessor
    value = outflux_right
    scaling_factor = '${fparse -1.0*conc_unit}'
  []
  [max_time_step_size_pp]
    type = FunctionValuePostprocessor
    function = max_time_step_size_func
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = none
  []
[]

[Preconditioning]
  [SMP]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient
  scheme = bdf2
  solve_type = NEWTON
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-7
  l_tol = 1e-4
  end_time = ${endtime}
  automatic_scaling = true
  line_search = 'none'

  [TimeSteppers]
    [timestepper1]
      type = IterationAdaptiveDT
      dt = 0.0001
      optimal_iterations = 4
      growth_factor = 1.1
      cutback_factor = 0.5

      # timestep_limiting_postprocessor = max_time_step_size_pp
    []
  []
  # steady_state_detection = true
[]

[Outputs]
  exodus = true
  [csv]
    type = CSV
  []
  perf_graph = true
[]
