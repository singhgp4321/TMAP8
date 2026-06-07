//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "Material.h"

/**
 * Computes enthalpy and its derivative with respect to concentration
 * from coupled temperature and concentration variables.
 */
class EnthalpyMaterial : public Material
{
public:
  static InputParameters validParams();

  EnthalpyMaterial(const InputParameters & parameters);

protected:
  virtual void computeQpProperties() override;

  /// Coupled temperature variable
  const VariableValue & _temperature;
  /// Coupled concentration variable
  const VariableValue & _concentration;
  /// Enthalpy material property
  MaterialProperty<Real> & _enthalpy;
  /// Derivative of enthalpy with respect to concentration
  MaterialProperty<Real> & _dH_dc;
  /// Scaling factor
  Real _scaling_factor;
};
