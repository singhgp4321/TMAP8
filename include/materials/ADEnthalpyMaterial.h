//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "ADMaterial.h"

/**
 * Computes enthalpy and its derivative with respect to concentration
 * from coupled temperature and concentration variables.
 */
class ADEnthalpyMaterial : public ADMaterial
{
public:
  static InputParameters validParams();

  ADEnthalpyMaterial(const InputParameters & parameters);

protected:
  virtual void computeQpProperties() override;

  /// Coupled temperature variable
  const ADVariableValue & _temperature;
  /// Coupled concentration variable
  const ADVariableValue & _concentration;
  /// Enthalpy material property
  ADMaterialProperty<Real> & _enthalpy;
  /// Derivative of enthalpy with respect to concentration
  ADMaterialProperty<Real> & _dH_dc;
  /// Scaling factor
  Real _scaling_factor;
};
