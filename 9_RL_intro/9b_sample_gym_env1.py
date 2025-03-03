# -*- coding: utf-8 -*-
"""
Created on Wed Sep 27 17:38:40 2023

@author: chaitrag
"""
'''
Some tools to keep updated 
$ conda update anaconda
$ conda update setuptools 
When installing gym package dependencies, to avoid conflicts with other packages, do not install in base environment; you can try to but may run into errors if there are conflicts in dependencies; 
So first create a new env, activate it; and then install below (see slideset 0-conda_navigation_guide to create and activate new environment, e.g.,)                                                                
$conda create --name myenv
$conda activate --name myenv“
$conda install -c conda-forge gym-box2d
If you come back to this file after closing it, first activate environment and then run this code as follows
$conda activate --name myenv“
#python sample_gym_env.py
$ Then call your python code through command prompt  
$ Useful links for gym
#https://www.gymlibrary.dev/environments/box2d/
#https://www.gymlibrary.dev/environments/classic_control/
#https://www.gymlibrary.dev/api/utils/ 
#making own custom environment : https://www.gymlibrary.dev/content/environment_creation/ 
'''

    
import gym
from gym.utils.play import play
import numpy as np

ENV_NAME_1 = "LunarLander-v2"
ENV_NAME_2= "CartPole-v1"
ENV_NAME_3 = "MountainCar-v0"
ENV_NAME_4 = "FrozenLake-v1"

env =gym.make(ENV_NAME_4, render_mode="human")#render_mode is how to display/vizualize the environments 

observation, info = env.reset(seed=42)
env.action_space.seed(42)#fixes the random seed for the action; during the learning phase there is a probability of exploration v exploitation
                        #useful for experimental analyses, e.g., when evaluating different rewards, we do not want the random value to create differnces in results

for _ in range(1000):
    action = env.action_space.sample() # take a random action 
    
    #action = policy(observation)  # User-defined policy function; this is where we can replace with a RL model
    observation, reward, terminated, truncated, info = env.step(action)
    #observation, reward, terminated, truncated, info = env.step(env.action_space.sample())

    if terminated or truncated:
      observation, info = env.reset()
env.close()

