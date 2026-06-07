/*************************************************/
/*           DO NOT MODIFY THIS HEADER           */
/*                                               */
/*                     BISON                     */
/*                                               */
/*    (c) 2015 Battelle Energy Alliance, LLC     */
/*            ALL RIGHTS RESERVED                */
/*                                               */
/*   Prepared by Battelle Energy Alliance, LLC   */
/*     Under Contract No. DE-AC07-05ID14517      */
/*     With the U. S. Department of Energy       */
/*                                               */
/*     See COPYRIGHT for full restrictions       */
/*************************************************/

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

  /// Scaling factor for hydrogen concentration
  const Real _h_conc_scale_factor;

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
