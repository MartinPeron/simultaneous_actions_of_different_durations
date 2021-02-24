License Agreement:
Copyright (c) 2016, Queensland University of Technology / Commonwealth Scientific and Industrial Research Organisation.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
- Neither the name of the Queensland University of Technology nor of the Commonwealth Scientific and Industrial Research Organisation may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This is the MATLAB code used for the paper "Selecting simultaneous actions of different durations to optimally manage an ecological network" (rev) Martin Péron, Cassie C. Jansen, Chrystal Mantyka-Pringle, Sam Nicol, Nancy A. Schellhorn, Kai H. Becker and Iadine Chadès. 
This program seeks to calculate the optimal management policy against invasive mosquitoes in the Torres Strait islands, which involves simultaneous actions of different durations. It calculates an exact model and two bound models with synchronised actions. 
Please email martin.peron(at)laposte.net for any enquiry.
 
Installation instructions: 
1) Extract the archive file “Simultaneous actions.rar” into a suitable directory. This will create a new directory “Simultaneous actions/” containing 17 files.
2) Make sure your MATLAB working directory is “Simultaneous actions/”.
3) Our program uses the MDPSOLVE MATLAB package. MDPSOLVE can be downloaded from P. Fackler’s website https://sites.google.com/site/mdpsolve/download. Extract MDPSOLVE.rar, and add the MDPSOLVE directory (with subfolders) to the MATLAB path:
 >> addpath(genpath('C:/xxxx/MDPSOLVE'))
4) Run the function simultaneous_actions, for example "simultaneous_actions(3,0)".

The first parameter is the maximum number of islands that the user wishes to solve (1-12). The second parameter describes the speed of transmission: high (0) or low (1). 
Other parameters such as the durations of each of the three sub-actions can be modified (1, 6, and 6 time steps by default) by manually changing their values in the program simultaneous_actions.m. 

- The output shows the progress of the program regarding generating and solving the MDPs 
- The code has been run on MATLAB R2016a and MATLAB 2012a successfully.
- The input file IslandData.mat contains information about the islands and the effectiveness of actions which is automatically read by our program. 
- The Markov decision process corresponding to the exact model is generated in "generate_exact_model.m". The Markov decision processes corresponding to the upper and lower bound models are generated in "generate_bound_model.m". 
- The program could solve other problems with simultaneous actions of different durations, by modifying the files in which the transition matrices are generated ("generate_exact_model.m" and "generate_bound_model.m").
 
 
 
 
 


