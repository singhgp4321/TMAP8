/************************************************************/
/*                DO NOT MODIFY THIS HEADER                 */
/*   TMAP8: Tritium Migration Analysis Program, Version 8   */
/*                                                          */
/*   Copyright 2021 - 2025 Battelle Energy Alliance, LLC    */
/*                   ALL RIGHTS RESERVED                    */
/************************************************************/

#include "ADInterfaceDiffusion.h"

registerMooseObject("TMAP8App", ADInterfaceDiffusion);

InputParameters
ADInterfaceDiffusion::validParams()
{
  InputParameters params = ADInterfaceKernel::validParams();
  params.addParam<MaterialPropertyName>("D", "D", "The diffusion coefficient.");
  params.addParam<MaterialPropertyName>(
      "D_neighbor", "D_neighbor", "The neighboring diffusion coefficient.");
  params.addClassDescription(
      "AD version of InterfaceDiffusion. Establishes flux equivalence on an interface for "
      "variables.");
  return params;
}

ADInterfaceDiffusion::ADInterfaceDiffusion(const InputParameters & parameters)
  : ADInterfaceKernel(parameters),
    _D(getADMaterialProperty<Real>("D")),
    _D_neighbor(getNeighborADMaterialProperty<Real>("D_neighbor"))
{
}

ADReal
ADInterfaceDiffusion::computeQpResidual(Moose::DGResidualType type)
{
  switch (type)
  {
    case Moose::Element:
      return _test[_i][_qp] * -_D_neighbor[_qp] * _grad_neighbor_value[_qp] * _normals[_qp];

    case Moose::Neighbor:
      return _test_neighbor[_i][_qp] * _D[_qp] * _grad_u[_qp] * _normals[_qp];
  }

  return 0;
}
