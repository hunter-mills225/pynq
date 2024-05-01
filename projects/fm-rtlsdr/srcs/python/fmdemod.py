"""
File        : fmdemod.py
Author      : Hunter Mills
Date        : April 2024
Description : Functions for FM Demodulation
References  : pysdr.org
"""

# Imports
import numpy as np
from scipy.signal import lfilter, hilbert, bilinear

def iqDemod(data:np.ndarray) -> np.ndarray:
    """
    Quadrature Demod for IQ samples

        Args :
            data    : IQ samples
        Returns:
            iqDemodData : Quadrature demodulated signal
    """
    # see https://wiki.gnuradio.org/index.php/Quadrature_Demod
    iqDemodData = .5 * np.angle(data[0:-1] * np.conj(data[1:]))
    return iqDemodData

def downsampFilter(data:np.ndarray, filt:np.ndarray, dec:int, mix:bool=False,
    mixer:np.ndarray=None) -> np.ndarray:
    """
    Downsampling filter

        Args :
            data        : Data to be decimated and filterd
            filt        : Filter taps
            dec         : Decimation rate
            mix         : Flag to use mixer
                Default : False
            mixer       : Sinusiodal signal to data with
                Default : None
        Returns :
            dsData      : Downsampled data
    """
    # Check if data needs to be mixed
    if mix:
        if mixer is None:
            raise TypeError('mixer cannot be of type None')
        data = data * mixer

    # Filtering
    filtData = lfilter(filt, 1, data)

    # Downsample
    dsData = filtData[::dec]
    return dsData

def deEmphasisFilter(data:np.ndarray, fs:int) -> np.ndarray:
    """
    De-emphasis filter for FM demodulation

        Args :
            data    : Array of processed audio data
            fs      : Sample frequency
        Returns :
            deEmphData  : De-emphasis fitlered data
    """
    # De-emphasis filter, H(s) = 1/(RC*s + 1) implemented as IIR with bilinear transform
    bz, az = bilinear(1, [75e-6, 1], fs=fs)
    deEmphData = lfilter(bz, az, data)
    return deEmphData

def processAudio(audio:np.ndarray) -> np.ndarray:
    """
    Process the FM Audio

        Args :
            audio   : Audio Signal
        Returns :
            audio   : Processes audio signal
    """
    # Remove DC
    audio = audio - np.mean(audio)

    # Scale
    audio = audio / np.max(np.abs(audio))

    # Convert to s16.15
    audio = audio * 2**15 / 2
    return audio
