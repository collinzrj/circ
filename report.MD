## Background
[CirC](https://github.com/circify/circ) is a compiler that compiles high level languages {C, ZoKrates, Circom} to (state-free, non-uniform, existentially quantified) circuits {SMT, ILP, R1CS, MPC} for SMT solver, zero-knowledge proof, multiparty computations, and more. To be more specific, it converts a program's source code into a set of mathematical constraints represented by vectors of variables. Optimization of such compilers primarily focus on reducing the size of the constraint system: having fewer constraints reduces the workload for creating proofs, and might also result in shorter proofs to verify. The typical formalism adopted by the majority of proof systems is rank-1 constraint system (R1CS). In an R1CS instance C, there exists a collection of constraints over a finite field F, often a prime p, or in other words, a circuit of additions and multiplications gates mod p. One significant cost of such system is introduced by arithmetic operations. Assume an underlying prime number p and operations such as multiplication done over p′, to obtain a correct result, a remainder operation is always applied on the result to adjust bitwidth and avoid overflow, which leads to a number of constraints that are at least equal to the bitwidth of the result, as it requires at least one split gate. Our project aims to apply a heuristic approach to optimize the translation of arithmetic operations. 

## Design
Our optimization mainly focuses on addition and multiplication, which would typically increase the bitwidth of resulting element by 1 or double the bitwidth, respectively. We classify elements into two types
- Elements that could be above the range and required to be returned within range: this includes program output, elements involved in bitwise operations and comparisons, operations like division or remainder, elements involved in memory operations, and so on.
- Elements that could be above the range but are not required to be within range: This includes intermediate elements that undergoes multiplication and addition operations and does not meet any of the criterions above.

The current system represents basic elements as bitvectors, and is designed to adjust their bitwidth after each arithmetic operation. Based on the classification of the elements above, our projects reduces the number of constraints in the system by greedily deciding when to adjust bitwidth for elements falls under the second category while ensuring no overflows can happen in later operations involving the elements. Or in other words, adjustments are only introduced if the next operation is going to result in an overflow.

Take this short program as an example:
'''
def main(u32 a, u32 b) -> u32:
    u32 c = a + b
    u32 d = a + c
    return c * d
'''
The old compiler would adjust immediately at a+b and a+c. By applying our optimization, the system would treat c and d as intermediate elements and only adjust at c*d, since it is producing the final program output.

## Implementation
1. We create a new type of operations: add_unadjust and mul_unadjust for addition and multiplication to minimize change introduced to the old system.
2. We implemented two passes to rewrite the operations. First pass is to classify elements in the system. We implemented an initial pass to scan the entire program and store elements requiring adjustments in a set S. Whenever we encounter an operation that definitely requires adjustment, we add the elements used in the operation to S. Then we implemented a rewrite pass to rewrite operations done on bitvectors not included in D to our newly introduced unadjust operation. 
3. During compile time, we would first compare the bitwidth of the resulting operation with the width of prime field to check if it would result in overflow, and adjust accordingly. If the operation is unadjust, we would not apply bitwidth adjustment in the end of operation.
## What were the hardest parts to get right
## Empirical evaluation
We uses two types of tests. 
1. We use the existing benchmarks in the circ repo to test whether the output of the optimized compiler is correct. When applying our compiler in the existing test suite, it generates correct R1CS constraints, which is used to generate correct proofs and is verified successfully.
2. To measure how well the proposed design improves the system, we use the number of r1cs constraints generated as the metrics. We runs our compiler and the original one over a set of zokrates programs in [CirC](https://github.com/circify/circ) and [Zombie](https://github.com/PepperSieve/Zombie/tree/master) and compares the number of constraints generated. Here is a shorted list of tests we run.
```
../Zombie/circ/zkmb/shaRound.zok
27172, 27137
29092, 29057
../Zombie/circ/zkmb/DotChaChaAmortized_Isolated.zok
23908, 23366
43100, 41835
../Zombie/circ/zkmb/DotChaChaAmortized.zok
112369, 111529
131557, 130232
../Zombie/circ/zkmb/tls_key_schedules/HKDF.zok
101350, 101304
109233, 109187
../Zombie/circ/zkmb/SHA.zok
26612, 26581
28537, 28505
../Zombie/circ/zkmb/DotChaChaAmortizedUnpack.zok
32466, 31422
51658, 50105
```