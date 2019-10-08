l=10
nx=100
num_steps=10

[Mesh]
  type = GeneratedMesh
  dim = 1
  xmax = ${l}
  nx = ${nx}
[]

[Variables]
  [u]
  []
  [lm]
  []
[]

[ICs]
  [u]
    type = FunctionIC
    variable = u
    function = '${l} - x'
  []
[]

[Kernels]
  [time]
    type = TimeDerivative
    variable = u
  []
  [diff]
    type = Diffusion
    variable = u
  []
  [ffn]
    type = BodyForce
    variable = u
    function = '-1'
  []
[]

[NodalKernels]
  [positive_constraint]
    type = RequirePositiveNCPNodalKernel
    variable = lm
    v = u
    exclude_boundaries = 'left right'
  []
  [forces]
    type = CoupledForceNodalKernel
    variable = u
    v = lm
  []
[]


[BCs]
  [left]
    type = DirichletBC
    boundary = left
    value = ${l}
    variable = u
  []
  [right]
    type = DirichletBC
    boundary = right
    value = 0
    variable = u
  []
[]

[NodalKernels]
[]

[Preconditioning]
  [smp]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient
  num_steps = ${num_steps}
  solve_type = NEWTON
  petsc_options_iname = '-snes_max_linear_solve_fail -ksp_max_it -pc_factor_levels -snes_linesearch_type'
  petsc_options_value = '0                           30          16                basic'
[]

[Outputs]
  exodus = true
  [dof]
    type = DOFMap
    execute_on = 'initial'
  []
[]

[Debug]
  show_var_residual_norms = true
[]

[Postprocessors]
  [active_lm]
    type = LMActiveSetSize
    variable = lm
    execute_on = 'nonlinear timestep_end'
    value = 1e-12
  []
  [violations]
    type = LMActiveSetSize
    variable = u
    execute_on = 'nonlinear timestep_end'
    value = -1e-8
    comparator = 'less'
  []
[]
