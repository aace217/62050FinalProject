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
MIDI_PERIOD = 3200

async def reset(rst,clk):
    """ Helper function to issue a reset signal to our module """
    rst.value = 1
    await ClockCycles(clk,3)
    rst.value = 0
    await ClockCycles(clk,2)


async def drive_burst(dut,valid_bits,midi_data):
    """ Helper function to send a note to the module
    midi_data_list is a at most five element list with 32 bit elements
    which contain MIDI data in the format of MIDI_burst:
    MSB to LSB:
    1 bit: status on/off
    4 bits: channel
    8 bits: note_number
    8 bits: velocity
    """
    dut.on_array_in.value = valid_bits
    dut.midi_burst_data_in.value = midi_data
    dut.midi_burst_change_in.value = 1
    await ClockCycles(dut.clk_in,1)
    dut.midi_burst_change_in.value = 0
    await ClockCycles(dut.clk_in,1)

    

    


    
@cocotb.test()
async def test_tmds(dut):
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    # use helper function to assert reset signal
    await reset(dut.rst_in,dut.clk_in)
    await ClockCycles(dut.clk_in,5)
    #must be backwards and 21 bits
    #await drive_burst(dut,0b10000,[0b0011_0101_0000_1111,0b0101_0011_0000_1111,0b0000_0000_0000_0000,0b0000_0000_0000_0000,0b0000_0000_0000_0000])
    #await ClockCycles(dut.clk_in,2000000)
    note_array = [0b0011_0101_0100_1110,0b0101_0011_0111_1111,0b0110_0011_0001_0000,0b0101_0101_0000_0000,0b0010_0010_0001_0100]
    await drive_burst(dut,0b11111,note_array)
    await ClockCycles(dut.clk_in,2000000)

    
    

    
def test_tmds_runner():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "pwm_combine.sv",proj_path / "hdl" / "mod12.sv",proj_path / "hdl" / "sine_machine.sv",proj_path / "hdl" / "xilinx_single_port_ram_read_first.sv"]
    print(sources)
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="pwm_combine",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="pwm_combine",
        test_module="test_pwm_combine",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    test_tmds_runner()
