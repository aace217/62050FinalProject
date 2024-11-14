import cocotb
from cocotb.triggers import Timer
import os
from pathlib import Path
import sys
import os
import numpy as np

from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,ReadWrite,with_timeout, First, Join
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner

from random import getrandbits
from PIL import Image

current_dir = Path(__file__).resolve().parent


# async def drive_data(dut,upper_pix, lower_pix, hcount, vcount):
#     """ submit a set of data values as input, then wait a clock cycle for them to stay there. """
    
async def drive_reset(dut):
    dut.btn[0].value = 1
    await ClockCycles(dut.clk_100mhz, 1)
    dut.btn.value = 0
    
@cocotb.test()
async def test_top(dut):
    cocotb.start_soon(Clock(dut.clk_100mhz, 10, units="ns").start())
    cocotb.start_soon(Clock(dut.cam_pclk, 20, units="ns").start())
    # use helper function to assert reset signal
    dut.camera_d.value = 0
    dut.cam_hsync.value = 1
    dut.cam_vsync.value = 1
    dut.sw.value = 0
    dut.btn.value = 0
    dut.midi_data_in.value = 1
    await drive_reset(dut)
    
    await ClockCycles(dut.clk_100mhz,10)
    # await drive_note(dut,90,100,2)
    # await ClockCycles(dut.clk_in,10000)
    # await end_note(dut,90,2)
    # await ClockCycles(dut.clk_in,10000)
    # await drive_note(dut,7,7,7)
    # await end_note(dut,7,7)

    
    

    
def test_top_runner():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "top_level_copy.sv",proj_path / "hdl" / "baton_tracker.sv"]
    sources += [proj_path / "hdl" / "bpm.sv"]
    sources += [proj_path / "hdl" / "camera_registers.sv"]
    sources += [proj_path / "hdl" / "center_of_mass.sv"]
    sources += [proj_path / "hdl" / "counter.sv"]
    sources += [proj_path / "hdl" / "cw_fast_clk_wiz.v"]
    sources += [proj_path / "hdl" / "cw_hdmi_clk_wiz.v"]
    sources += [proj_path / "hdl" / "divider.sv"]
    sources += [proj_path / "hdl" / "i2c_master.v"]
    sources += [proj_path / "hdl" / "lab05_ssc.sv"]
    sources += [proj_path / "hdl" / "midi_decode.sv"]
    sources += [proj_path / "hdl" / "pixel_reconstruct.sv"]
    sources += [proj_path / "hdl" / "pwm_combine.sv"]
    sources += [proj_path / "hdl" / "pwm.sv"]
    sources += [proj_path / "hdl" / "rgb_to_ycrcb.sv"]
    sources += [proj_path / "hdl" / "seven_segment_contoller.sv"]
    sources += [proj_path / "hdl" / "staff_creation.sv"]
    sources += [proj_path / "hdl" / "threshold.sv"]
    sources += [proj_path / "hdl" / "tm_choice.sv"]
    sources += [proj_path / "hdl" / "tmds_encoder.sv"]
    sources += [proj_path / "hdl" / "tmds_serializer.sv"]
    sources += [proj_path / "hdl" / "uart_receive.sv"]
    sources += [proj_path / "hdl" / "uart_transmit.sv"]
    sources += [proj_path / "hdl" / "video_mux.sv"]
    sources += [proj_path / "hdl" / "video_sig_gen.sv"]
    print(sources)
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="top_level_copy",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="top_level_copy",
        test_module="test_top_level_copy",
        test_args=run_test_args,
        # waves=True
    )

if __name__ == "__main__":
    test_top_runner()