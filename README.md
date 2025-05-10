# (A)MAZE Visualizer
A maze visualizer built for Brown University's CSCI 0190: Accelerated Introduction to Computer Science (taken Fall 2023). The visualizer was made in [Pyret](https://pyret.org/index.html), which is a [functional](https://en.wikipedia.org/wiki/Functional_programming) programming language used in education. Pyret is probably most similar to Racket. We were allowed to come up with any project, so I wanted to make a visualizer that could hopefully serve as an educational tool to understand graph traversals.

## Setup
Copy the code into the [Pyret Editor](https://code.pyret.org/editor) and click run.

## Algorithms

The visualizer includes both depth-first and breadth-first traversals. Some algorithms that it uses include:
- Depth-First-Search
- Breadth-First-Search
- Disjoint-Set Union
- Union Find
- Kruskal's Random Minimum Spanning Tree for Perfect Maze Generation
- Random Walk for Maze Generation

## Features
- Visualize two types of traversals
- Perfect (fully connected) maze generation
- Randomly remove walls using Random Walk
- "Step" back and forth through the different stages of both the traversals & generations
- Maze editing
- Undo any number of edits
- Change maze size
- Change animation speed

## Controls
See the comment at the top of the .arr file.
