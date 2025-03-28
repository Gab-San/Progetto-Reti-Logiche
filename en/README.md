# Digital Logic Design Project

The digital logic design project is the second of the three compulsory projects required for Polimi's bachelor degree in computer science.

The project consists in modelling a circuit, using a hardware description language, that adheres to the requirements.
Since VHDL was chosen as hardware description language, the choice to use a behavioural or architectural abstraction level was left to the student.

## Project requirements

The project component communicates with a memory from which it receives a sequence of K _words_. The sequence is then processed by writing to memory after every _word_ the associated credibilità value: it counts the number of subsequent occurrences of the same _word_, starting at 31 counting down to 0 (when at 0 remains 0).

![generic interface](./images/General_Schematic)

A detailed report of the requirements is [here]()

## Component's description

![whole component](./images/Project_Schematic)

The component is designed in 4 modules:

- a _credibilità_ counter;
- a counter to track the sequence's index;
- a counter to track the address;
- a module to handle _words_.

These four modules work in parallel with intermodule signals that allow for the correct read and write of the registers.

The detailed description of the components is [here]()

### The code

The code was requested in only one file. Thus modules' code is included in the file in _src_.

> The code was divided with comments in the various modules, for better clarity.
