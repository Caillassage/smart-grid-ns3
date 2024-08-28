#include <iostream>
#include <cstdlib> // For system()
#include <fstream>

int main(int argc, char *argv[]) {
    std::cout << "Running ns-3 simulation with Julia integration..." << std::endl;

    int variable = 42; // The variable you want to pass to Julia
    //std::string command = "julia script.jl " + std::to_string(variable);

    // Define the command to run the Julia script
    std::string juliaCommand = "julia Server.jl " + std::to_string(variable) + " " + std::to_string(variable+1) + " > output.txt";

    // Run the Julia script
    int result = std::system(juliaCommand.c_str());
    if (result != 0) {
        std::cerr << "Error running Julia script!" << std::endl;
        return 1;
    }

    // Optionally read the output from the file
    std::ifstream outputFile("output.txt");
    std::string line;
    while (std::getline(outputFile, line)) {
        std::cout << line << std::endl; // Print each line from the Julia script's output
    }
    outputFile.close();

    std::cout << "ns-3 simulation and Julia integration completed." << std::endl;
    return 0;
}