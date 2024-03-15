-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            Copyright (C) 2021-2030 Sylvain LAURENT, IRAP Toulouse.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                            This file is part of the ATHENA X-IFU DRE Time Domain Multiplexing Firmware.
--
--                            dmx-fw is free software: you can redistribute it and/or modify
--                            it under the terms of the GNU General Public License as published by
--                            the Free Software Foundation, either version 3 of the License, or
--                            (at your option) any later version.
--
--                            This program is distributed in the hope that it will be useful,
--                            but WITHOUT ANY WARRANTY; without even the implied warranty of
--                            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--                            GNU General Public License for more details.
--
--                            You should have received a copy of the GNU General Public License
--                            along with this program.  If not, see <https://www.gnu.org/licenses/>.
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    email                   slaurent@nanoxplore.com
--!   @file                   DRE_DMX_UT_5029_cfg.vhd
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--    Automatic Generation    No
--    Code Rules Reference    SOC of design and VHDL handbook for VLSI development, CNES Edition (v2.1)
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--!   @details                DRE DEMUX Unitary Test configuration file
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library fpasim;

configuration DRE_DMX_UT_5029_cfg of top_dmx_tb is

   for Simulation

      -- ------------------------------------------------------------------------------------------------------
      --!   Parser configuration
      -- ------------------------------------------------------------------------------------------------------
      for I_parser : parser
         use entity work.parser generic map (
            g_SIM_TIME           => 1000 us               , -- time    := c_SIM_TIME_DEF                     ; --! Simulation time
            g_BRD_MDL            => "dm"                 , -- string  := c_BRD_MDL_DEF                      ; --! Board model
            g_SIM_TYPE           => '1'                  , -- std_logic := c_SIM_TYPE_DEF                   ; --! Simulation type ('0': No regression, '1': Coupled simulation)
            g_TST_NUM            => "5029"                 -- string  := c_TST_NUM_DEF                        --! Test number
         );
      end for;

      -- ------------------------------------------------------------------------------------------------------
      --!   Science data model configuration
      -- ------------------------------------------------------------------------------------------------------
      for I_science_data_model: science_data_model
         use entity work.science_data_model generic map (
            g_SIM_TIME           => 1000 us              , -- time      := c_SIM_TIME_DEF                   ; --! Simulation time
            g_BRD_MDL            => "dm"                 , -- string  := c_BRD_MDL_DEF                      ; --! Board model
            g_SIM_TYPE           => '1'                  , -- std_logic := c_SIM_TYPE_DEF                   ; --! Simulation type ('0': No regression, '1': Coupled simulation)
            g_ERR_SC_DTA_ENA     => '0'                  , -- std_logic := c_ERR_SC_DTA_ENA_DEF             ; --! Error science data enable ('0' = No, '1' = Yes)
            g_FRM_CNT_SC_ENA     => '0'                  , -- std_logic := c_FRM_CNT_SC_ENA_DEF             ; --! Frame counter science enable ('0' = No, '1' = Yes)
            g_TST_NUM            => "5029"                 -- string    := c_TST_NUM_DEF                      --! Test number
         );
      end for;

      -- ------------------------------------------------------------------------------------------------------
      --!   EP SPI Model configuration
      -- ------------------------------------------------------------------------------------------------------
      for I_ep_spi_model : ep_spi_model
         use entity work.ep_spi_model generic map (
            g_EP_CLK_PER         => c_EP_CLK_PER_DEF     , -- time    := c_EP_CLK_PER_DEF                   ; --! EP: System clock period (ps)
            g_EP_CLK_PER_SHIFT   => c_EP_CLK_PER_SHFT_DEF, -- time    := c_EP_CLK_PER_SHFT_DEF              ; --! EP: Clock period shift
            g_EP_N_CLK_PER_SCLK_L=> 3                    , -- integer := c_EP_SCLK_L_DEF                    ; --! EP: Number of clock period for elaborating SPI Serial Clock low  level
            g_EP_N_CLK_PER_SCLK_H=> 1                    , -- integer := c_EP_SCLK_H_DEF                    ; --! EP: Number of clock period for elaborating SPI Serial Clock high level
            g_EP_BUF_DEL         => 0 ns                   -- time    := c_EP_BUF_DEL_DEF                     --! EP: Delay introduced by buffer
         );
      end for;

      -- ------------------------------------------------------------------------------------------------------
      --!   Squid model configuration
      -- ------------------------------------------------------------------------------------------------------
      for G_column_mgt(0)
         for I_squid_model: squid_model
            use entity work.squid_model generic map (
            g_SQM_ADC_VREF       => c_SQM_ADC_VREF_DEF   , -- real      := c_SQM_ADC_VREF_DEF               ; --! SQUID MUX ADC: Voltage reference (Volt)
            g_SQM_DAC_VREF       => c_SQM_DAC_VREF_DEF   , -- real      := c_SQM_DAC_VREF_DEF               ; --! SQUID MUX DAC: Voltage reference (Volt)
            g_SQA_DAC_VREF       => c_SQA_DAC_VREF_DEF   , -- real      := c_SQA_DAC_VREF_DEF               ; --! SQUID AMP DAC: Voltage reference (Volt)
            g_SQA_DAC_TS         => 0 ns                 , -- time      := c_SQA_DAC_TS_DEF                 ; --! SQUID AMP DAC: Output Voltage Settling time
            g_SQA_MUX_TPLH       => 0 ns                 , -- time      := c_SQA_MUX_TPLH_DEF               ; --! SQUID AMP MUX: Propagation delay switch in to out
            g_CLK_ADC_PER        => c_CLK_ADC_PER_DEF    , -- time      := c_CLK_ADC_PER_DEF                ; --! SQUID MUX ADC: Clock period
            g_TIM_ADC_TPD        => c_TIM_ADC_TPD_DEF    , -- time      := c_TIM_ADC_TPD_DEF                ; --! SQUID MUX ADC: Time, Data Propagation Delay
            g_SQM_VOLT_DEL       => 0 ns                 , -- time      := c_SQM_VOLT_DEL_DEF               ; --! SQUID MUX voltage delay
            g_SQA_VOLT_DEL       => 0 ns                 , -- time      := c_SQA_VOLT_DEL_DEF               ; --! SQUID AMP voltage delay
            g_SQERR_VOLT_DEL     => 0 ns                   -- time      := c_SQERR_VOLT_DEL_DEF               --! SQUID Error voltage delay
            );
         end for;

         for I_fpasim_model: fpga_system_fpasim_top
            use entity fpasim.fpga_system_fpasim_top generic map (
            g_ADC_VPP            => c_FPA_ADC_VPP_DEF    , -- natural := c_FPA_ADC_VPP_DEF                  ; --! ADC differential input voltage (Volt)
            g_ADC_DELAY          => 1                    , -- natural := c_FPA_ADC_DEL_DEF                  ; --! ADC conversion delay (clock cycle number)
            g_DAC_VPP            => c_FPA_DAC_VPP_DEF    , -- natural := c_FPA_DAC_VPP_DEF                  ; --! DAC differential output voltage (Volt)
            g_DAC_DELAY          => 0                    , -- natural := c_FPA_DAC_DEL_DEF                  ; --! DAC conversion delay (clock cycle number)
            g_MUX_SQ_FB_DELAY    => 0                    , -- natural := c_FPA_MUX_SQ_DEL_DEF               ; --! FPASIM cmd: Squid MUX delay (clock cycle number) (<= 63)
            g_AMP_SQ_OF_DELAY    => 0                    , -- natural := c_FPA_AMP_SQ_DEL_DEF               ; --! FPASIM cmd: Squid AMP delay (clock cycle number) (<= 63)
            g_ERROR_DELAY        => 0                    , -- natural := c_FPA_ERR_DEL_DEF                  ; --! FPASIM cmd: Error delay (clock cycle number) (<= 63)
            g_RA_DELAY           => 0                    , -- natural := c_FPA_SYNC_DEL_DEF                 ; --! FPASIM cmd: Pixel sequence sync. delay (clock cycle number) (<= 63)
            g_INTER_SQUID_GAIN   => 16                  ,  -- inter squid gain. The range is: [0;(2**8) - 1]
            g_NB_PIXEL_BY_FRAME  => c_MUX_FACT           , -- natural := c_MUX_FACT                         ; --! DEMUX multiplexing factor
            g_NB_SAMPLE_BY_PIXEL => c_FPA_PXL_NB_CYC_DEF   -- natural := c_FPA_PXL_NB_CYC_DEF                 --! Clock cycles number by pixel
         );
         end for;
      end for;

      for G_column_mgt(1)
         for I_squid_model: squid_model
            use entity work.squid_model generic map (
            g_SQM_ADC_VREF       => c_SQM_ADC_VREF_DEF   , -- real      := c_SQM_ADC_VREF_DEF               ; --! SQUID MUX ADC: Voltage reference (Volt)
            g_SQM_DAC_VREF       => c_SQM_DAC_VREF_DEF   , -- real      := c_SQM_DAC_VREF_DEF               ; --! SQUID MUX DAC: Voltage reference (Volt)
            g_SQA_DAC_VREF       => c_SQA_DAC_VREF_DEF   , -- real      := c_SQA_DAC_VREF_DEF               ; --! SQUID AMP DAC: Voltage reference (Volt)
            g_SQA_DAC_TS         => c_SQA_DAC_TS_DEF     , -- time      := c_SQA_DAC_TS_DEF                 ; --! SQUID AMP DAC: Output Voltage Settling time
            g_SQA_MUX_TPLH       => c_SQA_MUX_TPLH_DEF   , -- time      := c_SQA_MUX_TPLH_DEF               ; --! SQUID AMP MUX: Propagation delay switch in to out
            g_CLK_ADC_PER        => c_CLK_ADC_PER_DEF    , -- time      := c_CLK_ADC_PER_DEF                ; --! SQUID MUX ADC: Clock period
            g_TIM_ADC_TPD        => c_TIM_ADC_TPD_DEF    , -- time      := c_TIM_ADC_TPD_DEF                ; --! SQUID MUX ADC: Time, Data Propagation Delay
            g_SQM_VOLT_DEL       => c_SQM_VOLT_DEL_DEF   , -- time      := c_SQM_VOLT_DEL_DEF               ; --! SQUID MUX voltage delay
            g_SQA_VOLT_DEL       => c_SQA_VOLT_DEL_DEF   , -- time      := c_SQA_VOLT_DEL_DEF               ; --! SQUID AMP voltage delay
            g_SQERR_VOLT_DEL     => c_SQERR_VOLT_DEL_DEF   -- time      := c_SQERR_VOLT_DEL_DEF               --! SQUID Error voltage delay
            );
         end for;

         for I_fpasim_model: fpga_system_fpasim_top
            use entity work.fpga_system_fpasim_top generic map (
            g_ADC_VPP            => c_FPA_ADC_VPP_DEF    , -- natural := c_FPA_ADC_VPP_DEF                  ; --! ADC differential input voltage (Volt)
            g_ADC_DELAY          => c_FPA_ADC_DEL_DEF    , -- natural := c_FPA_ADC_DEL_DEF                  ; --! ADC conversion delay (clock cycle number)
            g_DAC_VPP            => c_FPA_DAC_VPP_DEF    , -- natural := c_FPA_DAC_VPP_DEF                  ; --! DAC differential output voltage (Volt)
            g_DAC_DELAY          => c_FPA_DAC_DEL_DEF    , -- natural := c_FPA_DAC_DEL_DEF                  ; --! DAC conversion delay (clock cycle number)
            g_MUX_SQ_FB_DELAY    => c_FPA_MUX_SQ_DEL_DEF , -- natural := c_FPA_MUX_SQ_DEL_DEF               ; --! FPASIM cmd: Squid MUX delay (clock cycle number) (<= 63)
            g_AMP_SQ_OF_DELAY    => c_FPA_AMP_SQ_DEL_DEF , -- natural := c_FPA_AMP_SQ_DEL_DEF               ; --! FPASIM cmd: Squid AMP delay (clock cycle number) (<= 63)
            g_ERROR_DELAY        => c_FPA_ERR_DEL_DEF    , -- natural := c_FPA_ERR_DEL_DEF                  ; --! FPASIM cmd: Error delay (clock cycle number) (<= 63)
            g_RA_DELAY           => c_FPA_SYNC_DEL_DEF   , -- natural := c_FPA_SYNC_DEL_DEF                 ; --! FPASIM cmd: Pixel sequence sync. delay (clock cycle number) (<= 63)
            g_INTER_SQUID_GAIN   => c_FPA_INR_SQ_GN_DEF  , -- natural := c_FPA_INR_SQ_GN_DEF                ; --! FPASIM cmd: Inter squid gain (<= 255)
            g_NB_PIXEL_BY_FRAME  => c_MUX_FACT           , -- natural := c_MUX_FACT                         ; --! DEMUX multiplexing factor
            g_NB_SAMPLE_BY_PIXEL => c_FPA_PXL_NB_CYC_DEF   -- natural := c_FPA_PXL_NB_CYC_DEF                 --! Clock cycles number by pixel
         );
         end for;
      end for;

      for G_column_mgt(2)
         for I_squid_model: squid_model
            use entity work.squid_model generic map (
            g_SQM_ADC_VREF       => c_SQM_ADC_VREF_DEF   , -- real      := c_SQM_ADC_VREF_DEF               ; --! SQUID MUX ADC: Voltage reference (Volt)
            g_SQM_DAC_VREF       => c_SQM_DAC_VREF_DEF   , -- real      := c_SQM_DAC_VREF_DEF               ; --! SQUID MUX DAC: Voltage reference (Volt)
            g_SQA_DAC_VREF       => c_SQA_DAC_VREF_DEF   , -- real      := c_SQA_DAC_VREF_DEF               ; --! SQUID AMP DAC: Voltage reference (Volt)
            g_SQA_DAC_TS         => c_SQA_DAC_TS_DEF     , -- time      := c_SQA_DAC_TS_DEF                 ; --! SQUID AMP DAC: Output Voltage Settling time
            g_SQA_MUX_TPLH       => c_SQA_MUX_TPLH_DEF   , -- time      := c_SQA_MUX_TPLH_DEF               ; --! SQUID AMP MUX: Propagation delay switch in to out
            g_CLK_ADC_PER        => c_CLK_ADC_PER_DEF    , -- time      := c_CLK_ADC_PER_DEF                ; --! SQUID MUX ADC: Clock period
            g_TIM_ADC_TPD        => c_TIM_ADC_TPD_DEF    , -- time      := c_TIM_ADC_TPD_DEF                ; --! SQUID MUX ADC: Time, Data Propagation Delay
            g_SQM_VOLT_DEL       => c_SQM_VOLT_DEL_DEF   , -- time      := c_SQM_VOLT_DEL_DEF               ; --! SQUID MUX voltage delay
            g_SQA_VOLT_DEL       => c_SQA_VOLT_DEL_DEF   , -- time      := c_SQA_VOLT_DEL_DEF               ; --! SQUID AMP voltage delay
            g_SQERR_VOLT_DEL     => c_SQERR_VOLT_DEL_DEF   -- time      := c_SQERR_VOLT_DEL_DEF               --! SQUID Error voltage delay
            );
         end for;

         for I_fpasim_model: fpga_system_fpasim_top
            use entity work.fpga_system_fpasim_top generic map (
            g_ADC_VPP            => c_FPA_ADC_VPP_DEF    , -- natural := c_FPA_ADC_VPP_DEF                  ; --! ADC differential input voltage (Volt)
            g_ADC_DELAY          => c_FPA_ADC_DEL_DEF    , -- natural := c_FPA_ADC_DEL_DEF                  ; --! ADC conversion delay (clock cycle number)
            g_DAC_VPP            => c_FPA_DAC_VPP_DEF    , -- natural := c_FPA_DAC_VPP_DEF                  ; --! DAC differential output voltage (Volt)
            g_DAC_DELAY          => c_FPA_DAC_DEL_DEF    , -- natural := c_FPA_DAC_DEL_DEF                  ; --! DAC conversion delay (clock cycle number)
            g_MUX_SQ_FB_DELAY    => c_FPA_MUX_SQ_DEL_DEF , -- natural := c_FPA_MUX_SQ_DEL_DEF               ; --! FPASIM cmd: Squid MUX delay (clock cycle number) (<= 63)
            g_AMP_SQ_OF_DELAY    => c_FPA_AMP_SQ_DEL_DEF , -- natural := c_FPA_AMP_SQ_DEL_DEF               ; --! FPASIM cmd: Squid AMP delay (clock cycle number) (<= 63)
            g_ERROR_DELAY        => c_FPA_ERR_DEL_DEF    , -- natural := c_FPA_ERR_DEL_DEF                  ; --! FPASIM cmd: Error delay (clock cycle number) (<= 63)
            g_RA_DELAY           => c_FPA_SYNC_DEL_DEF   , -- natural := c_FPA_SYNC_DEL_DEF                 ; --! FPASIM cmd: Pixel sequence sync. delay (clock cycle number) (<= 63)
            g_INTER_SQUID_GAIN   => c_FPA_INR_SQ_GN_DEF  , -- natural := c_FPA_INR_SQ_GN_DEF                ; --! FPASIM cmd: Inter squid gain (<= 255)
            g_NB_PIXEL_BY_FRAME  => c_MUX_FACT           , -- natural := c_MUX_FACT                         ; --! DEMUX multiplexing factor
            g_NB_SAMPLE_BY_PIXEL => c_FPA_PXL_NB_CYC_DEF   -- natural := c_FPA_PXL_NB_CYC_DEF                 --! Clock cycles number by pixel
         );
         end for;
      end for;

      for G_column_mgt(3)
         for I_squid_model: squid_model
            use entity work.squid_model generic map (
            g_SQM_ADC_VREF       => c_SQM_ADC_VREF_DEF   , -- real      := c_SQM_ADC_VREF_DEF               ; --! SQUID MUX ADC: Voltage reference (Volt)
            g_SQM_DAC_VREF       => c_SQM_DAC_VREF_DEF   , -- real      := c_SQM_DAC_VREF_DEF               ; --! SQUID MUX DAC: Voltage reference (Volt)
            g_SQA_DAC_VREF       => c_SQA_DAC_VREF_DEF   , -- real      := c_SQA_DAC_VREF_DEF               ; --! SQUID AMP DAC: Voltage reference (Volt)
            g_SQA_DAC_TS         => c_SQA_DAC_TS_DEF     , -- time      := c_SQA_DAC_TS_DEF                 ; --! SQUID AMP DAC: Output Voltage Settling time
            g_SQA_MUX_TPLH       => c_SQA_MUX_TPLH_DEF   , -- time      := c_SQA_MUX_TPLH_DEF               ; --! SQUID AMP MUX: Propagation delay switch in to out
            g_CLK_ADC_PER        => c_CLK_ADC_PER_DEF    , -- time      := c_CLK_ADC_PER_DEF                ; --! SQUID MUX ADC: Clock period
            g_TIM_ADC_TPD        => c_TIM_ADC_TPD_DEF    , -- time      := c_TIM_ADC_TPD_DEF                ; --! SQUID MUX ADC: Time, Data Propagation Delay
            g_SQM_VOLT_DEL       => c_SQM_VOLT_DEL_DEF   , -- time      := c_SQM_VOLT_DEL_DEF               ; --! SQUID MUX voltage delay
            g_SQA_VOLT_DEL       => c_SQA_VOLT_DEL_DEF   , -- time      := c_SQA_VOLT_DEL_DEF               ; --! SQUID AMP voltage delay
            g_SQERR_VOLT_DEL     => c_SQERR_VOLT_DEL_DEF   -- time      := c_SQERR_VOLT_DEL_DEF               --! SQUID Error voltage delay
            );
         end for;

         for I_fpasim_model: fpga_system_fpasim_top
            use entity work.fpga_system_fpasim_top generic map (
            g_ADC_VPP            => c_FPA_ADC_VPP_DEF    , -- natural := c_FPA_ADC_VPP_DEF                  ; --! ADC differential input voltage (Volt)
            g_ADC_DELAY          => c_FPA_ADC_DEL_DEF    , -- natural := c_FPA_ADC_DEL_DEF                  ; --! ADC conversion delay (clock cycle number)
            g_DAC_VPP            => c_FPA_DAC_VPP_DEF    , -- natural := c_FPA_DAC_VPP_DEF                  ; --! DAC differential output voltage (Volt)
            g_DAC_DELAY          => c_FPA_DAC_DEL_DEF    , -- natural := c_FPA_DAC_DEL_DEF                  ; --! DAC conversion delay (clock cycle number)
            g_MUX_SQ_FB_DELAY    => c_FPA_MUX_SQ_DEL_DEF , -- natural := c_FPA_MUX_SQ_DEL_DEF               ; --! FPASIM cmd: Squid MUX delay (clock cycle number) (<= 63)
            g_AMP_SQ_OF_DELAY    => c_FPA_AMP_SQ_DEL_DEF , -- natural := c_FPA_AMP_SQ_DEL_DEF               ; --! FPASIM cmd: Squid AMP delay (clock cycle number) (<= 63)
            g_ERROR_DELAY        => c_FPA_ERR_DEL_DEF    , -- natural := c_FPA_ERR_DEL_DEF                  ; --! FPASIM cmd: Error delay (clock cycle number) (<= 63)
            g_RA_DELAY           => c_FPA_SYNC_DEL_DEF   , -- natural := c_FPA_SYNC_DEL_DEF                 ; --! FPASIM cmd: Pixel sequence sync. delay (clock cycle number) (<= 63)
            g_INTER_SQUID_GAIN   => c_FPA_INR_SQ_GN_DEF  , -- natural := c_FPA_INR_SQ_GN_DEF                ; --! FPASIM cmd: Inter squid gain (<= 255)
            g_NB_PIXEL_BY_FRAME  => c_MUX_FACT           , -- natural := c_MUX_FACT                         ; --! DEMUX multiplexing factor
            g_NB_SAMPLE_BY_PIXEL => c_FPA_PXL_NB_CYC_DEF   -- natural := c_FPA_PXL_NB_CYC_DEF                 --! Clock cycles number by pixel
         );
         end for;
      end for;

   end for;

end configuration DRE_DMX_UT_5029_cfg;
