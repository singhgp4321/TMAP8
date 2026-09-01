  [Materials]
    [Cp]
      type = ADParsedMaterial
      property_name = specific_heat
      coupled_variables = 'temp'
      constant_names =       'a_tr b_tr c_tr d_tr
                              a_lo b_lo c_lo d_lo
                              a_hi b_hi c_hi d_hi'
      constant_expressions = '<val> <val> <val> <val>
                              <val> <val> <val> <val>
                              <val> <val> <val> <val>'
      expression = 'T_tr := a_tr * exp(b_tr * temp) + c_tr * exp(d_tr * temp);
                    Cp_lo := a_lo + b_lo*temp + c_lo*temp*temp + d_lo*temp*temp*temp;
                    Cp_hi := a_hi * exp(b_hi * temp) + c_hi * exp(d_hi * temp);
                    if(temp < T_tr, Cp_lo, Cp_hi)'
    []
  []

    [Materials]
    [Cp]
      type = ADParsedMaterial
      property_name = specific_heat
      coupled_variables = 'temp'
      constant_names =       'T_thresh
                              a_lo b_lo c_lo d_lo
                              a_hi b_hi c_hi d_hi
                              a_tr b_tr c_tr d_tr'
      constant_expressions = '<val>
                              <val> <val> <val> <val>
                              <val> <val> <val> <val>
                              <val> <val> <val> <val>'
      expression = 'T_tr := a_tr * exp(b_tr * temp) + c_tr * exp(d_tr * temp);
                    a := if(temp < T_thresh, a_lo, a_hi);
                    b := if(temp < T_thresh, b_lo, b_hi);
                    c := if(temp < T_thresh, c_lo, c_hi);
                    d := if(temp < T_thresh, d_lo, d_hi);
                    Cp_poly := a + b*temp + c*temp*temp + d*temp*temp*temp;
                    Cp_exp  := a * exp(b*temp) + c * exp(d*temp);
                    if(temp < T_tr, Cp_poly, Cp_exp)'
    []
  []