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
    await ClockCycles(clk,2)
    rst.value = 0
    await ClockCycles(clk,1)
    
@cocotb.test()
async def test_staff(dut):
    cocotb.start_soon(Clock(dut.clk_camera_in, 10, units="ns").start())
    # use helper function to assert reset signal
    await reset(dut.rst_in, dut.clk_camera_in)
    dut.hcount.value = 0
    dut.vcount.value = 0 
    dut.bpm.value = 60
    dut.received_note.value = 0x01000100_01000200_01000300_01000400_01000500
    dut.num_lines.value = 1
    
    await ClockCycles(dut.clk_camera_in,3)
    dut.received_note.value = 0x01000a00_01000200_01000300_01000400_01000500
    await ClockCycles(dut.clk_camera_in,3)
    dut.received_note.value = 0x01000a00_01000b00_01000c00_01000400_01000500
    await ClockCycles(dut.clk_camera_in,3)
    dut.received_note.value = 0x01000c00_01000d00_01000500_01000a00_01000b00
    await ClockCycles(dut.clk_camera_in,3)    # await drive_note(dut,90,100,2)
    dut.received_note.value = 0x01000500_01000a00_01000c00_01000d00_01000600
    await ClockCycles(dut.clk_camera_in,3)    # await drive_note(dut,90,100,2)    # await ClockCycles(dut.clk_in,10000)
    # await end_note(dut,90,2)
    # await ClockCycles(dut.clk_in,10000)
    # await drive_note(dut,7,7,7)
    # await end_note(dut,7,7)

    
    

    
def test_staff_creation_runner():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "staff_creation.sv"]
    print(sources)
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="staff_creation",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="staff_creation",
        test_module="test_staff_creation",
        test_args=run_test_args,
        # waves=True
    )

if __name__ == "__main__":
    test_staff_creation_runner()