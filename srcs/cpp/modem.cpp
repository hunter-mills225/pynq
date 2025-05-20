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
 * MODEM modulate, bytes -> symbols.
 */
void modem::modulate() {
    // Local variables
    uint8_t mask = pow(2, bits_per_symbol)-1;
    uint8_t masked_data;
    uint8_t shift_value;

    // Step through array of bytes with bps as the step
    std::vector<uint8_t> message_bps;
    if (8 % bits_per_symbol == int(8 % bits_per_symbol)) {
        for (int i = 0; i < message.size(); i++) {
            for (int j = 0; i < 8 % bits_per_symbol; i++) {
                shift_value = 8 - bits_per_symbol*(i+1);
                masked_data = message[i] & (mask << (shift_value)) >> shift_value;
                message_bps.push_back(masked_data);
            }
        }
    }
    else {
        std::cout << "Modulation for bits_per_symbol that are not a factor of 8 ";
        std::cout << "are not yet implemented." << std::endl;
    }

    // Modulate using constellation
    for (int i = 0; i < message_bps.size(); i++) {
        symbols.push_back(cosnstellation[message_bps[i]]);
    }
}

/**
* MODEM demodulate, symbols -> bytes.
*/
void modem::demod() {
   std::cout << "MODEM demod has not yet been implemented." << std::endl;
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
    if (bps % 2 != 0 || bps > 8) {
        std::cout << "ERROR : QAM Constructor, n is not a valid." << std::endl;
    }

    // Local parameters
    int m = pow(2, bps);
    std::unordered_map<int, std::complex<double>> constel;
    std::vector<double> n = linspace(-sqrt(2)/2, sqrt(2)/2, m);
    std::vector<int> gray_code = gen_gray_code(bps);
    int idx = 0;

    // Create constellation
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < m; j++) {
            std::complex<double> const_point(n[i], n[j]);
            idx = gray_code[i+j];
            constel.insert({idx, const_point});
        }
    }

    // Set the constellation in modem parent class
    set_const(constel);
    set_bps(bps);
}

/**
 * QAM print_const
 * Function to print the constellation to std_out.
 */
void qam::print_const() {
    for (int i = 0; i < modem::bits_per_symbol; i++) {
        std::cout << modem::cosnstellation[i] << "\t" << modem::cosnstellation[i] << "\t";
        std::cout << modem::cosnstellation[i] << "\t" << modem::cosnstellation[i] << std::endl;
    }
}

/******************************************************************************
 * PSK Methods
 *****************************************************************************
 *
 * PSK constructor
 * @param bps : Bits per symbol.
 */
psk::psk(int bps) {
    // Input checking
    int valid = 0;
    for (int i = 0; i < valid_bps.size(); i++) {
        if (bps == valid_bps[i]) {
            valid = 1;
        }
    }

    if (valid) {
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
    else {
        std::cout << "ERROR : PSK constructor, bps is not valid." << std::endl;
    }
}