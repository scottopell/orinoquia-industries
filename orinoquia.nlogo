globals [ total-capital total-people my-ticks ]


breed [  ff-factories ff-factory ]
breed [  p-factories  p-factory  ]
breed [  lg-factories lg-factory ]
breed [  lg-fields    lg-field   ]
breed [  bf-factories bf-factory ]
patches-own [ orinoquia? ] ;; defines if a patch is in orinoquia
turtles-own [    ;; All turtles have these properties
  success        ;; Change this to reflect how well your industry is doing
                 ;; The range is 0.0 (very poor) and 1.0 (very well)
  capital-share  ;; Don't modify
  people-share   ;; Don't modify
  profit
]
ff-factories-own [
  max-gov-reg
  extraction-sites
  max-extraction-sites
  bank-balance
]
p-factories-own [
  bank-balance
  palm-tree-has
  max-palm-tree-has
]

bf-factories-own [
  land-expense
  total-land-cost
  ha-purchased
  new-total-ha
  total-ha
  cost-per-ha
  cost-of-grazing
  cattle
  cattle-per-ha
  AUM
  beef-retail-price
  beef-production
  percent-cattle-slaugtered
  revenue
  average-beef-price
  total-expenses
  bank-balance
  revenue-tax
]  

lg-factories-own [
  first-year-ha-cost 
  ha-annual-cost 
  ha-land-cost  
  factory-capital
  m^3-per-ha
  average-sale-price
  ha-of-trees
  tax-rate
  tax-revenue-generated
  environmental-impact
  log-employment
  max-has-of-trees
]

to setup
  clear-all
  set total-capital initial-total-capital
  set total-people  initial-total-people
  setup-patches
  setup-industries
  set my-ticks 0
  reset-ticks
end

to setup-patches
  import-pcolors "orinoquia.png" ;; inputs a map of orinoquia onto the patches
  ask patches [
    ifelse pcolor = 0 [
      set orinoquia? 0
    ] ;; makes the orinoquia region
    [ set orinoquia? 1 ] ;; makes the region outside orinoquia
    if orinoquia? = 1 [
      set pcolor green
    ] ;; makes orinoquia region green
  ]
end

to go
  do-ff
  do-lg
  do-palm
  do-bf
  
  god
  tick
end

to god
  ask turtles [
    let randomness .05
    set success  success * ( (1 - randomness) + ( randomness * random-float 1))
  ]
  let ordered sort-on [ success ] turtles

  ask item 0 ordered [
    set capital-share .35
    set people-share .35
  ]
 ask item 1 ordered [
    set capital-share .30
    set people-share .30
  ]
  ask item 2 ordered [
    set capital-share .20
    set people-share .20
  ]
  ask item 3 ordered [
    set capital-share .15
    set people-share .15
  ]
end

;; Reporters - These return information based on a turtle's properties

to-report industry-people ;; returns the amount of people available to work in a given industry
  report total-people * people-share
end

to-report industry-capital ;; returns the amount of money allocated to a given industry
  ;set my-ticks my-ticks + 1
  ;if my-ticks > 12 [
  ;  report 0
  ;]
  report total-capital * capital-share * .01
end

;;;;;;; Fossil Fuels ;;;;;;;;;;

;;;;; Setup
to setup-industries
  setup-fossil-fuels
  setup-logs
  setup-palm
  setup-beef
  ask turtles [
    set success .25
  ]
end

to setup-fossil-fuels
  set-default-shape ff-factories "factory"
  create-ff-factories 1
  ask ff-factories [
    set capital-share initial-ff-capital-share
    set people-share initial-ff-people-share
    set max-gov-reg 50
    set extraction-sites 2
    set max-extraction-sites 200
    set bank-balance industry-capital
  ]
  ;;477 orinoquia patches
end

;;;;; End Setup

;; Main Method
to do-ff
  ;; main algorith here
  ask ff-factories [
    
    if bank-balance < 0 [
      set extraction-sites extraction-sites - 1
    ]
    
    set bank-balance bank-balance + (industry-capital  * (1 - ff-curr-tax-rate))
    let current-well-cost 7000000  * (1 + ( extraction-sites / max-extraction-sites) )

    if bank-balance > current-well-cost and extraction-sites < max-extraction-sites [
      set extraction-sites extraction-sites + 1
      set bank-balance bank-balance - current-well-cost
    ]
    
    let barrels-produced-per-site-per-day 400
    let days-in-month 30
    set barrels-produced-per-site-per-day barrels-produced-per-site-per-day - (100 * ff-curr-gov-reg / max-gov-reg )
    set profit extraction-sites * barrels-produced-per-site-per-day * days-in-month * price-per-barrel 
       
    ;; jobs provided

    let max-jobs industry-people
    let curr-jobs extraction-sites * 5 ;; assuming that each extraction site needs ~10 people working there
    if curr-jobs > industry-people [
      set curr-jobs industry-people
    ]
    
    let expenses curr-jobs * (ff-worker-wage / 12)
    
    set bank-balance bank-balance + ( (profit - expenses) * (1 - ff-curr-tax-rate) )

    ; Success Calculation here
    
    ;; get maximum environmental impact for THIS model (in my case its the max extractions sites * the max gov-reg ration (max ratio will always be 1)
    let max-env-impact max-extraction-sites * (1)
    ;; calculate the current environmental impact
    let curr-env-impact extraction-sites * (1 - (ff-curr-gov-reg / max-gov-reg))
    
    ;; define the maximum tax rate that this industry could sustain
    let max-tax-rate 0.85
    ;let curr-tax-rate 0.45 ; this should be scaled based in income, just for demo purposes

    
    let running-success-total 0
    set running-success-total 0.33 * curr-env-impact / max-env-impact
    print "env"
    print curr-env-impact / max-env-impact
    set running-success-total running-success-total + (0.33 * (ff-curr-tax-rate / max-tax-rate))
    print "tax"
    print (ff-curr-tax-rate / max-tax-rate)
    set running-success-total running-success-total + (0.33 * (ln(curr-jobs) / ln(max-jobs)))
    print "jobs"
    print curr-jobs / max-jobs

    set success running-success-total
    print success

  ]
  
  
end




;;;;;;; End Fossil Fuels ;;;;;;;;;;


;;;;;;;; Start Logs ;;;;;;;;;;;;;
to setup-logs
  set-default-shape lg-factories "factory"
  create-lg-factories 1
  ask lg-factories [
    set people-share initial-lg-people-share
    set capital-share initial-log-capital-share
    set xcor 5 
    set ycor -1
    set color 115
    set first-year-ha-cost 1476
   ;; set factory-capital industry-capital
    set ha-annual-cost 82.35
    set max-has-of-trees 15000
    ;; set ha-land-cost price-per-ha
    ;; set pulpwood-price pulpwood-sale-price;; 33 per m^3
    ;; set wood-to-be-treated-price wood-to-be-treated-sale-price;; 74 per m^3
    ;; set sawtimber-price sawtimber-sale-price;; 66 per m^3
    ;; set m^3-per-ha m^3-yield-per-ha
    ;; set market-buy-price discount-rate
    ;; set tax-rate log-farm-annual-tax-rate
    ;;note: gives equal weight....
  ]
end

to do-lg
  log-trees-and-money
  log-jobs
  log-impact
  log-display
  ask lg-factories [
    log-success
  ]
end

to log-trees-and-money
    ask lg-factories [
  set average-sale-price ( .33 * ( pulpwood-price + wood-to-be-treated-price + sawtimber-price ) * (1 - discount-rate) ) ;;note: gives equal weight....
  set factory-capital ( annual-in - annual-out ) 
    if ha-of-trees < max-has-of-trees and factory-capital > (14760 + (price-per-ha * 10) ) [
      set ha-of-trees ha-of-trees + 10
      set factory-capital factory-capital - (14760 + (price-per-ha * 10 ) )
      set tax-revenue-generated ( ( annual-sales * log-farm-annual-tax-rate ) + (industry-capital * ( log-farm-annual-tax-rate) ) )
    ] 

    if factory-capital < 5000 [
      let ha-to-sell 10
        if ha-to-sell > ha-of-trees [
          set ha-to-sell 0
        ]
       set ha-of-trees ha-of-trees - ha-to-sell
      set factory-capital factory-capital + ( price-per-ha * ha-to-sell )
  ]
    ]
    
end

to log-jobs
  ask lg-factories [
    set log-employment (ha-of-trees * .1)
  ]
end

to log-impact
   ask lg-factories [
   set environmental-impact 3 
   ]
end

to log-display
  set-default-shape lg-fields "tree"

  if ([ha-of-trees] of lg-factory 1) > 6000 [
    create-lg-fields 1 [
      set xcor 6
      set ycor -1
    ]
  ]
    
  if ([ha-of-trees] of lg-factory 1) > 12000 [
    create-lg-fields 1 [
      set xcor 5
      set ycor -2
    ]
  ] 
end
  
to log-success
   ; Success Calculation here
    

    
    ;; define the maximum tax rate that this industry could sustain
    let max-tax-rate 0.70
    ;let curr-tax-rate 0.45 ; this should be scaled based in income, just for demo purposes

    ;let max-has 20000
    let running-success-total 0
    set running-success-total 0.33 * .5 * (1 - ( ha-of-trees / max-has-of-trees ))
    set running-success-total running-success-total + (0.33 * (log-farm-annual-tax-rate / max-tax-rate))
    set running-success-total running-success-total + (0.33 * log-employment / industry-people)

    set success running-success-total
end

;;Report shit back;;

to-report annual-out
  report ( ( ha-of-trees * ha-annual-cost )  + labor-cost)
end

to-report annual-in
  report ( factory-capital + (annual-sales * (1 - tax-rate)) + ((initial-log-capital-share * .01 * initial-total-capital) * (1 - tax-rate)) )
end

to-report annual-sales
  report ( ha-of-trees * m^3-yield-per-ha * average-sale-price )
end

to-report labor-cost
  report ( log-employment * 2000 )
end

to-report transport-cost
  report ( distance-from-market * .13 * (ha-of-trees * m^3-yield-per-ha) )
end
;;;;;;;;;; End Logs;;;;;;;;;;;;;
to setup-palm
  set-default-shape p-factories "factory"
  create-p-factories 1
  ask p-factories [
    set capital-share initial-palm-capital-share
    set people-share initial-palm-people-share
    set bank-balance industry-capital
    set max-palm-tree-has 20000
  ]
end

to do-palm
  ;; main algorith here
  ask p-factories [
    
    if bank-balance < 0 [
      set palm-tree-has palm-tree-has - 1
    ]
    
    set bank-balance bank-balance + (industry-capital  * (1 - p-curr-tax-rate))

    if bank-balance > curr-palm-tree-ha-cost and palm-tree-has < max-palm-tree-has [
      set palm-tree-has palm-tree-has + 1
      set bank-balance bank-balance - curr-palm-tree-ha-cost
    ]
    
    let tons-oil-per-ha 3.75

    set profit palm-tree-has * tons-oil-per-ha * price-per-ton-oil
       
    ;; jobs provided
    let max-jobs industry-people
    let curr-jobs palm-tree-has * 5 + 2 ;; assuming that each extraction site can sustain 400 people working there
    if curr-jobs > industry-people [
      set curr-jobs industry-people
    ]
    
    let expenses curr-jobs * (p-worker-wage / 12)
    
    set bank-balance bank-balance + ( (profit - expenses) * (1 - p-curr-tax-rate) )

    ; Success Calculation here
    
    ;; define the maximum tax rate that this industry could sustain
    let max-tax-rate 0.45
    ;let curr-tax-rate 0.45 ; this should be scaled based in income, just for demo purposes

    
    let running-success-total 0
    set running-success-total 0.33 * .2
    set running-success-total running-success-total + (0.33 * (p-curr-tax-rate / max-tax-rate))
    set running-success-total running-success-total + (0.33 * curr-jobs / max-jobs)

    set success running-success-total

  ]
end



to setup-beef
  set-default-shape bf-factories "factory"
  create-bf-factories 1
  ask bf-factories [
    set capital-share initial-beef-capital-share
    set people-share initial-beef-people-share
    set bank-balance industry-capital
    set AUM .3
    set cattle-per-ha 20
    set beef-retail-price 50
    set ha-purchased 0
  ]
end

to do-bf
  bf-bank-balance
  bf-land
  bf-cattle
  bf-production
  bf-profit
  bf-success
end

to bf-bank-balance
  ask bf-factories [
   ;set bank-balance bank-balance + industry-capital
   if profit < total-expenses [
     set ha-purchased ha-purchased - 1
     set bank-balance bank-balance + 1500
   ]
   if bank-balance > 2000 [
     set ha-purchased ha-purchased + 1
     set bank-balance bank-balance - 2000
   ]
 ]
end



to bf-land
  ask bf-factories [
    set new-total-ha ( initial-ha + ha-purchased )
    set total-land-cost  bf-cost-per-ha * new-total-ha
    set cost-of-grazing  AUM * cattle
    set land-expense  total-land-cost + cost-of-grazing
  ]
end

to bf-cattle
  ask bf-factories [
    set cattle  new-total-ha * cattle-per-ha
  ]
end

to bf-production
  ask bf-factories [
    set beef-production  cattle * percent-cattle-slaughtered
    set revenue  beef-production * beef-retail-price
    set total-expenses  land-expense + employee-compensation / 12 * bf-people
  ]
end

to-report bf-people
  report cattle / 70 
end

to bf-profit
  ask bf-factories [
    set profit  revenue * bf-tax-rate - total-expenses
    set bank-balance  bank-balance + industry-capital * (1 - bf-tax-rate) + profit
  ]
end

to bf-success
  ask bf-factories [
    let curr-env-impact .7
    let max-tax-rate .65
    
    let running-success-total 0
    set running-success-total .33 * curr-env-impact
    set running-success-total running-success-total + (.33 * ( bf-tax-rate / max-tax-rate))
    set running-success-total running-success-total + (.33 * bf-people / industry-people)
    set success running-success-total
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
28
52
548
593
20
20
12.44
1
10
1
1
1
0
1
1
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
28
16
90
49
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

BUTTON
791
107
854
140
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
790
32
869
85
Industries
count turtles
17
1
13

SLIDER
559
89
760
122
initial-total-people
initial-total-people
4000
10000
10000
50
1
NIL
HORIZONTAL

SLIDER
559
56
760
89
initial-total-capital
initial-total-capital
0
1000000
500000
10000
1
NIL
HORIZONTAL

SLIDER
559
144
761
177
initial-ff-capital-share
initial-ff-capital-share
0
100
25
1
1
NIL
HORIZONTAL

SLIDER
559
306
760
339
initial-ff-people-share
initial-ff-people-share
0
100
25
1
1
NIL
HORIZONTAL

SLIDER
559
177
761
210
initial-log-capital-share
initial-log-capital-share
0
100
14
1
1
NIL
HORIZONTAL

SLIDER
559
210
761
243
initial-palm-capital-share
initial-palm-capital-share
0
100
28
1
1
NIL
HORIZONTAL

SLIDER
559
243
761
276
initial-beef-capital-share
initial-beef-capital-share
0
100
25
1
1
NIL
HORIZONTAL

MONITOR
871
32
970
85
Money
total-capital
17
1
13

MONITOR
972
32
1091
85
Workers
total-people
17
1
13

PLOT
25
595
1014
745
Success Rates
NIL
NIL
0.0
10.0
0.0
0.33
true
false
"" ""
PENS
"Fossil Fuels" 1.0 0 -16777216 true "" "plot [success] of ff-factory 0"
"Palm Oil" 1.0 0 -7500403 true "" "plot [success] of p-factory 2"
"Logging" 1.0 0 -2674135 true "" "plot [success] of lg-factory 1"
"Beef" 1.0 0 -955883 true "" "plot [success] of bf-factory 3"

SLIDER
1211
106
1382
139
initial_beef_retail_price
initial_beef_retail_price
0
100
4.29
1
1
NIL
HORIZONTAL

SLIDER
791
280
1001
313
price-per-ha
price-per-ha
0
4000
1200
1
1
NIL
HORIZONTAL

SLIDER
790
106
1001
139
pulpwood-price
pulpwood-price
0
100
33
1
1
NIL
HORIZONTAL

SLIDER
790
172
1007
205
wood-to-be-treated-price
wood-to-be-treated-price
0
100
74
1
1
NIL
HORIZONTAL

SLIDER
790
139
1001
172
sawtimber-price
sawtimber-price
0
100
66
1
1
NIL
HORIZONTAL

SLIDER
790
238
1001
271
m^3-yield-per-ha
m^3-yield-per-ha
0
40
20
1
1
NIL
HORIZONTAL

SLIDER
790
205
1001
238
discount-rate
discount-rate
0.0
1.0
0.03
.01
1
NIL
HORIZONTAL

SLIDER
791
321
1009
354
log-farm-annual-tax-rate
log-farm-annual-tax-rate
0.0
1.0
0.19
.01
1
NIL
HORIZONTAL

TEXTBOX
559
39
709
57
Universial Factors
11
0.0
1

TEXTBOX
560
128
710
146
Share of Investment
11
0.0
1

TEXTBOX
561
284
711
302
Share of Labor
11
0.0
1

TEXTBOX
791
89
941
107
Log Farm Variables
11
0.0
1

SLIDER
559
339
760
372
initial-lg-people-share
initial-lg-people-share
0
100
25
1
1
NIL
HORIZONTAL

SLIDER
559
372
760
405
initial-beef-people-share
initial-beef-people-share
0
100
25
1
1
NIL
HORIZONTAL

SLIDER
559
404
760
437
initial-palm-people-share
initial-palm-people-share
0
100
25
1
1
NIL
HORIZONTAL

SLIDER
1019
106
1191
139
ff-curr-gov-reg
ff-curr-gov-reg
0
50
23
1
1
NIL
HORIZONTAL

BUTTON
95
16
158
49
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1019
89
1169
107
Fossil Fuel Variables
11
0.0
1

TEXTBOX
1210
89
1360
107
Meatpacking Variables
11
0.0
1

TEXTBOX
1424
90
1574
108
Palm Oil Variables
11
0.0
1

SLIDER
1019
139
1190
172
ff-curr-tax-rate
ff-curr-tax-rate
0
.85
0.55
.01
1
NIL
HORIZONTAL

SLIDER
1019
171
1191
204
price-per-barrel
price-per-barrel
0
100
30
1
1
NIL
HORIZONTAL

MONITOR
1072
253
1129
298
Wells
[extraction-sites] of ff-factory 0
1
1
11

MONITOR
1048
310
1150
355
FF-Money
[bank-balance] of ff-factory 0
0
1
11

SLIDER
1020
203
1192
236
ff-worker-wage
ff-worker-wage
5000
15000
10000
100
1
NIL
HORIZONTAL

SLIDER
791
362
1011
395
distance-from-market
distance-from-market
0
1000
795
1
1
NIL
HORIZONTAL

MONITOR
799
407
974
452
NIL
[annual-in] of lg-factory 1
2
1
11

MONITOR
800
455
985
500
NIL
[annual-out] of lg-factory 1
17
1
11

SLIDER
1424
107
1596
140
p-curr-tax-rate
p-curr-tax-rate
0.0
.45
0.44
.01
1
NIL
HORIZONTAL

SLIDER
1424
144
1598
177
curr-palm-tree-ha-cost
curr-palm-tree-ha-cost
1000
4000
1200
1
1
NIL
HORIZONTAL

SLIDER
1424
183
1596
216
price-per-ton-oil
price-per-ton-oil
500
1500
620
1
1
NIL
HORIZONTAL

SLIDER
1424
216
1596
249
p-worker-wage
p-worker-wage
2000
10000
2500
1
1
NIL
HORIZONTAL

MONITOR
1451
280
1578
325
Palm-Oil-Money
[bank-balance] of p-factory 2
2
1
11

MONITOR
1452
336
1578
381
Current Hectacres
[palm-tree-has] of p-factory 2
2
1
11

SLIDER
1211
139
1383
172
bf-tax-rate
bf-tax-rate
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
1212
172
1384
205
initial-ha
initial-ha
1
780
30
1
1
NIL
HORIZONTAL

SLIDER
1212
204
1384
237
bf-cost-per-ha
bf-cost-per-ha
0
50
7
1
1
NIL
HORIZONTAL

SLIDER
1211
235
1385
268
percent-cattle-slaughtered
percent-cattle-slaughtered
0
1
0.2
.01
1
NIL
HORIZONTAL

SLIDER
1211
269
1385
302
employee-compensation
employee-compensation
1000
4000
1200
1
1
NIL
HORIZONTAL

MONITOR
807
505
931
550
hectacres of trees
[ha-of-trees] of lg-factory 1
17
1
11

MONITOR
1211
382
1385
427
# of Cattle
[cattle] of bf-factory 3
17
1
11

MONITOR
1212
336
1384
381
Beef-Money
[bank-balance] of bf-factory 3
2
1
11

MONITOR
1211
427
1383
472
Total Expenses
[total-expenses] of bf-factory 3
2
1
11

BUTTON
168
16
279
49
reset-sliders
set initial-total-capital 500000\nset initial-total-people 10000\n\nset initial-ff-capital-share 25\nset initial-log-capital-share 25\nset initial-palm-capital-share 25\nset initial-beef-capital-share 25\n\nset initial-ff-people-share 25\nset initial-lg-people-share 25\nset initial-palm-people-share 25\nset initial-beef-people-share 25\n\n; fossil fuels\nset ff-curr-gov-reg 23\nset ff-curr-tax-rate .55\nset price-per-barrel 30\nset ff-worker-wage 10000\n\n; log farm\nset pulpwood-price 33\nset sawtimber-price 66\nset wood-to-be-treated-price 74\nset discount-rate .1\nset m^3-yield-per-ha 20\nset price-per-ha 1200\nset log-farm-annual-tax-rate .28\nset distance-from-market 800\n\n; beef\nset initial_beef_retail_price 4.29\nset bf-tax-rate .10\nset initial-ha 30\nset bf-cost-per-ha 7\nset percent-cattle-slaughtered .20\nset employee-compensation 1200\n\n; palm oil\nset p-curr-tax-rate .44\nset curr-palm-tree-ha-cost 1200\nset price-per-ton-oil 620\nset p-worker-wage 2500\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
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
