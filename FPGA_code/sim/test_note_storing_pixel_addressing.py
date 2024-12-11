import cocotb
from cocotb.triggers import Timer
import os
from pathlib import Path
import sys
import os
import numpy as np
import random

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


async def drive_data(
        dut,
        detected_note_list,
        current_staff,
        y_dot_list,
        y_stem_in,
        sharp_shift_list,
        rhythm_shift_list,
        note_width_list
                     ):
    """ Helper function to send a note to the module"""
    dut.detected_note_in.value = detected_note_list
    dut.current_staff_cell_in.value = current_staff
    dut.y_dot_in.value = y_dot_list
    dut.y_stem_in.value = y_stem_in
    dut.sharp_shift_in.value = sharp_shift_list
    dut.rhythm_shift_in.value = rhythm_shift_list
    dut.note_width_in.value = note_width_list
    


    
@cocotb.test()
async def test_tmds(dut):
    cocotb.start_soon(Clock(dut.clk_in, 10, units="ns").start())
    # use helper function to assert reset signal
    await reset(dut.rst_in,dut.clk_in)
    await ClockCycles(dut.clk_in,5)
    detected_note_list = [int(''.join(random.choice('0123456789ABCDEF') for _ in range(3)),16) for i in range(5)]
    print(f"This is the note list:{detected_note_list}")
    current_staff_cell = 21
    y_dot_list = [100,150,299,2,57]
    binary_string = int(''.join(f'{value:09b}' for value in y_dot_list),2) #converting numbers to bit string
    y_stem = 110
    sharp_shift_list = [7,7,7,0,0]
    rhythm_shift_list = [20,2,100,80,165]
    note_width_list = [0,36,72,20,40]
    await drive_data(dut,detected_note_list,current_staff_cell,
                     binary_string,y_stem,sharp_shift_list,rhythm_shift_list,
                     note_width_list)
    await ClockCycles(dut.clk_in,100)

    
    

    
def test_tmds_runner():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "note_storing_pixel_addressing.sv",proj_path / "hdl" / "xilinx_single_port_ram_read_first.sv"]
    print(sources)
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="note_storing_pixel_addressing",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="note_storing_pixel_addressing",
        test_module="test_note_storing_pixel_addressing",
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    test_tmds_runner()