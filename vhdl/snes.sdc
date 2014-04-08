create_clock -name "inclk" -period 20.000ns [get_ports {inclk}]
derive_pll_clocks -create_base_clocks
derive_clock_uncertainty
