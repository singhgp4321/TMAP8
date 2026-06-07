//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "EnthalpyHeatSource.h"

registerMooseObject("HeatTransferApp", EnthalpyHeatSource);

InputParameters
EnthalpyHeatSource::validParams()
{
  InputParameters params = Kernel::validParams();
  params.addRequiredCoupledVar("c", "Concentration variable");
  params.addParam<MaterialPropertyName>(
      "dH_dc",
      "dH_dc",
      "Material property for the derivative of enthalpy with respect to concentration");
  params.addParam<Real>(
      "h_conc_scale_factor",
      1.0,
      "Scaling the hydrogen concentration value for computation within this kernel");
  params.addClassDescription(
      "Heat source/sink term from enthalpy changes due to concentration evolution: "
      "Q = dH/dc * dc/dt");
  return params;
}

EnthalpyHeatSource::EnthalpyHeatSource(const InputParameters & parameters)
  : Kernel(parameters),
    _dH_dc(getMaterialProperty<Real>("dH_dc")),
    _h_conc_scale_factor(getParam<Real>("h_conc_scale_factor")),
    _c_dot(coupledDot("c")),
    _dc_dot_du(coupledDotDu("c")),
    _c_var(coupled("c"))
{
}

Real
EnthalpyHeatSource::computeQpResidual()
{
  return _dH_dc[_qp] * _c_dot[_qp] * _test[_i][_qp];
}

Real
EnthalpyHeatSource::computeQpJacobian()
{
  return 0.0;
}

Real
EnthalpyHeatSource::computeQpOffDiagJacobian(unsigned int jvar)
{
  if (jvar == _c_var)
    return _dH_dc[_qp] * _dc_dot_du[_qp] * _phi[_j][_qp] * _test[_i][_qp];

  return 0.0;
}
