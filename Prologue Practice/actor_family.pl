% 1-ary predicates
kapoor(prithvi).
kapoor(raj).
kapoor(shammi).
kapoor(shashi).
kapoor(randhir).
kapoor(rishi).
kapoor(rajeev).
kapoor(ranbir).

































%n-ary predicates
father(prithvi, raj).
father(prithvi, shammi).
father(prithvi, shashi).
father(raj, randhir).
father(raj, rishi).
father(raj, rajeev).
father(rishi, ranbir).
father(dhirubhai, mukesh).
father(dhirubhai, anil).









































% Rules
% for all X, Y, there exists Z such that !(X=Y) and Z is father of X and 
% Z is father of Y implies X and Y are siblings 
sibling(X, Y) :- father(Z, X), father(Z, Y), X \= Y.




















































% Recursive rule
descendent(X, Y) :- father(Y, X).
descendent(X, Y) :- father(Z, X), descendent(Z, Y).
