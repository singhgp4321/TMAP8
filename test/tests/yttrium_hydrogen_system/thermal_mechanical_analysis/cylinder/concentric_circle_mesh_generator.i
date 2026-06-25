[Mesh]
  [circle_mesh]
    type = ConcentricCircleMeshGenerator
    num_sectors = 6
    # radii = '0.095 0.18 0.255 0.32 0.375 0.42 0.455 0.48 0.495 0.49595 0.4968 0.49755 0.4982 0.49875 0.4992 0.49955 0.4998 0.49995 0.5'
    # rings = '1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1'
    radii = '0.1        0.19501708 0.28502039 0.36997909 0.44986234
             0.52463929 0.59427909 0.65875089 0.71802386 0.77206715 0.82084992
             0.86434131 0.90251049 0.9353266  0.96275881 0.98477627 1.00134813
             1.01244355 1.01803168 1.01808168'
    rings = '1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1'
    has_outer_square = false #on
    pitch = 1.42063
    #portion = left_half
    preserve_volumes = off
    smoothing_max_it = 3
  []
  # [make3D]
  #   type = MeshExtruderGenerator
  #   extrusion_vector = '0 0 1'
  #   num_layers = 10
  #   bottom_sideset = 'bottom'
  #   top_sideset = 'top'
  #   input = circle_mesh
  # []

  # [extruder]
  #   type = AdvancedExtruderGenerator
  #   input = circle_mesh
  #   direction = '0 0 1'
  #   heights = '1.0'
  #   num_layers = '10'
  #   biases = '1.5'   # layers grow 1.5x each step along z
  # []

  [extruder]
    type = AdvancedExtruderGenerator
    input = circle_mesh
    direction = '0 0 1'
    heights    = '0.5  0.5'   # split total height in half
    num_layers = '10   10'
    biases     = '2 0.5'  # fine→coarse for first half, coarse→fine for second half
    bottom_boundary = 'bottom'
    top_boundary = 'top'
  []
[]

[Outputs]
  exodus = true
[]
