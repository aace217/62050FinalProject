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


async def drive_note(dut,note,velocity,channel):
    """ Helper function to send a note to the module"""
    clk = dut.clk_in
    dut.midi_Data_in.value = 0 # starting a message
    await ClockCycles(clk,MIDI_PERIOD) # must be held for this long
    note_on = format(9,"04b")[::-1] # telling the module that a note is turning on
    note_bits = format(note,"08b")[::-1]
    velocity_bits = format(velocity,"08b")[::-1]
    channel_bits = note_on + format(channel,"04b")[::-1]
    print(f"Going to send note {note} with a velocity of {velocity} on channel {channel}.")
    bin_data_to_send = "0" + channel_bits + "1" + "0" +  note_bits + "1" + "0" + velocity_bits + "1"
    print(f"Binary String:{bin_data_to_send}")
    count = 0
    for bit in bin_data_to_send:
        dut.midi_Data_in.value = int(bit)
        await ClockCycles(clk,MIDI_PERIOD)
        print(f"Just sent bit:{bit}")
        count += 1
    dut.midi_Data_in.value = 1
    await ClockCycles(clk,MIDI_PERIOD)
    print(f"Just sent {count} bits.")

async def end_note(dut,note,channel):
    clk = dut.clk_in
    print(f"Going to stop note {note} on channel {channel}.")
    dut.midi_Data_in.value = 0 #starting a message
    await ClockCycles(clk,MIDI_PERIOD)
    count = 0
    note_off = format(8,"04b")[::-1]
    note_bits = format(note,"08b")[::-1]
    channel_bits = note_off + format(channel,"04b")[::-1]
    print(f"Going to stop note {note} on channel {channel}.")
    bin_data_to_send = "0" + channel_bits + "1" + "0" + note_bits + "1" + "0" + "00000000" + "1"
    # release velocity of the note can be used but is usually just set to 0
    print(f"Binary String:{bin_data_to_send}")
    for bit in bin_data_to_send:
        dut.midi_Data_in.value = int(bit)
        print(f"Just sent bit:{bit}")
        await ClockCycles(clk,MIDI_PERIOD)
        count += 1
    print(f"Just sent {count} bits.")
    dut.midi_Data_in.value = 1
    await ClockCycles(clk,MIDI_PERIOD)

    
@cocotb.test()
async def test_tmds(dut):
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    # use helper function to assert reset signal
    dut.midi_Data_in.value = 1
    await reset(dut.rst_in,dut.clk_in)
    await ClockCycles(dut.clk_in,5)
    await drive_note(dut,90,100,2)
    await ClockCycles(dut.clk_in,10000)
    await end_note(dut,90,2)
    await ClockCycles(dut.clk_in,10000)
    await drive_note(dut,7,7,7)
    await end_note(dut,7,7)

    
    

    
def test_tmds_runner():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "midi_decode.sv",proj_path / "hdl" / "uart_receive.sv"]
    print(sources)
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="midi_decode",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="midi_decode",
        test_module="test_midi_decode",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    test_tmds_runner()