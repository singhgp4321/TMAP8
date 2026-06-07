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

#include "YHElasticityTensor.h"
#include "RankTwoTensor.h"

registerMooseObject("SolidMechanicsApp", YHElasticityTensor);
registerMooseObject("SolidMechanicsApp", ADYHElasticityTensor);

template <bool is_ad>
InputParameters
YHElasticityTensorTempl<is_ad>::validParams()
{
  InputParameters params = ComputeElasticityTensorBaseTempl<is_ad>::validParams();
  params.addClassDescription("Computes the Young's modulus and Poisson's ratio for YH as a "
                             "function of hydrogen concentration.");
  params.addRangeCheckedParam<Real>("youngs_modulus_scale_factor",
                                    1.0,
                                    "youngs_modulus_scale_factor>0",
                                    "The scaling factor on the Young's modulus.");
  params.addRangeCheckedParam<Real>("shear_modulus_scale_factor",
                                    1.0,
                                    "shear_modulus_scale_factor>0",
                                    "The scaling factor on the shear modulus.");
  params.addParamNamesToGroup("youngs_modulus_scale_factor shear_modulus_scale_factor",
                              "Advanced: Scaling Factor");
  params.addRequiredCoupledVar("hydrogen_concentration", "hydrogen concentration variable");
  params.addRequiredParam<Real>("hydrogen_equilibrium_concentration",
                                "Hydrogen equilibrium concentration in YH1.8");
  params.addParam<Real>(
      "h_conc_scale_factor",
      1.0,
      "Scaling the hydrogen concentration value for computation within this material");
  params.addParam<Real>("youngs_modulus_Y", 66e9, "Youngs modulus in Y");
  params.addParam<Real>("youngs_modulus_YH", 140e9, "Youngs modulus in YH");
  params.addParam<Real>("poissons_ratio", 0.27, "Poisson’s ratio in Y/YH");
  return params;
}

template <bool is_ad>
YHElasticityTensorTempl<is_ad>::YHElasticityTensorTempl(const InputParameters & parameters)
  : ComputeElasticityTensorBaseTempl<is_ad>(parameters),
    _youngs_modulus_scale_factor(this->template getParam<Real>("youngs_modulus_scale_factor")),
    _shear_modulus_scale_factor(this->template getParam<Real>("shear_modulus_scale_factor")),
    _youngs_modulus_Y(this->template getParam<Real>("youngs_modulus_Y")),
    _youngs_modulus_YH(this->template getParam<Real>("youngs_modulus_YH")),
    _poissons_ratio_value(this->template getParam<Real>("poissons_ratio")),
    _hydrogen_concentration(this->template coupledGenericValue<is_ad>("hydrogen_concentration")),
    _hydrogen_equilibrium_concentration(parameters.get<Real>("hydrogen_equilibrium_concentration")),
    _h_conc_scale_factor(this->template getParam<Real>("h_conc_scale_factor")),
    _youngs_modulus(this->template declareGenericProperty<Real, is_ad>("youngs_modulus")),
    _poissons_ratio(this->template declareGenericProperty<Real, is_ad>("poissons_ratio"))
{
  // the tensor created by this class is always isotropic
  issueGuarantee(_elasticity_tensor_name, Guarantee::ISOTROPIC);
}

template <bool is_ad>
void
YHElasticityTensorTempl<is_ad>::computeQpElasticityTensor()
{
  const GenericReal<is_ad> youngs_modulus =
      _youngs_modulus_Y + (_youngs_modulus_YH - _youngs_modulus_Y) *
                              (_hydrogen_concentration[_qp] * _h_conc_scale_factor) /
                              _hydrogen_equilibrium_concentration;

  _youngs_modulus[_qp] = youngs_modulus;
  _poissons_ratio[_qp] = _poissons_ratio_value;

  // Now that have the updated elasticity constants, update the elasticity tensor
  _elasticity_tensor[_qp].fillSymmetricIsotropicEandNu(youngs_modulus, _poissons_ratio_value);
}

template class YHElasticityTensorTempl<false>;
template class YHElasticityTensorTempl<true>;
