> Here reporting only the general description of the requirements.

---

# Digital Logic Design Project

<div align="center">
    Prof. Fornaciari, Prof. Palermo and Prof. Salice<br>
    AA 2023-2024
</div>

## General Description

The specification of _"Prova Finale (Progetto di Reti Logiche)"_ for the Academic Year 2023/2024 demands the implementation of an HW module (described in VHDL) interfacing with a memory and complying with the following specification.

The system reads a message comprised of a sequence of K words W, the value of which is between 0 and 255.
The value 0 inside of a sequence must be considered not as a value but as "_the value is not specified_". The sequence of K words W to process is stored in memory starting from a specified memory address (ADD), every 2 byte (e.g. ADD, ADD+2, ADD+4, ..., ADD+2*(K-1)).
The missing byte has to be completed as specified next. The designed module has to complete the sequence, substituing zeroes where present with the last read value other than zero, and inserting a _credibilità_ (credibility) value C, in the missing byte, for each value of the sequence.
The substitution of zeros is done by copying the last valid value (non-zero) previously read in the elaborated sequence.
The credibility value C is equal to 31 for each W not equal to zero, while it is decremented from the previous value every time W is equal to zero. The value C associated to each W word is stored in memory into the subsequent byte (i.e. ADD+1 for W in ADD, ADD+3 for W in ADD+2, ...).
The value C is always greater then or equal to 0 and is reinitialized to 31 each time a value of W other than zero is read. When C reaches a value of 0, it is not decremented any further.

### EXAMPLE
Starting sequence (W values in bold):
**128** 0 **64** 0 **0** 0 **0** 0 **0** 0 **0** 0 **0** 0 **100** 0 **1** 0 **0** 0 **5** 0 **23** 0 **200** 0 **0** 0

Final sequence:
**128** 31 **64** 31 **64** 30 **64** 29 **64** 28 **64** 27 **64** 26 **100** 31 **1** 31 **1** 30 **5** 31 **23** 31 **200** 31 **200** 30

> The functionality of the component as well as the interface is described in the [report](./Digital_Logic_Design_Report.pdf)
