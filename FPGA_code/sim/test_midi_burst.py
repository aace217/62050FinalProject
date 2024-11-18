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
MIDI_PERIOD = 6400

async def reset(rst,clk):
    """ Helper function to issue a reset signal to our module """
    rst.value = 1
    await ClockCycles(clk,3)
    rst.value = 0
    await ClockCycles(clk,2)


async def drive_note(dut,note,velocity,channel):
    """ Helper function to send a note to the module"""
    clk = dut.clk_in
    dut.midi_velocity_in.value = velocity
    dut.midi_received_note_in.value = note
    dut.midi_channel_in.value = channel
    dut.midi_status_in.value = 1
    dut.midi_data_ready_in.value = 1
    await ClockCycles(clk,1)
    dut.midi_data_ready_in.value = 0
    dut.midi_velocity_in.value = 0
    dut.midi_received_note_in.value = 0
    dut.midi_channel_in.value = 0
    

async def end_note(dut,note,channel):
    clk = dut.clk_in
    dut.midi_received_note_in.value = note
    dut.midi_channel_in.value = channel
    dut.midi_status_in.value = 1
    dut.midi_data_ready_in.value = 0
    await ClockCycles(clk,1)
    dut.midi_data_ready_in.value = 0
    dut.midi_received_note_in.value = 0
    dut.midi_channel_in.value = 0



@cocotb.test()
async def test_tmds(dut):
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    # use helper function to assert reset signal
    await reset(dut.rst_in,dut.clk_in)
    await ClockCycles(dut.clk_in,5)
    await drive_note(dut,0x90,0x50,0x1)
    await ClockCycles(dut.clk_in,10000)
    await end_note(dut,90,2)
    await ClockCycles(dut.clk_in,10000)
    await drive_note(dut,0x7,0x7,0x7)
    await end_note(dut,0x7,0x7)

    
    

    
def test_tmds_runner():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "midi_burst.sv"]
    print(sources)
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="midi_burst",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="midi_burst",
        test_module="test_midi_burst",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    test_tmds_runner()