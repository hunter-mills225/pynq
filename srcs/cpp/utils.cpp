/**************************************************************************************************
 * 
 * @file    utils.cpp
 * @author  Hunter Mills
 * @brief   Utility functions used for PYNQ projects.
 * 
 *************************************************************************************************/

#include <iostream>
#include <vector>

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