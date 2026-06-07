//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "ADEnthalpyHeatSource.h"

registerMooseObject("HeatTransferApp", ADEnthalpyHeatSource);

InputParameters
ADEnthalpyHeatSource::validParams()
{
  InputParameters params = ADKernel::validParams();
  params.addRequiredCoupledVar("c", "Concentration variable");
  params.addParam<MaterialPropertyName>(
      "dH_dc", "dH_dc", "Material property for the derivative of enthalpy with respect to concentration");
  params.addClassDescription(
      "Heat source/sink term from enthalpy changes due to concentration evolution: "
      "Q = dH/dc * dc/dt");
  return params;
}

ADEnthalpyHeatSource::ADEnthalpyHeatSource(const InputParameters & parameters)
  : ADKernel(parameters),
    _dH_dc(getADMaterialProperty<Real>("dH_dc")),
    _c_dot(adCoupledDot("c"))
{
}

ADReal
ADEnthalpyHeatSource::computeQpResidual()
{
  return _dH_dc[_qp] * _c_dot[_qp] * _test[_i][_qp];
}
