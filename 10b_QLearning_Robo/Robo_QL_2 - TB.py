# -*- coding: utf-8 -*-
"""
Created on Sat Sep 16 21:45:36 2023

@author: chaitrag
"""

import numpy as np
from tensorboardX import SummaryWriter

class Environment:
    def __init__(self, num_states, num_actions):
        self.num_states = num_states
        self.num_actions = num_actions  # 4 possible actions (up, down, left, right)
        self.state =np.random.choice(self.num_states)
        
    def step(self, action): #Take action and transition one-step; return next-state, reward, and termination criteria
        self.state =np.random.choice(self.num_states)#replace with simulation update to determine state it transitions to next if action=action
        reward = 1000 #replace with reward function
        if self.state == self.num_states - 1:#is terminating state? Change as needed for application
            done = True
        else:
            done = False
        return self.state, reward, done
    def reset(self):
       self.state = 0 #reset environment to starting state; As example setting state=0 as starting state
       return self.state
    
class QLearning:
    def __init__(self, num_states, num_actions, learning_rate=0.1, discount_factor=0.9, exploration_prob=0.1):
        self.num_states = num_states
        self.num_actions = num_actions
        self.learning_rate = learning_rate
        self.discount_factor = discount_factor
        self.exploration_prob = exploration_prob
        self.q_table = np.zeros((num_states, num_actions))#initialize q-values 

    def choose_action(self, state):
        if np.random.rand() < self.exploration_prob:
            return np.random.choice(self.num_actions)  # Exploration
        else:
            return np.argmax(self.q_table[state])  # Exploitation

    def update_q_table(self, state, action, next_state, reward):
        best_next_action = np.argmax(self.q_table[next_state, :])
        self.q_table[state, action] += self.learning_rate * (reward + self.discount_factor * self.q_table[next_state, best_next_action] - self.q_table[state, action])
     
    def update_rates(self, iteration):
        self.exploration_prob = 1 / iteration

def main():
   #Dummy code for testing; Agent is created in Netlogo (see netlogo code Robo_QL)
    env = Environment(5,5)
    ql_agent = QLearning(env.num_states, env.num_actions)
    writer = SummaryWriter(comment="-q-learning_robo")

    NUM_EPISODES = 10
    EPISODE_LENGTH = 10
    for episode in range(NUM_EPISODES):
        state = env.reset()
        iteration =0
        total_reward=0
        while iteration < EPISODE_LENGTH:
            
            action = ql_agent.choose_action(state)#choose action using epsilon greedy; we can also send epsilon value here if updated every iteration
            next_state, reward, done = env.step(action)#step through one step of environment
            
            ql_agent.update_q_table(state, action, next_state, reward)#update Q-factors
            total_reward += reward #track total reward
            if done:
                break
            state = next_state
            iteration+=1
        
        writer.add_scalar("reward", total_reward, episode) 
       
    print(ql_agent.q_table)
    policy= np.zeros((env.num_states,1))
    for i in range(env.num_states):
        policy[i] = np.argmax(ql_agent.q_table[i, :])
        writer.add_scalar("policy", policy[i], i)
    print("optimal policy:", policy)
    writer.close()
   
if __name__ == "__main__":
    main()
