//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "Kernel.h"

class EnthalpyHeatSource : public Kernel
{
public:
  static InputParameters validParams();

  EnthalpyHeatSource(const InputParameters & parameters);

protected:
  virtual Real computeQpResidual() override;
  virtual Real computeQpJacobian() override;
  virtual Real computeQpOffDiagJacobian(unsigned int jvar) override;

  /// Derivative of enthalpy with respect to concentration
  const MaterialProperty<Real> & _dH_dc;
  /// Scaling factor for hydrogen concentration
  const Real _h_conc_scale_factor;
  /// Time derivative of the concentration variable
  const VariableValue & _c_dot;
  /// Derivative of c_dot with respect to c
  const VariableValue & _dc_dot_du;
  /// Variable number of the concentration variable
  const unsigned int _c_var;
};
