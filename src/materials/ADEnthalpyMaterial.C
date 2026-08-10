//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "ADEnthalpyMaterial.h"

registerMooseObject("TMAP8App", ADEnthalpyMaterial);

InputParameters
ADEnthalpyMaterial::validParams()
{
  InputParameters params = ADMaterial::validParams();
  params.addClassDescription(
      "Computes enthalpy and its derivative with respect to concentration "
      "from coupled temperature and concentration variables.");
  params.addRequiredCoupledVar("temperature", "The temperature variable");
  params.addRequiredCoupledVar("concentration", "The concentration variable");
  params.addParam<Real>("scaling_factor", 1.0, "The scaling factor");
  return params;
}

ADEnthalpyMaterial::ADEnthalpyMaterial(const InputParameters & parameters)
  : ADMaterial(parameters),
    _temperature(adCoupledValue("temperature")),
    _concentration(adCoupledValue("concentration")),
    _enthalpy(declareADProperty<Real>("enthalpy")),
    _dH_dc(declareADProperty<Real>("dH_dc")),
    _scaling_factor(getParam<Real>("scaling_factor"))
{
}

void
ADEnthalpyMaterial::computeQpProperties()
{
  Real a = _scaling_factor * 222.2222;
  Real b = _scaling_factor * -154320.9876;
  Real c = _scaling_factor * -570543.2099;
  _enthalpy[_qp] = a * _temperature[_qp] + b * _concentration[_qp] + c; // J/kg
  _dH_dc[_qp] = b;
}
