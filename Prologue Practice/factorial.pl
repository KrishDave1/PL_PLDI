# factorial(0,1).

# factorial(N, X):- N > 0, N1 is N - 1, factorial(N1, X1), X is N * X1.
fact(1, 1).
fact(N, F):- fact(N1, F1), N is N1 + 1, F is F1 * N.