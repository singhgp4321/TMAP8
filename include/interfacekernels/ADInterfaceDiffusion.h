/************************************************************/
/*                DO NOT MODIFY THIS HEADER                 */
/*   TMAP8: Tritium Migration Analysis Program, Version 8   */
/*                                                          */
/*   Copyright 2021 - 2025 Battelle Energy Alliance, LLC    */
/*                   ALL RIGHTS RESERVED                    */
/************************************************************/

#pragma once

#include "ADInterfaceKernel.h"

/**
 * AD version of InterfaceDiffusion.
 * DG kernel for interfacing diffusion between two variables on adjacent blocks.
 */
class ADInterfaceDiffusion : public ADInterfaceKernel
{
public:
  static InputParameters validParams();

  ADInterfaceDiffusion(const InputParameters & parameters);

protected:
  virtual ADReal computeQpResidual(Moose::DGResidualType type) override;

  const ADMaterialProperty<Real> & _D;
  const ADMaterialProperty<Real> & _D_neighbor;
};
