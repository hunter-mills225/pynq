/**
@filename   modem_unittest.cpp
@author     Hunter Mills
@brief      Unit test for modem.
**/
#include <complex>
#include <vector>
#include "../modem.cpp"
#include "catch2/catch_test_macros.hpp"

#define CONFIG_CATCH_MAIN
#include "catch2/catch_all.hpp"

// Test symbols for modulation
std::complex<double> s0(.707, .707);
std::complex<double> s1(.707, -.707);
std::complex<double> s2(-.707, .707);
std::complex<double> s3(-.707, -.707);
std::complex<double> testSym[12] = {s3, s3, s3, s3, s2, s2, s1, s1, s1, s1, s0, s0};
std::complex<double> testSym1[8] = {s0, s1, s2, s3, s3, s2, s1, s0};
std::complex<double> fullTestSym[24] = {s3, s3, s3, s3, s2, s2, s1, s1, s1, s1, s0,s0,
                                        s1, s1, s0, s0, s2, s2, s1, s1, s3, s3, s3, s3};

// Generate gray code
std::vector<int> gray_code = gen_gray_code(4);

TEST_CASE("Modulator", "[modulator]"){
    // Init QPSK Object
    std::vector<uint8_t> testBytes;
    testBytes.push_back(0xff);
    testBytes.push_back(0xa5);
    testBytes.push_back(0x50);
    qam qam_modem = qam(4);
    qam_modem.set_message(testBytes);
    qam_modem.modulate();

    // Get constellation
    std::unordered_map<int, std::complex<double> > cosnstellation = qam_modem.cosnstellation;
    std::vector<int> correct_symbols = {0xf, 0xf, 0xa, 0x5, 0x5, 0x0};

    for (int i = 0; i < correct_symbols.size(); i++) {
        REQUIRE(cosnstellation[correct_symbols[i]] == qam_modem.symbols[i]);    // Test generated symbols
    }
}


