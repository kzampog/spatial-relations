# spatial-relations
Direct grounding of spatial relations that correspond to most commonly used in language spatial prepositions and abstract action representations based on the temporal evolution of object-wise spatial relations.

#### Usage
See `Spatial Relations/demo.m` for quick examples on how to compute PVS-based action descriptors given tracked object point clouds and how to compare action descriptors.

#### Dependencies
Computing distances between PVS-based action descriptors is formulated as a MIQP (Mixed-Integer Quadratic Program) and the current implementation (`compareActions.m`) relies on [OPTI Toolbox](http://www.i2c2.aut.ac.nz/Wiki/OPTI/index.php) (SCIP solver). Switching to another MIQP solver should not be difficult (the laborious part of building the objective/constraint matrices is done).

#### Project homepage  
http://www.cs.umd.edu/~kzampog/research.html#spatial_relations

#### References
This is the original implementation for the work introduced in the *ICRA 2015* paper:  
_**Learning the Spatial Semantics of Manipulation Actions through Preposition Grounding**_ [[pdf](http://www.cs.umd.edu/%7Ekzampog/papers/ICRA2015_spatial_relations.pdf)]  
Konstantinos Zampogiannis, Yezhou Yang, Cornelia Fermüller, Yiannis Aloimonos
