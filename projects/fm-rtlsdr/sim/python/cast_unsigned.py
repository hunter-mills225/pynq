"""
File		: cast_unsigned.py
Author		: Hunter Mills
Date		: May 2024
Description	: Function to cast an integer in-place to its unsigned rep
"""

# Imports
import numpy as np

def cast_unsigned(signed_number:np.ndarray, num_bits:int):
    """
    Cast an integer in place to its unsigned rep
    
        Args :
            signed_number   : Array of signed numbers
            num_bit         : Number of bits in unsigned rep
        Returns :
            unsigned_val    : Array of unsigned numbers
    """
    unsigned_val = np.zeros(np.size(signed_number), dtype=np.int64)
    for index, signed_int in enumerate(signed_number):
        if signed_int < 0:
            unsigned_val[index] = ((int(2**num_bits-1)) ^ int(abs(signed_int))) + 1
        else:
            unsigned_val[index] = int(signed_int)

    return unsigned_val
