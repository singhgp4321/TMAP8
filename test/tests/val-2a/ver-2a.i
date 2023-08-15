endtime = 0.01
Krtt = 1.0
# scale = 1e20
# temperature = 703 # K

length_unit = 1e6 # number of length units in a meter
conc_unit = 1e19

[Mesh]
  [cmg]
    type = CartesianMeshGenerator
    dim = 1
    # dx = '1.0e-9 4.0e-9 4.0e-9 4.0e-9 4.0e-9 4.0e-9 1e-8 1e-7 1e-6 1e-5 5.4319e-5 5.4319e-5 5.4319e-5 5.4319e-5 5.4319e-5 5.4319e-5 5.4319e-5 5.4319e-5 5.4319e-5' # in meters
    dx = '1.0e-3 4.0e-3 4.0e-3 4.0e-3 4.0e-3 4.0e-3 1e-2 1e-1 1.0 10.0 54.319 54.319 54.319 54.319 54.319 54.319 54.319 54.319 54.319' # in microns
    subdomain_id = '0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1'
  []
  [interface]
    type = SideSetsBetweenSubdomainsGenerator
    input = cmg
    primary_block = '0' # Implantation zone
    paired_block = '1' # Rest of the sample
    new_boundary = 'interface'
  []
  [interface_other_side]
    type = SideSetsBetweenSubdomainsGenerator
    input = interface
    primary_block = '1' # Rest of the sample
    paired_block = '0' # Implantation zone
    new_boundary = 'interface_other'
  []
[]

[Functions]
  [implantation_flux]
    type = PiecewiseLinear
    x = '0 '
    y = '4.9  '
    # scale_factor = 22000
  []
[]

[Variables]
  [u]
  []
  # [u2]
  # []
[]

[Kernels]
  [species_source]
    type = ADBodyForce
    # value = 100
    function = implantation_flux
    variable = u
    block = 0
  []
  [diff]
    type = ADMatDiffusion
    variable = u
    diffusivity = '${fparse 3.0e-10*length_unit^2}' # '${fparse length_unit/length_unit}'
  []
  [time]
    type = ADTimeDerivative
    variable = u
  []
[]

[Materials]
  [Krtt_material]
    type = ADConstantMaterial
    property_name = 'Krtt_name'
    value = ${Krtt}
    outputs = all
  []
[]

[BCs]
  # [left]
  #   type = ADMolecularRecombinationBC2
  #   variable = u
  #   boundary = 'left'
  #   alpha_o = 2.0e-4
  #   Kro = 1e-3
  #   beta = 6.0e-5
  #   fluence = '${fparse 3.9e17 / (60.0 * (1.0e-2 * length_unit)^2)}'
  # []

  [u_recombination]
    type = BinaryRecombinationBC
    variable = 'u'
    v = 'u'
    Kr = Krtt_name
    boundary = 'left right'
  []

  [right]
    type = ADNeumannBC
    variable = u
    boundary = 'right'
    value = 0
  []
  [left]
    type = ADDirichletBC
    variable = u
    boundary = 'left'
    value = 10
  []
[]

[Postprocessors]
  [outflux_left]
    type = ADSideDiffusiveFluxAverage
    boundary = 'left'
    diffusivity = 1
    variable = u
    outputs = none
  []
  [scaled_outflux_left]
    type = ScalePostprocessor
    value = outflux_left
    scaling_factor = '${fparse -1.0*conc_unit}'
  []
  # [outflux_right]
  #   type = SideDiffusiveFluxAverage
  #   boundary = 'right'
  #   diffusivity = 1
  #   variable = u
  #   outputs = none
  # []
  # [scaled_outflux_right]
  #   type = ScalePostprocessor
  #   value = outflux_right
  #   scaling_factor = '${fparse -1.0*conc_unit}'
  # []
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
  steady_state_detection = true
[]

[Outputs]
  exodus = true
  [csv]
    type = CSV
  []
  perf_graph = true
[]
