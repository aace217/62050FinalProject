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
async def test_durations(dut):
    cocotb.start_soon(Clock(dut.clk_camera_in, 10, units="ns").start())
    # use helper function to assert reset signal
    await reset(dut.rst_in, dut.clk_camera_in)
    dut.valid_note_in.value = 1
    dut.note_on_in.value = 0b11111
    dut.received_note.value = 0x0100_0200_0300_0400_0500
    
    await ClockCycles(dut.clk_camera_in,3)
    dut.note_on_in.value = 0b11111
    dut.received_note.value = 0x0a00_0200_0300_0400_0500
    await ClockCycles(dut.clk_camera_in,3)
    dut.note_on_in.value = 0b11111
    dut.received_note.value = 0x0a00_0b00_0c00_0400_0500
    await ClockCycles(dut.clk_camera_in,3)
    dut.note_on_in.value = 0b11111
    dut.received_note.value = 0x0c00_0d00_0500_0a00_0b00
    await ClockCycles(dut.clk_camera_in,3)    # await drive_note(dut,90,100,2)
    dut.note_on_in.value = 0b11111
    dut.received_note.value = 0x0500_0a00_0c00_0d00_0600
    await ClockCycles(dut.clk_camera_in,3)    # await drive_note(dut,90,100,2)    # await ClockCycles(dut.clk_in,10000)
    dut.note_on_in.value = 0b01111
    dut.received_note.value = 0x0500_0a00_0c00_0d00_0600
    await ClockCycles(dut.clk_camera_in,3)    # await drive_note(dut,90,100,2)    # await ClockCycles(dut.clk_in,10000)
    # await end_note(dut,90,2)
    # await ClockCycles(dut.clk_in,10000)
    # await drive_note(dut,7,7,7)
    # await end_note(dut,7,7)

    
    

    
def test_note_duration_runner():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "note_duration.sv"]
    print(sources)
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="note_duration",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="note_duration",
        test_module="test_note_duration",
        test_args=run_test_args,
        # waves=True
    )

if __name__ == "__main__":
    test_note_duration_runner()