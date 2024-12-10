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
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    # use helper function to assert reset signal
    # dut.notes_in.value = 0x00_00_00_00_45 # e5
    # dut.durations_in.value = 0x00000000_00000000_00000000_00000000_02FAF080
    
    for i in range(5):
        dut.notes_in[i].value = 0x00
        dut.durations_in[i].value = 0x00000000
    dut.bpm.value = 40
    dut.num_lines.value = 1
    await reset(dut.rst_in, dut.clk_in)
    dut.notes_in[0].value = 0x45
    dut.durations_in[0].value = 0x8F0D17FF
    await ClockCycles(dut.clk_in,57000)
    dut.durations_in[0].value = 0
    await ClockCycles(dut.clk_in,10)


    # dut.note_on_in.value = 0b11111
    # dut.received_note.value = 0x0a00_0200_0300_0400_0500
    # await ClockCycles(dut.clk_in,3)
    # dut.note_on_in.value = 0b11111
    # dut.received_note.value = 0x0a00_0b00_0c00_0400_0500
    # await ClockCycles(dut.clk_in,3)
    # dut.note_on_in.value = 0b11111
    # dut.received_note.value = 0x0c00_0d00_0500_0a00_0b00
    # await ClockCycles(dut.clk_in,3)    # await drive_note(dut,90,100,2)
    # dut.note_on_in.value = 0b11111
    # dut.received_note.value = 0x0500_0a00_0c00_0d00_0600
    # await ClockCycles(dut.clk_in,3)    # await drive_note(dut,90,100,2)    # await ClockCycles(dut.clk_in,10000)
    # dut.note_on_in.value = 0b01111
    # dut.received_note.value = 0x0500_0a00_0c00_0d00_0600
    # await ClockCycles(dut.clk_in,3)    # await drive_note(dut,90,100,2)    # await ClockCycles(dut.clk_in,10000)
    # await end_note(dut,90,2)
    # await ClockCycles(dut.clk_in,10000)
    # await drive_note(dut,7,7,7)
    # await end_note(dut,7,7)

    
    

    
def test_note_storing_run_it_back_runner():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "note_storing_run_it_back.sv", proj_path / "hdl" / "xilinx_single_port_ram_read_first.sv"]
    print(sources)
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="note_storing_run_it_back",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="note_storing_run_it_back",
        test_module="test_note_storing_run_it_back",
        test_args=run_test_args,
        # waves=True
    )

if __name__ == "__main__":
    test_note_storing_run_it_back_runner()