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


async def drive_burst(dut,midi_data):
    """ Helper function to send a note to the module
    midi_data_list is a at most five element list with 32 bit elements
    which contain MIDI data in the format of MIDI_burst:
    MSB to LSB:
    1 bit: status on/off
    4 bits: channel
    8 bits: note_number
    8 bits: velocity
    """
    dut.on_msg_count_in.value = 1
    dut.midi_burst_data_in.value = midi_data
    dut.midi_burst_ready_in.value = 1
    await ClockCycles(dut.clk_in,1)
    dut.midi_burst_ready_in.value = 0
    await ClockCycles(dut.clk_in,1)

    

    


    
@cocotb.test()
async def test_tmds(dut):
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    # use helper function to assert reset signal
    await reset(dut.rst_in,dut.clk_in)
    await ClockCycles(dut.clk_in,5)
    #must be backwards and 21 bits
    await drive_burst(dut,[0b1_1100_00001111_00100111,0b00000000_00000000_0000_0,0b00000000_00000000_0000_0,0b00000000_00000000_0000_0,0b00000000_00000000_0000_0])
    print(f"The note should be {0b01100100} with an octave of {0b01100100 % 12}")
    await ClockCycles(dut.clk_in,200)
    print(f"vals_ready: {dut.vals_ready.value}")
    print(f"octave_count: {[dut.octave_count[i].value for i in range(5)]}")
    print(f"note_value_array: {[dut.note_value_array[i].value for i in range(5)]}")
    print(f"note_velocity_array: {[dut.note_velocity_array[i].value for i in range(5)]}")

    
    

    
def test_tmds_runner():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "pwm_combine.sv"]
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