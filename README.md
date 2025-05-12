# (A)MAZE Interactive Visualizer
A maze visualizer built for the Accelerated Introduction to Computer Science course I took during my first semester at Brown. The interactive visualizer was made in [Pyret](https://pyret.org/index.html), which is a [functional](https://en.wikipedia.org/wiki/Functional_programming) programming language used in education. Pyret is most similar to Racket and originally started as a ```#lang``` in Racket. For this project we were allowed to make anything, so I wanted to make an interactive visualizer that could hopefully serve as an educational tool to understand graph traversals.

## Setup
Copy the code into the [Pyret Editor](https://code.pyret.org/editor) and click run.

## Algorithms

The interactive visualizer includes both depth-first and breadth-first traversals. Some algorithms that it uses include:
- Depth-First-Search
- Breadth-First-Search
- Disjoint-Set Union
- Union Find
- Kruskal's Random Minimum Spanning Tree for Perfect Maze Generation
- Random Walk for Maze Generation

## Features
- Visualize two types of traversals
- Perfect (fully connected) maze generation with minimum removals
- Randomly remove walls using Random Walk
- "Step" back and forth through the different stages of both the traversals & generations
- Maze editing
- Undo any number of edits
- Change maze size
- Change animation speed

## Controls
See the comment at the top of the .arr file.
