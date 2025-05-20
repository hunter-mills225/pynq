/**************************************************************************************************
 * 
 * @file    modem.hh
 * @author  Hunter Mills
 * @brief   Class header for modulation and demodulation for different constellations.
 * 
 *************************************************************************************************/

#include <iostream>
#include <complex>
#include <vector>
#include <unordered_map>

class modem {
    public:
        int bits_per_symbol;
        std::unordered_map<int, std::complex<double>> cosnstellation;
        std::vector<uint8_t> message;
        std::vector<std::complex<double>> symbols;
        std::vector<uint8_t> message_bytes;
        std::vector<uint8_t> demod_bytes;
    public:
        modem() = default;
        void set_const(std::unordered_map<int, std::complex<double>> c) {cosnstellation = c;}
        void set_message(std::vector<uint8_t> m) {message = m;}
        void set_bps(int bps) {bits_per_symbol = bps;}
        void modulate();
        void demod();
};

class psk : public modem {
    private:
        std::vector<int> valid_bps = {1, 2, 3, 4};
    public:
        psk(int bits_per_symbol);
};

class qam : public modem {
    public:
        qam(int bits_per_symbol);
        void print_const();
};