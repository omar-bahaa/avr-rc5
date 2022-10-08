# avr-rc5

Author: Omar Bahaa

E-mail: omar.bahaa@ejust.edu.eg


Project part of CSE324 Embedded systems course at Egypt-Japan University of Science and Technology

This project contains one assembly file containing avr assembly code for rc5 key expansion, encryption, and decryption.

RC5 algorithm description:

1. number of rounds (r) = 8
1. size of expanded key table (t = 2 * (r + 1) = 18)
1. the word size in bits (w) equals 16
1. the word size in bytes (u = w /8) equals 2
1. the number of bytes in the secrete key (b) equals 12
1. the number of words in the secrete key (c = ceil(b/u)) equals 6
1. the number of iterations of the key-expansion module (n = 3*max(t, c)) equals 54
1. the constant P16 used in the key-expansion module equals (b7e1)16 or (1011011111100001)2, where Pw = Odd((e – 2)*2w and e = 2.718281828459
1. the constant Q16 used in the key-expansion module equals (9e37)16 or (1001111000110111)2, where Qw = Odd(( – 1)*2w and phi = 1.618033988749.
