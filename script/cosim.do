# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
#
#                            dmx-ngl-fw is free software: you can redistribute it and/or modify
#                            it under the terms of the GNU General Public License as published by
#                            the Free Software Foundation, either version 3 of the License, or
#                            (at your option) any later version.
#
#                            This program is distributed in the hope that it will be useful,
#                            but WITHOUT ANY WARRANTY; without even the implied warranty of
#                            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#                            GNU General Public License for more details.
#
#                            You should have received a copy of the GNU General Public License
#                            along with this program.  If not, see <https://www.gnu.org/licenses/>.
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    email                   slaurent@nanoxplore.com
#    @file                   no_regression.do
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#    @details                Modelsim script for no regression:
#                                * proc run_utest: run all the unitary tests
#                                * proc run_utest [CONF_FILE]: run the unitary test selected by the configuration file [CONF_FILE] and display chronograms
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#### Parameters ####
quietly set VARIANT "NG-LARGE"
quietly set NXMAP3_MODEL_PATH "../modelsim"
quietly set PR_DIR "../project/dmx-NGL-fw"
quietly set FPASIM_DIR "../project/fpasim-fw"
quietly set XLX_LIB_DIR "../xilinx_lib"
quietly set NR_FILE "no_regression.csv"
quietly set PREF_UTEST "DRE_DMX_UT_"
quietly set SUFF_UTEST "_cfg"

#### Directories ####
quietly set IP_DIR "${PR_DIR}/ip/nx/${VARIANT}"
quietly set SRC_DIR "${PR_DIR}/src"
quietly set TB_DIR "${PR_DIR}/simu/tb"
quietly set CFG_DIR "${PR_DIR}/simu/cosim/conf"
quietly set RES_DIR "${PR_DIR}/simu/cosim/result"
quietly set SC_DIR "${PR_DIR}/simu/script"
quietly set VIVADO_DIR "${XLX_LIB_DIR}/vivado"
quietly set OPKELLY_DIR "${XLX_LIB_DIR}/opal_kelly"

# Compile library linked to the FPGA technology
vlib nx
if {${VARIANT} == "NG-MEDIUM" || ${VARIANT} == "NG-MEDIUM-EMBEDDED"} {
   vcom -work nx -2008 "${NXMAP3_MODEL_PATH}/nxLibrary-Medium.vhdp"
} elseif { $VARIANT == "NG-LARGE" || ${VARIANT} == "NG-LARGE-EMBEDDED"} {
   vcom -work nx -2008 "${NXMAP3_MODEL_PATH}/nxLibrary-Large.vhdp"
} elseif { $VARIANT == "NG-ULTRA" || ${VARIANT} == "NG-ULTRA-EMBEDDED"} {
   vcom -work nx -2008 "${NXMAP3_MODEL_PATH}/nxLibrary-Ultra.vhdp"
} else {
   puts "Unrecognized Variant"}

   # Check the FPASIM directory existence and compile the directory
   if { [file isdirectory ${FPASIM_DIR}] == 1} {
      do ${SC_DIR}/fpasim.do $FPASIM_DIR $XLX_LIB_DIR $VIVADO_DIR $OPKELLY_DIR
   }

#### Run unitary test(s)
proc run_utest {args} {
   global IP_DIR
   global SRC_DIR
   global TB_DIR
   global CFG_DIR
   global RES_DIR
   global NR_FILE
   global SC_DIR
   global NR_FILE
   global PREF_UTEST
   global SUFF_UTEST

   do ${SC_DIR}/dmx_fw_vsim.do $IP_DIR $SRC_DIR $TB_DIR

   # Test the argument number
   if {[llength $args] == 0} {

      # In the case of no argument, compile all configuration files
      vcom -work work -2008 "${CFG_DIR}/*.vhd"

      # No regression file initialization
      set file_nr [open ${RES_DIR}/${NR_FILE} w]
      puts $file_nr "Test result number; Test Title; Final Status"

      foreach file [lsort -dictionary [glob -directory ${CFG_DIR} *.vhd]] {

         # Check if FPASIM is requested for the test
         set fpasim_req 0
         set file_sel [open $file]
         while {[gets $file_sel line] != -1} {
            if {[regexp {fpasim.fpga_system_fpasim_top} $line l fpasim_req]} {
               set fpasim_req 1
               break
            }
         }

         close $file_sel

         # Extract the simulation time from the selected configuration file
         set file_sel [open $file]
         while {[gets $file_sel line] != -1} {
            if {[regexp {g_SIM_TIME\s+=>\s+(\d*?\d*.\d*\s+(sec|ms|us|ns|ps))} $line l sim_time]} {
               break
            }
         }

         close $file_sel

         # Run simulation
         if {${fpasim_req} == 0} {
            vsim -t ps -lib work work.[file rootname [file tail $file]]

         } else {

            # Copy FPASIM memory content in simulation directory
            foreach mem_file [glob -directory "${CFG_DIR}/[file rootname [file tail $file]]" -nocomplain *] {
               file copy -force $mem_file .
            }

            vsim -t ps fpasim.glbl -L fpasim -L xpm -L unisims_ver -L secureip -lib work work.[file rootname [file tail $file]]

         }
         run $sim_time
         quit -sim

         # Get the root file name
         set root_file_name [string range [file rootname [file tail $file]] 0 end-4]

         # Check result file exists
         if { [file exists ${RES_DIR}/${root_file_name}_res] == 0} {

            # If result file does not exist, write test fail in no regression file
            puts $file_nr "${root_file_name};"No result files";FAIL"

         } else {

            set res_file [open ${RES_DIR}/${root_file_name}_res]
            set title ""

            # Get the test title
            while {[gets $res_file line] != -1} {
               if {[regexp {Test: } $line]} {
                  set title [string range $line [expr {[string last ":" $line] + 2}] end]
                  break
               }
            }

            # Check the final simulation status
            while {[gets $res_file line] != -1} {

               # If final simulation status is pass, write test pass in non regression file
               if {[regexp {# Simulation status             : PASS} $line]} {
                  puts $file_nr "${root_file_name};${title};PASS"
                  break
               }
            }

            # If final simulation status pass is not detected, write test fail in non regression file
            if {[gets $res_file line] == -1} {
               puts $file_nr "${root_file_name};${title};FAIL"
            }
         }
      }

      close $file_nr

   } else {

      # In the case of arguments, compile the mentioned configuration files
      foreach nb_file $args {

         set cfg_file "${PREF_UTEST}${nb_file}${SUFF_UTEST}"

         vcom -work work -2008 "${CFG_DIR}/${cfg_file}.vhd"

         # Check if FPASIM is requested for the test
         set fpasim_req 0
         set file_sel [open "${CFG_DIR}/${cfg_file}.vhd"]
         while {[gets $file_sel line] != -1} {
            if {[regexp {fpasim.fpga_system_fpasim_top} $line l fpasim_req]} {
               set fpasim_req 1
               break
            }
         }

         close $file_sel

         # Extract the simulation time from the selected configuration file
         set file_sel [open "${CFG_DIR}/${cfg_file}.vhd"]
         while {[gets $file_sel line] != -1} {
            if {[regexp {g_SIM_TIME\s+=>\s+(\d*?\d*.\d*\s+(sec|ms|us|ns|ps))} $line l sim_time]} {
               break
            }
         }

         close $file_sel

         # Run simulation
         if {${fpasim_req} == 0} {
            vsim -t ps -lib work work.${cfg_file}

         } else {

            # Copy FPASIM memory content in simulation directory
            foreach mem_file [glob -directory "${CFG_DIR}/${cfg_file}" -nocomplain *] {
               file copy -force $mem_file .
            }

            vsim -t ps fpasim.glbl -L fpasim -L xpm -L unisims_ver -L secureip -lib work work.${cfg_file}

         }

         # Display signals
         add wave -noupdate -divider "Reset & general clocks"
         add wave -format Logic -Radix unsigned    -group "Inputs"                              sim/:top_dmx_tb:I_top_dmx:i_brd_ref
         add wave -format Logic -Radix unsigned    -group "Inputs"                              sim/:top_dmx_tb:I_top_dmx:i_brd_model

         add wave -format Logic                    -group "Inputs"                              sim/:top_dmx_tb:I_top_dmx:i_arst_n
         add wave -format Logic                    -group "Inputs"                              sim/:top_dmx_tb:I_top_dmx:i_clk_ref
         add wave -format Logic                    -group "Inputs"                              sim/:top_dmx_tb:I_top_dmx:i_sync
         add wave -format Logic                    -group "Inputs"                              sim/:top_dmx_tb:I_top_dmx:i_ras_data_valid

         add wave -format Logic                    -group "Local Resets"                        sim/:top_dmx_tb:I_top_dmx:G_column_mgt(0):I_squid_adc_mgt:i_rst_sqm_adc_dac
         add wave -format Logic                    -group "Local Resets"                        sim/:top_dmx_tb:I_top_dmx:G_column_mgt(1):I_squid_adc_mgt:i_rst_sqm_adc_dac
         add wave -format Logic                    -group "Local Resets"                        sim/:top_dmx_tb:I_top_dmx:G_column_mgt(2):I_squid_adc_mgt:i_rst_sqm_adc_dac
         add wave -format Logic                    -group "Local Resets"                        sim/:top_dmx_tb:I_top_dmx:G_column_mgt(3):I_squid_adc_mgt:i_rst_sqm_adc_dac
         add wave -format Logic                    -group "Local Resets"                        sim/:top_dmx_tb:I_top_dmx:G_column_mgt(0):I_sqm_dac_mgt:i_rst_sqm_adc_dac
         add wave -format Logic                    -group "Local Resets"                        sim/:top_dmx_tb:I_top_dmx:G_column_mgt(1):I_sqm_dac_mgt:i_rst_sqm_adc_dac
         add wave -format Logic                    -group "Local Resets"                        sim/:top_dmx_tb:I_top_dmx:G_column_mgt(2):I_sqm_dac_mgt:i_rst_sqm_adc_dac
         add wave -format Logic                    -group "Local Resets"                        sim/:top_dmx_tb:I_top_dmx:G_column_mgt(3):I_sqm_dac_mgt:i_rst_sqm_adc_dac
         add wave -format Logic                    -group "Local Resets"                        sim/:top_dmx_tb:I_top_dmx:G_column_mgt(0):I_sqa_dac_mgt:i_rst_sqm_adc_dac
         add wave -format Logic                    -group "Local Resets"                        sim/:top_dmx_tb:I_top_dmx:G_column_mgt(1):I_sqa_dac_mgt:i_rst_sqm_adc_dac
         add wave -format Logic                    -group "Local Resets"                        sim/:top_dmx_tb:I_top_dmx:G_column_mgt(2):I_sqa_dac_mgt:i_rst_sqm_adc_dac
         add wave -format Logic                    -group "Local Resets"                        sim/:top_dmx_tb:I_top_dmx:G_column_mgt(3):I_sqa_dac_mgt:i_rst_sqm_adc_dac

         add wave -format Logic                                                                 sim/:top_dmx_tb:I_top_dmx:rst
         add wave -format Logic                                                                 sim/:top_dmx_tb:I_top_dmx:clk
         add wave -format Logic                                                                 sim/:top_dmx_tb:I_top_dmx:clk_sqm_adc_dac
         add wave -format Logic                                                                 sim/:top_dmx_tb:I_top_dmx:clk_90
         add wave -format Logic                                                                 sim/:top_dmx_tb:I_top_dmx:clk_sqm_adc_dac_90
         add wave -format Logic                                                                 sim/:top_dmx_tb:clk_fpasim
         add wave -format Logic                                                                 sim/:top_dmx_tb:clk_fpasim_shift

         add wave -noupdate -divider "Channel 0"
         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "0 - SQUID MUX ADC"                   sim/:top_dmx_tb:sqm_adc_ana(0)
         add wave -format Logic                    -group "0 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_pwdn(0)
         add wave -format Logic                    -group "0 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:o_clk_sqm_adc(0)
         add wave -format Logic -Radix decimal     -group "0 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:i_sqm_adc_data(0)
         add wave -format Logic                    -group "0 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:i_sqm_adc_oor(0)

         add wave -format Logic                    -group "0 - SQUID MUX ADC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_spi_sdio(0)
         add wave -format Logic                    -group "0 - SQUID MUX ADC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_spi_sclk(0)
         add wave -format Logic                    -group "0 - SQUID MUX ADC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_spi_cs_n(0)

         add wave -format Logic                    -group "0 - SQUID MUX DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqm_dac_sleep(0)
         add wave -format Logic                    -group "0 - SQUID MUX DAC"                   sim/:top_dmx_tb:I_top_dmx:o_clk_sqm_dac(0)
         add wave -format Logic -Radix unsigned    -group "0 - SQUID MUX DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqm_dac_data(0)
         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "0 - SQUID MUX DAC"                   sim/:top_dmx_tb:sqm_dac_delta_volt(0)

         add wave -format Logic -Radix unsigned    -group "0 - SQUID AMP DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_mux(0)
         add wave -format Logic                    -group "0 - SQUID AMP DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_mx_en_n(0)
         add wave -format Logic                    -group "0 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_data(0)
         add wave -format Logic                    -group "0 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_sclk(0)
         add wave -format Logic                    -group "0 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_snc_l_n(0)
         add wave -format Logic                    -group "0 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_snc_o_n(0)
         add wave -format Analog-step -min -0.0 -max 1.0 \
                                                   -group "0 - SQUID AMP DAC"                   sim/:top_dmx_tb:sqa_volt(0)

         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "0 - FPASIM"                          sim/:top_dmx_tb:sqm_dac_delta_volt(0)
         add wave -format Analog-step -min -0.0 -max 1.0 \
                                                   -group "0 - FPASIM"                          sim/:top_dmx_tb:sqa_volt(0)
         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "0 - FPASIM"                          sim/:top_dmx_tb:squid_err_volt(0)
         add wave -format Logic                    -group "0 - FPASIM"                          sim/:top_dmx_tb:fpa_conf_busy(0)
         add wave -format Logic                    -group "0 - FPASIM"                          sim/:top_dmx_tb:fpa_cmd_rdy(0)
         add wave -format Logic -Radix hexadecimal -group "0 - FPASIM"                          sim/:top_dmx_tb:fpa_cmd(0)
         add wave -format Logic                    -group "0 - FPASIM"                          sim/:top_dmx_tb:fpa_cmd_valid(0)

         add wave -noupdate -divider "Channel 1"
         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "1 - SQUID MUX ADC"                   sim/:top_dmx_tb:sqm_adc_ana(1)
         add wave -format Logic                    -group "1 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_pwdn(1)
         add wave -format Logic                    -group "1 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:o_clk_sqm_adc(1)
         add wave -format Logic -Radix decimal     -group "1 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:i_sqm_adc_data(1)
         add wave -format Logic                    -group "1 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:i_sqm_adc_oor(1)

         add wave -format Logic                    -group "1 - SQUID MUX ADC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_spi_sdio(1)
         add wave -format Logic                    -group "1 - SQUID MUX ADC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_spi_sclk(1)
         add wave -format Logic                    -group "1 - SQUID MUX ADC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_spi_cs_n(1)

         add wave -format Logic                    -group "1 - SQUID MUX DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqm_dac_sleep(1)
         add wave -format Logic                    -group "1 - SQUID MUX DAC"                   sim/:top_dmx_tb:I_top_dmx:o_clk_sqm_dac(1)
         add wave -format Logic -Radix unsigned    -group "1 - SQUID MUX DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqm_dac_data(1)
         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "1 - SQUID MUX DAC"                   sim/:top_dmx_tb:sqm_dac_delta_volt(1)

         add wave -format Logic -Radix unsigned    -group "1 - SQUID AMP DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_mux(1)
         add wave -format Logic                    -group "1 - SQUID AMP DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_mx_en_n(1)
         add wave -format Logic                    -group "1 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_data(1)
         add wave -format Logic                    -group "1 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_sclk(1)
         add wave -format Logic                    -group "1 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_snc_l_n(1)
         add wave -format Logic                    -group "1 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_snc_o_n(1)
         add wave -format Analog-step -min -0.0 -max 1.0 \
                                                   -group "1 - SQUID AMP DAC"                   sim/:top_dmx_tb:sqa_volt(1)

         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "1 - FPASIM"                          sim/:top_dmx_tb:sqm_dac_delta_volt(1)
         add wave -format Analog-step -min -0.0 -max 1.0 \
                                                   -group "1 - FPASIM"                          sim/:top_dmx_tb:sqa_volt(1)
         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "1 - FPASIM"                          sim/:top_dmx_tb:squid_err_volt(1)
         add wave -format Logic                    -group "1 - FPASIM"                          sim/:top_dmx_tb:fpa_conf_busy(1)
         add wave -format Logic                    -group "1 - FPASIM"                          sim/:top_dmx_tb:fpa_cmd_rdy(1)
         add wave -format Logic -Radix hexadecimal -group "1 - FPASIM"                          sim/:top_dmx_tb:fpa_cmd(1)
         add wave -format Logic                    -group "1 - FPASIM"                          sim/:top_dmx_tb:fpa_cmd_valid(1)

         add wave -noupdate -divider "Channel 2"
         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "2 - SQUID MUX ADC"                   sim/:top_dmx_tb:sqm_adc_ana(2)
         add wave -format Logic                    -group "2 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_pwdn(2)
         add wave -format Logic                    -group "2 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:o_clk_sqm_adc(2)
         add wave -format Logic -Radix decimal     -group "2 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:i_sqm_adc_data(2)
         add wave -format Logic                    -group "2 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:i_sqm_adc_oor(2)

         add wave -format Logic                    -group "2 - SQUID MUX ADC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_spi_sdio(2)
         add wave -format Logic                    -group "2 - SQUID MUX ADC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_spi_sclk(2)
         add wave -format Logic                    -group "2 - SQUID MUX ADC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_spi_cs_n(2)

         add wave -format Logic                    -group "2 - SQUID MUX DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqm_dac_sleep(2)
         add wave -format Logic                    -group "2 - SQUID MUX DAC"                   sim/:top_dmx_tb:I_top_dmx:o_clk_sqm_dac(2)
         add wave -format Logic -Radix unsigned    -group "2 - SQUID MUX DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqm_dac_data(2)
         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "2 - SQUID MUX DAC"                   sim/:top_dmx_tb:sqm_dac_delta_volt(2)

         add wave -format Logic -Radix unsigned    -group "2 - SQUID AMP DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_mux(2)
         add wave -format Logic                    -group "2 - SQUID AMP DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_mx_en_n(2)
         add wave -format Logic                    -group "2 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_data(2)
         add wave -format Logic                    -group "2 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_sclk(2)
         add wave -format Logic                    -group "2 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_snc_l_n(2)
         add wave -format Logic                    -group "2 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_snc_o_n(2)
         add wave -format Analog-step -min -0.0 -max 1.0 \
                                                   -group "2 - SQUID AMP DAC"                   sim/:top_dmx_tb:sqa_volt(2)

         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "2 - FPASIM"                          sim/:top_dmx_tb:sqm_dac_delta_volt(2)
         add wave -format Analog-step -min -0.0 -max 1.0 \
                                                   -group "2 - FPASIM"                          sim/:top_dmx_tb:sqa_volt(2)
         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "2 - FPASIM"                          sim/:top_dmx_tb:squid_err_volt(2)
         add wave -format Logic                    -group "2 - FPASIM"                          sim/:top_dmx_tb:fpa_conf_busy(2)
         add wave -format Logic                    -group "2 - FPASIM"                          sim/:top_dmx_tb:fpa_cmd_rdy(2)
         add wave -format Logic -Radix hexadecimal -group "2 - FPASIM"                          sim/:top_dmx_tb:fpa_cmd(2)
         add wave -format Logic                    -group "2 - FPASIM"                          sim/:top_dmx_tb:fpa_cmd_valid(2)

         add wave -noupdate -divider "Channel 3"
         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "3 - SQUID MUX ADC"                   sim/:top_dmx_tb:sqm_adc_ana(3)
         add wave -format Logic                    -group "3 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_pwdn(3)
         add wave -format Logic                    -group "3 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:o_clk_sqm_adc(3)
         add wave -format Logic -Radix decimal     -group "3 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:i_sqm_adc_data(3)
         add wave -format Logic                    -group "3 - SQUID MUX ADC"                   sim/:top_dmx_tb:I_top_dmx:i_sqm_adc_oor(3)

         add wave -format Logic                    -group "3 - SQUID MUX ADC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_spi_sdio(3)
         add wave -format Logic                    -group "3 - SQUID MUX ADC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_spi_sclk(3)
         add wave -format Logic                    -group "3 - SQUID MUX ADC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqm_adc_spi_cs_n(3)

         add wave -format Logic                    -group "3 - SQUID MUX DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqm_dac_sleep(3)
         add wave -format Logic                    -group "3 - SQUID MUX DAC"                   sim/:top_dmx_tb:I_top_dmx:o_clk_sqm_dac(3)
         add wave -format Logic -Radix unsigned    -group "3 - SQUID MUX DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqm_dac_data(3)
         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "3 - SQUID MUX DAC"                   sim/:top_dmx_tb:sqm_dac_delta_volt(3)

         add wave -format Logic -Radix unsigned    -group "3 - SQUID AMP DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_mux(3)
         add wave -format Logic                    -group "3 - SQUID AMP DAC"                   sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_mx_en_n(3)
         add wave -format Logic                    -group "3 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_data(3)
         add wave -format Logic                    -group "3 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_sclk(3)
         add wave -format Logic                    -group "3 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_snc_l_n(3)
         add wave -format Logic                    -group "3 - SQUID AMP DAC" -group "SPI"      sim/:top_dmx_tb:I_top_dmx:o_sqa_dac_snc_o_n(3)
         add wave -format Analog-step -min -0.0 -max 1.0 \
                                                   -group "3 - SQUID AMP DAC"                   sim/:top_dmx_tb:sqa_volt(3)

         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "3 - FPASIM"                          sim/:top_dmx_tb:sqm_dac_delta_volt(3)
         add wave -format Analog-step -min -0.0 -max 1.0 \
                                                   -group "3 - FPASIM"                          sim/:top_dmx_tb:sqa_volt(3)
         add wave -format Analog-step -min -1.0 -max 1.0 \
                                                   -group "3 - FPASIM"                          sim/:top_dmx_tb:squid_err_volt(3)
         add wave -format Logic                    -group "3 - FPASIM"                          sim/:top_dmx_tb:fpa_conf_busy(3)
         add wave -format Logic                    -group "3 - FPASIM"                          sim/:top_dmx_tb:fpa_cmd_rdy(3)
         add wave -format Logic -Radix hexadecimal -group "3 - FPASIM"                          sim/:top_dmx_tb:fpa_cmd(3)
         add wave -format Logic                    -group "3 - FPASIM"                          sim/:top_dmx_tb:fpa_cmd_valid(3)

         add wave -noupdate -divider
         add wave -format Logic                    -group "Science" -group "TX"                 sim/:top_dmx_tb:I_top_dmx:o_clk_science_01
         add wave -format Logic                    -group "Science" -group "TX"                 sim/:top_dmx_tb:I_top_dmx:o_clk_science_23
         add wave -format Logic                    -group "Science" -group "TX"                 sim/:top_dmx_tb:I_top_dmx:o_science_ctrl_01
         add wave -format Logic                    -group "Science" -group "TX"                 sim/:top_dmx_tb:I_top_dmx:o_science_ctrl_23
         add wave -format Logic                    -group "Science" -group "TX"                 sim/:top_dmx_tb:I_top_dmx:o_science_data(0)
         add wave -format Logic                    -group "Science" -group "TX"                 sim/:top_dmx_tb:I_top_dmx:o_science_data(1)
         add wave -format Logic                    -group "Science" -group "TX"                 sim/:top_dmx_tb:I_top_dmx:o_science_data(2)
         add wave -format Logic                    -group "Science" -group "TX"                 sim/:top_dmx_tb:I_top_dmx:o_science_data(3)
         add wave -format Logic -Radix hexadecimal -group "Science" -group "EP"                 sim/:top_dmx_tb:I_science_data_model:science_data_ctrl(0)
         add wave -format Logic -Radix hexadecimal -group "Science" -group "EP"                 sim/:top_dmx_tb:I_science_data_model:science_data_ctrl(1)
         add wave -format Logic -Radix hexadecimal -group "Science" -group "EP"                 sim/:top_dmx_tb:I_science_data_model:science_data(0)
         add wave -format Logic -Radix hexadecimal -group "Science" -group "EP"                 sim/:top_dmx_tb:I_science_data_model:science_data(1)
         add wave -format Logic -Radix hexadecimal -group "Science" -group "EP"                 sim/:top_dmx_tb:I_science_data_model:science_data(2)
         add wave -format Logic -Radix hexadecimal -group "Science" -group "EP"                 sim/:top_dmx_tb:I_science_data_model:science_data(3)

         add wave -format Logic -Radix unsigned    -group "Command" -group "EP"                 sim/:top_dmx_tb:ep_cmd_ser_wd_s
         add wave -format Logic -Radix hexadecimal -group "Command" -group "EP"                 sim/:top_dmx_tb:ep_cmd
         add wave -format Logic                    -group "Command" -group "EP"                 sim/:top_dmx_tb:ep_cmd_start
         add wave -format Logic                    -group "Command" -group "EP"                 sim/:top_dmx_tb:ep_cmd_busy_n
         add wave -format Logic -Radix hexadecimal -group "Command" -group "EP"                 sim/:top_dmx_tb:ep_data_rx
         add wave -format Logic                    -group "Command" -group "EP"                 sim/:top_dmx_tb:ep_data_rx_rdy
         add wave -format Logic                    -group "Command" -group "SPI-EP"             sim/:top_dmx_tb:I_ep_spi_model:ep_spi_mosi_bf_buf
         add wave -format Logic                    -group "Command" -group "SPI-EP"             sim/:top_dmx_tb:I_ep_spi_model:ep_spi_miso_bf_buf
         add wave -format Logic                    -group "Command" -group "SPI-EP"             sim/:top_dmx_tb:I_ep_spi_model:ep_spi_sclk_bf_buf
         add wave -format Logic                    -group "Command" -group "SPI-EP"             sim/:top_dmx_tb:I_ep_spi_model:ep_spi_cs_n_bf_buf
         add wave -format Logic                    -group "Command" -group "SPI-DMX"            sim/:top_dmx_tb:I_top_dmx:i_ep_spi_mosi
         add wave -format Logic                    -group "Command" -group "SPI-DMX"            sim/:top_dmx_tb:I_top_dmx:o_ep_spi_miso
         add wave -format Logic                    -group "Command" -group "SPI-DMX"            sim/:top_dmx_tb:I_top_dmx:i_ep_spi_sclk
         add wave -format Logic                    -group "Command" -group "SPI-DMX"            sim/:top_dmx_tb:I_top_dmx:i_ep_spi_cs_n
         add wave -format Logic -Radix hexadecimal -group "Command"                             sim/:top_dmx_tb:I_top_dmx:ep_cmd_sts_rg
         add wave -format Logic -Radix hexadecimal -group "Command"                             sim/:top_dmx_tb:I_top_dmx:ep_cmd_rx_wd_add
         add wave -format Logic -Radix hexadecimal -group "Command"                             sim/:top_dmx_tb:I_top_dmx:ep_cmd_rx_wd_data
         add wave -format Logic                    -group "Command"                             sim/:top_dmx_tb:I_top_dmx:ep_cmd_rx_rw
         add wave -format Logic                    -group "Command"                             sim/:top_dmx_tb:I_top_dmx:ep_cmd_rx_nerr_rdy
         add wave -format Logic -Radix hexadecimal -group "Command"                             sim/:top_dmx_tb:I_top_dmx:I_ep_cmd:ep_cmd_tx_wd_add_end
         add wave -format Logic                    -group "Command"                             sim/:top_dmx_tb:I_top_dmx:I_ep_cmd:I_spi_slave:data_tx_wd_nb(0)
         add wave -format Logic -Radix hexadecimal -group "Command"                             sim/:top_dmx_tb:I_top_dmx:I_ep_cmd:ep_cmd_tx_wd_add
         add wave -format Logic -Radix hexadecimal -group "Command"                             sim/:top_dmx_tb:I_top_dmx:ep_cmd_tx_wd_rd_rg
         add wave -format Logic -Radix hexadecimal -group "Command"                             sim/:top_dmx_tb:I_top_dmx:I_ep_cmd:ep_spi_data_tx_wd
         add wave -format Logic                    -group "Command"                             sim/:top_dmx_tb:I_top_dmx:I_ep_cmd:ep_cmd_rx_add_err_rdy
         add wave -format Logic                    -group "Command"                             sim/:top_dmx_tb:I_top_dmx:I_ep_cmd:ep_spi_wd_end

         add wave -format Logic                    -group "HouseKeeping"                        sim/:top_dmx_tb:I_top_dmx:i_hk1_spi_miso
         add wave -format Logic                    -group "HouseKeeping"                        sim/:top_dmx_tb:I_top_dmx:o_hk1_spi_mosi
         add wave -format Logic                    -group "HouseKeeping"                        sim/:top_dmx_tb:I_top_dmx:o_hk1_spi_sclk
         add wave -format Logic                    -group "HouseKeeping"                        sim/:top_dmx_tb:I_top_dmx:o_hk1_spi_cs_n
         add wave -format Logic -Radix hexadecimal -group "HouseKeeping"                        sim/:top_dmx_tb:I_top_dmx:o_hk1_mux
         add wave -format Logic                    -group "HouseKeeping"                        sim/:top_dmx_tb:I_top_dmx:o_hk1_mux_ena_n


         # Display adjustment
         configure wave -namecolwidth 220
         configure wave -valuecolwidth 30
         configure wave -justifyvalue left
         configure wave -signalnamewidth 1
         configure wave -snapdistance 10
         configure wave -datasetprefix 0
         configure wave -rowmargin 4
         configure wave -childrowmargin 2
         configure wave -gridoffset 0
         configure wave -gridperiod 1000
         configure wave -griddelta 40
         configure wave -timeline 0
         configure wave -timelineunits ns
         update

         # Run simulation
         run $sim_time
      }
   }
}