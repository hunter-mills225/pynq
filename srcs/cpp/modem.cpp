/**************************************************************************************************
 * 
 * @file    modem.cpp
 * @author  Hunter Mills
 * @brief   Class implementation for modulation and demodulation for different constellations.
 * 
 *************************************************************************************************/

#include <iostream>
#include <complex>
#include <vector>
#include <unordered_map>
#include <cmath>
#include "modem.hh"
#include "utils.cpp"

/******************************************************************************
 * MODEM Methods
 ******************************************************************************
 *
 * MODEM modulate
 */
void modem::modulate() {
    // Step through array of bytes with bps as the step
    std::vector<uint8_t> message_bps;
    for (int i = 0; i < message.size(); i++) {
        for (int j = 0; i < 8 % bits_per_symbol; i++) {
            
        }
    }
}


/******************************************************************************
 * QAM Methods
 *****************************************************************************
 *
 * QAM constructor
 * @param bps : Bits per symbol.
 */
qam::qam(int bps) {
    // Input checking
    if (bps & 2 != 0) {
        std::cout << "ERROR : QAM Constructor, n is not a valid." << std::endl;
    }

    // Local parameters
    int m = pow(2, bps);
    std::unordered_map<int, std::complex<double>> constel;
    std::vector<double> n = linspace(-sqrt(2)/2, sqrt(2)/2, m);

    // Create constellation
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < m; j++) {
            std::complex<double> const_point(n[i], n[j]);
            int idx = m+j;
            constel.insert({idx, const_point});
        }
    }

    // Set the constellation in modem parent class
    set_const(constel);
    set_bps(bps);
}

/******************************************************************************
 * PSK Methods
 *****************************************************************************
 *
 * PSK constructor
 * @param bps : Bits per symbol.
 */
psk::psk(int bps) {
    // Local parameters
    std::unordered_map<int, std::complex<double>> constel;

    // Create constellation
    if (bps == 1) {
        std::complex<double> const_point(-1, 0);
        constel.insert({0, const_point});
        std::complex<double> const_point(1, 0);
        constel.insert({1, const_point});
    }
    else {
        std::vector<double> n = arange(0, 2*M_PI, 2*M_PI/pow(2, bps));
        for (int i = 0; i < pow(2, bps); i++) {
            std::complex<double> const_point = std::exp(n[i]);
            constel.insert({i, const_point});
        }
    }

    // Set the constellation in modem parent class
    set_const(constel);
    set_bps(bps);
}