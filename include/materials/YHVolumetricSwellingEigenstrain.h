//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "ComputeEigenstrainBase.h"
#include "RankTwoTensor.h"

template <bool is_ad>
class YHVolumetricSwellingEigenstrainTempl : public ComputeEigenstrainBaseTempl<is_ad>
{
public:
  static InputParameters validParams();
  YHVolumetricSwellingEigenstrainTempl(const InputParameters & parameters);

  virtual void initQpStatefulProperties();
  virtual void computeQpEigenstrain();

protected:
  const GenericVariableValue<is_ad> & _hydrogen_concentration;

  const Real _hydrogen_equilibrium_concentration;

  /// Yttrium concentration in mol/m^3
  const Real _y_concentration;

  const Real _yh_swelling_strain;

  /// Scaling factor on the total swelling strain. Used for sensitivity and calibration studies
  const Real _total_swelling_scaling_factor;

  /// Material property to store the total swelling strain
  GenericMaterialProperty<Real, is_ad> & _total_scalar_swelling_strain;

  using ComputeEigenstrainBaseTempl<is_ad>::_qp;
  using ComputeEigenstrainBaseTempl<is_ad>::_eigenstrain;
  using ComputeEigenstrainBaseTempl<is_ad>::computeVolumetricStrainComponent;
};

typedef YHVolumetricSwellingEigenstrainTempl<false> YHVolumetricSwellingEigenstrain;
typedef YHVolumetricSwellingEigenstrainTempl<true> ADYHVolumetricSwellingEigenstrain;
