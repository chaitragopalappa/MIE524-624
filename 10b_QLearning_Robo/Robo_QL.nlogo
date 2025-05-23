extensions [ py ]
;; Each candidate strategy is represented by one individual.
;; These individuals don't appear in the view; they are an invisible source
;; of strategies for Robby to use.
breed [individuals individual]

;; This is Robby.
;; Instead of making a separate variable to keep his current score in, we just
;; use the built-in variable "label", so we can see his score as he moves around.
breed [robots robot]
robots-own [strategy]

breed [cans can]

globals [
  reward
  ;total_reward
  num_states
  num_actions
  ;can-density
  can-reward
  wall-penalty
  pick-up-penalty
  step-counter ;; used for keeping track of Robby's movements in the trial
  visuals?     ;; only true when the set up environment button (SETUP-VISUALS procedure) is called. During the regular GA runs we
               ;; skimp on visuals to get greater speed.
]

;;; setup procedures


to setup
  clear-all
  reset-ticks
  ask patches [set pcolor white]
  set visuals? false
  initialize-globals
  set-default-shape robots "Wall-e"
  set-default-shape cans "dot"
  set-default-shape individuals "person"
  set num_states 243
  set num_actions 7
  plot-pen-up
  ; plots are initialized to begin at an x-value of 0, this moves the plot-pen to
  ; the point (-1,0) so that best-fitness for generation 0 will be drawn at x = 0
  plotxy -1 0

  plot-pen-down
  setup-robot-visuals
  setup-python-environment

end
to setup-python-environment
  py:setup py:python
  py:run "import Robo_QL_2 as q"
  py:set "num_actions" num_actions
  py:set "num_states" num_states
  py:run "env = q.Environment(num_states,num_actions)"; #'object of a class'
  ;py:run "agent = q.Agent()";#'object of a class'
  py:run "ql_agent = q.QLearning(env.num_states, env.num_actions)"
end

to initialize-globals
  ;set can-density 0.5
  set wall-penalty 5
  set can-reward 10
  set pick-up-penalty 1

end

;; randomly distribute cans, one per patch
to distribute-cans
  ask cans [ die ]
  ask patches with [random-float 1 < can-density] [
    sprout-cans 1 [
      set color orange
      if not visuals? [hide-turtle]
    ]
  ]
end

to draw-grid
  clear-drawing
  ask patches [
    sprout 1 [
      set shape "square"
      set color blue + 4
      stamp
      die
    ]
  ]
end

to go
  tick
  ;set total_reward []
  py:set "state" ([state] of one-of robots)
  ifelse user-input?[
    let action user-action
    set reward 0; reset reward
    ask robots [implement_action action]
  ]

  [
    ;py:run "env.set_observation(state)"
    let action  (py:runresult "ql_agent.choose_action(state)")
    if random_action? [set action random 7]
    set reward 0; reset reward
    ask robots [implement_action action + 1]
    py:set "action" action
    py:set "reward" reward
    py:set "next_state" ([state] of one-of robots)
    py:run "ql_agent.update_q_table(state, action, next_state, reward)"
    py:set "state" ([state] of one-of robots)
    py:set "iteration" (ceiling (ticks / episode_length))
    py:run "ql_agent.update_rates(iteration)"
  ]
  ;print (list "Transitioned state:" [state] of one-of robots)

  if ticks = episode_length * num_episodes [stop]
  if ticks mod episode_length = 0 [ print (list "Total-reward:" ([label] of one-of robots) ) wait 2 setup-robot-visuals]

end


to initialize-robot [s]
  ask robots [ die ]
  create-robots 1 [
    set label 0
    ifelse visuals? [ ; Show robot if this is during a trial of Robby that will be displayed in the view.
      set color blue
      pen-down
      set label-color black
      ]
      [set hidden? true]  ; Hide robot if this is during the GA run.
    set strategy s
  ]
  ;print (list("Initial state:") ([state] of one-of robots))
end
to implement_action [action]
  if action = 1 [move-north]
  if action = 2 [move-east]
  if action = 3 [move-south]
  if action = 4 [move-west]
  if action = 5 [move-random]
  if action = 6 [stay-put]
  if action = 7 [pick-up-can]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;; robot procedures
;
;;; These procedures are called an extremely high number of times as the GA runs, so it's
;;; important they be fast.  Therefore they are written in a style which maximizes
;;; execution speed rather than maximizing clarity for the human reader.
;
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
to-report state
  let north patch-at 0 1
  let east patch-at 1 0
  let south patch-at 0 -1
  let west patch-at -1 0
  report (ifelse-value is-patch? north [ifelse-value any? cans-on north [81] [0]] [162]) +;if 'wall' value = 162 (=3^4 X 2), else if 'can' value = 3^4 X 1 =81, else value = 3^4 X 0 = 0
         (ifelse-value is-patch? east  [ifelse-value any? cans-on east  [27] [0]] [ 54]) +;if 'wall' value =  54 (=3^3 X 2), else if 'can' value = 3^3 X 1 =27, else value = 3^3 X 0 = 0
         (ifelse-value is-patch? south [ifelse-value any? cans-on south [ 9] [0]] [ 18]) +;if 'wall' value =  18 (=3^2 X 2), else if 'can' value = 3^2 X 1 = 9, else value = 3^2 X 0 = 0
         (ifelse-value is-patch? west  [ifelse-value any? cans-on west  [ 3] [0]] [  6]) +;if 'wall' value =   6 (=3^1 X 2), else if 'can' value = 3^1 X 1 = 3, else value = 3^1 X 0 = 0
         (ifelse-value any? cans-here [1] [0]);if 'wall' value = 2 (3^0 X 2) (but if there is a robot there cannot be a wall here), else if 'can' value = 3^0 X 1=1, else value = 3^0 X 0 = 0
                                                                                           ; state = sum of all values
end

;; Below are the definitions of Robby's seven basic actions
to move-north  set heading   0  ifelse can-move? 1 [ fd 1 set reward 0] [ set label label - wall-penalty set reward (- wall-penalty)]  end
to move-east   set heading  90  ifelse can-move? 1 [ fd 1 set reward 0] [ set label label - wall-penalty set reward (- wall-penalty)]  end
to move-south  set heading 180  ifelse can-move? 1 [ fd 1 set reward 0] [ set label label - wall-penalty set reward (- wall-penalty)]  end
to move-west   set heading 270  ifelse can-move? 1 [ fd 1 set reward 0] [ set label label - wall-penalty set reward (- wall-penalty)]  end
to move-random run one-of ["move-north" "move-south" "move-east" "move-west"] end
to stay-put  set reward 0  end  ;; Do nothing


to pick-up-can
  ifelse any? cans-here
    [ set label label + can-reward set reward can-reward]
    [ set label label - pick-up-penalty set reward (- pick-up-penalty)]
  ask cans-here [
    ;; during RUN-TRIAL, leave gray circles behind so we can see where the cans were
    if visuals? [
      set color gray
      stamp
    ]
    die
  ]
end

to setup-robot-visuals
  ;if ticks = 0 [ stop ]  ;; must run at least one generation before a best-individual exists
  clear-output
  ;ask individuals [hide-turtle]
  set visuals? true
  draw-grid
  distribute-cans
  initialize-robot 0
  set step-counter 1
  ;output-print "Setting up a new random can distribution"
end

; Public Domain:
; To the extent possible under law, Uri Wilensky has waived all
; copyright and related or neighboring rights to this model.
@#$#@#$#@
GRAPHICS-WINDOW
384
11
966
594
-1
-1
57.4
1
10
1
1
1
0
0
0
1
0
9
0
9
1
1
1
generations
90.0

SLIDER
0
311
172
344
can-density
can-density
0.1
1
0.4
0.1
1
NIL
HORIZONTAL

BUTTON
4
32
101
65
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
970
10
1775
595
Total reward
Episode
Reward
0.0
5.0
-30.0
1.0
true
false
"" ""
PENS
"total-reward" 1.0 0 -16777216 true "" "plot [label] of one-of robots"

BUTTON
0
141
100
174
go-forever
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
0
71
100
135
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
179
323
392
365
Probability can in cell
17
0.0
1

SWITCH
114
29
232
62
user-input?
user-input?
1
1
-1000

INPUTBOX
107
73
222
133
user-action
7.0
1
0
Number

TEXTBOX
235
53
385
151
1 [move-north]\n2 [move-east] \n3 [move-south]\n4 [move-west]\n5 [move-random]\n6 [stay-put]\n7 [pick-up-can]
11
0.0
1

INPUTBOX
1
235
156
295
num_episodes
100.0
1
0
Number

INPUTBOX
3
176
158
236
episode_length
1000.0
1
0
Number

SWITCH
234
10
377
43
random_action?
random_action?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

Robby the Robot is a virtual robot who moves around a room and picks up cans.  This model demonstrates the use of actions return from Reinforcement learning(RL) agent (called from Python) to move Robby. The basic setup of the grid and robot movement were taken from the Netlogo model library (Robby the Robot) and modified for use in MIE524/624, UMAss Amherst. The RL currently returns random actions.

## RL algorithm: 
The Python code uses Q-learning to train the robot. The Netlogo model is used as the environment for the training

## HOW IT WORKS

### How Robby works (original setuo from Netlogo library)

Robby's 10x10 square world contains randomly scattered cans. His goal is to pick up as many as he can.  At each time tick, Robby can perform one of seven actions: move in one of the four cardinal directions, move in a random direction, pick up a can, or stay put.

When Robby picks up a can, he gets a reward. If he tries to pick up a can where none exists, or bumps into a wall, he is penalized.  His score at the end of a run is the sum of these rewards and penalties. The higher his score, the better he did.

To decide which action to perform, Robby senses his surroundings. He can see the contents of the square he is in and the four neighboring squares.  Each square can contain a wall, a can, or neither.  That means his sensors can be in one of 3<sup>5</sup> = 243 possible combinations.

A "strategy" for Robby specifies one of his seven possible actions for each of those 243 possible situations he can find himself in.

(Advanced note: If you actually do the math, you'll realize that some of those 243 situations turn out to be "impossible", e.g., Robby will never actually find himself in a situation in which all cardinal directions contain walls.  This is no problem; the genetic algorithm essentially ignores the "impossible" situations since Robby never encounters them.)

### How the algorithm works
It is setup to either run using actions returned from RL (Python code), or through user-input 


## HOW TO USE IT

### User-input: 
1. Switch 'on' user-input? on interface. 
2. Click setup
3. Enter the acton to take in 'action' and click 'go' to implement action. 
4. Repeat step 3 as many times as you need it

### RL code
1. Switch 'off' user-input? on interface. 
2. Click setup
3. Click 'go' to implement action one- step at a time, or 'go-forever' to step until stop condition. 



## CREDITS AND REFERENCES: THE CODE FOR MIE524/624 TAKEN FROM NETLOGO LIBRARY (see refernce below) and modified for RL


Robby was invented by Melanie Mitchell and described in her book _Complexity: A Guided Tour_ (Oxford University Press, 2009), pages 130-142.   Robby was inspired by The "Herbert" robot developed at the MIT Artificial Intelligence Lab in the 1980s.

This NetLogo version of Robby is based on Mitchell's earlier versions in NetLogo and C.
It uses code from the Simple Genetic Algorithms model (Stonedahl & Wilensky, 2008) in the NetLogo Sample Models Library.

Robby resembles a simpler version of Richard E. Pattis' Karel the Robot, https://en.wikipedia.org/wiki/Karel_(programming_language).

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Mitchell, M., Tisue, S. and Wilensky, U. (2012).  NetLogo Robby the Robot model.  http://ccl.northwestern.edu/netlogo/models/RobbytheRobot.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

[![CC0](http://ccl.northwestern.edu/images/creativecommons/zero.png)](https://creativecommons.org/publicdomain/zero/1.0/)

Public Domain: To the extent possible under law, Uri Wilensky has waived all copyright and related or neighboring rights to this model.

<!-- 2012 CC0 Cite: Mitchell, M., Tisue, S. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 5 4 294 295

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wall-e
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Rectangle -16777216 true false 60 165 240 270
Circle -16777216 true false 129 24 42
Rectangle -16777216 false false 135 105 180 135
Rectangle -7500403 true true 210 45 240 45
Rectangle -7500403 true true 90 0 210 75
Circle -16777216 true false 99 9 42
Circle -16777216 true false 159 9 42

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
setup repeat 5 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
