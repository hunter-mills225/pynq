#!/usr/bin/python3
"""
File		: fm_sim_iq.py
Author		: Hunter Mills
Date		: April 2024
Description	: Simple FM Demod reading from IQ file (assume 250ksps input)
"""

# Imports
import sys
import argparse
import numpy as np
import sounddevice as sd
import matplotlib.pyplot as plt
from scipy.signal import firwin
from ...srcs.python.fmdemod import *

def readIQ(filepath:str) -> np.ndarray:
	"""
	Function to read IQ file into np.ndarray

		Args :
			filepath	: Filepath to IQ file
		Returns :
			iqData		: IQ data from file in np.ndarray(complex)
	"""
	iqData = np.fromfile(filepath, dtype=np.complex64)
	return iqData

def main():
	"""
	Script to read IQ FM data file and play to computer audio
	"""
	# Read Iput args
	defaultIQpath = 'projects/fm-rtlsdr/sim/data/fm_rds_250k_1Msamples.iq'
	parser = argparse.ArgumentParser()
	parser.add_argument('-f', '--filename',
					 	help='Filename of IQ data',
						type=str,
						default=defaultIQpath,
						required=False)
	parser.add_argument('-fs', '--sampleRate',
					 	help='Sample frequency of IQ data',
						type=int,
						default=250000,
						required=False)
	parser.add_argument('-p', '--plot',
					 	help='Plotting flag',
						action='store_true',
						required=False)
	args = parser.parse_args()
	
	# Read IQ data
	iqData = readIQ(args.filename)
	if args.plot:
		plt.figure(1)
		plt.plot(np.abs(np.fft.fftshift(np.fft.fft(iqData))))
		plt.title('Raw Sample Spectrum')
		plt.show(block=False)

	# Quadrature Demod of iqData
	fmData = iqDemod(iqData)

	# Filter and decimate
	decFac	= 6
	numTaps	= 91
	cutOff	= 19000
	h 		= firwin(numTaps, cutOff, nyq=args.sampleRate)
	fmFilt	= np.real(downsampFilter(fmData, h, decFac))
	if args.plot:
		plt.figure(2)
		plt.plot(h)
		plt.title('Time Domain Downsample Filter')
		plt.show(block=False)
		plt.figure(3)
		plt.plot(fmFilt)
		plt.title('L+R Filtered FM Data')
		plt.show(block=False)

	# Scale and DC Filter
	audioData	= processAudio(fmFilt)

	# De-emphasis filter
	audioFs 	= args.sampleRate / decFac
	deEmphData	= deEmphasisFilter(audioData, audioFs)
	if args.plot:
		plt.figure(4)
		plt.plot(deEmphData)
		plt.show(block=False)

	# Play Audio
	sd.play(deEmphData.astype(np.int16), blocking=True)

	# Show all plots
	if args.plot:
		plt.show()

if __name__ == '__main__':
	sys.exit(main())
