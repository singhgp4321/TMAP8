//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "ADMolecularRecombinationBC2.h"

registerMooseObject("TMAP8App", ADMolecularRecombinationBC2);

InputParameters
ADMolecularRecombinationBC2::validParams()
{
  InputParameters params = ADIntegratedBC::validParams();
  params.addClassDescription(
      "Computes the atoms flux at the boundary based on the phenomenon of molecular recombinaton.");
  params.addRequiredParam<Real>("Kro", "The parameter $Kro$ for the molecular recombination");
  params.addRequiredParam<Real>("alpha_o", "The sticking factor");
  params.addRequiredParam<Real>("beta", "The sputtering time constant");
  params.addRequiredParam<Real>("fluence", "The fluence of implanted atoms");
  return params;
}

ADMolecularRecombinationBC2::ADMolecularRecombinationBC2(const InputParameters & parameters)
  : ADIntegratedBC(parameters),
    _Kro(getParam<Real>("Kro")),
    _alpha_o(getParam<Real>("alpha")),
    _beta(getParam<Real>("beta")),
    _fluence(getParam<Real>("fluence"))
{
}

ADReal
ADMolecularRecombinationBC2::computeQpResidual()
{
  return -_test[_i][_qp] * (2.0 * _u[_qp] * _u[_qp] * _Kro *
                            (1 - (1 - _alpha_o) * std::exp(-1.0 * _beta * _fluence)));
}
