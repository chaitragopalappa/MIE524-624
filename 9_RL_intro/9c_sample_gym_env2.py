# -*- coding: utf-8 -*-
"""
Created on Wed Sep 27 17:38:40 2023

@author: chaitrag
"""
'''
Some tools to keep updated 
$ conda update anaconda
$ conda update setuptools 
When installing gym packages depencies, to avoid conflicts with other packages, do not install in base environment; you can try to but may run into errors if there are conflicts in dependencies; 
So first create a new env, activate it; and then install below (see slideset 0-conda_navigation_guide to create and activate new environment, e.g.,)                                                                
$conda create --name myenv
$conda activate --name myenv“
$conda install -c conda-forge gym-box2d
If you come back to this file after closing it, first activate environment and then run this code as follows
$conda activate --name myenv“
#python sample_gym_env.py
$ Then call your python code through command prompt  

#Useful links for gym
#https://www.gymlibrary.dev/environments/box2d/
#https://www.gymlibrary.dev/environments/classic_control/
#https://www.gymlibrary.dev/api/utils/ 
#making own custom environment : https://www.gymlibrary.dev/content/environment_creation/ 
'''
import numpy as np
import gym
from gym.utils.play import play

play(gym.make("CarRacing-v2", render_mode="rgb_array"), keys_to_action={# use w,a,sd on the keyboard to move forward, left, stop, right, and the combinations to move in correposning directions 
                                                "w": np.array([0, 0.7, 0]),
                                                "a": np.array([-1, 0, 0]),
                                                "s": np.array([0, 0, 1]),
                                                "d": np.array([1, 0, 0]),
                                                "wa": np.array([-1, 0.7, 0]),
                                                "dw": np.array([1, 0.7, 0]),
                                                "ds": np.array([1, 0, 1]),
                                                "as": np.array([-1, 0, 1]),
                                              }, noop=np.array([0,0,0]))
    
