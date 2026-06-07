//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "EnthalpyMaterial.h"

registerMooseObject("HeatTransferApp", EnthalpyMaterial);

InputParameters
EnthalpyMaterial::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription(
      "Computes enthalpy and its derivative with respect to concentration "
      "from coupled temperature and concentration variables.");
  params.addRequiredCoupledVar("temperature", "The temperature variable");
  params.addRequiredCoupledVar("concentration", "The concentration variable");
  params.addParam<Real>("scaling_factor", 1.0, "The scaling factor");
  return params;
}

EnthalpyMaterial::EnthalpyMaterial(const InputParameters & parameters)
  : Material(parameters),
    _temperature(coupledValue("temperature")),
    _concentration(coupledValue("concentration")),
    _enthalpy(declareProperty<Real>("enthalpy")),
    _dH_dc(declareProperty<Real>("dH_dc")),
    _scaling_factor(getParam<Real>("scaling_factor"))
{
}

void
EnthalpyMaterial::computeQpProperties()
{
  Real a = _scaling_factor * 222.2222;
  Real b = _scaling_factor * -154320.9876;
  Real c = _scaling_factor * -570543.2099;
  _enthalpy[_qp] = a * _temperature[_qp] + b * _concentration[_qp] + c; // J/kg
  _dH_dc[_qp] = b;
}
