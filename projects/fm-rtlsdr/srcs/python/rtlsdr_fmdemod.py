#!/usr/bin/python3
"""
File		: rtlsdr_fmdemod.py
Author		: Hunter Mills
Date		: April 2024
Description	: FM Demodator using RTL-SDR as source
"""

# Imports
import os
import sys
import queue
import argparse
import threading
import numpy as np
import sounddevice as sd
from .fmdemod import *
from rtlsdr import RtlSdr
from scipy.signal import firwin

# Queues that are shared between classes
dataQueue = queue.Queue()
audioQueue = queue.Queue()

class fmDemod(threading.Thread):
    """
    Threaded FM Demodulation Class.
    """

    def setup(self, sampleRate:float, decFac:int):
        """
        Constructor for fmDemod
        
        Args :
            sampleRate  : Sample rate of RTL-SDR
            decFac      : Decimation factor for audio
        """
        # Args
        self.sampleRate = sampleRate
        self.decFac     = decFac

        # fmDemod Constants
        self.numTaps    = 91
        self.cutOff 	= 19000 # Hz
        self.h 		    = firwin(self.numTaps, self.cutOff, nyq=sampleRate)

    def run(self):
        """
        Run method for thread
        """
        # Loop forever waiting on queue to be filled by RTL-SDR
        while(1):
            # Grab IQ data
            iqData  = dataQueue.get()
            dataQueue.task_done()

            # Quadrature Demod of iqData
            fmData = iqDemod(iqData)

            # Filter and decimate
            fmFilt	= np.real(downsampFilter(fmData, self.h, self.decFac))

            # Scale and DC Filter
            audioData	= processAudio(fmFilt)

            # De-emphasis filter
            audioFs 	= self.sampleRate / self.decFac
            deEmphData	= deEmphasisFilter(audioData, audioFs)

            # Put audio data onto queue
            audioQueue.put(deEmphData)
            
class playAudio(threading.Thread):
    """
    Threaded Audio Playing class.
    """
    def run(self):
        """
        Run method for thread
        """
        # Loop forever to play audio
        while(1):
            # Grab audio data
            audioData = audioQueue.get()
            audioQueue.task_done()

            # Play Audio
            sd.play(audioData.astype(np.int16))
            sd.wait()

class exitProg(threading.Thread):
    """
    Class to exit program.
    """
    def run(self):
        """
        Run method for thread
        """
        input('Press key to exit')
        os._exit(1)

def sdrCallback(samples, sampleRate:int):
    """
    Callback function for RTL-SDR to put data into dataQueue
    """
    dataQueue.put(np.array(samples, dtype=np.complex64))

def main():
    """
	Function to Demodulate FM radio from RTL-SDR
	"""
    # Read Iput args
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--freq',
    				 	help='Frequency of RTL-SDR to tune to',
    					type=float,
    					required=True)
    parser.add_argument('-fs', '--sampleRate',
    				 	help='Sample frequency of RTL-SDR data',
    					type=int,
    					default=250000,
    					required=False)
    parser.add_argument('-dec', '--decimation',
    				 	help='Decimation rate from sampleRate to audioRate (~48kHz)',
    					type=int,
                        default=6,
    					required=False)
    args = parser.parse_args()

    # Run threads
    try:
        # Create RTL-SDR object
        sdr = RtlSdr()
        sdr.sample_rate = args.sampleRate
        sdr.center_freq = args.freq
        sdr.gain        = 'auto'

        # Create objects
        demod = fmDemod()
        demod.setup(args.sampleRate, args.decimation)
        audio = playAudio()
        exitp = exitProg()

        # Start Threads
        demod.start()
        audio.start()
        exitp.start()

        # Read Samples from RTL-SDR
        sdr.read_samples_async(sdrCallback, args.sampleRate)
    
    except ValueError:
        print('ERROR')

if __name__ == '__main__':
	sys.exit(main())
      