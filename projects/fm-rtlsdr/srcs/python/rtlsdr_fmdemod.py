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

# Constants
SAMPLERATE  = 250000
DECRATE     = 6

# Queues that are shared between classes
dataQueue = queue.Queue()
audioQueue = queue.Queue()

def sdrCallback(samples, sampleRate:int):
    """
    Callback function for RTL-SDR to put data into dataQueue
    """
    dataQueue.put(np.array(samples, dtype=np.complex64))

class fmDemod(threading.Thread):
    """
    Threaded FM Demodulation Class.
    """

    def setup(self):
        """
        Constructor for fmDemod
        
        Args :
            sampleRate  : Sample rate of RTL-SDR
            decFac      : Decimation factor for audio
        """
        # Args
        self.sampleRate = SAMPLERATE
        self.decFac     = DECRATE

        # fmDemod Constants
        self.numTaps    = 91
        self.cutOff 	= 19000 # Hz
        self.h 		    = firwin(self.numTaps, self.cutOff, nyq=SAMPLERATE)

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
        # Create Sounddevice output stream
        audioFs = SAMPLERATE / DECRATE
        stream = sd.OutputStream(samplerate=audioFs, channels=1, dtype=np.int16)
        stream.start()

        # Loop forever to play audio
        while(1):
            # Grab audio data
            audioData = audioQueue.get()
            audioQueue.task_done()

            # Play Audio
            stream.write(audioData.astype(np.int16))

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
    args = parser.parse_args()

    # Run threads
    try:
        # Create RTL-SDR object
        sdr = RtlSdr()
        sdr.sample_rate = 250000
        sdr.center_freq = args.freq
        sdr.gain        = 'auto'

        # Create objects
        demod = fmDemod()
        demod.setup()
        audio = playAudio()
        exitp = exitProg()

        # Start Threads
        demod.start()
        audio.start()
        exitp.start()

        # Read Samples from RTL-SDR
        sdr.read_samples_async(sdrCallback, SAMPLERATE)
    
    except ValueError:
        print('ERROR')

if __name__ == '__main__':
	sys.exit(main())
      