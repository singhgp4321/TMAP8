//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "YHVolumetricSwellingEigenstrain.h"

registerMooseObject("TMAP8App", YHVolumetricSwellingEigenstrain);
registerMooseObject("TMAP8App", ADYHVolumetricSwellingEigenstrain);

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
      "y_concentration",
      48605.0,
      "Used to compute the volumetric swelling strain in Yttrium Hydride. This is the concentration of Yttrium in mol/m^3.");
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
    _y_concentration(this->template getParam<Real>("y_concentration")),
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
                                       _hydrogen_concentration[_qp] /
                                       _hydrogen_equilibrium_concentration;

  _total_scalar_swelling_strain[_qp] = ((4.37 - 0.0582 * (_hydrogen_equilibrium_concentration / _y_concentration)) / 
                                        (4.37 - 0.0582 * (_hydrogen_concentration[_qp] / _y_concentration)) - 1.0) / 3.0; // Factor of 1/3 to convert from volumetric to linear strain
  _total_scalar_swelling_strain[_qp] *= _total_swelling_scaling_factor;

  const GenericReal<is_ad> scalar_swelling_strain_comp =
      computeVolumetricStrainComponent(_total_scalar_swelling_strain[_qp]);
  _eigenstrain[_qp].zero();
  _eigenstrain[_qp].addIa(scalar_swelling_strain_comp);
}

template class YHVolumetricSwellingEigenstrainTempl<false>;
template class YHVolumetricSwellingEigenstrainTempl<true>;
