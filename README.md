A program which learns a basic strategy for Blackjack, implemented using CUDA.

Requires compute capability >= 3.5 as it uses recursion to build trees on the GPU.

Each thread iterates one hand of Blackjack.

Learning is accomplished using the Sarsa algorithm and Temporal Difference Learning.
