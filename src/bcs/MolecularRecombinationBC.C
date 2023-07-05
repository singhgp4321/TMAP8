/************************************************************/
/*                DO NOT MODIFY THIS HEADER                 */
/*   TMAP8: Tritium Migration Analysis Program, Version 8   */
/*                                                          */
/*   Copyright 2021 - 2023 Battelle Energy Alliance, LLC    */
/*                   ALL RIGHTS RESERVED                    */
/************************************************************/

#include "MolecularRecombinationBC.h"

registerMooseObject("TMAP8App", MolecularRecombinationBC);

InputParameters
MolecularRecombinationBC::validParams()
{
  auto params = ADNodalBC::validParams();
  params.addRequiredParam<Real>("Kro", "The parameter $Kro$ for the molecular recombination");
  params.addRequiredParam<Real>("alpha_o", "The sticking factor");
  params.addRequiredParam<Real>("beta", "The sputtering time constant");
  params.addRequiredParam<Real>("fluence", "The fluence of implanted atoms");
  return params;
}

MolecularRecombinationBC::MolecularRecombinationBC(const InputParameters & parameters)
  : ADNodalBC(parameters),
    _Kro(getParam<Real>("Kro")),
    _alpha_o(getParam<Real>("alpha")),
    _beta(getParam<Real>("beta")),
    _fluence(getParam<Real>("fluence"))
{
}

ADReal
MolecularRecombinationBC::computeQpResidual()
{
  return (2.0 * _u * _u * _Kro * (1 - (1 - _alpha_o) * std::exp(-1.0 * _beta * _fluence)));
}
