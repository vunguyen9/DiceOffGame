# DiceOffGame

In this game the player will see a grid of dice with the number 1. When they select any dice it add 1 to the value on the dice,
until that number exceeds the number of neighbors the dice has. When that happens, the dice will split: it will reset its
value to 1, but will add 1 to each of its neighbors. This means corner dice will split when they reach 3, edge dice will split
when they reach 4, and all other pieces will split when they reach 5.
