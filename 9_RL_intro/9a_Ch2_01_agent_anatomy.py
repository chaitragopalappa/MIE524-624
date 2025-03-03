#USE THIS CODE FOR 2 PURPOSES
#..1.....# INTRO TO OBJECT ORIENTED PROGRAMMING: understand  'class' 'object of a class';
#..2.....# INTRO TO RL - agent anatomy (Source: Deep reinforcement learning Hands-on, by Maxim Lapan https://github.com/packtpublishing/deep-reinforcement-learning-hands-on)
import random
from typing import List
#chnage code such that value of reward = 0 if action =0, 1 if action = 1; and verify if results are correct (increase steps_left to large number
#;then check  rewards ~ Steps_left / 2)
class Environment:
    def __init__(self): #initialize all paramters of the class
        self.steps_left = 100000
    #class can have multiple functions 
    def get_observation(self) -> List[float]:
        return [0.0, 0.0, 0.0]
    def get_actions(self) -> List[int]:
        return [0, 1]
    def is_done(self) -> bool:
        return self.steps_left == 0#returns 1 if steps_left = 0
    def action(self, action: int) -> float:
        if self.is_done():
            raise Exception("Game is over")
        self.steps_left -= 1
        if action == 0:
            val = 0
        else:
            val = 1
        return val
class Agent:
    def __init__(self):
        self.total_reward = 0.0
    def step(self, env: Environment):
        current_obs = env.get_observation()
        actions = env.get_actions()
        reward = env.action(random.choice(actions))
        self.total_reward += reward
if __name__ == "__main__":#this will be called if running this as main script; if instead this module is called from a differnt script this part will not be run
    env = Environment() #'object of a class'
    agent = Agent()#'object of a class'
    while not env.is_done():
        agent.step(env)

    print("Total reward got: %.4f" % agent.total_reward)
