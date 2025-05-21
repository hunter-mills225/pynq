/**************************************************************************************************
 * 
 * @file    utils.cpp
 * @author  Hunter Mills
 * @brief   Utility functions used for PYNQ projects.
 * 
 *************************************************************************************************/

#include <iostream>
#include <vector>
#include <cmath>
#include <string>

/**
 * Function : linspace
 * Details  : Create n equally spaced values beginning at start and ending at end.
 */
std::vector<double> linspace(double start, double end, int n) {
    std::vector<double> result;
    if (n <= 0) {
        std::cout << "ERROR : Linspace, n == 0" << std::endl;
        return result; // Return empty vector for invalid input
    }
    if (n == 1) {
        result.push_back(start);
        return result;
    }

    double delta = (end - start) / (n - 1);
    for (int i = 0; i < n; ++i) {
        result.push_back(start + i * delta);
    }
    return result;
}

/**
 * Function : arange
 * Details  : Create a vector from start to stop with a step of step.
 */
std::vector<double> arange(double start, double stop, double step) {
    std::vector<double> values;
    for (double value = start; value < stop; value += step)
        values.push_back(value);
    return values;
}

/**
 * Function : gen_gray_code
 * Details  : Generate a gray coded constellation.
 */
std::vector<int> gen_gray_code(int n) {
    // Local variables
    std::vector<int> temp_code;
    std::vector<int> gray_code;
    int i = 0;
    int j = 0;

    // Base case
    if (n <= 0)
        return gray_code;

    // str_arr will store all generated codes
    std::vector<std::string> str_arr;

    // Start with one-bit pattern
    str_arr.push_back("0");
    str_arr.push_back("1");

    // Every iteration of this loop generates 2*i codes from previously generated i codes.
    for (i = 2; i < (1<<n); i = i<<1) {
        // Enter the previously generated codes again in arr[] in reverse
        // order. Nor arr[] has double number of codes.
        for (j = i-1 ; j >= 0 ; j--)
            str_arr.push_back(str_arr[j]);

        // append 0 to the first half
        for (j = 0 ; j < i ; j++)
            str_arr[j] = "0" + str_arr[j];

        // append 1 to the second half
        for (j = i ; j < 2*i ; j++)
            str_arr[j] = "1" + str_arr[j];
    }

    // Create constellation
    for (int i = 0; i < str_arr.size(); i++) {
        temp_code.push_back(std::stoi(str_arr[i], nullptr, 2));
    }

    // Swap the indexes of odd rows
    for (int i = 0; i < n; i++) {
        if (i % 2 == 0) {
            for (int j = 0; j < n; j++) {
                gray_code.push_back(temp_code[i*n + j]);
            }
        }
        else {
            for (int j = 0; j < n; j++) {
                gray_code.push_back(temp_code[(i+1)*n - j - 1]);
            }
        }
    }
    return gray_code;
}
