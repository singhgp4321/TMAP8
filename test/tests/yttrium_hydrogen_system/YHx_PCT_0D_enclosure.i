# Adaptation of YHx_PCT.i where the gas (enclosure 1) is modeled as a 0D,
# spatially-uniform enclosure instead of a 1D diffusion field.
#
# - partial_pressure is a SCALAR variable (same value everywhere) holding the
#   H2 partial pressure in the gas enclosure (Pa).
# - It depletes as atomic H diffuses into the YHx slab surface, via the
#   integrated surface flux fed into EnclosureSinkScalarKernel.
# - The YHx surface concentration is held at the PCT-equilibrium value
#   C_eq = f_at(T, P) * density_Y, reproducing the physics of
#   ADMatInterfaceReactionYHxPCT but driven by the scalar pressure.
#   (The PCT *interface* kernel cannot be used here because it requires a
#    gas-side field neighbor variable, which no longer exists.)

# Physical constants
R = '${units 8.31446261815324 J/mol/K}' # ideal gas constant from PhysicalConstants.h
N_a = '${units 6.02214076e23 1/mol}' # Avogadro's number from PhysicalConstants.h

# Simulation conditions and material properties
temperature = '${units 1200 K}'
density_Y = '${units 48605 mol/m^3}'
initial_pressure_H2_enclosure = '${units 1e4 Pa}'
initial_atomic_fraction = 1.8 # (-)
initial_concentration_H_YHx = '${units ${fparse initial_atomic_fraction*density_Y} mol/m^3}'

# 0D gas enclosure parameters  ---  SET THESE TO YOUR GEOMETRY
# The depletion rate scales with surface_area/volume_enclosure.
volume_enclosure = '${units 5e-4 m^3}' # gas enclosure volume
surface_area = '${units 1 m^2}' # contact area between the enclosure and the YHx surface
# Converts an atomic-H concentration rate to an H2 pressure rate: zeta = R*T/2
# (the /2 is because two H atoms form one H2 molecule, consistent with P = R*T*c/2).
concentration_to_pressure_conversion_factor = '${fparse R * temperature / 2}' # Pa*m^3/mol

# YHx PCT-curve coefficients, precomputed at the (constant) temperature.
# Valid range of the correlation: pressure_plateau < P < 1e6 Pa.
pressure_plateau = '${fparse exp(-26.1 + 3.88e-2 * temperature - 9.7e-6 * temperature * temperature)}' # Pa
fat_coeff_1 = '${fparse 21.6 - 0.0225 * temperature}'
fat_coeff_2 = '${fparse -0.0445 + 7.18e-4 * temperature}'

# diffusivity from Majer et al., Journal of Alloys and Compounds 330-332 (2002) 438-442.
diffusivity_Do = '${units 1.e-8 m^2/s}'
diffusivity_Ea = '${units 0.38 eV -> J}'

# Domain size and mesh parameters (YHx slab only; gas is now 0D)
slab_thickness = '${units 0.5 m}'
num_nodes = 8

# time
simulation_time = '${units 1e9 s}'
dt_max = '${fparse simulation_time/100}'
dt_init = '${units 1e-3 s}'

# convergence parameters
lower_value_threshold_concentration_YHx = -1e-20

# file base
output_file_base = 'YHx_PCT_0D_enclosure_out'

[Mesh]
  # Only the YHx slab is meshed. 'left' is the surface in contact with the gas
  # enclosure; 'right' is the sealed far end (zero-flux natural BC).
  [generated]
    type = GeneratedMeshGenerator
    dim = 1
    nx = ${num_nodes}
    xmax = ${slab_thickness}
  []
[]

[Variables]
  # H concentration in the YHx slab (mol/m^3)
  [concentration_H_YHx]
    initial_condition = '${initial_concentration_H_YHx}'
  []
  # H2 partial pressure in the 0D gas enclosure (Pa), uniform in space
  [partial_pressure]
    family = SCALAR
    order = FIRST
    initial_condition = '${initial_pressure_H2_enclosure}'
  []
[]

[Bounds]
  # To prevent negative concentrations
  [concentration_H_YHx_lower_bound]
    type = ConstantBounds
    variable = bounds_dummy_concentration_H_YHx
    bounded_variable = concentration_H_YHx
    bound_type = lower
    bound_value = ${lower_value_threshold_concentration_YHx}
  []
[]

[Kernels]
  # Diffusion equation for H in the YHx slab
  [H_time_derivative_YHx]
    type = TimeDerivative
    variable = concentration_H_YHx
  []
  [H_diffusion_YHx]
    type = MatDiffusion
    variable = concentration_H_YHx
    diffusivity = diffusivity_YHx
  []
[]

[ScalarKernels]
  # dP/dt term for the enclosure pressure
  [pressure_time_derivative]
    type = ODETimeDerivative
    variable = partial_pressure
  []
  # Sink: pressure drops as H diffuses into the YHx surface.
  # residual = flux * surface_area / volume * (R*T/2)
  [pressure_sink]
    type = EnclosureSinkScalarKernel
    variable = partial_pressure
    flux = scaled_flux_surface # positive = H leaving the enclosure into the YHx
    surface_area = '${surface_area}'
    volume = '${volume_enclosure}'
    concentration_to_pressure_conversion_factor = '${concentration_to_pressure_conversion_factor}'
  []
[]

[BCs]
  # The YHx surface in contact with the gas is held at the PCT-equilibrium
  # concentration corresponding to the current enclosure pressure.
  [surface_equilibrium]
    type = PostprocessorDirichletBC
    variable = concentration_H_YHx
    boundary = 'left'
    postprocessor = surface_equilibrium_concentration
  []
  # 'right' (far end of the slab) has no BC -> zero-flux (sealed sample),
  # so H leaving the enclosure is conserved within enclosure + slab.
[]

[AuxVariables]
  [temperature]
    initial_condition = '${temperature}'
  []
  [bounds_dummy_concentration_H_YHx]
    order = FIRST
    family = LAGRANGE
  []
[]

[Materials]
  [diffusivity_YHx]
    type = DerivativeParsedMaterial
    property_name = diffusivity_YHx
    coupled_variables = 'temperature'
    expression = '${diffusivity_Do} * exp(-${fparse diffusivity_Ea*N_a/R}/temperature)'
    outputs = exodus
  []
[]

[Postprocessors]
  # Current value of the scalar enclosure pressure (Pa)
  [partial_pressure_value]
    type = ScalarVariable
    variable = partial_pressure
    execute_on = 'initial linear nonlinear timestep_end'
    outputs = 'csv console'
  []
  # PCT-equilibrium surface concentration C_eq = f_at(T, P) * density_Y (mol/m^3).
  # f_at = 2 - 1 / (1 + exp(a1 + a2 * log(max(P - P_lim, 1e-10))))
  [surface_equilibrium_concentration]
    type = ParsedPostprocessor
    pp_names = 'partial_pressure_value'
    expression = '(2 - 1 / (1 + exp(${fat_coeff_1} + ${fat_coeff_2} '
                 '* log(max(partial_pressure_value - ${pressure_plateau}, 1e-10))))) * ${density_Y}'
    execute_on = 'initial linear nonlinear timestep_end'
    outputs = 'csv console'
  []
  # Equilibrium atomic fraction imposed at the surface (-)
  [surface_atomic_fraction]
    type = ParsedPostprocessor
    pp_names = 'surface_equilibrium_concentration'
    expression = 'surface_equilibrium_concentration / ${density_Y}'
    execute_on = 'initial timestep_end'
    outputs = 'csv console'
  []
  # Actual H concentration at the YHx surface (mol/m^3)
  [concentration_H_YHx_at_surface]
    type = SideAverageValue
    boundary = 'left'
    variable = concentration_H_YHx
    execute_on = 'initial timestep_end'
    outputs = 'csv console'
  []
  # Diffusive flux of H through the gas-contact surface
  [flux_surface]
    type = SideDiffusiveFluxIntegral
    variable = concentration_H_YHx
    diffusivity = diffusivity_YHx
    boundary = 'left'
    execute_on = 'initial linear nonlinear timestep_end'
    outputs = ''
  []
  # Scale so that a positive value means H leaving the enclosure (entering YHx)
  [scaled_flux_surface]
    type = ScalePostprocessor
    scaling_factor = -1
    value = flux_surface
    execute_on = 'initial linear nonlinear timestep_end'
    outputs = 'csv console'
  []

  # --- inventories for monitoring mass conservation ---
  # H inventory in the gas enclosure (mol): 2 * n_H2 = 2 * P*V/(R*T) = P*V/zeta
  [enclosure_H_inventory]
    type = ParsedPostprocessor
    pp_names = 'partial_pressure_value'
    expression = 'partial_pressure_value * ${volume_enclosure} / ${concentration_to_pressure_conversion_factor}'
    execute_on = 'initial timestep_end'
    outputs = 'csv console'
  []
  # H inventory in the YHx slab (mol). The 1D integral (mol/m^2) is scaled by the
  # contact surface_area to be consistent with the 0D enclosure coupling.
  [slab_H_inventory]
    type = ElementIntegralVariablePostprocessor
    variable = concentration_H_YHx
    execute_on = 'initial timestep_end'
    outputs = 'csv console'
  []
[]

[Preconditioning]
  [smp]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient
  end_time = ${simulation_time}
  dtmax = ${dt_max}
  nl_max_its = 16
  l_max_its = 30
  nl_rel_tol = 1e-7
  nl_abs_tol = 4e-12
  scheme = 'bdf2'
  solve_type = 'Newton'
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_type -snes_type'
  petsc_options_value = 'lu       mumps                      vinewtonrsls' # This petsc option helps prevent negative concentrations with bounds'
  line_search = 'none'
  automatic_scaling = true
  compute_scaling_once = true
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = ${dt_init}
    optimal_iterations = 13
    iteration_window = 1
    growth_factor = 1.2
    cutback_factor = 0.9
    cutback_factor_at_failure = 0.9
  []
[]

[Outputs]
  file_base = ${output_file_base}
  csv = true
  exodus = true
[]
