/************************************************************/
/*                DO NOT MODIFY THIS HEADER                 */
/*   TMAP8: Tritium Migration Analysis Program, Version 8   */
/*                                                          */
/*   Copyright 2021 - 2023 Battelle Energy Alliance, LLC    */
/*                   ALL RIGHTS RESERVED                    */
/************************************************************/

#pragma once

#include "ADNodalBC.h"

class MolecularRecombinationBC : public ADNodalBC
{
public:
  MolecularRecombinationBC(const InputParameters & parameters);

  static InputParameters validParams();

protected:
  ADReal computeQpResidual() override;

  /// The molecular recombination parameter
  const Real _Kro;

  /// The sticking factor
  const Real _alpha_o;

  /// The sputtering time constant
  const Real _beta;

  /// The implanted atoms fluence
  const Real _fluence;
};
