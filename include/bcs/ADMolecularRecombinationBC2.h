//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "ADIntegratedBC.h"

/**
 * Boundary condition for convective heat flux where temperature and heat transfer coefficient are
 * given by material properties.
 */
class ADMolecularRecombinationBC2 : public ADIntegratedBC
{
public:
  static InputParameters validParams();

  ADMolecularRecombinationBC2(const InputParameters & parameters);

protected:
  virtual ADReal computeQpResidual() override;

  /// The molecular recombination parameter
  const Real _Kro;

  /// The sticking factor
  const Real _alpha_o;

  /// The sputtering time constant
  const Real _beta;

  /// The implanted atoms fluence
  const Real _fluence;
};
