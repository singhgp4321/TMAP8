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

#include "ComputeElasticityTensorBase.h"

template <bool is_ad>
class YHElasticityTensorTempl : public ComputeElasticityTensorBaseTempl<is_ad>
{
public:
  static InputParameters validParams();
  YHElasticityTensorTempl(const InputParameters & parameters);

protected:
  virtual void initQpStatefulProperties() override {};

  virtual void computeQpElasticityTensor() override;

  Real _youngs_modulus_scale_factor;
  Real _shear_modulus_scale_factor;

  Real _youngs_modulus_Y;
  Real _youngs_modulus_YH;
  Real _poissons_ratio_value;

  const GenericVariableValue<is_ad> & _hydrogen_concentration;
  const Real _hydrogen_equilibrium_concentration;
  /// Scaling factor for hydrogen concentration
  const Real _h_conc_scale_factor;

  GenericMaterialProperty<Real, is_ad> & _youngs_modulus;
  GenericMaterialProperty<Real, is_ad> & _poissons_ratio;

  using ComputeElasticityTensorBaseTempl<is_ad>::_qp;
  using ComputeElasticityTensorBaseTempl<is_ad>::_elasticity_tensor;
  using ComputeElasticityTensorBaseTempl<is_ad>::_elasticity_tensor_name;
  using ComputeElasticityTensorBaseTempl<is_ad>::issueGuarantee;
};

typedef YHElasticityTensorTempl<false> YHElasticityTensor;
typedef YHElasticityTensorTempl<true> ADYHElasticityTensor;
