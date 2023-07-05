length_unit = 1e6 # number of length units in a meter
temperature = 703 # K

[Mesh]
  type = GeneratedMesh
  dim = 1
  nx = 100
  xmax = '${fparse 500 * length_unit}'
[]

[Variables]
  [u]
  []
[]

[Kernels]
  [diff]
    type = MatDiffusion
    variable = u
    diffusivity = '${fparse 3.0e-10*exp(-308000/(8.314*temperature))*length_unit^2}'
  []
  [time]
    type = TimeDerivative
    variable = u
  []
[]

[BCs]
  [left_right]
    type = ADMolecularRecombinationBC2
    variable = u
    boundary = 'left right'
    alpha = 2.0e-4
    Kro = 1e-3
    beta = 6.0e-5
    fluence = '${fparse 3.9e17 / (60.0 * (1.0e-2 * length_unit)^2)}'
  []
[]

[Postprocessors]
  [point0]
    type = PointValue
    variable = u
    point = '0 0 0'
  []
  [point10]
    type = PointValue
    variable = u
    point = '10 0 0'
  []
  [point12]
    type = PointValue
    variable = u
    point = '12 0 0'
  []
[]

[Executioner]
  type = Transient
  end_time = 100
  dt = .05
  solve_type = NEWTON
  petsc_options_iname = '-pc_type -pc_hypre_type'
  petsc_options_value = 'hypre boomeramg'
  l_tol = 1e-9
  # scheme = 'crank-nicolson'
  timestep_tolerance = 1e-8
[]

[Outputs]
  exodus = true
  [csv]
    type = CSV
  []
  perf_graph = true
[]
