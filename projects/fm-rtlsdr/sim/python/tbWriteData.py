"""
File		: tbWriteData.py
Author		: Hunter Mills
Date		: May 2024
Description	: Function to write testbench data for HDL
"""

# Imports
import sys
import argparse
import numpy as np
import sounddevice as sd
import matplotlib.pyplot as plt
from scipy.signal import firwin
from ...srcs.python.fmdemod import *

def tbWriteData(data:np.ndarray, filename:str):
    """
    Function to write testbench data for HDL
    
        Args :
            data        : Data to write to file
            filename    : Filename to write data to
    """
    file = 'projects/fm-rtlsdr/sim/data/' + filename + '_axis.txt'
    with open(file , "w", encoding="utf8") as outfile:
            # Create a TLAST vector which is high on the last word of the packet
            tlasts = np.zeros(len(data))
            tlasts[len(tlasts)-1] = 1

            # Write to file
            for i, sample in enumerate(data):
                hex_val = hex(int(sample))[2:]
                for _ in range(4-len(hex_val)):
                    hex_val = '0' + hex_val
                outfile.write(str(int(tlasts[i])) + "\t" + hex_val + "\n")