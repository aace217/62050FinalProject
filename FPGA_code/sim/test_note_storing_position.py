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
# \    input wire [7:0] bpm,
#     input wire  [7:0] notes_in [4:0],
#     input wire  [31:0] durations_in[4:0],
#     output logic [5:0] current_staff_cell,
    
    # output logic [4:0][6:0] note_width,
    # output logic [4:0][2:0] sharp_shift,
    # output logic [4:0][7:0] rhythm_shift,
    
    # output logic [3:0] note_rhythms [4:0],
    # output logic [3:0] notes_out [4:0],
    
    # output logic [4:0][7:0] y_dot_out,
    # output logic [7:0] y_stem_out
    dut.bpm.value = 60
    await reset(dut.rst_in, dut.clk_in)

    await ClockCycles(dut.clk_in,2)
    dut.notes_in[0].value = 0x33
    dut.notes_in[1].value = 0x55
    dut.notes_in[2].value = 0x77
    dut.notes_in[3].value = 0x88
    dut.notes_in[4].value = 0x00
    dut.durations_in[0].value = 10000
    dut.durations_in[1].value = 20000
    dut.durations_in[2].value = 30000
    dut.durations_in[3].value = 40000
    dut.durations_in[4].value = 50000
    await ClockCycles(dut.clk_in,5)
    dut.notes_in[4].value = 0xFF
    await ClockCycles(dut.clk_in,5)





    
    

    
def test_note_storing_run_it_back_runner():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "note_storing_position.sv", proj_path / "hdl" / "xilinx_single_port_ram_read_first.sv"]
    print(sources)
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="note_storing_position",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="note_storing_position",
        test_module="test_note_storing_position",
        test_args=run_test_args,
        # waves=True
    )

if __name__ == "__main__":
    test_note_storing_run_it_back_runner()