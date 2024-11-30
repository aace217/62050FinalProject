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
    
async def reset(rst,clk):
    """ Helper function to issue a reset signal to our module """
    rst.value = 1
    await ClockCycles(clk,3)
    rst.value = 0
    await ClockCycles(clk,2)
    
@cocotb.test()
async def test_top(dut):
    # use helper function to assert reset signal
    cocotb.start_soon(Clock(dut.clk_camera_in, 10, units="ns").start())

    await reset(dut.rst_in, dut.clk_camera_in)
    dut.y_in.value = 0
    dut.measure_in.value = 1
    await ClockCycles(dut.clk_camera_in, 10)

    dut.y_in.value = 46
    await ClockCycles(dut.clk_camera_in, 10)
    dut.y_in.value = 34
    await ClockCycles(dut.clk_camera_in, 10)
    dut.y_in.value = 27
    await ClockCycles(dut.clk_camera_in, 10)
    dut.y_in.value = 26
    await ClockCycles(dut.clk_camera_in, 10)
    dut.y_in.value = 33
    await ClockCycles(dut.clk_camera_in, 10)
    dut.y_in.value = 56
    await ClockCycles(dut.clk_camera_in, 10)


    # for i in range(5):
    #     dut.y_in.value = i + 1
    #     await ClockCycles(dut.clk_camera_in, 1)
    #     # assert dut.change_out.value == 0

    # await ClockCycles(dut.clk_camera_in, 1)

    # for i in range(3):
    #     dut.y_in.value = 5 - i - 1
    #     await ClockCycles(dut.clk_camera_in, 1)
    #     # if i == 0:
    #     #     assert dut.change_out.value == 1
    #     # else:
    #     #     assert dut.change_out.value == 0

    # await ClockCycles(dut.clk_camera_in, 3)

    
    # for i in range(6):
    #     dut.y_in.value = 2 + i
    #     await ClockCycles(dut.clk_camera_in, 1)
    #     # if i == 0:
    #     #     assert dut.change_out.value == 1
    #     # else:
    #     #     assert dut.change_out.value == 0
    
    # for i in range(8):
    #     dut.y_in.value = 8 - i  -1
    #     await ClockCycles(dut.clk_camera_in, 1)
    #     # if i == 0:
    #     #     assert dut.change_out.value == 1
    #     # else:
    #     #     assert dut.change_out.value == 0

    

    
    # await drive_note(dut,90,100,2)
    # await ClockCycles(dut.clk_in,10000)
    # await end_note(dut,90,2)
    # await ClockCycles(dut.clk_in,10000)
    # await drive_note(dut,7,7,7)
    # await end_note(dut,7,7)

    
    

    
def test_baton_tracker():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "baton_tracker.sv"]
    print(sources)
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="baton_tracker",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="baton_tracker",
        test_module="test_baton_tracker",
        test_args=run_test_args,
        # waves=True
    )

if __name__ == "__main__":
    test_baton_tracker()