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
#include "YHVolumetricSwellingEigenstrain.h"

registerMooseObject("SolidMechanicsApp", YHVolumetricSwellingEigenstrain);
registerMooseObject("SolidMechanicsApp", ADYHVolumetricSwellingEigenstrain);

template <bool is_ad>
InputParameters
YHVolumetricSwellingEigenstrainTempl<is_ad>::validParams()
{
  InputParameters params = ComputeEigenstrainBaseTempl<is_ad>::validParams();
  params.addClassDescription("Computes the change in volume due to swelling in Yttrium Hydride.");
  params.addRequiredCoupledVar("hydrogen_concentration", "hydrogen concentration variable");
  params.addRequiredParam<Real>("hydrogen_equilibrium_concentration",
                                "Hydrogen equilibrium concentration in YH1.8");
  params.addParam<Real>(
      "h_conc_scale_factor",
      1.0,
      "Scaling the hydrogen concentration value for computation within this kernel");
  params.addParam<Real>("YH_swelling_strain", 0.071, "Volumetric swelling strain of YH1.8");
  params.addParam<Real>("total_swelling_scaling_factor",
                        1.0,
                        "Scaling factor to be applied to the swelling strain. Used for sensitivity "
                        "and calibration studies");
  params.addParamNamesToGroup("total_swelling_scaling_factor", "Advanced: Scaling Factors");

  return params;
}

template <bool is_ad>
YHVolumetricSwellingEigenstrainTempl<is_ad>::YHVolumetricSwellingEigenstrainTempl(
    const InputParameters & parameters)
  : ComputeEigenstrainBaseTempl<is_ad>(parameters),
    _hydrogen_concentration(this->template coupledGenericValue<is_ad>("hydrogen_concentration")),
    _hydrogen_equilibrium_concentration(parameters.get<Real>("hydrogen_equilibrium_concentration")),
    _h_conc_scale_factor(this->template getParam<Real>("h_conc_scale_factor")),
    _yh_swelling_strain(parameters.get<Real>("YH_swelling_strain")),
    _total_swelling_scaling_factor(parameters.get<Real>("total_swelling_scaling_factor")),
    _total_scalar_swelling_strain(
        this->template declareGenericProperty<Real, is_ad>("volumetric_swelling_strain"))
{
}

template <bool is_ad>
void
YHVolumetricSwellingEigenstrainTempl<is_ad>::initQpStatefulProperties()
{
  _total_scalar_swelling_strain[_qp] = 0.0;
  ComputeEigenstrainBaseTempl<is_ad>::initQpStatefulProperties();
}

template <bool is_ad>
void
YHVolumetricSwellingEigenstrainTempl<is_ad>::computeQpEigenstrain()
{
  _total_scalar_swelling_strain[_qp] = _yh_swelling_strain *
                                       (_hydrogen_concentration[_qp] * _h_conc_scale_factor) /
                                       _hydrogen_equilibrium_concentration;
  const GenericReal<is_ad> scalar_swelling_strain_comp =
      computeVolumetricStrainComponent(_total_scalar_swelling_strain[_qp]);
  _eigenstrain[_qp].zero();
  _eigenstrain[_qp].addIa(scalar_swelling_strain_comp);
}

template class YHVolumetricSwellingEigenstrainTempl<false>;
template class YHVolumetricSwellingEigenstrainTempl<true>;
