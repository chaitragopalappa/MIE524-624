This folder has two files

To run the model run the Netlogo model. The .py file serves as a good template for writing your own environment, and for QL
1. Robo_QL.py
	Uses Q-learning. The environment is  in the Netlogo model. 
	If you run this .py file directly, it would assign random rewards and state transitions. 

2. Robo_QL.netlogo
	This is an example of an environment for training a RL algorithm. The environment here is a simulation. Unlike in DP, here we do not have a model (TPM, and TRM), 
	but we have a simulation model. Note: You can write your simulation in Python itself. Here I am using netlogo as an alternative. 
	We can also use inbuilt environments from libraries such as gym. Or cretae your own environment using gym
	This code currently sends the 'state' of the robo to python, and python sends back what 'action' to take 
	(this is repeated for every step, here every step is every move of the robo)
		
	State: 
	;;; Each possible state is encoded as an integer from 0 to 242 and then used as an index
	;;; into a strategy (which is a 243-element list).  Here's how the encoding works.  There
	;;; are five patches Robby can sense.  Each patch can be in one of three states, which
	;;; we encode as 0 (empty), 1 (can), and 2 (wall).  Putting the five states in an arbitrary
	;;; order (N, E, S, W, patch-here), we get a five digit number, for example 10220 (can
	;;; to the north, walls to the south and west, nothing to the east and here).  Then we
	;;; interpret this number in base 3, where the first digit is the 81s place,
	;;; the second digit is the 27s place, the third is the 9s place, the fourth is the 3s place,
	;;; and the fifth is the 1s place.  For speed, we do this math using a compact series of
	;;; nested IFELSE-VALUE expressions.

	Action:
	1 [move-north]
	2 [move-east] 
	3 [move-south]
	4 [move-west]
	5 [move-random]
	6 [stay-put]
	7 [pick-up-can]

	But note: the Python is set to use QL as solution algorithm
	 