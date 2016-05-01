$include $lib/ansi (ansilib.muf)
$include $lib/useful (Useful.muf)
$include $rp/combat/CalcStats (CalculateStats.muf)
$include $rp/combat/Triggers (Triggers.muf)
$include $rp/combat/End
$include $rp/combat/AI
 
var arg
var pos
var tpos
var BID
var attacker
var who
var move
var accuracy
var user
var movetype
var attack
var defense
var tmove
var ttype
var turncount
var tkcount
var tkdamage
var oldval
var lastmove
var stockpile
var damage
var weather
var berryeffect
var effect
var weaken
var weakenstip
var heal
var misshurtself
 
var arrayx
var env
var movenum
var counter

var tempref
var temp
var temp2
var temp3
var temp4
var temp5
var noeffect
 
var majorstatus
 
var StartedFullHP
 
var startsub
 
var protected

var min
var max

var hittimes
var debug
 
 ( Takes params "target" and "attacker" )
 ( Make attacker read from battle context? Same as "target"? )
: powerlevelset
 
    var! target
    var! attacker (NOT THE GLOBAL VAR)
    var PL (power level)
    attacker @ PowerLevel PL !
    loc @ { "@battle/" BID @ "/battlepoints/" target @ "/PL" }cat getprop if
    loc @ { "@battle/" BID @ "/battlepoints/" target @ "/PL" }cat getprop PL @ >= if exit then
    then
    loc @ { "@battle/" BID @ "/battlepoints/" target @ "/PL" }cat PL @ setprop
    loc @ { "@battle/" BID @ "/battlepoints/" target @ "/attacker" }cat attacker @ setprop
 
;
 
 ( Params: msg )
: notify_watchers
    var! msg
    var watchers
    oc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop 
        stod watchers ! watchers @ awake? not if continue then
        watchers @ location loc @ = not if continue then
        watchers @ { msg @ }cat notify
    repeat
;

 ( Takes param "div" and "hp" )
: divdamage ( this is just used to change the division to decimals, round up, then make back into int )
    var! div
    var! hp
     
    hp @ div @ / dup not if pop 1 then
;
 
 ( Takes param "move" )
: attack_type
    var! move
    POKEDEX { "moves/" move @ "/type" }cat getprop
;

( Takes param "id" )
: hidden_power_type
    var! id
    id @ "Hiddenpower" get dup if exit else pop then
    var ivs
    var type
    ID @ "IVs" get ivs !
    {
        ivs @  5 1 midstr
        ivs @ 10 1 midstr
        ivs @ 15 1 midstr
        ivs @ 20 1 midstr
        ivs @ 25 1 midstr
        ivs @ 30 1 midstr
    }cat bindec 15 * 63 / type !
 
    type @ 0  = if "Fighting" exit then
    type @ 1  = if "Flying" exit then
    type @ 2  = if "Poison" exit then
    type @ 3  = if "Ground" exit then
    type @ 4  = if "Rock" exit then
    type @ 5  = if "Bug" exit then
    type @ 6  = if "Ghost" exit then
    type @ 7  = if "Steel" exit then
    type @ 8  = if "Fire" exit then
    type @ 9  = if "Water" exit then
    type @ 10 = if "Grass" exit then
    type @ 11 = if "Electric" exit then
    type @ 12 = if "Psychic" exit then
    type @ 13 = if "Ice" exit then
    type @ 14 = if "Dragon" exit then
    type @ 15 = if "Dark" exit then
    ( Add ??? type? )
;

( Takes param "target" and "id" ) 
: transform
    ( Transform Routine )
    var! target
    var! id

    POKESTORE { "@pokemon/" id @ fid "/@temp/level" }cat id @ FindPokeLevel setprop
    POKESTORE { "@pokemon/" ID @ fid "/@temp/hiddenpower" }cat target @ hidden_power_type setprop
    POKESTORE { "@pokemon/" ID @ fid "/@temp/hiddenpowerbasepower" }cat
    
    var ivs
    target @ "IVs" get ivs !
    {
        ivs @  4 1 midstr
        ivs @  9 1 midstr
        ivs @ 14 1 midstr
        ivs @ 19 1 midstr
        ivs @ 24 1 midstr
        ivs @ 29 1 midstr
    }cat bindec 40 * 63 / 30 + setprop
         
    (attacker is the user of the move, target is the target of the move)
    ( caster @ "maxhp" calculate var! maxhp -- delete this? )
    POKESTORE { 
        "@pokemon/" id @ fid "/@temp/species" 
    }cat target @ "species" fget setprop
  
    POKESTORE { "@pokemon/" id @ fid "/@temp/ability" }cat
    id @ "status/statmods/abilityremoved" get if
        pop
    else
       target @ "ability" fget setprop
    then
  
   
    ( caster @ "status/hp" )
    ( caster @ "maxhp" calculate caster @ "status/hp" get atoi * maxhp @ / setto )
    ( caster @ "status/hp" get atoi 1 < if caster @ "status/hp" 1 setto then )
    
    var knownMove
    target @ "movesknown" fgetvals foreach pop knownMove !
        POKESTORE { "@pokemon/" id @ fid "/@temp/movesknown/" knownMove @ }cat 1 setprop
        POKESTORE { "@pokemon/" id @ fid "/@temp/movesknown/" knownMove @ "/pp" }cat 5 setprop
    repeat
    
    loc @ { "@battle/" BID @ "/4moves" }cat getprop if
        loc @ { "@battle/" BID @ "/movesets/" target @ }cat getprop var! oset
        target @ { "movesets/" oset @ "/A" }cat fget var! moveA
        target @ { "movesets/" oset @ "/B" }cat fget var! moveB
        target @ { "movesets/" oset @ "/C" }cat fget var! moveC
        target @ { "movesets/" oset @ "/D" }cat fget var! moveD
        Loc @ { "@battle/" BID @ "/movesets/" id @ }cat getprop var! mset
    
        POKESTORE { "@pokemon/" ID @ fid "/@temp/movesets/" mset @ "/A" }cat moveA @ setprop     
        POKESTORE { "@pokemon/" ID @ fid "/@temp/movesets/" mset @ "/B" }cat moveB @ setprop
        POKESTORE { "@pokemon/" ID @ fid "/@temp/movesets/" mset @ "/C" }cat moveC @ setprop
        POKESTORE { "@pokemon/" ID @ fid "/@temp/movesets/" mset @ "/D" }cat moveD @ setprop
    then
;

( Uses tpos and BID locally )
$libdef onfield_ability
: onfield_ability ( Params: bid, ability : 1 or 0 )
 
    var tpos ( NOT THE GLOBAL vARIABLE )
    var ttarget(typo?)
    var found
    var! bid ( NOT GLOBAL )
    var! ability
 
    0 found !
    { "A1" "A2" "A3" "B1" "B2" "B3"  }list foreach tpos ! pop
        loc @ { "@battle/" BID @ "/position/" tpos @ }cat getprop ttarget !
        ttarget @ if
            ttarget @ "ability" fget ability @ smatch if
                1 found ! break
            then
        then
    repeat
    found @
; PUBLIC onfield_ability
 
( bid, ability, pos, tpos are used locally )
( params: bid, ability, pos )
$libdef team_ability
: team_ability ( returns the number of times ability is found )
    var! bid
    var! ability
    var! pos
 
    var tpos
    var ttarget ( again, typo? )
    var found
    var team
    0 found !
    pos @ 1 1 midstr team !
    { { team @ "1" }cat { team @ "2" }cat  { team @ "3" }cat }list foreach tpos ! pop
        loc @ { "@battle/" BID @ "/position/" tpos @ }cat getprop ttarget !
        ttarget @ if
            ttarget @ "ability" fget ability @ smatch if
                found @ 1 + found !
            then
        then
    repeat
    found @
; PUBLIC team_ability

( Params: iuser, ipos )
: can_use_hold_item
    var! iuser
    var! ipos

    ipos @ "A*" smatch if "B" else "A" then var! ioppteam

    ( Move the "and"s around )
    iuser @ "status/statmods/embargo" get not 
    iuser @ "ability" fget "klutz" smatch not 
    loc @ { "@battle/" BID @ "/MagicRoom" }cat getprop not 
    ioppteam @ "Unnerve" bid @ team_ability iuser @ "holding" get "*berry" smatch and not
    and and and if 1 else 0 then
;
 
( Params: bid ) 
( Uses weather, bid locally )
$libdef check_weather
: check_weather ( returns the weather )
    var! bid ( Not global )
    var weather
     
    loc @ { "@battle/" bid @ "/roomweather" }cat getprop dup not if pop "none" then
    weather !
     
    weather @ "none" smatch not if
        "Air Lock" bid @ onfield_ability
        "Cloud Nine" bid @ onfield_ability
        or
        if
            "none" weather !
        then
    then
    weather @
; PUBLIC check_weather

( this is done after the ability smatch, if it has a 0 then skip this and return 0, 
  if it has a 1 then do the check for the ability. return a 0 if broken and a 1 if not 
)
( Params: targ, sresult )
: moldbreaker 
    ( Don't have an "and" or an "or" after this if you are trying to compare it )
    var! targ
    var! sresult

    sresult @ not if 0 exit then

    targ @ "Ability" fget var! uabil

    uabil @ "mold breaker" smatch
    uabil @ "Turboblaze" smatch or
    uabil @ "Teravolt" smatch or if
        loc @ { "@battle/" BID @ "/temp/moldbreakermessage" }cat getprop not if
            loc @ { "@battle/" BID @ "/temp/moldbreakermessage" }cat 1 setprop
            uabil @ "mold breaker" smatch if
                { "^[o^[y" targ @ id_name " breaks the mold!" }cat notify_watchers
            then
            uabil @ "Turboblaze" smatch if
                { "^[o^[y" targ @ id_name " is radiating a blazing aura!" }cat notify_watchers
            then
            uabil @ "Teravolt" smatch if
                { "^[o^[y" targ @ id_name " is radiating a bursting aura!" }cat notify_watchers
            then
            0
        else
            1
        then
    else
        1
    then
;
 
( Params: user )
$libdef check_status
: check_status 
var! user
    user @ "status/poisoned" get if "poisoned" exit then
    user @ "status/toxic" get if "toxic" exit then
    user @ "status/burned" get if "burned" exit then
    user @ "status/asleep" get if "asleep" exit then
    user @ "status/paralyzed" get if "paralyzed" exit then
    user @ "status/frozen" get if "frozen" exit then
    0
; PUBLIC check_status

( Params: wt )
( Rename wt into something much better )
$libdef weightcalc
: weightcalc
    var! wt
    POKEDEX { "pokemon/" wt @ "species" fget "/weight" }cat getprop " " "lb" subst strip strtof var! weight
    
    wt @ "status/statmods/Autotomize" get if weight @ 2 / weight ! then
    
    wt @ "ability" fget "heavy metal" smatch if
        weight @ 2 * weight !
    then
    
    wt @ "ability" fget "light metal" smatch if
        weight @ 2 / weight !
    then

    weight @
; PUBLIC weightcalc


( Params: target, possibly more values implied on stack )
$libdef eatberry
: eatberry
    var! target
    
    loc @ { "@battle/" BID @ "/EatenBerry/" target @ }cat target @ "holding" get setprop
    
    target @ "holding" "Nothing" setto
    target @ "happiness" over over fget atoi 1 + fsetto
    target @ "happiness" fget atoi 255 > if
        target @ "happiness" 255 fsetto
    then
; PUBLIC eatberry


( Params: tpos )
( Uses tpos, who, locally )
( Uses global berryeffect, weaken, BID, misshurtself )
: typetotalcalculate
    var! tpos
    loc @ { "@battle/" BID @ "/position/" tpos @ }cat getprop var! who
    1

    " " weaken !
    POKEDEX { "items/" who @ "holding" get "/holdeffect" }cat getprop berryeffect !
    
    ( Berry modifying "weaken" - make its own function? )
    berryeffect @
    tpos @ who @ can_use_hold_item and
    if
        berryeffect @ ":" explode_array foreach effect ! pop
        effect @ "weaken*" smatch if
            effect @ " " "Weaken" subst strip weaken !
            continue
        then
        repeat
        POKEDEX { "items/" who @ "holding" get "/Conditional" }cat getprop weakenstip !
    then

    var whotype
    var lasttype
    
    "" lasttype !
    who @ typelist foreach swap pop dup whotype !
        who @ "status/statmods/roost" get 
        who @ "status/statmods/smackdown" get or if
            whotype @ "flying" smatch if 
                who @ typelist array_count 1 = if 
                    "Normal" whotype ! pop whotype @ 
                else 
                    pop continue 
                then
            then
        then
        
        whotype @ lasttype @ smatch if pop continue then
        whotype @ lasttype !
        ( { "Whotype: " whotype @  }cat "Debug" pretty notify_watchers )
        misshurtself @
        whotype @ "ghost" smatch and if pop continue then

        ( Could this be cleaned up a bit? - moved to its own function perhaps? )
        ( The variable effect is being used in a different context! Replace it with a new variable )
        whotype @ "Ghost" smatch
        movetype @ "fighting" smatch
        movetype @ "normal" smatch or and
        who @ "status/statmods/foresight" get
        user @ "ability" fget "Scrappy" smatch or
        and
        movetype @ "psychic" smatch
        whotype @ "dark" smatch and
        who @ "status/statmods/Miracle Eye" get and or
        not if
            { "typetable/" movetype @ "/" }cat swap strcat user @ swap get strtof
            effect !
            who @ "ability" fget "levitate" smatch
            user @ moldbreaker
            who @ "status/statmods/Magnet Rise" get 
            who @ "status/statmods/telekinesis" get or
            loc @ { "@battle/" BID @ "/gravity" }cat getprop not and or
            who @ "status/statmods/ingrain/move" get not and
            who @ "holding" get stringify "iron ball" smatch not and
            if
                movetype @ "ground" smatch if
                    -1.0 effect !
                then
            then

            loc @ { "@battle/"BID @ "/gravity" }cat getprop
            who @ "status/statmods/ingrain/move" get or
            who @ "holding" get stringify "iron ball" smatch or
            if
                whotype @ "flying" smatch
                movetype @ "ground" smatch and
                if
                    0 effect !
                then
            then

            movetype @ weaken @ smatch if
                weakenstip @
                effect @ 0 > and
                weakenstip @ not or
                if
                    effect @ 0.5 * effect !
                    { "^[o^[c" who @ id_name "^[y weakened the attack by eating its ^[c" who @ "holding" get "^[y!" }cat notify_watchers
                    who @ eatberry
                then
            then

            effect @ 1 + *
        else  (this else is for miracle eye)
            1
        then
    repeat


;

( Params: damage )
( Uses damage locally )
( Uses who, tpos globally )
: substitute_damage
    var! damage
    who @ "status/statmods/substitute" over over get atoi damage @ - setto
    { "^[o^[c" tpos @ "." who @ id_name "'s^[y substitute took its damage!" }cat notify_watchers
    
    who @ "status/statmods/substitute" get atoi 1 < if
        "^[o^[yThe substitute broke!" notify_watchers
        who @ "status/statmods/substitute" 0 setto
    then
;

( Params: target )
( Uses Weather locally )
( Uses BID globally )
$libdef forecast
: forecast
    var! target
     
    target @ "species" fget "351" smatch not if exit then
     
    bid @ check_weather var! weather ( check_weather is an earlier function )
     
    weather @ "rain dance" smatch if
        target @ "status/statmods/type" "Water" setto
        exit
    then
     
    weather @ "sunny day" smatch if
        target @ "status/statmods/type" "Fire" setto
        exit
    then
     
    weather @ "Hail" smatch if
        target @ "status/statmods/type" "Ice" setto
        exit
    then
; PUBLIC forecast
 
 
$libdef switch_check
: switch_check (bid, pos)
pos !
bid !
 
       var team
       var id
       var notvalid
 
       pos @ 1 1  midstr team !
       loc @ { "@battle/" BID @ "/temp/validstats/" team @ }cat remove_prop
 
                loc @ { "@battle/" BID @ "/teams/" team @ "/" }cat array_get_propvals foreach id ! pop
 
                  0 notvalid !
                  loc @ { "@battle/" BID @ "/position/" team @ "1" }cat getprop stringify id @ smatch if 1 notvalid ! then
                  loc @ { "@battle/" BID @ "/position/" team @ "2" }cat getprop stringify id @ smatch if 1 notvalid ! then
                  id @ "status/hp" get not if 3 notvalid ! then
                  id @ "egg?" get if 4 notvalid ! then
                  loc @ { "@battle/" BID @ "/temp/validstats/" team @ "/" id @ }cat notvalid @ setprop
                 repeat
 
                 var switchable
                 0 switchable !
                 loc @ { "@battle/" BID @ "/teams/" team @ "/" }cat array_get_propvals foreach id ! pop
                 loc @ { "@battle/" BID @ "/temp/validstats/" team @ "/" id @ }cat getprop not if 1 switchable ! break then
                 repeat
 
        switchable @
; PUBLIC switch_check
 
$libdef placed_abilities (pos, bid)
: placed_abilities (this is for abilities that are placed, this isn't used to check if one is in effect)
BID !
pos !
 
var oteam
 
pos @ "A*" smatch if
"B" oteam !
else
"A" oteam !
then
 
var target
 
loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop target !
 
target @ "ability" fget "Drizzle" smatch if
        loc @ { "@battle/" BID @ "/roomweather" }cat "rain dance" setprop
        loc @ { "@battle/" BID @ "/roomweather/length" }cat 5 setprop
        { "^[y^[oThe weather changed to rain due to ^[c" target @ id_name "'s^[y ability ^[c" target @ "ability" fget "^[y." }cat notify_watchers
then
 
target @ "ability" fget "Drought" smatch if
        loc @ { "@battle/" BID @ "/roomweather" }cat "sunny day" setprop
        loc @ { "@battle/" BID @ "/roomweather/length" }cat 5 setprop
        { "^[y^[oThe weather changed to strong sunlight due to ^[c" target @ id_name "'s^[y ability ^[c" target @ "ability" fget "^[y." }cat notify_watchers
then
 
target @ "ability" fget "Sand Stream" smatch if
        loc @ { "@battle/" BID @ "/roomweather" }cat "sandstorm" setprop
        loc @ { "@battle/" BID @ "/roomweather/length" }cat 5 setprop
        { "^[y^[oThe weather changed to a strong sandstorm due to ^[c" target @ id_name "'s^[y ability ^[c" target @ "ability" fget "^[y." }cat notify_watchers
then
 
target @ "ability" fget "Snow Warning" smatch if
        loc @ { "@battle/" BID @ "/roomweather" }cat "hail" setprop
        loc @ { "@battle/" BID @ "/roomweather/length" }cat 5 setprop
        { "^[y^[oThe weather changed to hailing due to ^[c" target @ id_name "'s^[y ability ^[c" target @ "ability" fget }cat notify_watchers
 
then
 
target @ "ability" fget "Mold Breaker" smatch 
target @ "ability" fget "turboblaze" smatch or
target @ "ability" fget "teravolt" smatch or
{ "Mold Breaker" "Turboblaze" "Teravolt" "Unnerve" "Scrappy" "Infiltrator" }list target @ "ability" fget array_findval array_count
if
        { "^[o^[c" pos @ "." target @ id_name "^[y has the ability ^[c" target @ "ability" fget cap "^[y!" }cat notify_watchers
then

 
target @ "ability" fget "Intimidate" smatch if
        target @ "status/statmods/ability/intimidate" get not if
        { { oteam @ "1" }cat  { oteam @ "2" }cat }list foreach swap pop temp !
        loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop temp2 !
        temp2 @ if
                temp2 @ "ability" fget "Clear Body" smatch not
                temp2 @ "ability" fget "White Smoke" smatch not and
                temp2 @ "ability" fget "Hyper Cutter" smatch not and
                temp2 @ "status/statmods/substitute" get not and
                if
                { "^[o^[c" pos @ "." target @ id_name "'s ^[yIntimidate cuts ^[c" temp @ "." temp2 @ id_name "'s^[y attack!" }cat notify_watchers
                temp2 @ "status/statmods/PhysAtk" over over atoi 1 - setto
                then
                temp2 @ "ability" fget "Defiant" smatch if
                temp2 @ "status/statmods/PhysAtk" over over atoi 2 + setto 
                { "^[o^[c" temp @ "." temp2 @ id_name "'s ^[yability ^[cDefiant^[y raised its attack by two levels!" }cat notify_watchers
                then
        then
        repeat
        then
        target @ "status/statmods/ability/intimidate" 1 setto
then
 
target @ "ability" fget "multitype" smatch if
        target @ "holding" get "*plate" smatch if
                POKEDEX { "items/" target @ "holding" get "/judgment" }cat getprop temp !
                target @ "status/statmods/type" temp @ setto
                { "^[o^[c" pos @ "." target @ id_name "'s ^[ytype is ^[c" temp @ cap "^[y." }cat notify_watchers
        then
then

target @ "ability" fget "air lock" smatch if
        { "^[o^[c" pos @ "." target @ id_name " ^[yhas ^[cAir Lock^[y." }cat notify_watchers
then

target @ "ability" fget "cloud nine" smatch if
        { "^[o^[yThe effects of weather disappeared.." }cat notify_watchers
then
 
target @ "ability" fget "Download" smatch if
        var phys
        var spec
        { { oteam @ "1" }cat  { oteam @ "2" }cat }list foreach swap pop temp !
        loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop temp2 !
 
        temp2 @ if
                temp2 @ "PhysDef" calculate phys @ + phys !
                temp2 @ "SpecDef" calculate spec @ + spec !
        then
        repeat
 
        phys @ spec @ > if
        target @ "status/statmods/PhysAtk" over over get atoi 1 + setto
        else
        target @ "status/statmods/SpecAtk" over over get atoi 1 + setto
        then
then
 
target @ "ability" fget "slow start" smatch if
        target @ "status/statmods/ability/slow start" get not if
        target @ "status/statmods/ability/slow start" 1 setto
        { "^[o^[c" pos @ "." target @ id_name "^[y is having a ^[cSlow Start^[y."}cat notify_watchers
        then
then
 
target @ "ability" fget "Frisk" smatch if
        loc @ { "@battle/" BID @ "/position/" { oteam @ "1" }cat }cat getprop dup if "holding" get temp ! else 0 temp ! then
        loc @ { "@battle/" BID @ "/position/" { oteam @ "2" }cat }cat getprop dup if "holding" get temp2 ! else 0 temp2 ! then
         { "^[o^[c" pos @ "." target @ id_name "^[y used its ability ^[cFrisk^[y and found that an opponent is carrying ^[c"
        temp @ temp2 @ and if
 
                random 2 % if
                        temp @ cap
                else
                        temp2 @ cap
                then
 
        else
                temp2 @ not if
                        temp @ cap
                else
                        temp2 @ cap
                then
        then
         "^[y." }cat notify_watchers
then
 
target @ "ability" fget "Anticipation" smatch if
        target @ "status/statmods/ability/Anticipation" get not if
        0 temp5 !
                0 temp4 !
                target @ "status/statmods/ability/Anticipation" 1 setto
                { { oteam @ "1" }cat { oteam @ "2" }cat { oteam @ "3" }cat }list foreach swap pop temp !
                temp4 @ not if
                        loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop temp2 !
                        temp2 @ if
                                { temp2 @ "movesknown" fgetvals foreach pop cap
                                repeat
                                }list temp5 !
                                
                                { "Explosion" "SelfDestruct" "Horn Drill" "Guillotine" "Fissure" "Sheer Cold" }list foreach swap pop temp3 !
                                
                                temp5 @ temp3 @ array_findval array_count if
                                "OHKO found!" "Debug" pretty notify_watchers
                                temp3 @ attack_type movetype !
                                pos @ typetotalcalculate if
                                temp3 @ temp4 !
                                
                                break
                                then
                                then
                                repeat
 
                                temp4 @ not if
                                        temp2 @ "movesknown" fgetvals foreach pop cap temp3 !
                                                temp3 @ attack_type movetype !
                                                pos @ typetotalcalculate 1 - if
                                                POKEDEX { "moves/" temp3 @ "/power" }cat getprop atoi not if continue then
                                                temp3 @ temp4 !
                                                break
                                                then
                                        repeat
                                then
 
 
                        then
                then
                repeat
 
                temp4 @ if
                { "^[o^[c" pos @ "." target @ id_name "^[y realizes that one of its opponents has a dangerous move!" }cat notify_watchers
                then
        then
 
 
then
 
target @ "ability" fget "Forewarn" smatch if
        loc @ { "@battle/" BID @ "/Forewarn" }cat remove_prop
        { { oteam @ "1" }cat { oteam @ "2" }cat }list foreach swap pop temp !
                loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop temp2 !
                temp2 @ if
                temp2 @ "movesknown" fgetvals foreach pop cap temp3 !
 
                         POKEDEX { "abilities/Forewarn/AssignedBasePower/" temp3 @ }cat getprop if
                                POKEDEX { "abilities/Forewarn/AssignedBasePower/" temp3 @ }cat getprop
                         else
                                POKEDEX { "moves/" temp3 @ "/power" }cat getprop
                         then
                        temp4 @ loc @ { "@battle/" BID @ "/Forewarn/power" }cat getprop >
                        temp4 @ loc @ { "@battle/" BID @ "/Forewarn/power" }cat getprop = random 2 % and or
                        if
                        loc @ { "@battle/" BID @ "/Forewarn/power" }cat temp4 @ setprop
                        loc @ { "@battle/" BID @ "/Forewarn/move" }cat temp3 @ setprop
                        loc @ { "@battle/" BID @ "/Forewarn/target" }cat temp2 @ setprop
                        loc @ { "@battle/" BID @ "/Forewarn/pos" }cat temp @ setprop
                        then
 
                repeat
                then
        repeat
 
        loc @ { "@battle/" BID @ "/Forewarn/power" }cat getprop if
                { "^[o^[c" pos @ "." target @ id_name "^[y used its ability ^[cForewarn^[y and learned that ^[c" loc @ { "@battle/" BID @ "/Forewarn/pos" }cat getprop "." loc @ { "@battle/" BID @ "/Forewarn/target" }cat getprop id_name "'s^[y strongest move is ^[c" loc @ { "@battle/" BID @ "/Forewarn/move" }cat getprop "^[y."  }cat notify_watchers
        then
then

target @ "ability" fget "Imposter" smatch if
        { { oteam @ "1" }cat { oteam @ "2" }cat { oteam @ "3" }cat }list 4 array_sort foreach swap pop temp !
                loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop if
                                loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop temp2 !
                                
                                temp2 @ "species" fget "132" smatch not
                                temp2 @ "status/statmods/substitute" get not and
                                temp2 @ "status/statmods/illusion" get not and                                
                                
                                if
                                        (now transform)
                                        (caster target transform)
                                        target @ temp2 @ transform
                                        break
                                then
                then
        repeat
then

target @ "ability" fget "Trace" smatch if
        { { oteam @ "1" }cat { oteam @ "2" }cat { oteam @ "3" }cat }list 4 array_sort foreach swap pop temp !
                loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop if
                                loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop temp2 !
                                { "Trace" "Multitype" "Illusion" "Flower Gift" "Imposter" "Stance Change" }list temp2 @ "ability" fget array_findval array_count not if
                                
                                then
                then
        repeat
then
 
bid @ check_weather "none" smatch not if
        { "A1" "A2" "A3" "B1" "B2" "B3" }list foreach swap pop temp !
        loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop temp2 !
        temp2 @ if
                temp2 @ "ability" fget "forecast" smatch if temp2 @ forecast then
        then
        repeat
then
; PUBLIC placed_abilities

$libdef illusion (id, bid, team -> return id)
: illusion
(for illusion, save curpoke as temp and overwrite it with the illusion, replace during the status bits)
var! team
var! bid
var! curpoke
var temp2
var temp3

curpoke @ "ability" fget "illusion" smatch if
        curpoke @ "status/statmods/illusion" get not if
                loc @ { "@battle/" BID @ "/teams/" team @ }cat array_get_propvals foreach swap temp2 ! temp3 ! 
                temp2 @ atoi if (for now, don't do fusions)
                temp3 @ curpoke @ smatch if continue then
                temp3 @ "status/hp" get if curpoke @ "status/statmods/illusion" temp3 @ setto then
                then
                repeat
        then
        curpoke @ "status/statmods/illusion/broken" get not if
                curpoke @ "status/statmods/illusion" get if
                        curpoke @ "status/statmods/illusion" get curpoke !
                then
        then
then
curpoke @

; PUBLIC illusion
 
$libdef switch_handler (pos, bid, target)
: switch_handler
  var! target
  BID !
  pos !
  var beforepoke
 
  loc @ { "@battle/" BID @ "/needtoswitch" }cat remove_prop
  loc @ { "@battle/" BID @ "/Begin Position/" pos @ }cat getprop beforepoke !
  loc @ { "@battle/" BID @ "/position/" pos @ }cat target @ setprop
  beforepoke @ "battle/position" "" setto
  target @ "battle/position" pos @ setto
  target @ bid @ pos @ 1 1 midstr illusion target !
 { "^[o^[c" pos @ "." target @ id_name " ^[yis changing places with ^[c" pos @ "." beforepoke @ id_name "^[y!" }cat notify_watchers
  loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop target !
  loc @ { "@battle/" BID @ "/Begin Position/" pos @ }cat target @ setprop
  var oppteam
  pos @ "A*" smatch if
   "B" oppteam !
  else
   "A" oppteam !
  then
  (when switching, toxic is reset back to 1)
  target @ "status/toxic" get if
  target @ "status/toxic" 1 setto
  then
 
  beforepoke @ "MaxHP" calculate var! maxhp
  beforepoke @ "status/hp" get atoi var! currhp
 
  loc @ { "@battle/" BID @ "/repeats/" POS @ }cat remove_prop
  loc @ { "@battle/" BID @ "/uproar/" pos @ }cat remove_prop
  loc @ { "@battle/" BID @ "/declare/" pos @ }cat remove_prop 
  
  POKESTORE { "@pokemon/" target @ "/@RP/status/statmods" }cat remove_prop
  POKESTORE { "@pokemon/" target @ "/@temp/" }cat remove_prop
  POKESTORE { "@pokemon/" target @ "fusion" get "/@temp/" }cat remove_prop
  POKESTORE { "@pokemon/" beforepoke @ "/@temp/" }cat remove_prop
  POKESTORE { "@pokemon/" beforepoke @ "fusion" get "/@temp/" }cat remove_prop
  POKESTORE { "@pokemon/" beforepoke @ "/@RP/status/statmods" }cat remove_prop
  (natural cure for "beforepoke")
  beforepoke @ "ability" fget "natural cure" smatch 
  beforepoke @ "status/fainted" get not and
  if
  POKESTORE { "@pokemon/" beforepoke @ "/@RP/status/" }cat remove_prop
  then
  (regenerator for beforepoke)
  beforepoke @ "ability" fget "regenerator" smatch if
          beforepoke @ "status/hp" over over get atoi beforepoke @ "maxhp" calculate 3 /  + setto
          beforepoke @ "status/hp" get atoi beforepoke @ "maxhp" calculate > if
          beforepoke @ "status/hp" beforepoke @ "maxhp" calculate setto
          then
  then
 
  beforepoke @ "status/hp"
        beforepoke @ "maxhp" calculate currhp @ * maxhp @ / setto
 
 
 
  loc @ { "@battle/" BID @ "/position/" oppteam @ "1" }cat getprop if
  loc @ { "@battle/" BID @ "/Battled/Team" oppteam @ "/" loc @ { "@battle/" BID @ "/Position/" oppteam @ "1" }cat getprop "/" target @ }cat 1 setprop
  then
  loc @ { "@battle/" BID @ "/position/" oppteam @ "2" }cat getprop if
  loc @ { "@battle/" BID @ "/Battled/Team" oppteam @ "/" loc @ { "@battle/" BID @ "/Position/" oppteam @ "2" }cat getprop "/" target @ }cat 1 setprop
  then
  loc @ { "@battle/" BID @ "/lasthit/" pos @ }cat remove_prop
  loc @ { "@battle/" BID @ "/charge/" pos @ }cat remove_prop

(switch activated abilities)
pos @ bid @ placed_abilities

 
(do spikes now)
 
  loc @ { "@battle/" BID @ "/spikes/" pos @ 1 1 midstr }cat propdir?
        if
        target @ "maxhp" calculate maxhp !
        
        loc @ { "@battle/" BID @ "/spikes/" pos @ 1 1 midstr "/spikes" }cat propdir? if
        loc @ { "@battle/" BID @ "/spikes/" pos @ 1 1 midstr "/spikes/count" }cat getprop temp2 !
        (cluster for flying)
           target @ typelist "flying" array_findval array_count if 1 else 0 then
           target @ "ability" fget "levitate" smatch or
                loc @ { "@battle/"BID @ "/gravity" }cat getprop
                who @ "holding" get stringify "iron ball" smatch or not and not
                target @ "ability" fget "Magic Guard" smatch not and
           (end cluster) if
                temp2 @ 1  = if target @ "status/hp" over over get atoi maxhp @ 8 target @ "pvp/hpboost" fget dup if atoi * else pop then / - setto then
                temp2 @ 2  = if target @ "status/hp" over over get atoi maxhp @ 6 target @ "pvp/hpboost" fget dup if atoi * else pop then / - setto then
                temp2 @ 3 >= if target @ "status/hp" over over get atoi maxhp @ 4 target @ "pvp/hpboost" fget dup if atoi * else pop then / - setto then
                { "^[o^[c" target @ id_name "^[y took damage from spikes!" }cat notify_watchers
        then then
 
        loc @ { "@battle/" BID @ "/spikes/" pos @ 1 1 midstr "/toxicspikes" }cat propdir? if
 
           target @ check_status not
           target @ "ability" fget "leaf guard" smatch bid @ check_weather "sunny day" smatch and if 0 else 1 then
           target @ "status/fainted"   get not and
           startsub @ not and          
           target @ typelist "steel" array_findval array_count if 0 else 1 then and
 
           (cluster for flying)
           target @ typelist "flying" array_findval array_count if 1 else 0 then
           target @ "ability" fget "levitate" smatch or
                loc @ { "@battle/"BID @ "/gravity" }cat getprop
                who @ "holding" get stringify "iron ball" smatch or not and not
           (end cluster)
           and
           if
           target @ typelist "poison" array_findval array_count if 
                      (remove the spikes and end it)
                      { "^[o^[c" target @ id_name "^[y is a poison type! The Toxic Spikes are removed!" }cat notify_watchers
                      else
           
loc @ { "@battle/" BID @ "/shields/" pos @ 1 1 midstr "/safeguard" }cat getprop if { "^[o^[c" target @ id_name "^[y was safeguarded from the effect of the Toxic Spikes!" }cat notify_watchers
 
           else
                target @ "ability" fget "immunity" smatch not if
                loc @ { "@battle/" BID @ "/spikes/" pos @ 1 1 midstr "/toxicspikes/count" }cat getprop temp2 !
 
                temp2 @ 1  = if target @ "status/poisoned" 1 setto
                { "^[o^[c" target @ id_name "^[y is now ^[mpoisoned ^[yfrom the toxic spikes!" }cat notify_watchers
                then
                temp2 @ 2 >= if target @ "status/toxic" 1 setto
                { "^[o^[c" target @ id_name "^[y is now ^[mbadly poisoned ^[yfrom the toxic spikes!" }cat notify_watchers
                then
           then
           then
           then
           then
        then
 
        loc @ { "@battle/" BID @ "/spikes/" pos @ 1 1 midstr "/stealthrock" }cat propdir? 
        target @ "ability" fget "Magic Guard" smatch not and
        if
                1
                target @ typelist foreach swap pop
                var effect
 
                { "typetable/rock/" }cat swap strcat user @ swap get strtof effect !
                effect @ 1 + *
                repeat
                temp !
                0 temp2 !
                temp @ 0.25 = if maxhp @ 0.03125 target @ "pvp/hpboost" fget dup if atoi * else pop then * floor temp2 ! then
                temp @ 0.5  = if maxhp @ 0.0625  target @ "pvp/hpboost" fget dup if atoi * else pop then * floor temp2 ! then
                temp @ 1    = if maxhp @ 0.125   target @ "pvp/hpboost" fget dup if atoi * else pop then * floor temp2 ! then
                temp @ 2    = if maxhp @ 0.25    target @ "pvp/hpboost" fget dup if atoi * else pop then * floor temp2 ! then
                temp @ 4    = if maxhp @ 0.5     target @ "pvp/hpboost" fget dup if atoi * else pop then * floor temp2 ! then
                target @ "status/hp" over over get atoi temp2 @ - setto
                { "^[o^[c" target @ id_name "^[y took damage from rocks!" }cat notify_watchers
        then
 
        target @ "status/hp" get atoi 0 <= if
                 POKESTORE { "@pokemon/" target @ "/@RP/status" }cat remove_prop
                 target @ "status/hp" 0 setto
                 target @ "status/fainted" 1 setto
         then
  then
 
 target @ "status/fainted" get if
 { "^[o^[c" pos @ cap "." target @ id_name " ^[yFainted!!" }cat notify_watchers
 then
(end spikes)
 
(healing wish)
target @ "status/fainted" get not
loc @ { "@battle/" BID @ "/HealingWish/" pos @ }cat getprop and if
        loc @ { "@battle/" BID @ "/HealingWish/" pos @ }cat remove_prop
        POKESTORE { "@pokemon/" target @ "/@RP/status" }cat remove_prop
        target @ "status/hp" target @ "maxhp" calculate target @ "pvp/hpboost" fget dup if atoi / else pop then setto
        { "^[o^[c" target @ id_name "^[y was healed by Healing Wish!" }cat notify_watchers
then
 
(lunar dance)
target @ "status/fainted" get not
loc @ { "@battle/" BID @ "/LunarDance/" pos @ }cat getprop and if
        loc @ { "@battle/" BID @ "/LunarDance/" pos @ }cat remove_prop
        POKESTORE { "@pokemon/" target @ "/@RP/status" }cat remove_prop
        target @ "status/hp" target @ "maxhp" calculate target @ "pvp/hpboost" fget dup if atoi / else pop then setto
        target @ "movesknown" fgetvals foreach pop move !
            target @ { "movesknown/" move @ "/pp" }cat
             target @ { "moves/" move @ "/pp" }cat get
            fsetto
  repeat
        { "^[o^[c" target @ id_name "^[y was healed and had its PP restored by Lunar Dance!" }cat notify_watchers
then

  
(update recycle prop)
loc @ { "@battle/" BID @ "/recycle/" pos @ }cat target @ "holding" get setprop
; PUBLIC switch_handler
 
: forceswitch ( s - )
    var! pos
    pos @ 1 1 midstr var! team
 
    { loc @ { "@battle/" bid @ "/teams/" team @ }cat array_get_propvals foreach swap pop repeat }list
    var! choices
    ( choices is the list of pokes on your team )
 
    {
    loc @ { "@battle/" bid @ "/position/" team @ "1" }cat getprop dup not if pop then
    loc @ { "@battle/" bid @ "/position/" team @ "2" }cat getprop dup not if pop then
    }list choices @ array_diff choices !
    ( choices is now the list of pokes on your team who aren't on the field )
 
    {
    var pokeID
    choices @ foreach swap pop pokeID !
      pokeID @ "status/hp" get 
      pokeID @ "egg?" get not and
      if
        pokeID @
      then
    repeat
    }list choices !
    ( choices is now the list of pokes on your team who aren't on the field and are not fainted and not eggs)
 
    choices @ array_count not if
      ( If there are no legal targets to swap to, do something to the effect of 'You suck, it didn't work!' )
      "^[o^[yBut it failed..." notify_watchers
      exit
    then
 
    pos @ bid @
      choices @ random choices @ array_count % array_getitem
    switch_handler
 
    ;
 
 
$libdef moveswitch
: moveswitch ( AI/player, bid, user position)
 
var! pos
BID !
var! user
var controller
var id
var notvalid
var maxhp
var percent
var switchid
var trainer1
var trainer2
user @ "AI" smatch not if
 
        bid @ pos @ switch_check pop
        pos @ 1 1 midstr var! team
        loc @ { "@battle/" BID @ "/begin position/" pos @ }cat getprop switchid !
        switchid @ not if
        loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop switchid !
        then
        loc @ { "@battle/" BID @ "/control/team" team @ "/" switchid @ }cat getprop controller !
          var counter
          0 counter !
          var trainer1
          var trainer2
          var fusionnudge
 
          loc @ { "@battle/" BID @ "/teams/" team @ "/A" }cat getprop trainer1 !
          loc @ { "@battle/" BID @ "/teams/" team @ "/B" }cat getprop trainer2 !
 
          trainer1 @ if 1 fusionnudge ! then
          trainer2 @ if fusionnudge @ 1 + fusionnudge !
          then
 
          var othercont
          controller @ { "^[y^[oSwitching for ^[c" switchid @ id_name }cat notify
          controller @ { "^[y^[o------------------------------------------------------------------------" }cat notify
          bid @ pos @ switch_check pop
          1 loc @ { "@battle/" BID @ "/teams/" team @ "/" }cat array_get_propvals  array_count 1 for id !
 
          id @ fusionnudge @ - id !
 
          id @ 1 < if
                  trainer1 @ if
                          0 trainer1 !
                          "A" id !
                  else
                          "B" id !
                  then
          then
                id @ counter !
                loc @ { "@battle/" BID @ "/teams/" team @ "/" id @ }cat getprop id !
          loc @ { "@battle/" BID @ "/temp/validstats/" team @ "/" id @ }cat getprop notvalid !
          controller @
           { "^[y^[o" counter @ ". "
           id @ id_name 12 " " padr
           id @ { "/pokemon/" id @ "species" fget "/name" }cat fget dup not if pop "??????????" then 15 " " padr
           " "
           "^[yLv "
           id @ FindPokeLevel intostr 3 " " padr
           " "
           id @ "egg?" get if
                   "^[o^[w?"
           else
                   id @ "gender" fget "M*" smatch if
                   "^[o^[c" { id @ "gender" fget 1 1 midstr }cat
                   then

                   id @ "gender" fget "F*" smatch if
                   "^[o^[r" { id @ "gender" fget 1 1 midstr }cat
                   then

                   id @ "gender" fget "N*" smatch if
                   "^[o^[m" { id @ "gender" fget 1 1 midstr }cat
                   then
           then
           " "
           var hpcolor
 
           id @ "MaxHP"   Calculate maxhp !
 
               id @ "status/hp" get atoi 100 * maxhp @ / percent !
 
               percent @ 51 >= if "^[O^[g" hpcolor ! then
               percent @ 50 <= percent @ 26 >= and if "^[O^[y" hpcolor ! then
               percent @ 25 <= if "^[O^[r" hpcolor ! then
           hpcolor @
           id @ "status/hp" get dup not if pop "0" then 3 " " padl
           "^[x^[o/" hpcolor @
           maxhp @ intostr 3 " " padl
           "  "
           percent @ intostr 3 " " padl
           "%"
 
           notvalid @ 1 = if
           " ^[y<On Field>"
           then
 
           notvalid @ 2 = if
           " ^[y<To be switched>"
           then
 
           notvalid @ 3 = if
           " ^[r<Fainted>"
           then
           
           notvalid @ 4 = if
           " ^[y<Egg>"
           then
           
           loc @ { "@Battle/" BID @ "/control/team" team @ "/" id @ }cat getprop othercont !
           othercont @ controller @ = not if
           { "  ^[g<" othercont @ name ">" }cat
           then
 
           }cat notify
           repeat
           controller @ { "^[y^[o------------------------------------------------------------------------" }cat notify
 
           var choice
           begin
           controller @ "^[o^[rSwitch with whom?" "Battle" pretty notify
           read choice !
                choice @ strip arg !
 
                choice @ "A" smatch
                choice @ "B" smatch or not if
                choice @ atoi arg ! then
 
                choice @ not if
           controller @ "^[o^[rInvalid pokemon position." "Battle" pretty notify
           continue
           then
 
           loc @ { "@battle/" BID @ "/teams/" team @ "/" choice @ }cat getprop not if
           controller @ "^[o^[rThere isn't a pokemon there." "Battle" pretty notify
           continue then
           var cid
           loc @ { "@battle/" BID @ "/teams/" team @ "/" choice @ }cat getprop cid !
           loc @ { "@battle/" BID @ "/temp/validstats/" team @ "/" cid @ }cat getprop if
           controller @ "^[o^[rYou can't switch with that pokemon at this time" "Battle" pretty notify
           continue then
 
                Pos @ BID @ cid @ switch_handler
               break
               repeat
               else
               (for AI)
               loc @ { "@battle/" BID @ "/AItype" }cat getprop "wild" smatch if
                pos @ forceswitch  (wilds arn't smart about how they switch, so leave it like this)
 
                else
 
                pos @ BID @
                pos @ BID @ AI_switch
                switch_handler
 
               then
               then
 loc @ { "@battle/" BID @ "/needtoswitch" }cat remove_prop
; PUBLIC moveswitch
 
 
$libdef batonpass
: batonpass
var! pos
bid !
var! user
var caster
loc @ { "@battle/" BID @ "/Position/" pos @ }cat getprop caster !
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ }cat remove_prop
 
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/PhysAtk" }cat caster @ "status/statmods/PhysAtk" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/PhysDef" }cat caster @ "status/statmods/PhysDef" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/SpecAtk" }cat caster @ "status/statmods/SpecAtk" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/SpecDef" }cat caster @ "status/statmods/SpecDef" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/Speed" }cat caster @ "status/statmods/Speed" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/substitute" }cat caster @ "status/statmods/substitute" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/block/move" }cat caster @ "status/statmods/block/move" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/block/user" }cat caster @ "status/statmods/block/user" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/block/userposition" }cat caster @ "status/statmods/block/userposition" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/healovertime/move" }cat caster @ "status/statmods/healovertime/move" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/ingrain/move" }cat caster @ "status/statmods/ingrain/move" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/confused" }cat caster @ "status/statmods/confused" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/A1/user" }cat  caster @ "status/statmods/lock-on/A1/user" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/A1/count" }cat caster @ "status/statmods/lock-on/A1/count" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/A2/user" }cat caster @ "status/statmods/lock-on/A2/user" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/A2/count" }cat caster @ "status/statmods/lock-on/A2/count" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/B1/user" }cat caster @ "status/statmods/lock-on/B1/user" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/B1/count" }cat caster @ "status/statmods/lock-on/B1/count" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/B2/user" }cat caster @ "status/statmods/lock-on/B2/user" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/B2/count" }cat caster @ "status/statmods/lock-on/B2/count" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/embargo" }cat caster @ "status/statmods/embargo" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/abilityremoved" }cat caster @ "status/statmods/abilityremoved" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/perishsong" }cat caster @ "status/statmods/perishsong" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/freehit/caster" }cat caster @ "status/statmods/freehit/caster" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/freehit/count" }cat caster @ "status/statmods/freehit/count" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/accuracy" }cat caster @ "status/statmods/accuracy" get setprop
                loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/evasion" }cat caster @ "status/statmods/evasion" get setprop
                user @ bid @ pos @ moveswitch
                (now copy over all the effects)
                var afterswitch
                loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop afterswitch !
                afterswitch @ "status/statmods/PhysAtk" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/PhysAtk" }cat getprop setto
                afterswitch @ "status/statmods/PhysDef" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/PhysDef" }cat getprop setto
                afterswitch @ "status/statmods/SpecAtk" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/SpecAtk" }cat getprop setto
                afterswitch @ "status/statmods/SpecDef" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/SpecDef" }cat getprop setto
                afterswitch @ "status/statmods/Speed" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/Speed" }cat getprop setto
                afterswitch @ "status/statmods/substitute" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/substitute" }cat getprop setto
                afterswitch @ "status/statmods/block/move" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/block/move" }cat getprop setto
                afterswitch @ "status/statmods/block/user" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/block/user" }cat getprop setto
                afterswitch @ "status/statmods/block/userposition" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/block/userposition" }cat getprop setto
                afterswitch @ "status/statmods/healovertime/move" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/healovertime/move" }cat getprop setto
                afterswitch @ "status/statmods/ingrain/move" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/ingrain/move" }cat getprop setto
                afterswitch @ "status/statmods/confused" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/confused" }cat getprop setto
                afterswitch @ "status/statmods/lock-on/A1/user"  loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/A1/user" }cat getprop setto
                afterswitch @ "status/statmods/lock-on/A1/count" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/A1/count" }cat getprop setto
                afterswitch @ "status/statmods/lock-on/A2/user"  loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/A2/user" }cat getprop setto
                afterswitch @ "status/statmods/lock-on/A2/count" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/A2/count" }cat getprop setto
                afterswitch @ "status/statmods/lock-on/B1/user"  loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/B1/user" }cat getprop setto
                afterswitch @ "status/statmods/lock-on/B1/count" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/B1/count" }cat getprop setto
                afterswitch @ "status/statmods/lock-on/B2/user"  loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/B2/user" }cat getprop setto
                afterswitch @ "status/statmods/lock-on/B2/count" loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/lock-on/B2/count" }cat getprop setto
                afterswitch @ "status/statmods/embargo"          loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/embargo" }cat getprop setto
                afterswitch @ "status/statmods/abilityremoved"   loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/abilityremoved" }cat getprop setto
                afterswitch @ "status/statmods/perishsong"       loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/perishsong" }cat getprop setto
                afterswitch @ "status/statmods/freehit/caster"   loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/freehit/caster" }cat getprop setto
                afterswitch @ "status/statmods/freehit/count"    loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/freehit/count" }cat getprop setto
                afterswitch @ "status/statmods/accuracy"         loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/accuracy"}cat getprop setto
                afterswitch @ "status/statmods/evasion"          loc @ { "@battle/" BID @ "/temp/pass/" pos @ "/status/statmods/evasion"}cat getprop setto
                afterswitch @ "status/statmods/abilityremoved" get if
                POKESTORE { "@pokemon/" afterswitch @ fid "/@temp/ability" }Cat "Disabled" setprop
                then
; PUBLIC batonpass

: findrank (search the speed ranks and find the rank of the POS)
var! posid
var counter
1 loc @ { "@battle/" bid @ "/speed/rank/" }cat array_get_propvals array_count 1 for counter !
        loc @ { "@battle/" BID @ "/speed/rank/" counter @ }cat getprop posid @ smatch if break then
repeat
counter @
;

: rankchange (take the position rank and place it in a new position, Shifting everything above the value up and everything below down)

var! newindex
var! oldindex


loc @ { "@battle/" bid @ "/speed/rank/" oldindex @ }cat getprop var! olddata

1 var! count
var data
var index
loc @ { "@battle/" bid @ "/speed/rank/"}cat array_get_propvals foreach data ! atoi index ! 
        index @ oldindex @ = if continue then
        
        index @ newindex @ = if 
        loc @ { "@battle/" bid @ "/speed/rank/" count @ }cat olddata @ setprop
        count ++
        then
        loc @ { "@battle/" bid @ "/speed/rank/" count @ }cat data @ setprop
        count ++
repeat
; 

: variable_attack
var! basepower
var dam
(return what ever basepower will be)
(what this does is take the name of the move then does the math required.  Just return the number of the basepower.  If it fails, return -1 so the system can exit itself without borking)

move @ "beat up" smatch if

        loc @ { "@battle/" BID @ "/temp/beatup/" pos @  1 1 midstr "/" turncount @ }cat getprop

exit
then

move @ "round" smatch if
        loc @ { "@battle/" BID @ "/temp/round_boost/" pos @ }cat getprop if basepower @ 2 * basepower ! then
        basepower @
exit
then

move @ "Electro Ball" smatch if
        who @ "speed" calculate temp !
        attacker @ "speed" calculate temp2 !
        temp2 @ temp @ 1.0 * / temp3 !
        
        temp3 @ 2 <= if
        60 exit then
        
        temp3 @ 3 <= if
        80 exit then
        
        temp3 @ 4 <= if
        120 exit then
        
        150 exit
        
then

move @ "Venoshock" smatch if
        who @ "status/posioned" get 
        who @ "status/tocix" get or if
        130
        else
        65
        then
exit
then

move @ "Stored Power" smatch if
        20
        0
        { "PhysAtk" "PhysDef" "SpecAtk" "SpecDef" "Speed" "Accuracy" "Evasion" }list foreach swap pop temp !
        attacker @ { "status/statmods/" temp @ }Cat get atoi dup 0 > if + else pop then
        repeat
        20 * +
        
exit
then

move @ "low kick" smatch move @ "grass knot" smatch or if
 who @ weightcalc var! weight
 
 weight @ 22.0 <= if
 20 exit then
 weight @ 55.0 <= if
 40 exit then
 weight @ 110.0 <= if
 60 exit then
 weight @ 220.0 <= if
 80 exit then
 weight @ 440.0 <= if
 100 exit then
 120 exit
then

move @ "Heat Crash" smatch move @ "Heavy Slam" smatch or if
        who @ weightcalc temp !
        attacker @ weightcalc temp2 !
        temp2 @ temp @ 1.0 * / temp3 !
        
                temp3 @ 2 <= if
                40 exit then
                
                temp3 @ 3 <= if
                60 exit then
                
                temp3 @ 4 <= if
                80 exit then
                
                temp3 @ 5 <= if
                100 exit then
                
                150 exit
then

 
move @ "spit up" smatch if
attacker @ "status/statmods/stockpile" get atoi stockpile !
stockpile @ 1 = if 100 exit then
stockpile @ 2 = if 200 exit then
stockpile @ 3 = if 300 exit then
 
-1
exit
then
 
move @ "assurance" smatch if
 loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn/" tpos @ }cat getprop if
 100
 exit
 else
 50
 exit
 then
then

move @ "Retaliate" smatch if
loc @ { "@battle/" BID @ "/faint turns/" pos @ 1 1 midstr "/" loc @ { "@battle/" BID @ "/turn" }cat getprop 1 - }cat getprop if
140
else
70
then

exit then
 
move @ "present" smatch if
random 10 % 1 + temp !
temp @ 1  = if 120 exit then
temp @ 3 <= if 1 80 heal ! exit then
temp @ 6 <= if 80 exit then
40
exit
then
 
move @ "payback" smatch if
loc @ { "@Battle/" BID @ "/declare/finished/" tpos @ }cat getprop 
        loc @ { "@battle/" BID @ "/declare/" tpos @ }cat getprop dup not if pop " " then "item*" smatch not and
        if
100
else
50
then
exit
then
 
move @ "avalanche" smatch
move @ "revenge" smatch or
if
 loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn/" pos @ }cat getprop if
 120
 exit
 else
 60
 exit
 then
then
 
move @ "reversal" smatch if
 attacker @ "MaxHP"   Calculate var! maxhp
 attacker @ "status/hp" get atoi var! hp
 var temp
 hp @ 1.0 * maxhp @ / 64 * floor temp !
 temp @ 43 >= if  20 exit then
 temp @ 23 >= if  40 exit then
 temp @ 13 >= if  80 exit then
 temp @  6 >= if 100 exit then
 temp @  2 >= if 150 exit then
 200
exit
then
 
move @ "solarbeam" smatch if
 
        weather @ "Rain Dance" smatch
        weather @ "hail" smatch or
        weather @ "sandstorm" smatch or if
        basepower @ 2 / exit
        else
        basepower @ exit
        then
then
 
move @ "wring out" smatch if
        who @ "status/hp" get atoi who @ "maxhp" calculate 1.0 * / 120 * floor basepower !
        basepower @ not if 1 exit else basepower @ exit then
then
 
move @ "gyro ball" smatch if
        who @ "Speed" calculate temp !
        POKEDEX { "items/" who @ "holding" get "/halfSpeed" }cat getprop if
        temp @ 2 / temp !
        then
        who @ "ability" fget "slow start" smatch if
                who @ "status/statmods/ability/slow start" get atoi  5 > not if
                temp @ 0.5 * floor temp !
                then
        then
 
        who @ "ability" fget "quick feet" smatch
        who @ check_status and if
        temp @ 1.5 * floor temp !
        ( temp @ 999 > if 999 temp ! then )
        then
 
        who @ "ability" fget "unburden" smatch
        who @ "holding" get "nothing" smatch and
        who @ "Ability" fget "Chlorophyll" smatch
        bid @ check_weather "sunny day" smatch and or
        who @ "Ability" fget "Swift Swim" smatch
        bid @ check_weather "rain dance" smatch and or
        who @ "ability" fget "Sand Rush" smatch
        bid @ check_weather "sandstorm" smatch and or
        if
        temp @ 2 * temp !
        ( temp @ 999 > if 999 temp ! then )
 
        then
        loc @ { "@battle/" BID @ "/tailwind/" tpos @ 1 1 midstr }cat getprop if
        temp @ 2 * temp !
        ( temp @ 999 > if 999 temp ! then )
        then
 
        temp @
        25 *
        attacker @ "Speed" calculate temp2 !
        POKEDEX { "items/" attacker @ "holding" get "/halfSpeed" }cat getprop if
        temp2 @ 2 / temp2 !
        then
 
        attacker @ "ability" fget "slow start" smatch if
                attacker @ "status/statmods/ability/slow start" get atoi 5 > not if
                temp2 @ 0.5 * floor temp2 !
                then
        then
 
        attacker @ "ability" fget "quick feet" smatch
        attacker @ check_status and if
        temp2 @ 1.5 * floor temp2 !
        ( temp2 @ 999 > if 999 temp2 ! then )
        then
 
        attacker @ "Ability" fget "unburden" smatch
        attacker @ "holding" get "nothing" smatch and
        attacker @ "Ability" fget "Chlorophyll" smatch
        bid @ check_weather "sunny day" smatch and or
        attacker @ "ability" fget "swift swim" smatch
        bid @ check_weather "rain dance" smatch and or
        if
        temp2 @ 2 * temp2 !
        ( temp2 @ 999 > if 999 temp2 ! then )
 
        then
        loc @ { "@battle/" BID @ "/tailwind/" pos @ 1 1 midstr }cat getprop if
        temp2 @ 2 * temp2 !
        ( temp2 @ 999 > if 999 temp2 ! then)
        then
 
        temp2 @
        1.0 * / floor 1 + basepower !
        basepower @ 150 > if 150 exit else basepower @ exit then
then
 
move @ "hidden power" smatch if
60
(Old way down here)
(
 who @ "hiddenpowerbasepower" get dup if exit else pop then
 var ivs
 
 attacker @ "IVs" get ivs !
 {
  ivs @  4 1 midstr
  ivs @  9 1 midstr
  ivs @ 14 1 midstr
  ivs @ 19 1 midstr
  ivs @ 24 1 midstr
  ivs @ 29 1 midstr
 }cat bindec 40 * 63 / 30 +
 )
 exit
then
 
move @ "brine" smatch if
 who @ "MaxHP"   Calculate var! maxhp
 who @ "status/hp" get atoi var! hp
 hp @ maxhp @ 2 / <= if
 130 exit else 65 exit then
then
 
move @ "crush grip" smatch if
 who @ "MaxHP"   Calculate var! maxhp
 who @ "status/hp" get atoi var! hp
 120.0 hp @ * maxhp @ / floor 1 +
 exit
then
 
move @ "eruption" smatch
move @ "water spout" smatch or
if
 attacker @ "MaxHP"   Calculate var! maxhp
 attacker @ "status/hp" get atoi var! hp
 150 hp @ * maxhp @ /
 exit
then
 
move @ "facade" smatch if
 attacker @ "status/paralyzed" get
 attacker @ "status/poisoned" get or
 attacker @ "status/burned" get or 
 attacker @ "status/toxic" get or if
 140 exit else 70 exit then
then
 
move @ "wake-up slap" smatch if
who @ "status/asleep" get if
        120 exit
        else
        60
        exit
        then
then
 
move @ "SmellingSalt" smatch if
who @ "status/paralyzed" get if
        120 exit
        else
        60
        exit
        then
then
 
move @ "flail" smatch if
 attacker @ "MaxHP"   Calculate var! maxhp
 attacker @ "status/hp" get atoi var! hp
 hp @ 64 * maxhp @ / var! cp
 
 cp @ 1  <= if 200 exit then
 cp @ 5  <= if 150 exit then
 cp @ 12 <= if 100 exit then
 cp @ 21 <= if  80 exit then
 cp @ 42 <= if  40 exit then
 cp @ 64 <= if  20 exit then
 
then
 
move @ "fling" smatch if
attacker @ "ability" fget "klutz" smatch if -1 exit then
var item
   attacker @ "holding" get item !
   item @ stringify "Nothing" smatch if
   -1 exit
   then
   attacker @ "status/statmods/embargo" get 
   loc @ { "@battle/" BID @ "/MagicRoom" }cat getprop or
   if
   -1 exit
   then
   POKEDEX { "/items/" item @ "/fling" }cat getprop atoi exit
then
 
move @ "frustration" smatch if
 attacker @ "happiness" fget atoi var! happy
 ({ "^[o^[g Happiness: ^[w" happy @ }cat "Debug" pretty notify_watchers )
 255 happy @ - 2.5 / floor dam !
 dam @ not if 1 else dam @ then exit
 
then
 
move @ "return" smatch if
 attacker @ "happiness" fget atoi var! happy
 ({ "^[o^[g Happiness: ^[w" happy @ }cat "Debug" pretty notify_watchers)
  happy @ 2.5 / floor  dam !
 dam @ not if 1 else dam @ then exit
then
 
move @ "pursuit" smatch if
 loc @ { "@battle/" bid @ "/declare/" TPOS @ }cat getprop if
 loc @ { "@battle/" bid @ "/declare/" TPOS @ }cat getprop " " split pop "switch" smatch if
 80
 loc @ { "@battle/" bid @ "/pursuit/" pos @ }cat tpos @ setprop
 exit else 40 exit then
 else
 40 exit then
then
 
move @ "fury cutter" smatch if
 
 attacker @ "status/statmods/movecontinued/times" get atoi var! counter
 counter @ not if 1 counter ! then
 5 dam !
 1 counter @ 1 for pop
 dam @ dam @ + dam !
 dam @ 160 > if 160 dam ! break then
 repeat
 dam @ exit
then

move @ "Hex" smatch if
who @ check_status if 100 else 50 then
exit 
then

move @ "Fusion Bolt" smatch if
loc @ { "@battle/" BID @ "/tempvalues/Fusion Bolt/" pos @ 1 1 midstr "/last use" }cat loc @ { "@battle/" BID @ "/turn" }cat getprop setprop
loc @ { "@battle/" BID @ "/tempvalues/Fusion Flare/" pos @ 1 1 midstr "/last use" }cat getprop if
        loc @ { "@battle/" BID @ "/turn" }cat getprop 
        loc @ { "@battle/" BID @ "/tempvalues/Fusion Flare/" pos @ 1 1 midstr "/last use" }cat getprop
        = if
        200
        else
        100
        then
else
100
then

exit
then

move @ "Fusion Flare" smatch if
loc @ { "@battle/" BID @ "/tempvalues/Fusion Flare/" pos @ 1 1 midstr "/last use" }cat loc @ { "@battle/" BID @ "/turn" }cat getprop setprop
loc @ { "@battle/" BID @ "/tempvalues/Fusion Bolt/" pos @ 1 1 midstr "/last use" }cat getprop if
        loc @ { "@battle/" BID @ "/turn" }cat getprop 
        loc @ { "@battle/" BID @ "/tempvalues/Fusion Bolt/" pos @ 1 1 midstr "/last use" }cat getprop
        = if
        200
        else
        100
        then
else
100
then

exit
then

move @ "Echoed voice" smatch if
loc @ { "@battle/" BID @ "/tempvalues/Echoed Voice/" pos @ 1 1 midstr "/last use" }cat getprop if
        loc @ { "@battle/" BID @ "/turn" }cat getprop 
        loc @ { "@battle/" BID @ "/tempvalues/Echoed Voice/" pos @ 1 1 midstr "/last use" }cat getprop
        - 1 > if 1 else loc @ { "@battle/" BID @ "/tempvalues/Echoed Voice/" pos @ 1 1 midstr "/uses" }cat getprop then
else
loc @ { "@battle/" BID @ "/tempvalues/Echoed Voice/" pos @ 1 1 midstr }cat remove_prop
1
then
 40 * temp !
 loc @ { "@battle/" BID @ "/tempvalues/Echoed Voice/" pos @ 1 1 midstr "/last use" }cat loc @ { "@battle/" BID @ "/turn" }cat getprop setprop
 loc @ { "@battle/" BID @ "/tempvalues/Echoed Voice/" pos @ 1 1 midstr "/uses" }cat over over getprop 1 + setprop
 temp @ 200 > if 200 temp ! then temp @
exit
then
 
move @ "ice ball" smatch move @ "rollout" smatch or if
 attacker @ "status/statmods/SuccessfulMoves/Defense Curl" get if 30 else 15 then dam !
 attacker @ "status/statmods/movecontinued/times" get atoi var! counter
 
 counter @ 5 > if
 1 counter !
 attacker @ "status/statmods/movecontinued/times" 1 setto
 then
 1 counter @ 1 for pop
 dam @ dam @ + dam !
 repeat
 dam @ exit
then
 
move @ "trump card" smatch if
var pp
attacker @  { "movesknown/" move @ "/pp" }cat fget atoi pp !
pp @ 4 >= if  40 exit then
pp @ 3  = if  50 exit then
pp @ 2  = if  60 exit then
pp @ 1  = if  80 exit then
pp @ 0  = if 200 exit then
exit
then
 
 
move @ "Magnitude" smatch if
var randomval
        loc @ { "@battle/" BID @ "/tempvalues/storedtemp/" pos @ "/magnitude" }cat getprop not if
        frand randomval !
        loc @ { "@battle/" BID @ "/tempvalues/storedtemp/" pos @ "/magnitude" }cat randomval @ setprop
        else
        loc @ { "@battle/" BID @ "/tempvalues/storedtemp/" pos @ "/magnitude" }cat getprop randomval !
        then
        randomval @  0.05 <= if  { "^[y^[oMagnitude 4!" }cat notify_watchers 10 exit then
        randomval @  0.15 <= if  { "^[y^[oMagnitude 5!" }cat notify_watchers 30 exit then
        randomval @  0.35 <= if  { "^[y^[oMagnitude 6!" }cat notify_watchers 50 exit then
        randomval @  0.65 <= if  { "^[y^[oMagnitude 7!" }cat notify_watchers 70 exit then
        randomval @  0.85 <= if  { "^[y^[oMagnitude 8!" }cat notify_watchers 90 exit then
        randomval @  0.95 <= if  { "^[y^[oMagnitude 9!" }cat notify_watchers 110 exit then
        randomval @  0.95 >  if  { "^[y^[oMagnitude 10!" }cat notify_watchers 150 exit then
 
        exit
then
 
move @ "weather ball" smatch if
        weather @ "none" smatch not if
        100 exit
        then
        basepower @
exit
then
 
move @ "punishment" smatch if
        0 temp2 !
        { "PhysAtk" "PhysDef" "SpecAtk" "SpecDef" "Speed" }list foreach swap pop temp !
        who @ { "status/statmods/" temp @ }cat get atoi dup 0 > if temp2 @ + temp2 ! else pop then
        repeat
        basepower @ temp2 @ 20 * + basepower !
        basepower @ 200 > if 200 basepower ! then
        basepower @
exit
then
 
move @ "natural gift" smatch if
        pos @ attacker @ can_use_hold_item
        if
                -1 (-1 is fail) exit then
                
        POKEDEX { "items/" attacker @ "holding" get "/NaturalGift" }cat getprop if
        POKEDEX { "items/" attacker @ "holding" get "/NaturalGift" }cat getprop
        "-" explode pop
        atoi basepower !
        pop
        basepower @
        else
        -1
        then
exit
then

move @ "Acrobatics" smatch if
        attacker @ "holding" get "Nothing" smatch if 110 else 55 then
exit
then
 
basepower @ (use this if it never changes)
;
 

 
 
 
$libdef confusion_damage
: confusion_damage
cap pos ! BID ! attacker !
 
attacker @ user !
var beforestockpile
var defstat

loc @ { "@battle/" BID @ "/wonderroom" }cat getprop if
        "SpecDef" 
else
        "PhysDef"
then
defstat !

user @ { "status/statmods/" Defstat @ }cat get atoi beforestockpile !
user @ { "status/statmods/" Defstat @ }cat over over get atoi user @ "status/statmods/stockpile" get atoi + setto
user @ "ability" fget "unaware" smatch if
        user @ "status/statmods/PhysAtk" get atoi dup temp ! 0 > if user @ "status/statmods/PhysAtk" 0 setto then
        user @ "PhysAtk" Calculate attack !
        user @ "status/statmods/PhysAtk" temp @ setto
else
        user @ "PhysAtk" Calculate attack !
then
        user @ "ability" fget "slow start" smatch if
                        user @ "status/statmods/ability/slow start" get atoi 5 > not if
                        Attack @ 0.5 * floor Attack !
                        then
        then
        
        pos @ "Flower Gift" bid @ team_ability if
                attack @ 1.5 * floor attack !
                then
 
                user @ "ability" fget "Huge power" smatch
                user @ "Ability" fget "pure power" smatch or
                if
                attack @ 2 * attack !
        then
        user @ "ability" fget "Huge power" smatch
                user @ "Ability" fget "pure power" smatch or
                if
                Attack @ 2 * Attack !
                then
         
                user @ "ability" fget "hustle" smatch if
                Attack @ 1.5 * floor Attack !
        then
       user @ "ability" fget "guts" smatch if
                user @ check_status if
                attack @ 1.5 * floor attack !
                then
       then
 
user @ Defstat @ Calculate defense !
        Defstat @ "Physdef" smatch if
        user @ "ability" fget "marvel scale" smatch if
                user @ check_status if
                defense @ 1.5 * floor defense !
                then
        then
        else
                tpos @ "Flower Gift" bid @ team_ability
                user @ moldbreaker
                if
                        defense @ 1.5 * floor defense !
                then
                who @ typelist "rock" array_findval array_count
                        bid @ check_weather "sandstorm" smatch and
                        if
                                defense @ 1.5 * floor defense !
        then
        then

        
        
user @ { "status/statmods/" Defstat @ }cat beforestockpile @ setto
var level
 
 
user @ FindPokeLevel level !
 
level @ 2 * 5 / 2 + 40 * attack @ * 50 / defense @ / 2 + random 16 % 85 + * 100 / floor damage !
 
loc @ { "@battle/" BID @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
tempref @ awake? not if continue then
tempref @ location loc @ = not if continue then
 
tempref @ { "^[o^[c" pos @ "." attacker @ id_name "^[y hurt itself in its confusion!" }cat notify repeat
 
user @ "status/statmods/substitute" get if
damage @ substitute_damage
else
user @ "status/hp" over over get atoi damage @ - setto
user @ "status/hp" get atoi 0 <= if
POKESTORE { "@pokemon/" user @ "/@RP/status" }cat remove_prop
user @ "status/hp" 0 setto
user @ "status/fainted" 1 setto
 { "^[o^[c" pos @ cap "." user @ id_name " ^[yFainted!!" }cat bid @ notify_watchers
                                    user @ "happiness" over over fget atoi 1 - fsetto
                user @ "happiness" over over fget atoi 0 < if 0 fsetto else pop pop then
loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn/" pos @ }cat 1 setprop
then then
 
 
 
; PUBLIC confusion_damage
 
 
: effects
 
POKEDEX { "moves/" move @ "/effects" }cat getprop if  (if there is an effect prop)
 
  POKEDEX { "moves/" move @ "/effects" }cat getprop ":" explode_array var! effectlist
 
  var percent
  var target
  var targettype
  var effect
  var nestedeffects
  var tempeffect
  var oldval
  var position
  var tposition
  var positionteam
  var caster
 
  effectlist @ foreach
     "/" explode pop
     effect !
     targettype !
     atoi percent !
     pop
     (do percentage abilities)
     user @ "ability" fget "Serene Grace" smatch
     loc @ { "@battle/" BID @ "/pledge field/" pos @ 1 1 midstr "/move" }cat getprop dup if "water pledge" smatch or else pop then
     POKEDEX { "moves/" move @ "/power" }cat getprop atoi and
     if
     percent @ 2 * percent ! then
 
     targettype @ "self" smatch not
     who @ "ability" fget "Shield Dust" smatch
     POKEDEX { "moves/" move @ "/power" }cat getprop atoi and and
     user @ moldbreaker
     if
     0 percent ! then
 
     (abilities end)
 
     (deal with percent first, if it doesn't make it, no point in finishing)
     random 100 % 1 + percent @ <= not if continue then
 
     var temp
     (target finder)
 
     targettype @ "self" smatch if
     user @ target !
     user @ caster !
     pos @ position !
     tpos @ tposition !
     pos @ 1 1 midstr positionteam !
     else
 
     who @ target !
     user @ caster !
     tpos @ position !
     pos @ tposition !
     tpos @ 1 1 midstr positionteam !
 then
     (check for snatch)
     POKEDEX { "moves/" move @ "/snatch?" }cat getprop loc @ { "@battle/" BID @ "/snatch/" positionteam @ "/caster" }cat getprop and if
     loc @ { "@battle/" BID @ "/snatch/" positionteam @ "/snatched" }cat getprop not
     loc @ { "@battle/" BID @ "/snatch/" positionteam @ "/snatched" }cat getprop stringify pos @ smatch or if
     loc @ { "@battle/" BID @ "/snatch/" positionteam @ "/pos" }cat getprop temp !
     loc @ { "@battle/" BID @ "/snatch/" positionteam @ "/caster" }cat getprop temp2 !
     loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop stringify temp2 @ stringify smatch if
     loc @ { "@battle/" BID @ "/snatch/" positionteam @ "/snatched" }cat getprop not if
     { "^[o^[c" temp @ "." temp2 @ id_name "^[y snatched the move!" }cat notify_watchers
     loc @ { "@battle/" BID @ "/snatch/" positionteam @ "/snatched" }cat pos @ setprop
     then
 
     temp2 @ target !
     temp2 @ caster !
     position @ tposition !
     temp @ position !
 
     temp @ 1 1 midstr positionteam !
 
     then
     then
     then
        (do magic coat)
        loc @ { "@battle/" bid @ "/magic coat/" tpos @ }cat getprop 
        who @ "ability" fget "Magic bounce" smatch 
        caster @ moldbreaker 
        or
        POKEDEX { "moves/" move @ "/reflectable" }cat getprop and
        if
                who @ caster !
                user @ target !
                pos @ position !
                pos @ 1 1 midstr positionteam !
                who @ "ability" fget "Magic Bounce" smatch if
                "^[o^[cMagic Bounce^[y reflected the effect!" notify_watchers
                else
                "^[o^[cMagic Coat^[y reflected the effect!" notify_watchers
                then
        then
        (end magic coat)
     effect @ "," explode_array nestedeffects !
     nestedeffects @ foreach effect ! pop
 
 POKEDEX { "moves/" move @ "/sub-ignore" }cat getprop not if
        target @ "status/statmods/substitute" get 
        targettype @ "self" smatch not and
        if
        continue
        then
 
 then
        (sheer force)
        targettype @ "self" smatch not who @ "ability" fget "Sheer Force"  smatch and POKEDEX { "move/" move @ "/power" }cat getprop and if continue then

        effect @ "secretpower" smatch if
                loc @ "@locationtype" getprop temp !
                temp @ not if
                "other" temp !
                then
                begin
 
                temp @ "Snow" smatch if
                "Frozen" effect !
                break
                then
 
                temp @ "Water" smatch if
                "PhysAtk-1" effect !
                break
                then
 
                temp @ "Grass" smatch if
                "asleep" effect !
                break
                then
 
                temp @ "Rock" smatch if
                "Flinch" effect !
                break
                then
 
                temp @ "Sand" smatch if
                "Accuracy-1" effect !
                break
                then
 
                temp @ "Building" smatch if
                "Paralyzed" effect !
                break
                then
 
                temp @ "Path" smatch if
                "Paralyzed" effect !
                break
                then
 
                "Paralyzed" effect !
                break repeat
        (don't continue, so you can just use the effects in place)
 
        then
        
        effect @ "ClearSmog" smatch if
                startsub @ if continue then
                { "PhysAtk" "PhysDef" "Speed" "SpecAtk" "SpecDef" "Accuracy" "Evasion" }list foreach swap pop temp3 !
                        target @ { "status/statmods/" temp3 @ }cat 0 setto
                repeat
                { "^[o^[c" target @ id_name "^[y had all of their stat mods cleared!" }cat notify_watchers
        
        continue then
       effect @ "autotomize" smatch if
       target @ "status/statmods/autotomize" get if continue then
       
       target @ "status/statmods/autotomize" 1 setto
       { "^[o^[c" target @ id_name "^[y became nimble!" }cat notify_watchers
       continue then
       
       effect @ "Incinerate" smatch if
       
       target @ "holding" get "*berry" smatch if
       { "^[o^[c" target @ id_name "'s " target @ "holding" get "^[y has been incinerated!" }cat notify_watchers
       POKESTORE { "@pokemon/" target @ "/@long/holding" }cat "Nothing" setprop
       
       then
       
       continue then
       
       effect @ "attracted" smatch if
       0 tempeffect !
        target @ "status/statmods/attracted" get if continue then
         caster @ "gender" fget "male" smatch if
           target @ "gender" fget "female" smatch if
           1 tempeffect !
           then then
         caster @ "gender" fget "female" smatch if
                  target @ "gender" fget "male" smatch if
                  1 tempeffect !
           then then
 
         tempeffect @ if
         target @ "ability" fget "Oblivious" smatch
         caster @ moldbreaker
         not if
         target @ "status/statmods/attracted" caster @ setto
 
         { "^[o^[c" target @ id_name "^[y is now attracted!" }cat notify_watchers
         target @ "holding" get "Destiny Knot" smatch if
         caster @ "status/statmods/attracted" target @ setto
         { "^[o^[c" caster @ id_name "^[y is now attracted due to ^[c" target @ id_name "'s Destiny Knot^[y!" }cat notify_watchers
         then
         
   then then
       continue
       then
 
        effect @ "recycle" smatch if
        caster @ "holding" get "nothing" smatch not if
        "^[o^[yBut it failed..." notify_watchers
        exit
        then
        loc @ { "@battle/" bid @ "/recycle/" pos @ }cat getprop temp !
        temp @ not if "Nothing" temp ! then
        temp @ "Nothing" smatch if
        "^[o^[yBut it failed..." notify_watchers
        exit
        then
 
        caster @ "holding" temp @ setto
        { "^[o^[c" caster @ id_name "^[y is now holding another ^[c" temp @ cap "^[y." }cat notify_watchers
 
        continue
        then
        
        effect @ "Bestow" smatch if
        caster @ "holding" "nothing" smatch 
        target @ "holding" "nothing" smatch not or
        if
        "^[o^[yBut it failed..." notify_watchers
        else
        { "^[o^[c" caster @ id_name "^[y has given away their item." }cat notify_watchers
        POKESTORE { "@pokemon/" target @ "/@long/holding" }cat caster @ "holding" get setprop
        POKESTORE { "@pokemon/" caster @ "/@long/holding" }cat "Nothing" setprop
        
        then
        continue
        then
        
        effect @ "powersplit" smatch effect @ "guardsplit" smatch or if
        
                effect @ "powersplit" smatch if 
                { "PhysAtk" "SpecAtk" }list temp !
                else
                { "PhysDef" "SpecDef" }list temp !
                then
                
                temp @ foreach swap pop temp2 !  
                
                target @ temp2 @ calculate temp3 !
                caster @ temp2 @ calculate temp4 !
                
                temp3 @ temp4 @ + 2 / temp5 !
                
                POKESTORE { "@pokemon/" target @ "/temp/forcestat/" temp @ }cat temp5 @ setprop
                POKESTORE { "@pokemon/" attacker @ "/temp/forcestat/" temp @ }cat temp5 @ setprop
                
                repeat
                { "^[o^[c" attacker @ id_name "^[y shared its ^[c" effect @ "powersplit" smatch if "power" else "guard" then "^[y with ^[c" target @ id_name "^[y." }Cat notify_Watchers
        
        continue
        then

        
        effect @ "mimic" smatch if
 
                caster @ { "status/statmods/mimic/move" }cat get not if
 
                        loc @ { "@battle/" BID @ "/position/" loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat getprop }cat getprop "status/statmods/MoveContinued/MoveName" get temp !
                        temp @ not if
                        "^[o^[yBut it failed..." notify_watchers
                        continue
                        then
 
                        caster @ { "movesknown/" temp @ }cat get if
                        "^[o^[yBut it failed..." notify_watchers
                        continue
                        then
                        temp @ "sketch" smatch
                        temp @ "skip" smatch or
                        temp @ "metronome" smatch or
                        temp @ "struggle" smatch or
                        temp @ "mimic" smatch or
                        temp @ "chatter" smatch or
 
                        if
                        "^[o^[yBut it failed..." notify_watchers
                        continue
                        then
                        caster @ { "status/statmods/mimic/move" }cat temp @ setto
                        caster @ { "status/statmods/mimic/pp" }cat 5 setto
                        { "^[o^[c" temp @ " ^[y is now being mimiced!" }cat notify_watchers
 
                        else
                        caster @ { "status/statmods/mimic/pp" }cat over over get atoi 1 - setto
                        caster @ { "/movesknown/mimic/pp" }cat over over fget atoi 1 + fsetto
                then
        continue
        then

 
        effect @ "transform" smatch if
        target @ "status/statmods/semi-inv" get
        target @ "species" fget "132" smatch or
        target @ "status/statmods/substitute" get or
        target @ "status/statmods/illusion" get or
        
        if
        "^[o^[cBut it failed..." notify_watchers
        continue then
        caster @ target @ transform
            
        continue
 
        then
        effect @ "painsplit" smatch if
        startsub @ if continue then
        caster @ "status/hp" get atoi target @ "status/hp" get atoi + 2 / temp !
        caster @ "status/hp" caster @ "maxhp" calculate dup temp @ < not if pop temp @ then setto
        target @ "status/hp" target @ "maxhp" calculate dup temp @ < not if pop temp @ then setto
        { "^[o^[c" caster @ id_name "^[y and ^[c" target @ id_name "^[y have had its pain split!" }cat notify_watchers
 
        continue
        then
        
        effect @ "typechange*" smatch if
        
                effect @ tolower  " " "typechange-" subst strip effect !
                
                target @ "ability" fget "multitype" smatch if
                "^[o^[yBut it failed..." notify_watchers
                continue
                then
                
                POKESTORE { "@pokemon/" target @ "/type" }cat effect @ setprop
                
                 { "^[o^[c" target @ id_name "^[y transformed into ^[c" effect @ cap "^[y type!" }cat notify_watchers
                
        continue
        then
        
        effect @ "entrainment" smatch if
        caster @ "ability" fget temp !
        { "Flower Gift" "Forecast" "Illusion" "Imposter" "Multitype" "Trace" "Zen Mode" }list temp @ array_findval array_count if
        "^[o^[yBut it failed..." notify_watchers
        else        
        POKESTORE { "@pokemon/" target @ fid "/@temp/ability" }cat temp @ setprop
        { "^[o^[c" caster @ id_name "^[y gave ^[c" target @ id_name "^[y its abilitiy ^[c" temp @ cap "^[y!" }cat notify_watchers
        then
        continue then
        
        effect @ "roleplay" smatch if
        target @ "ability" fget temp !
        { "Flower Gift" "Forecast" "Illusion" "Imposter" "Multitype" "Trace" "Zen Mode" }list temp @ array_findval array_count if
        "^[o^[yBut it failed..." notify_watchers
        else
                POKESTORE { "@pokemon/" caster @ fid "/@temp/ability" }cat temp @ setprop
                { "^[o^[c" caster @ id_name "^[y copied ^[c" target @ id_name "'s^[y abilitiy ^[c" temp @ cap "^[y!" }cat notify_watchers
                pos @ bid @ placed_abilities
        then
        continue
        then
 
        effect @ "skillswap" smatch if
        target @ "ability" fget temp !
        caster @ "ability" fget temp2 !
        temp @ "multitype" smatch
        temp @ "wonder guard" smatch or
        temp2 @ "multitype" smatch or
        temp2 @ "wonder guard" smatch or
        if
                "^[o^[yBut it failed..." notify_watchers
        else
                POKESTORE { "@pokemon/" target @ fid "/@long/ability" }cat temp2 @ setprop
                POKESTORE { "@pokemon/" caster @ fid "/@long/ability" }cat temp @ setprop
                { "^[o^[c" caster @ id_name "^[y and ^[c" target @ id_name "^[y have had its abilities ^[c" temp2 @ cap "^[y and ^[c" temp @ cap " swapped!" }cat notify_watchers
                position @ bid @ placed_abilities
                tposition @ bid @ placed_abilities
        then
        continue
        then
 
 
        effect @ "PsychUp" smatch if
        { "PhysAtk" "PhysDef" "SpecAtk" "SpecDef" "Speed" }list foreach swap pop temp !
        caster @ { "status/statmods/" temp @ }cat target @ { "status/statmods/" temp @ }cat get setto
        repeat
        { "^[o^[c" caster @ id_name "^[y has copied ^[c" target @ id_name "'s^[y stat changes!" }cat notify_watchers
        continue
        then
        effect @ "snatch" smatch if
                position @ "A*" smatch if "B" else "A" then temp !
                loc @ { "@battle/" BID @ "/snatch/" temp @ "/caster" }cat caster @ setprop
                loc @ { "@battle/" BID @ "/snatch/" temp @ "/pos" }cat position @ setprop
                { "^[o^[c" caster @ id_name "^[y waits for a target to make a move!" }cat notify_watchers
        continue
        then
 
        effect @ "shieldbreaker" smatch if
                        loc @ { "@battle/" BID @ "/shields/" position @ 1 1 midstr "/light screen" }cat getprop if
                        loc @ { "@battle/" BID @ "/shields/" position @ 1 1 midstr "/light screen" }cat remove_prop
                        "^[o^[yLight Screen was broken!" notify_watchers
                then
                        loc @ { "@battle/" BID @ "/shields/" position @ 1 1 midstr "/reflect" }cat getprop if
                        loc @ { "@battle/" BID @ "/shields/" position @ 1 1 midstr "/reflect" }cat remove_prop
                        "^[o^[yReflect was broken!" notify_watchers
                then
                continue
        then
 
        effect @ "tailwind" smatch if
                loc @ { "@battle/" BID @ "/tailwind/" position @ 1 1 midstr }cat 4 setprop
                { "^[o^[cTeam " position @ 1 1 midstr "^[y Speeds up for a while!" }cat notify_watchers
        continue
        then
 
        effect @ "rapidspin" smatch if
                loc @ { "@battle/" BID @ "/spikes/" pos @ 1 1 midstr }cat propdir? if
                loc @ { "@battle/" BID @ "/spikes/" pos @ 1 1 midstr "/spikes" }cat propdir? if
                        { "^[o^[c" caster @ id_name "^[y removed the ^[cspikes^[y from its side!" }cat notify_watchers
                then
                loc @ { "@battle/" BID @ "/spikes/" pos @ 1 1 midstr "/toxicspikes" }cat propdir? if
                        { "^[o^[c" caster @ id_name "^[y removed the ^[ctoxic spikes^[y from its side!" }cat notify_watchers
                then
                loc @ { "@battle/" BID @ "/spikes/" pos @ 1 1 midstr "/stealthrock" }cat propdir? if
                        { "^[o^[c" caster @ id_name "^[y removed the ^[cstealth rock^[y from its side!" }cat notify_watchers
                then
                loc @ { "@battle/" BID @ "/spikes/" pos @ 1 1 midstr }cat remove_prop
                then
 
                caster @ "status/statmods/vortex/turns" get if
                startsub @ if continue then
                { "^[o^[c" caster @ id_name "^[y is no longer bound!" }cat notify_watchers
                caster @ "status/statmods/vortex/turns" 0 setto
                caster @ "status/statmods/vortex/holder" 0 setto
                caster @ "status/statmods/vortex/holderposition" 0 setto
                caster @ "status/statmods/vortex/move" 0 setto
 
                then
 
                caster @ "status/statmods/seeded" get if
                { "^[o^[c" caster @ id_name "^[y is no longer seeded!" }Cat notify_watchers
                caster @ "status/statmods/seeded" 0 setto
                then
 
        continue
        then
 
        effect @ "spikes" smatch if
                loc @ { "@battle/" BID @ "/spikes/" position @ 1 1 midstr "/spikes/count" }cat over over getprop 1 + setprop
                loc @ { "@battle/" BID @ "/spikes/" position @ 1 1 midstr "/spikes/count" }cat getprop 3 > if
                      { "^[o^[yNo more Spikes can be thrown over the floor around ^[cTeam " position @ 1 1 midstr "^[y!" }cat notify_watchers
                else
                { "^[o^[ySpikes were thrown over the floor around ^[cTeam " position @ 1 1 midstr "^[y!" }cat notify_watchers
                then
                continue
        then
 
        effect @ "toxicspikes" smatch if
                loc @ { "@battle/" BID @ "/spikes/" position @ 1 1 midstr "/toxicspikes/count" }cat over over getprop 1 + setprop
                loc @ { "@battle/" BID @ "/spikes/" position @ 1 1 midstr "/toxicspikes/count" }cat getprop 2 > if
                { "^[o^[yNo more Toxic Spikes can be thrown over the floor around ^[cTeam " position @ 1 1 midstr "^[y!" }cat notify_watchers
                else
                { "^[o^[yToxic Spikes were thrown over the floor around ^[cTeam " position @ 1 1 midstr "^[y!" }cat notify_watchers
                then
                continue
        then
 
        effect @ "stealthrock" smatch if
                loc @ { "@battle/" BID @ "/spikes/" position @ 1 1 midstr "/stealthrock/count" }cat over over getprop 1 + setprop
                loc @ { "@battle/" BID @ "/spikes/" position @ 1 1 midstr "/stealthrock/count" }cat getprop 1 > if
                { "^[o^[yNo more Stealth Rocks can be thrown over the floor around ^[cTeam " position @ 1 1 midstr "^[y!" }cat notify_watchers
                else
                { "^[o^[yStealth Rocks were thrown over the floor around ^[cTeam " position @ 1 1 midstr "^[y!" }cat notify_watchers
                then
                continue
        then
        effect @ "Defog" smatch if
                loc @ { "@battle/" BID @ "/spikes/" position @ 1 1 midstr }cat remove_prop
                loc @ { "@battle/" BID @ "/shields/" position @ 1 1 midstr }cat remove_prop
                { "^[o^[cTeam " position @ 1 1 midstr " ^[yhas had its field cheared. All shields and spikes are removed!" }cat notify_watchers
                bid @ check_weather "fog" smatch if
                { "^[o^[yThe fog had cleared!" }cat notify_watchers
                loc @ { "@battle/" BID @ "/roomweather" }cat remove_prop
                then
        continue
        then
 
        effect @ "block" smatch if
                target @ "status/statmods/block/move" move @ setto
                target @ "status/statmods/block/user" caster @ setto
                target @ "status/statmods/block/userposition" pos @ setto
                { "^[o^[c" target @ id_name "^[y is now blocked!" }cat notify_watchers
                continue
        then
 
        effect @ "fling" smatch if
                caster @ "holding" get "Nothing" smatch if
                "^[o^[yBut it failed..." notify_watchers
                continue
                then
                caster @ "holding" get temp !
                caster @ "holding" "Nothing" setto
                POKEDEX { "items/" temp @ "/fling effect" }cat getprop temp2 !
 
POKEDEX { "items/" temp @ "/holdeffect" }cat getprop berryeffect !
   berryeffect @ if
        target @ "happiness" over over fget atoi 1 + fsetto
        target @ "happiness" fget atoi 255 > if
        target @ "happiness" 255 fsetto
        then
        { "^[o^[c" target @ id_name "^[y ate ^[c" target @ id_name "'s " temp @ cap "^[y!" }cat notify_watchers
        berryeffect @ ":" explode_array foreach effect ! pop
                effect @ "Heal*" smatch if
                        target @ { "status/" effect @ }cat get if
                        { "^[o^[c" target @ id_name "^[y was healed from being ^[c" effect @ "^[y!" }cat notify_watchers
                        then
                        continue
                then
                effect @ "Restore/*" smatch if
                        POKEDEX { "items/" temp @ "/conditional" }cat getprop if continue then
                                effect @ " " "Restore" subst strip atoi effect !
                                target @ "status/hp" over over get atoi target @ "maxhp" calculate effect @ / + setto
                                target @ "status/hp" get atoi target @ "maxhp" calculate > if
                                target @ "status/hp" target @ "maxhp" calculate setto
                                then
                                { "^[o^[c" target @ id_name "^[y regained some health!" }cat notify_watchers
                                continue
                        then
                 effect @ "Restore *" smatch if
                         POKEDEX { "items/" temp @ "/conditional" }cat getprop if continue then
                                 effect @ " " "Restore" subst strip atoi effect !
                                 target @ "status/hp" over over get atoi effect @ + setto
                                 target @ "status/hp" get atoi target @ "maxhp" calculate > if
                                 target @ "status/hp" target @ "maxhp" calculate setto
                                 then
                                 { "^[o^[c" target @ id_name "^[y regained some health!" }cat notify_watchers
                                 continue
                        then
                        effect @ "confused" smatch
                        if
                                POKEDEX { "items/" temp @ "/" POKEDEX { "natures/" target @ "nature" get "/dislikes" }cat getprop }cat getprop if
                                target @ "status/statmods/confused" get if continue then
                                target @ "ability" fget "Own Tempo" smatch if
                                { "^[o^[c" target @ id_name "^[y would of been confused, but can't be due to its ability ^[cOwn Tempo^[y." }cat notify_watchers
                                                continue then
                                { "^[o^[c" target @ id_name "^[y is now confused!" }cat notify_watchers
                                       target @ "status/statmods/confused"  random 4 % 2 + setto
                                then
                                continue
                        then
 
                        effect @ "move first" smatch if
                                 { "^[o^[c" target @ id_name "^[y is attacking sooner next turn!" }cat bid @ notify_watchers
                                 target @ "status/statmods/movefirst" 1 setto
                                 continue
                        then
 
                        effect @ "pp*" smatch if
                                effect @ " " "pp" subst strip atoi effect !
                                target @ "status/statmods/movecontinued/movename" get temp3 !
                                temp3 @ if
                                target @ { "/movesknown/" temp3 @ "/pp" }cat over over fget atoi effect @ + fsetto
                                target @ { "/movesknown/" temp3 @ "/pp" }cat over over fget atoi POKEDEX { "moves/" move @ "/pp" }cat fget atoi < if
                                POKEDEX { "moves/" temp3 @ "/pp" }cat fget atoi fsetto
                                else
                                pop
                                then
                                { "^[o^[c" target @ id_name "^[y regained some PP for ^[c" move @ cap "^[y!" }cat notify_watchers
                                continue
                        then
                        then
                repeat
                        "fling" effect !
                        then
 
 
                temp2 @ if
                        temp2 @ "*cure*" smatch if
                                temp2 @ "*infatuation*" smatch if
                                target @ "status/attracted" 0 setto
                                then
 
                                temp2 @ "*stat loss*" smatch if
                                { "PhysAtk" "PhysDef" "SpecAtk" "SpecDef" "Speed" }list foreach swap pop temp3 !
                                target @ { "status/statmods/" temp3 @ }cat over over get atoi 0 < if 0 setto else pop pop then
                                repeat
                                { "^[o^[c" target @ id_name "^[y had its negative stat changes cleared!" }cat notify_watchers
                                then
 
                        continue
                        else
                           temp2 @ effect !
                        then
                then
 
 
        then
 
        effect @ "HealOverTime" smatch if
                target @ "status/statmods/healovertime/move" move @ setto
 
                continue
        then
 
        effect @ "Ingrain" smatch if
                target @ "status/statmods/ingrain/move" move @ setto
                continue
        then
 
        effect @ "Struggle" smatch if
                caster @ "status/hp" over over get atoi caster @ "maxhp" calculate 4 / - setto
                caster @ "status/hp" get atoi 0 <= if
                  POKESTORE { "@pokemon/" caster @ "/@RP/status" }cat remove_prop
                  caster @ "status/hp" 0 setto
                  caster @ "status/fainted" 1 setto
                then
        continue
        then
 
        effect @ "Embargo" smatch if
                target @ "status/statmods/embargo" get if
                "^[o^[yBut it failed..." notify_watchers
                continue
                then
 
                target @ "status/statmods/embargo" 6 setto
                { "^[o^[c" target @ id_name "^[y is now embargoed!" }cat notify_watchers
        continue
        then
 
        effect @ "Bugbite" smatch if
                var item
                startsub @ if continue then
                target @ "holding" get item !
                POKEDEX { "items/" item @ "/holdeffect" }cat getprop berryeffect !
                berryeffect @ if
                        POKESTORE { "@pokemon/" target @ "/@long/holding" }cat "Nothing" setprop
                        caster @ "status/statmods/embargo" get if
                        "^[y^[oThe berry was wasted due to the effects of embargo..." notify_watchers
                        continue then
                        caster @ "happiness" over over fget atoi 1 + fsetto
                        caster @ "happiness" fget atoi 255 > if
                        caster @ "happiness" 255 fsetto
                        then
                        { "^[o^[c" caster @ id_name "^[y ate ^[c" target @ id_name "'s " item @ cap "^[y!" }cat notify_watchers
                        berryeffect @ ":" explode_array foreach effect ! pop
                                effect @ "Heal*" smatch if
                                        caster @ { "status/" effect @ }cat get if
                                        { "^[o^[c" caster @ id_name "^[y was healed from being ^[c" effect @ "^[y!" }cat notify_watchers
                                        then
                                        continue
                                then
                                effect @ "Restore*" smatch if
                                        POKEDEX { "items/" item @ "/conditional" }cat getprop if continue then
                                                effect @ " " "Restore" subst strip atoi effect !
                                                caster @ "status/hp" over over get atoi caster @ "maxhp" calculate effect @ / + setto
                                                caster @ "status/hp" get atoi caster @ "maxhp" calculate > if
                                                caster @ "status/hp" caster @ "maxhp" calculate setto
                                                then
                                                { "^[o^[c" caster @ id_name "^[y regained some health!" }cat notify_watchers
                                                continue
                                        then
 
                                        effect @ "confused" smatch if
                                        caster @ "ability" fget "Own Tempo" smatch if continue then
                                                POKEDEX { "items/" item @ "/" POKEDEX { "natures/" caster @ "nature" get "/dislikes" }cat getprop }cat getprop if
                                                caster @ "status/statmods/confused" get if continue then
                                                { "^[o^[c" caster @ id_name "^[y is now confused!" }cat notify_watchers
                                                       caster @ "status/statmods/confused"  random 4 % 2 + setto
                                                then
                                                continue
                                        then
                                        effect @ "move first" smatch if
                                                 { "^[o^[c" caster @ id_name "^[y is attacking sooner next turn!" }cat notify_watchers
                                                 caster @ "status/statmods/movefirst" 1 setto
                                                 continue
                                        then
                                        effect @ "pp*" smatch if
                                                effect @ " " "pp" subst strip atoi effect !
                                                caster @ { "/movesknown/" move @ "/pp" }cat over over fget atoi effect @ + fsetto
                                                caster @ { "/movesknown/" move @ "/pp" }cat over over fget atoi POKEDEX { "moves/" move @ "/pp" }cat fget atoi < if
                                                POKEDEX { "moves/" move @ "/pp" }cat fget atoi fsetto
                                                else
                                                pop
                                                then
                                                { "^[o^[c" caster @ id_name "^[y regained some PP for ^[c" move @ cap "^[y!" }cat notify_watchers
                                                continue
                                        then
 
                                                effect @ "raise*" smatch if
                                                                effect @ " " "Raise" subst strip effect !
                                                                effect @ " " "stat" subst strip effect !
                                                                effect @ "random" smatch if
                                                                random 5 % 1 +
                                                                dup 1 = if "PhysAtk" effect ! then
                                                                dup 2 = if "PhysDef" effect ! then
                                                                dup 3 = if "SpecAtk" effect ! then
                                                                dup 4 = if "SpecDef" effect ! then
                                                                    5 = if "Speed"   effect ! then
                                                                then
                                                                effect @ "critical*" smatch if "critical" effect ! then
                                                                caster @ { "status/statmods/" effect @ }cat over over get atoi 1 + setto
                                                                { "^[o^[c" caster @ id_name "^[y raised its ^[c" effect @ "^[y stat!" }cat notify_watchers
 
                                                                continue
                                                then
 
                        repeat
 
                then
                continue
        then
 
        effect @ "vortex" smatch if
        startsub @ if continue then
        target @ "status/fainted" get if continue then
        target @ "status/statmods/vortex/turns" get if
        "^[y^[oBut it failed..." notify_watchers
        continue
        then

                POKEDEX { "moves/" move @ "/vortex_turns" }cat getprop not if
                caster @ "holding" get "Grip Claw" smatch
                position @ caster @ can_use_hold_item and if 5 hittimes ! else
                frand
                dup 0.875 >  if 5 hittimes ! then
                dup 0.875 <= if 4 hittimes ! then
                dup 0.750 <= if 3 hittimes ! then
                    0.375 <= if 2 hittimes ! then
                then
                
                else
                POKEDEX { "moves/" move @ "/vortex_turns" }cat getprop "-" split atoi max ! atoi min !
                random max @ min @ - 1 + % min @ +  hittimes ! (don't subtract one for this turn)
                
                then
                target @ "status/statmods/vortex/turns" hittimes @ setto
                target @ "status/statmods/vortex/holder" caster @ setto
                target @ "status/statmods/vortex/holderposition" pos @ setto
                target @ "status/statmods/vortex/move" move @ setto
                { "^[o^[c" caster @ id_name "^[y has ^[c" target @ id_name "^[y trapped!" }cat notify_watchers
                continue
        then
 
        effect @ "worryseed" smatch if
                target @ "ability" fget "truant" smatch not if
                POKESTORE { "@pokemon/" target @ fid "/@temp/ability" }cat "Insomnia" setprop
                then
                continue
        then
 
        effect @ "repeater" smatch if
                (this is going to be a special effect for moves that repeat)
                (moves that repeat need to have a folder in them called /repeater)
                (this folder needs the following properties)
                (min - stored as a string, this is the minimum number of turns a move will happen - needed)
                (max - stored as a string, this is the maximum number of turns a move will happen - needed)
                (EndingEffect - stored as a string, this is what the effect changes to - optional)
                loc @ { "@battle/" BID @ "/repeats/" pos @ }cat propdir? not if
 
                        loc @ { "@battle/" BID @ "/repeats/" pos @ "/move" }cat move @ setprop
                        POKEDEX {  "moves/" move @ "/repeats/max" }cat getprop atoi max !
                        POKEDEX {  "moves/" move @ "/repeats/min" }cat getprop atoi min !
                        random max @ min @ - 1 + % min @ +  var! turns (don't subtract one for this turn)
                        loc @ { "@battle/" BID @ "/repeats/" pos @ "/turns" }cat turns @ setprop
 
                        continue
 
 
                then
 
        then
 
        effect @ "trickroom" smatch if
                loc @ { "@battle/" BID @ "/trickroom" }cat getprop if
                loc @ { "@battle/" BID @ "/trickroom" }cat remove_prop
                else
                loc @ { "@battle/" BID @ "/trickroom" }cat 6 setprop
                then
                continue
        then
        
                effect @ "Magicroom" smatch if
                        loc @ { "@battle/" BID @ "/Magicroom" }cat getprop if
                        loc @ { "@battle/" BID @ "/Magicroom" }cat remove_prop
                        else
                        loc @ { "@battle/" BID @ "/Magicroom" }cat 6 setprop
                        then
                        continue
        then
        
                effect @ "Wonderroom" smatch if
                        loc @ { "@battle/" BID @ "/Wonderroom" }cat getprop if
                        loc @ { "@battle/" BID @ "/Wonderroom" }cat remove_prop
                        else
                        loc @ { "@battle/" BID @ "/Wonderroom" }cat 6 setprop
                        then
                        continue
        then
 
        effect @ "payday" smatch if
                loc @ { "@battle/" BID @ "/pay day" }cat  over over getprop caster @ FindPokeLevel 2 * + setprop
                { "^[y^[oCredits were scattered on the ground!" }cat notify_watchers
                continue
        then
 
        effect @ "uproar" smatch if
                loc @ { "@battle/" BID @ "/uproar/" pos @ }cat caster @ setprop
                (next remove the sleeping status of any pokemon that is sleeping)
                var temppos
                var temptarget
                { "A1" "B1" "A2" "B2" }list foreach temppos ! pop
                loc @ { "@battle/" BID @ "/position/" temppos @ }cat getprop if
                loc @ { "@battle/" BID @ "/position/" temppos @ }cat getprop temptarget !
                temptarget @ "status/asleep" get if
                temptarget @ "status/asleep" 0 setto
                { "^[o^[c" temppos @ "." temptarget @ id_name "^[y was awoken by the uproar!" }cat notify_watchers
                then then
                repeat
                continue
        then
 
        effect @ "mixgender" smatch if
             target @ "gender" fget "male" smatch if
               caster @ "gender" fget "female" smatch if
               1 tempeffect !
               then then
             target @ "gender" fget "female" smatch if
               caster @ "gender" fget "male" smatch if
               1 tempeffect !
               then then
        target @ "ability" fget "oblivious" smatch if 0 tempeffect ! then
        
     tempeffect @ not if
     "^[o^[yBut it failed..." notify_watchers
     break break
     else
     continue
     then
 
        then
 
        effect @ "perishsong" smatch if
        target @ "status/statmods/perishsong" get if
        "^[y^[oBut it failed..." notify_watchers
        continue
        then
        target @ "status/statmods/perishsong" 4 setto
        target @ stringify caster @ stringify smatch if
        "^[y^[oAn eery song is heard..." notify_watchers
        then
        continue
        then
        effect @ "freehit" smatch if
 
        { "^[o^[c" caster @ id_name "'s ^[ynext attack against ^[c" target @ id_name "^[y should hit!" }cat notify_watchers
        target @ "status/statmods/freehit/caster" attacker @ setto
        target @ "status/statmods/freehit/count" 2 setto
        continue
        then
 
       effect @ "tri-attack" smatch if
           loc @ { "@battle/" BID @ "/shields/" positionteam @ "/safeguard" }cat getprop targettype @ "target" smatch user @ "ability" fget "Infiltrator" smatch not and and if { "^[o^[c" target @ id_name "^[y was safeguarded from the effect of the attack!" }cat notify_watchers continue then
           target @ "status/frozen"    get if continue then
           target @ "status/paralyzed" get if continue then
           target @ "status/asleep"    get if continue then
           target @ "status/poisoned"  get if continue then
           target @ "status/toxic"     get if continue then
           target @ "status/burned"    get if continue then
           target @ "status/fainted"   get if continue then
           target @ "ability" fget "leaf guard" smatch bid @ check_weather "sunny day" smatch and caster @ moldbreaker  if continue then
           startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
           random 3 % 1 + effect !
           effect @ 1 = if target @ "ability" fget "water veil" smatch if continue then target @ typelist "fire" array_findval array_count
           caster @ moldbreaker
           if continue then target @ "status/burned" 1 setto { "^[o^[c" target @ id_name "^[y has been ^[rBurned^[y!" }cat notify_watchers then
           effect @ 2 = if target @ "ability" fget "Magma Armor" smatch if continue then target @ typelist "ice" array_findval array_count
           caster @ moldbreaker
           if continue then target @ "status/frozen" 1 setto { "^[o^[c" target @ id_name "^[y has been ^[cfrozen^[y!" }cat notify_watchers then
           effect @ 3 = if target @ "ability" fget "Limber" smatch
           caster @ moldbreaker
           if continue then target @ "status/paralyzed" 1 setto { "^[o^[c" target @ id_name "^[y has been ^[yparalyzed^[y!" }cat notify_watchers then
       continue
       then
 
       effect @ "faintafter" smatch if
       loc @ { "@battle/" BID @ "/FaintAfterTurn/" pos @ }cat "yes" setprop
       then
 
       effect @ "randomstat*" smatch if
 ( the old way
        var randnum
        random 5 % 1 + randnum !
        var stat
        randnum @ 1 = if "PhysAtk" stat ! then
        randnum @ 2 = if "PhysDef" stat ! then
        randnum @ 3 = if "SpecAtk" stat ! then
        randnum @ 4 = if "SpecDef" stat ! then
        randnum @ 5 = if "Speed" stat ! then
 )
        
        { "PhysAtk" "PhysDef" "SpecAtk" "SpecDef" "Speed" }list temp !
        temp @ foreach swap pop temp2 !
        target @ { "status/statmods/" temp2 @ }cat get atoi 6 >= if temp2 @ temp @ array_appenditem then 
        
        repeat
        
        temp @ if
        temp @ 4 array_sort foreach swap pop temp2 ! break repeat
        else
        "^[o^[yBut it failed..." notify_watchers
        break break
        then
 
        effect @ temp2 @ "randomstat" subst effect !
 
        (don't continue)
       then
 
 
       effect @ "hurtnear" smatch if
        pos @ "A*" smatch if "A" temp ! (tpos) else "B" temp ! then
        pos @ "?1" smatch pos @ "?3" smatch if
        { { temp @ "2" }cat }list temp3 !
                
        else
        { { temp @ "1" }cat { temp @ "3" }cat }list temp3 !
        then
        temp3 @ foreach swap pop temp4 !
                loc @ { "@battle/" BID @ "/position/" temp4 @ }cat getprop if
                                loc @ { "@battle/" BID @ "/position/" temp4 @ }cat getprop temp2 !
                                temp2 @ "ability" fget "magic guard" smatch not if
                                        temp2 @ "maxhp" calculate 16 divdamage damage !
                                        temp2 "status/hp" over over get atoi damage @ - setto
                                        { "^[o^[c" temp4 @ cap "." temp2 @ id_name " ^[ywas hit with splash damage!" }cat notify_watchers
                                        
                                                temp2 @ "status/hp" get atoi 0 <= if
                                                         POKESTORE { "@pokemon/" temp2 @ "/@RP/status" }cat remove_prop
                                                         temp2 @ "status/hp" 0 setto
                                                         temp2 @ "status/fainted" 1 setto
                                                         { "^[o^[c" temp4 @ cap "." temp2 @ id_name " ^[yFainted!!" }cat notify_watchers
                                                 then
                                         then
                                        
                                then
                repeat
                       continue
        then
       
       effect @ "simplebeam" smatch if
                target @ "ability" fget temp !
                { "Multitype" "Simple" "Truant" }list temp @ array_findval array_count if
                        "^[o^[yBut it failed..." notify_watchers
                continue
                then
                POKESTORE { "@pokemon/" target @ fid "/@temp/ability" }cat "Simple" setprop
                { "^[o^[c" target @ id_name "'s^[y abilitiy changed to ^[cSimple^[y!" }cat notify_watchers
       continue
       then
       
       effect @ "moveswitch" smatch if
                bid @ pos @ switch_check not if continue then
                loc @ { "@battle/" BID @ "/control/team" pos @ 1 1 midstr "/" caster @ }cat getprop DBref? if
                loc @ { "@battle/" BID @ "/pause" }cat pos @ setprop
                loc @ { "@battle/" BID @ "/control/team" pos @ 1 1 midstr "/" caster @ }cat getprop "@battle/moveswitch" pos @ setprop
                else
                loc @ { "@battle/" BID @ "/moveswitch/" pos @ }cat 1 setprop
                then
                continue
       then
       effect @ "yawn" smatch if
        var failed
        0 failed !
           loc @ { "@battle/" BID @ "/shields/" positionteam @ "/safeguard" }cat getprop targettype @ "target" smatch user @ "ability" fget "Infiltrator" smatch not and and if { "^[o^[c" target @ id_name "^[y was safeguarded from the effect of the attack!" }cat notify_watchers continue then
           target @ "status/frozen"    get if 1 failed ! then
           target @ "status/paralyzed" get if 1 failed ! then
           target @ "status/asleep"    get if 1 failed ! then
           target @ "status/poisoned"  get if 1 failed ! then
           target @ "status/toxic"     get if 1 failed ! then
           target @ "status/burned"    get if 1 failed ! then
           target @ "status/fainted"   get if 1 failed ! then
           target @ "status/statmods/yawn" get if 1 failed ! then
           startsub @ if 1 failed ! then
           failed @ if
           "^[o^[ybut it failed..." notify_watchers
           continue
           then
           target @ "ability" fget "Vital spirit" smatch
           target @ "ability" fget "Insomnia" smatch or
           caster @ moldbreaker
           if
           { "^[o^[c" target @ id_name "^[y can't get tired due to its ability ^[c" target @ "ability" fget cap "^[y." }cat notify_watchers
           continue
           then
           target @ "status/statmods/yawn" 2 setto
 
           { "^[o^[c" target @ id_name "^[y yawns lightly..." }cat notify_watchers
           continue
       then
 
       effect @ "nightmares" smatch if
       target @ "status/statmods/nightmare" 1 setto
       { "^[o^[c" target @ id_name "^[y is now having nightmares!" }cat notify_watchers
       continue
       then
 
       effect @ "asleep" smatch if
 
           loc @ { "@battle/" BID @ "/shields/" positionteam @ "/safeguard" }cat getprop targettype @ "target" smatch user @ "ability" fget "Infiltrator" smatch not and and if { "^[o^[c" target @ id_name "^[y was safeguarded from the effect of the attack!" }cat notify_watchers continue then
           target @ "status/frozen"    get if continue then
           target @ "status/paralyzed" get if continue then
           target @ "status/asleep"    get if continue then
           target @ "status/poisoned"  get if continue then
           target @ "status/toxic"     get if continue then
           target @ "status/burned"    get if continue then
           target @ "status/fainted"   get if continue then
           target @ "ability" fget "leaf guard" smatch bid @ check_weather "sunny day" smatch and targettype @ "target" smatch and if continue then
           startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
           loc @ { "@battle/" BID @ "/uproar" }cat propdir? if
           { "^[o^[c" target @ id_name "^[y would have fallen ^[bAsleep^[y but couldn't due to the effect of uproar!" }cat notify_watchers continue then
           target @ "ability" fget "Vital Spirit" smatch
           target @ "ability" fget "Insomnia" smatch or if
           { "^[o^[c" target @ id_name "^[y can't fall ^[bAsleep^[y due to its ability ^[c " target @ "ability" fget cap "^[y!" }cat notify_watchers continue then
 
           target @ "status/asleep"
           move @ "rest" smatch if
           3
           else
           random 5 % 2 + then
           user @ "ability" fget "early bird" smatch if dup 2 / - then
           setto
     loc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
     tempref @ awake? not if continue then
     tempref @ location loc @ = not if continue then
 
     tempref @ { "^[o^[c" target @ id_name "^[y is now ^[basleep!" }cat notify
         repeat
         continue
       then
 
       effect @     "Accuracy*" smatch if
       effect @ " " "Accuracy" subst strip atoi effect !
       target @ "ability" fget "simple" smatch caster @ moldbreaker if effect @ 2 * effect ! then
       target @ "ability" fget "contrary" smatch caster @ moldbreaker if effect @ -1 * effect ! then
       effect @ 0 < if
       target @ "ability" fget "Clear Body" smatch target @ "ability" fget "White smoke" smatch or targettype @ "self" smatch not and
       caster @ moldbreaker
       if { "^[o^[c" target @ id_name "^[y was protected by its ability ^[c" target @ "ability" fget cap "^[y." }cat notify_watchers continue then
       target @ "ability" fget "keen eye" smatch
       caster @ moldbreaker
       if
       { "^[o^[c" target @ id_name "^[y can't have its accuracy lowered due to its ^[cKeen Eye^[y ability!" }cat notify_watchers
       continue
       then
        loc @ { "@battle/" BID @ "/shields/" positionteam @ "/mist" }cat getprop targettype @ "target" smatch and if { "^[o^[c" target @ id_name "^[y was protected by mist from the attack's effect!" }cat notify_watchers continue then
       then
 
       startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
       target @ "status/statmods/accuracy" get atoi oldval !
       target @ "status/statmods/accuracy" over over get atoi effect @ + temp !
       temp @ 6 > if 6 temp ! then
       temp @ -6 < if -6 temp ! then
       temp @ setto
{
         oldval @ temp @ = if
         "^[o^[c" target @ id_name "'s ^[yaccuracy can't go any " effect @ 0 > if "higher" else "lower" then "."
         else
 
   effect @ 1 = if
   "^[o^[c" target @ id_name "'s ^[yaccuracy raised."
   then
 
   effect @ 1 > if
   "^[o^[c" target @ id_name "'s ^[yaccuracy raised greatly."
   then
 
   effect @ -1 = if
   "^[o^[c" target @ id_name "'s ^[yaccuracy dropped."
   then
 
   effect @ -1 < if
   "^[o^[c" target @ id_name "'s ^[yaccuracy dropped greatly."
   then
 
         then
         }cat notify_watchers
         
         effect @ 0 < 
         caster @ stringify target @ stringify smatch not and
         if
         target @ "ability" fget "Defiant" smatch if
                         target @ "status/statmods/PhysAtk" over over atoi 2 + setto 
                         { "^[o^[c" target @ id_name "'s ^[yability ^[cDefiant^[y raised its attack by two levels!" }cat notify_watchers
                then
         then
         continue
       then
        
        effect @ "safeguard" smatch if
        loc @ { "@battle/" BID @ "/shields/" positionteam @ "/safeguard" }cat 5 setprop
        continue
        then
 
        effect @ "reflect" smatch if
        loc @ { "@battle/" BID @ "/shields/" positionteam @ "/reflect" }cat 
        caster @ "holding" get "Light Clay" smatch position @ caster @ can_use_hold_item and if 9 else
        5 then setprop
        continue
        then
 
        effect @ "Luckychant" smatch if
        loc @ { "@battle/" BID @ "/shields/" positionteam @ "/lucky chant" }cat 5 setprop
        continue
        then
 
        effect @ "Light Screen" smatch if
        loc @ { "@battle/" BID @ "/shields/" positionteam @ "/Light Screen" }cat 
        caster @ "holding" get "Light Clay" smatch position @ caster @ can_use_hold_item and if 9 else
        5 then setprop
        continue
        then
 
        effect @ "mist" smatch if
        loc @ { "@battle/" BID @ "/shields/" positionteam @ "/Mist" }cat 5 setprop
        continue
        then
 
       effect @ "Burned" smatch if
  loc @ { "@battle/" BID @ "/shields/" positionteam @ "/safeguard" }cat getprop targettype @ "target" smatch user @ "ability" fget "Infiltrator" smatch not and and if { "^[o^[c" target @ id_name "^[y was safeguarded from the effect of the attack!" }cat notify_watchers continue then
  target @ "status/frozen"    get if continue then
  target @ "status/paralyzed" get if continue then
  target @ "status/asleep"    get if continue then
  target @ "status/poisoned"  get if continue then
  target @ "status/toxic"     get if continue then
  target @ "status/burned"    get if continue then
  target @ "status/fainted"   get if continue then
  target @ "ability" fget "leaf guard" smatch bid @ check_weather "sunny day" smatch and caster @ moldbreaker  if continue then
  target @ "ability" fget "water veil" smatch caster @ moldbreaker if continue then
  startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
  target @ typelist "fire" array_findval array_count if
  target @ "ability" fget "flash fire" smatch target @ "status/statmods/damageboost/fire" get not and if
          target @ "status/statmods/damageboost/fire" 1 setto
          { "^[o^[c" tpos @ "." target @ id_name "'s^[y ability ^[cFlash Fire^[y has been activated!"  }cat notify_watchers
        then
  continue then
  target @ "status/burned"    1 setto
loc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
tempref @ awake? not if continue then
tempref @ location loc @ = not if continue then
 
  tempref @ { "^[o^[c" target @ id_name "^[y has been ^[rBurned^[y!" }cat notify
        repeat
continue
       then
 
       effect @ "Confused" smatch if
       target @ "ability" fget "Own Tempo" smatch
       caster @ moldbreaker
       if
       { "^[o^[c" target @ id_name "^[y can't be confused due to its ability ^[c" target @ "ability" fget cap "^[y." }cat notify_watchers
       continue
       then
       target @ "status/statmods/confused"  get if continue then
       startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
       target @ "status/statmods/confused"
       random 4 % 2 + setto
 
 
        { "^[o^[c" target @ id_name "^[y is now ^[mConfused^[y!" }cat notify_watchers
        POKEDEX { "items/" target @ "holding" get "/holdeffect" }cat getprop dup not if pop " " then "*Heal Confused*" smatch if
        1 sleep 
                target @ "status/statmods/confused" 0 setto
                { "^[o^[c" target @ id_name "^[y was healed from being ^[c" effect @ "^[y by eating its ^[c" target @ "holding" get "^[y!" }cat notify_watchers
        then
       continue
       then
 
       effect @ "Critical*" smatch if
 
              effect @ " " "Critical" subst strip atoi effect !
              target @ "status/statmods/critical" over over get atoi effect @ + temp !
              temp @ 1 = if
              temp @ setto
              else
              pop
              then
                loc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
                tempref @ awake? not if continue then
  tempref @ location loc @ = not if continue then
  temp @ 1 = if
       tempref @ { "^[o^[c" target @ id_name "'s^[y crit chance raised!" }cat notify
  else
       tempref @ { "^[o^[c" target @ id_name " ^[yfailed to raise crit chance!" }cat notify
       then
         repeat
                continue
       then
 
       effect @ "afteryou" smatch if
       
                caster @ findrank target @ findrank < if "^[o^[yBut it failed..." notify_watchers continue then
                
                target @ findrank caster @ findrank 1 + rankchange
                
                { "^[o^[c" target @ id_name "^[y must now go next!" }cat notify_watchers
       continue
       then
       
       effect @ "quash" smatch if
                caster @ findrank target @ findrank < if "^[o^[yBut it failed..." notify_watchers continue then
                target @ findrank loc @ { "@battle/" bid @ "/speed/rank/" }cat array_get_propvals array_count rankchange
                
                { "^[o^[c" target @ id_name "^[y must now go last!" }cat notify_watchers
       continue
       then
       
       effect @ "allyswitch" smatch if
                0 temp !
                { -1 1 }list foreach temp2 !
                loc @ { "@battle/" BID @ "/position/" pos @ 1 1 midstr pos @ 2 1 midstr atoi temp2 @ + }cat getprop if temp @ 1 + temp ! then
                repeat
                
                temp @ 1 != if "^[o^[yBut it failed..." notify_watchers continue then
                
                { -1 1 }list foreach temp2 !
                loc @ { "@battle/" BID @ "/position/" pos @ 1 1 midstr pos @ 2 1 midstr atoi temp2 @ + }cat getprop if
                { pos @ 1 1 midstr pos @ 2 1 midstr atoi temp @ + }cat temp3 !
                break
                then
                repeat
                
                loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop temp !
                loc @ { "@battle/" BID @ "/position/" temp3 @ }cat getprop temp2 !
                loc @ { "@battle/" BID @ "/position/" pos @ }cat temp2 @ setprop
                loc @ { "@battle/" BID @ "/position/" temp3 @ }cat temp @ setprop
                
                { "^[o^[c" caster @ id_name "^[y traded places with its partner!" }cat notify_watchers
                
       continue
       then
       
       effect @ "Drain" smatch if
       (should give you some health from the damage you do, its half)
       caster @ "status/statmods/healblock" get if
       { "^[o^[c" caster @ id_name "^[y couldn't gain hp from draining due to the effects of heal block!" }cat notify_watchers
       continue then
       var healing
       damage @ 2 / healing !
       caster @ "holding" get "Big Root" smatch
       position @ caster @ can_use_hold_item and
       if healing @ 1.3 * floor healing ! then
       target @ "ability" fget "Liquid Ooze" smatch if
         caster @ "status/hp" over over get atoi healing @ - setto
         caster @ "status/hp" get atoi 0 <= if
          POKESTORE { "@pokemon/" caster @ "/@RP/status" }cat remove_prop
          caster @ "status/hp" 0 setto
          caster @ "status/fainted" 1 setto
          then
 
{ "^[o^[c" caster @ id_name "^[y lost hp from draining due to target's ability"
  caster @ "status/fainted" get if " and fainted!" else "." then
  }cat notify_watchers
 
       else
         caster @ "status/hp" over over get atoi healing @ + setto
         var maxhp
         caster @ "MaxHP"   Calculate maxhp !
         caster @ "status/hp" get atoi maxhp @ > if caster @ "status/hp" maxhp @ setto then
 
 { "^[o^[c" caster @ id_name "^[y gained hp from draining!" }cat notify_watchers
 
       then
                       continue
       then
 
       effect @ "Cure1" smatch if
           (works for rest)
           target @ "MaxHP"   Calculate var! curemaxhp
           target @ "status/hp" get atoi curemaxhp @ = if
           "^[o^[yBut it failed..." notify_watchers
           break break
           then
           target @ "status/hp" curemaxhp @ setto
           target @ "status/frozen"    0 setto
    target @ "status/paralyzed" 0 setto
    target @ "status/asleep"    0 setto
    target @ "status/poisoned"  0 setto
    target @ "status/toxic"     0 setto
    target @ "status/burned"    0 setto
           target @ "status/fainted"   0 setto
           continue
       then
 
       effect @ "Cure2" smatch if
           (half max health)
           caster @ stringify target @ stringify smatch not
           target @ "status/statmods/substitute" get and if
                { "^[o^[c" target @ id_name "^[y couldn't be healed due to their substitute!" }cat notify_watchers
           then
                      target @ "status/statmods/healblock" get if
                             { "^[o^[c" target @ id_name "^[y couldn't heal due to the effects of heal block!" }cat notify_watchers
       continue then
           var cureammount
           0.5 cureammount !
           target @ "MaxHP"   Calculate var! curemaxhp
 
           (use this to modify the cure ammount for weather based changes)
        bid @ check_weather weather !
        weather @ if
           weather @ "Rain Dance" smatch
           weather @ "hail" smatch or
           weather @ "sandstorm" smatch or
           weather @ "fog" smatch or
           if
                   move @ "moonlight" smatch
                   move @ "synthesis" smatch or
                   move @ "morning sun" smatch or if
                        0.25 cureammount !
                   then
           then
           weather @ "Sunny day" smatch if
                   move @ "moonlight" smatch
                   move @ "synthesis" smatch or
                   move @ "morning sun" smatch or if
                        2.0 3.0 / cureammount !
                   then
           then
           then
 
           (end cureammount)
 
           target @ "status/hp" over over get atoi curemaxhp @ cureammount @ * floor + setto
           target @ "status/hp" get atoi curemaxhp @ > if target @ "status/hp" curemaxhp @ setto then
           { "^[o^[c" target @ id_name "^[g regains some health!" }cat notify_watchers
           continue
       then
        effect @ "UproarCheck" smatch if
        caster @ "ability" fget "Vital Spirit" smatch
        caster @ "ability" fget "Insomnia" smatch or
        if
        { "^[o^[c" caster @ id_name "^[y can't fall ^[bAsleep^[y because of its ability ^[c" caster @ "ability" fget cap "^[y!" }cat notify_watchers
        break break
        then
                   loc @ { "@battle/" BID @ "/uproar" }cat propdir? if
           { "^[o^[c" caster @ id_name "^[y would have fallen ^[bAsleep^[y but couldn't due to the effect of uproar!" }cat notify_watchers break break then
           continue
        then
       Effect @ "Dull-*" smatch if
               effect @ "" "Dull-" subst strip effect !
               (this takes out the dull and you know what the element is)
               loc @ { "@battle/" BID @ "/dull/" effect @ }cat attacker @ setprop
               { "^[o^[c" effect @ cap "^[y attacks are now weaker!" }cat notify_watchers
               continue
       then
       effect @ "Evasion*" smatch if
       effect @ " " "Evasion" subst strip atoi effect !
       target @ "ability" fget "simple" smatch caster @ moldbreaker if effect @ 2 * effect ! then
       target @ "ability" fget "contrary" smatch caster @ moldbreaker if effect @ -1 * effect ! then
       effect @ 0 < if
               target @ "ability" fget "Clear Body" smatch target @ "ability" fget "White smoke" smatch or targettype @ "self" smatch not and
               caster @ moldbreaker
               if { "^[o^[c" target @ id_name "^[y was protected by its ability ^[c" target @ "ability" fget cap "^[y." }cat notify_watchers continue then
               loc @ { "@battle/" BID @ "/shields/" positionteam @ "/mist" }cat getprop targettype @ "target" smatch and if { "^[o^[c" target @ id_name "^[y was protected by mist from the attack's effect!" }cat notify_watchers continue then
       then
       startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
       target @ "status/statmods/evasion" get atoi oldval !
       target @ "status/statmods/evasion" over over get atoi effect @ + temp !
       temp @ 6 > if 6 temp ! then
       temp @ -6 < if -6 temp ! then
       temp @ setto
       loc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
 tempref @ awake? not if continue then
 tempref @ location loc @ = not if continue then
         tempref @ {
         oldval @ temp @ = if
         "^[o^[c" target @ id_name "'s ^[yevasion can't go any " effect @ 0 > if "higher" else "lower" then "."
         else
 
   effect @ 1 = if
   "^[o^[c" target @ id_name "'s ^[yevasion raised."
   then
 
   effect @ 1 > if
   "^[o^[c" target @ id_name "'s ^[yevasion raised greatly."
   then
 
   effect @ -1 = if
   "^[o^[c" target @ id_name "'s ^[yevasion dropped."
   then
 
   effect @ -1 < if
   "^[o^[c" target @ id_name "'s ^[yevasion dropped greatly."
   then
 
         then
         }cat notify
 
         repeat
 
                              continue
       then
        effect @ "bellydrum" smatch if
                caster @ "status/hp" get atoi caster @ "maxhp" calculate 2 / <= if
                        "^[o^[cBut it failed..."  notify_watchers
                        break break
                else
                        caster @ "status/hp" over over get atoi caster @ "maxhp" calculate 2 / - setto
                        continue
                then
        then
 
        effect @ "psychoshift" smatch if
        begin
        0 temp !
           caster @ "status/frozen"    get if "frozen" temp ! break then
           caster @ "status/paralyzed" get if "paralyzed" temp ! break then
           caster @ "status/asleep"    get if "asleep" temp ! break then
           caster @ "status/poisoned"  get if "poisoned" temp ! break then
           caster @ "status/toxic"     get if "toxic" temp ! break then
           caster @ "status/burned"    get if "burned" temp ! break then
        break repeat
        begin
        0 temp2 !
           target @ "status/frozen"    get if "frozen" temp2 ! break then
           target @ "status/paralyzed" get if "paralyzed" temp2 ! break then
           target @ "status/asleep"    get if "asleep" temp2 ! break then
           target @ "status/poisoned"  get if "poisoned" temp2 ! break then
           target @ "status/toxic"     get if "toxic" temp2 ! break then
           target @ "status/burned"    get if "burned" temp2 ! break then
        break repeat
 
        temp @ temp2 @ not and if
        target @ { "status/" temp @ }cat caster @ { "status/" temp @ }cat get setto
        { "^[o^[c" target @ id_name "^[y is now ^[c" temp @ "^[y." }cat notify_watchers
        else
        "^[y^[oBut it failed..." notify_watchers
        then
        continue
        then
 
       effect @ "Flinched" smatch if
        (you can only flinch someone if they haven't attacked yet)
        target @ "ability" fget "inner focus" smatch
        caster @ moldbreaker
        if
        { "^[o^[c" target @ id_name "^[y was protected from flinching by its ability ^[cInner Focus^[y!" }cat notify_watchers
        continue then
        startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
        loc @ { "@battle/" BID @ "/declare/finished/" position @ }cat getprop not target @ "status/hp" get atoi 0 > and if
        loc @ { "@battle/" BID @ "/flinched/" position @ }cat target @ setprop
        { "^[o^[c" target @ id_name "^[y flinched!" }cat notify_watchers
        then
 
        continue
        then
 
       effect @ "frozen" smatch if
   bid @ check_weather weather !
   weather @ "sunny day" smatch if continue then
   loc @ { "@battle/" BID @ "/shields/" positionteam @ "/safeguard" }cat getprop targettype @ "target" smatch user @ "ability" fget "Infiltrator" smatch not and and if { "^[o^[c" target @ id_name "^[y was safeguarded from the effect of the attack!" }cat notify_watchers continue then
   target @ "status/frozen"    get if continue then
   target @ "status/paralyzed" get if continue then
   target @ "status/asleep"    get if continue then
   target @ "status/poisoned"  get if continue then
   target @ "status/toxic"     get if continue then
   target @ "status/burned"    get if continue then
   target @ "status/fainted"   get if continue then
   target @ "ability" fget "magma armor" smatch caster @ moldbreaker if continue then
   target @ "ability" fget "leaf guard" smatch bid @ check_weather "sunny day" smatch and caster @ moldbreaker  if continue then
   startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
          target @ typelist "ice" array_findval array_count not if
          target @ "status/Frozen" 1 setto
     loc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
     tempref @ awake? not if continue then
     tempref @ location loc @ = not if continue then
 
     tempref @ { "^[o^[c" target @ id_name "^[y has been ^[cfrozen^[y!" }cat notify
         repeat
 
          then
        continue
       then
 
 
 
           effect @ "PhysAtk*" smatch if
            effect @ " " "PhysAtk" subst strip atoi effect !
            target @ "ability" fget "contrary" smatch caster @ moldbreaker if effect @ -1 * effect ! then
            target @ "ability" fget "simple" smatch caster @ moldbreaker if effect @ 2 * effect ! then
            POKEDEX { "moves/" move @ "/weatherboost" }cat getprop dup if bid @ check_weather smatch if effect @ 2 * effect ! then else pop then
                   effect @ 0 < if
                   target @ "ability" fget "Clear Body" smatch target @ "ability" fget "White smoke" smatch or target @ "ability" fget "hyper cutter" smatch or targettype @ "self" smatch not and
                   caster @ moldbreaker
                   if { "^[o^[c" target @ id_name "^[y was protected by its ability ^[c" target @ "ability" fget cap "^[y." }cat notify_watchers continue then
                    loc @ { "@battle/" BID @ "/shields/" positionteam @ "/mist" }cat getprop targettype @ "target" smatch and if { "^[o^[c" target @ id_name "^[y was protected by mist from the attack's effect!" }cat notify_watchers continue then
                then
            startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
            target @ "status/statmods/PhysAtk" get atoi oldval !
            target @ "status/statmods/PhysAtk" over over get atoi effect @ + temp !
            temp @ 6 > if 6 temp ! then
            temp @ -6 < if -6 temp ! then
            temp @ setto
            loc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
            tempref @ awake? not if continue then
     tempref @ location loc @ = not if continue then
              tempref @ {
              oldval @ temp @ = if
              "^[o^[c" target @ id_name "'s ^[yPhysAtk can't go any " effect @ 0 > if "higher" else "lower" then "."
              else
 
        effect @ 1 = if
        "^[o^[c" target @ id_name "'s ^[yPhysAtk raised."
        then
 
        effect @ 1 > if
        "^[o^[c" target @ id_name "'s ^[yPhysAtk raised greatly."
        then
 
        effect @ -1 = if
        "^[o^[c" target @ id_name "'s ^[yPhysAtk dropped."
        then
 
        effect @ -1 < if
        "^[o^[c" target @ id_name "'s ^[yPhysAtk dropped greatly."
        then
 
              then
              }cat notify
 
              repeat
              continue
       then
 
        effect @ "PhysDef*" smatch if
                   effect @ " " "PhysDef" subst strip atoi effect !
                   target @ "ability" fget "simple" smatch caster @ moldbreaker if effect @ 2 * effect ! then
                   target @ "ability" fget "contrary" smatch caster @ moldbreaker if effect @ -1 * effect ! then
                   POKEDEX { "moves/" move @ "/weatherboost" }cat getprop dup if bid @ check_weather smatch if effect @ 2 * effect ! then else pop then
                       effect @ 0 < if
                           target @ "ability" fget "Clear Body" smatch target @ "ability" fget "White smoke" smatch or targettype @ "self" smatch not and
                           target @ "ability" fget "Big Pecks" smatch targettype @ "self" smatch not and or
                           caster @ moldbreaker
                           if { "^[o^[c" target @ id_name "^[y was protected by its ability ^[c" target @ "ability" fget cap "^[y." }cat notify_watchers continue then
                           loc @ { "@battle/" BID @ "/shields/" positionteam @ "/mist" }cat getprop targettype @ "target" smatch and if { "^[o^[c" target @ id_name "^[y was protected by mist from the attack's effect!" }cat notify_watchers continue then
                       then
                   startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
                   target @ "status/statmods/PhysDef" get atoi oldval !
                   target @ "status/statmods/PhysDef" over over get atoi effect @ + temp !
                   temp @ 6 > if 6 temp ! then
                   temp @ -6 < if -6 temp ! then
                   temp @ setto
                   loc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
                   tempref @ awake? not if continue then
     tempref @ location loc @ = not if continue then
 
                     tempref @ {
                     oldval @ temp @ = if
                     "^[o^[c" target @ id_name "'s ^[yPhysDef can't go any " effect @ 0 > if "higher" else "lower" then "."
                     else
 
               effect @ 1 = if
               "^[o^[c" target @ id_name "'s ^[yPhysDef raised."
               then
 
               effect @ 1 > if
               "^[o^[c" target @ id_name "'s ^[yPhysDef raised greatly."
               then
 
               effect @ -1 = if
               "^[o^[c" target @ id_name "'s ^[yPhysDef dropped."
               then
 
               effect @ -1 < if
               "^[o^[c" target @ id_name "'s ^[yPhysDef dropped greatly."
               then
 
                     then
                     }cat notify
 
                     repeat
                     continue
              then
 
           effect @ "SpecAtk*" smatch if
                          effect @ " " "SpecAtk" subst strip atoi effect !
                          target @ "ability" fget "simple" smatch caster @ moldbreaker if effect @ 2 * effect ! then
                          target @ "ability" fget "contrary" smatch caster @ moldbreaker if effect @ -1 * effect ! then
                          POKEDEX { "moves/" move @ "/weatherboost" }cat getprop dup if bid @ check_weather smatch if effect @ 2 * effect ! then else pop then
                       effect @ 0 < if
                           target @ "ability" fget "Clear Body" smatch target @ "ability" fget "White smoke" smatch or targettype @ "self" smatch not and
                           caster @ moldbreaker
                           if { "^[o^[c" target @ id_name "^[y was protected by its ability ^[c" target @ "ability" fget cap "^[y." }cat notify_watchers continue then
                           loc @ { "@battle/" BID @ "/shields/" positionteam @ "/mist" }cat getprop targettype @ "target" smatch and if { "^[o^[c" target @ id_name "^[y was protected by mist from the attack's effect!" }cat notify_watchers continue then
                       then
                          startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
                          target @ "status/statmods/SpecAtk" get atoi oldval !
                          target @ "status/statmods/SpecAtk" over over get atoi effect @ + temp !
                          temp @ 6 > if 6 temp ! then
                          temp @ -6 < if -6 temp ! then
                          temp @ setto
                          loc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
                          tempref @ awake? not if continue then
     tempref @ location loc @ = not if continue then
 
                            tempref @ {
                            oldval @ temp @ = if
                            "^[o^[c" target @ id_name "'s ^[ySpecAtk can't go any " effect @ 0 > if "higher" else "lower" then "."
                            else
 
                      effect @ 1 = if
                      "^[o^[c" target @ id_name "'s ^[ySpecAtk raised."
                      then
 
                      effect @ 1 > if
                      "^[o^[c" target @ id_name "'s ^[ySpecAtk raised greatly."
                      then
 
                      effect @ -1 = if
                      "^[o^[c" target @ id_name "'s ^[ySpecAtk dropped."
                      then
 
                      effect @ -1 < if
                      "^[o^[c" target @ id_name "'s ^[ySpecAtk dropped greatly."
                      then
 
                            then
                            }cat notify
 
                            repeat
                            continue
              then
       effect @ "SpecDef*" smatch if
                         effect @ " " "SpecDef" subst strip atoi effect !
                         target @ "ability" fget "simple" smatch caster @ moldbreaker if effect @ 2 * effect ! then
                         target @ "ability" fget "contrary" smatch caster @ moldbreaker if effect @ -1 * effect ! then
                         POKEDEX { "moves/" move @ "/weatherboost" }cat getprop dup if bid @ check_weather smatch if effect @ 2 * effect ! then else pop then
                       effect @ 0 < if
                           target @ "ability" fget "Clear Body" smatch target @ "ability" fget "White smoke" smatch or targettype @ "self" smatch not and
                           caster @ moldbreaker
                           if { "^[o^[c" target @ id_name "^[y was protected by its ability ^[c" target @ "ability" fget cap "^[y." }cat notify_watchers continue then
                           loc @ { "@battle/" BID @ "/shields/" positionteam @ "/mist" }cat getprop targettype @ "target" smatch and if { "^[o^[c" target @ id_name "^[y was protected by mist from the attack's effect!" }cat notify_watchers continue then
                       then
                                 startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
                                 target @ "status/statmods/SpecDef" get atoi oldval !
                                 target @ "status/statmods/SpecDef" over over get atoi effect @ + temp !
                                 temp @ 6 > if 6 temp ! then
                                 temp @ -6 < if -6 temp ! then
                                 temp @ setto
                                 loc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
                                 tempref @ awake? not if continue then
     tempref @ location loc @ = not if continue then
 
                                   tempref @ {
                                   oldval @ temp @ = if
                                   "^[o^[c" target @ id_name "'s ^[ySpecDef can't go any " effect @ 0 > if "higher" else "lower" then "."
                                   else
 
                             effect @ 1 = if
                             "^[o^[c" target @ id_name "'s ^[ySpecDef raised."
                             then
 
                             effect @ 1 > if
                             "^[o^[c" target @ id_name "'s ^[ySpecDef raised greatly."
                             then
 
                             effect @ -1 = if
                             "^[o^[c" target @ id_name "'s ^[ySpecDef dropped."
                             then
 
                             effect @ -1 < if
                             "^[o^[c" target @ id_name "'s ^[ySpecDef dropped greatly."
                             then
 
                                   then
                                   }cat notify
 
                                   repeat
                                   continue
              then
 
     effect @ "Speed*" smatch if
                      effect @ " " "Speed" subst strip atoi effect !
                      target @ "ability" fget "simple" smatch caster @ moldbreaker if effect @ 2 * effect ! then
                      target @ "ability" fget "contrary" smatch caster @ moldbreaker if effect @ -1 * effect ! then
                      POKEDEX { "moves/" move @ "/weatherboost" }cat getprop dup if bid @ check_weather smatch if effect @ 2 * effect ! then else pop then
                       effect @ 0 < if
                           target @ "ability" fget "Clear Body" smatch target @ "ability" fget "White smoke" smatch or targettype @ "self" smatch not and
                           caster @ moldbreaker
                           if { "^[o^[c" target @ id_name "^[y was protected by its ability ^[c" target @ "ability" fget cap "^[y." }cat notify_watchers continue then
                           loc @ { "@battle/" BID @ "/shields/" positionteam @ "/mist" }cat getprop targettype @ "target" smatch and if { "^[o^[c" target @ id_name "^[y was protected by mist from the attack's effect!" }cat notify_watchers continue then
                       then
                                      startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
                                      target @ "status/statmods/Speed" get atoi oldval !
                                      target @ "status/statmods/Speed" over over get atoi effect @ + temp !
                                      temp @ 6 > if 6 temp ! then
                                      temp @ -6 < if -6 temp ! then
                                      temp @ setto
                                      loc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
                                      tempref @ awake? not if continue then
          tempref @ location loc @ = not if continue then
                                        tempref @ {
                                        oldval @ temp @ = if
                                        "^[o^[c" target @ id_name "'s ^[ySpeed can't go any " effect @ 0 > if "higher" else "lower" then "."
                                        else
 
                                  effect @ 1 = if
                                  "^[o^[c" target @ id_name "'s ^[ySpeed raised."
                                  then
 
                                  effect @ 1 > if
                                  "^[o^[c" target @ id_name "'s ^[ySpeed raised greatly."
                                  then
 
                                  effect @ -1 = if
                                  "^[o^[c" target @ id_name "'s ^[ySpeed dropped."
                                  then
 
                                  effect @ -1 < if
                                  "^[o^[c" target @ id_name "'s ^[ySpeed dropped greatly."
                                  then
 
                                        then
                                        }cat notify
 
                                        repeat
                                        continue
              then
 
     effect @ "Allstats*" smatch if
                effect @ " " "Allstats" subst strip atoi effect !
                target @ "ability" fget "contrary" smatch caster @ moldbreaker if effect @ -1 * effect ! then
                target @ "ability" fget "simple" smatch caster @ moldbreaker if effect @ 2 * effect ! then
                       effect @ 0 < if
                           target @ "ability" fget "Clear Body" smatch target @ "ability" fget "White smoke" smatch or targettype @ "self" smatch not and
                           caster @ moldbreaker
                           if { "^[o^[c" target @ id_name "^[y was protected by its ability ^[c" target @ "ability" fget cap "^[y." }cat notify_watchers continue then
                           loc @ { "@battle/" BID @ "/shields/" positionteam @ "/mist" }cat getprop targettype @ "target" smatch and if { "^[o^[c" target @ id_name "^[y was protected by mist from the attack's effect!" }cat notify_watchers continue then
                       then
                startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
                target @ "status/statmods/Speed" over over get atoi effect @ + temp !
                temp @ 6 > if 6 temp ! then
                temp @ -6 < if -6 temp ! then
                temp @ setto
                target @ "status/statmods/SpecDef" over over get atoi effect @ + temp !
                temp @ 6 > if 6 temp ! then
                temp @ -6 < if -6 temp ! then
                temp @ setto
                target @ "status/statmods/SpecAtk" over over get atoi effect @ + temp !
                temp @ 6 > if 6 temp ! then
                temp @ -6 < if -6 temp ! then
                temp @ setto
                target @ "status/statmods/PhysDef" over over get atoi effect @ + temp !
                temp @ 6 > if 6 temp ! then
                temp @ -6 < if -6 temp ! then
                temp @ setto
                target @ "status/statmods/PhysAtk" over over get atoi effect @ + temp !
                temp @ 6 > if 6 temp ! then
                temp @ -6 < if -6 temp ! then
                temp @ setto
                {
              effect @ 1 = if
                "^[o^[c" target @ id_name "'s ^[ystats have all raised."
                then
 
                effect @ 1 > if
                "^[o^[c" target @ id_name "'s ^[ystats have all raised greatly."
                then
 
                effect @ -1 = if
                "^[o^[c" target @ id_name "'s ^[ystats have all dropped."
                then
 
                effect @ -1 < if
                "^[o^[c" target @ id_name "'s ^[ystats have all dropped greatly."
                then
                }cat    notify_watchers
 
                continue
     then
 
   effect @ "healbell" smatch if
   1 loc @ { "@battle/" BID @ "/teams/" position @ 1 1 midstr "/" }cat array_get_propvals array_count 1 for temp !
   loc @ { "@battle/" BID @ "/teams/" position @ 1 1 midstr "/" temp @ }cat getprop temp !
   
   (check for sound proof)
   ( This has been removed in gen V POKEDEX { "moves/" move @ "/soundproof" }cat getprop  
   if
           temp @ "ability" fget "soundproof" smatch
           attacker @ moldbreaker
           if
           { "^[o^[y But it failed on ^[c"who @ id_name " ^[ybecause they are soundproof..." }Cat notify_watchers
           continue
           then
        then
   )
   
           temp @ "status/frozen"    get if temp @ "status/frozen"                      0 setto  { "^[o^[cTeam " position @ 1 1 midstr "'s " temp @ id_name "^[y is no longer ^[cfrozen^[o^[y!" }cat notify_watchers then
           temp @ "status/paralyzed" get if temp @ "status/paralyzed"                   0 setto  { "^[o^[cTeam " position @ 1 1 midstr "'s " temp @ id_name "^[y is no longer ^[yparalyzed^[o^[y!" }cat notify_watchers then
           temp @ "status/asleep"    get if temp @ "status/asleep"                      0 setto  { "^[o^[cTeam " position @ 1 1 midstr "'s " temp @ id_name "^[y is no longer ^[basleep^[o^[y!" }cat notify_watchers then
           temp @ "status/poisoned"  get if temp @ "status/poisoned"                    0 setto  { "^[o^[cTeam " position @ 1 1 midstr "'s " temp @ id_name "^[y is no longer ^[mpoisoned^[o^[y!" }cat notify_watchers then
           temp @ "status/toxic"     get if temp @ "status/toxic"                       0 setto  { "^[o^[cTeam " position @ 1 1 midstr "'s " temp @ id_name "^[y is no longer ^[mbaddly poisoned^[o^[y!" }cat notify_watchers then
           temp @ "status/burned"    get if temp @ "status/burned"                      0 setto  { "^[o^[cTeam " position @ 1 1 midstr "'s " temp @ id_name "^[y is no longer ^[rburned^[o^[y!" }cat notify_watchers then
           temp @ "status/statmods/confused"  get if temp @ "status/statmods/confused"  0 setto  { "^[o^[cTeam " position @ 1 1 midstr "'s " temp @ id_name "^[y is no longer ^[xconfused^[o^[y!" }cat notify_watchers then
   repeat
   
   continue
   then
 
 
   effect @ "heal-*" smatch if
            effect @ " " "Heal-" subst strip effect !
            POKESTORE { "@pokemon/" target @ "/@RP/status/" effect @ }cat getprop not if continue then
            POKESTORE { "@pokemon/" target @ "/@RP/status/" effect @ }cat remove_prop
            {
            "^[o^[c" target @ id_name " ^yis cured of " effect @ "!"
 
            }cat notify_watchers
            continue
        then
 
   effect @ "seeded" smatch if
          var grasstype
          target @ "status/statmods/seeded"  get if
          "^[o^[yBut it failed..." notify_watchers
          continue then
 
          target @ typelist "grass" array_findval if 1 grasstype ! then
 
          grasstype @ if
          { "^[o^[c" target @ id_name "^[y is immune to being seeded!" }cat notify_watchers
          continue then
          startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
          target @ "status/statmods/seeded"
       pos @ setto
       { "^[o^[c" target @ id_name "^[y has been seeded!" }cat notify_watchers
       continue
       then
 
   effect @ "Toxic" smatch if
   loc @ { "@battle/" BID @ "/shields/" positionteam @ "/safeguard" }cat getprop targettype @ "target" smatch user @ "ability" fget "Infiltrator" smatch not and and if { "^[o^[c" target @ id_name "^[y was safeguarded from the effect of the attack!" }cat notify_watchers continue then
   target @ "status/frozen"    get if continue then
   target @ "status/paralyzed" get if continue then
   target @ "status/asleep"    get if continue then
   target @ "status/poisoned"  get if continue then
   target @ "status/toxic"     get if continue then
   target @ "status/burned"    get if continue then
   target @ "ability" fget "leaf guard" smatch bid @ check_weather "sunny day" smatch and caster @ moldbreaker  if continue then
   target @ "status/fainted"   get if continue then
   startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
             target @ typelist "poison" array_findval array_count if continue then
             target @ typelist "steel" array_findval array_count if continue then
             target @ "ability" fget "immunity" smatch
             caster @ moldbreaker
             if continue then
             target @ "status/Toxic" 1 setto
     loc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
     tempref @ awake? not if continue then
     tempref @ location loc @ = not if continue then
 
     tempref @ { "^[o^[c" target @ id_name "^[y has been ^[mbadly poisoned^[y!" }cat notify
         repeat
 
          continue
       then
 
   effect @ "paralyzed" smatch if
   loc @ { "@battle/" BID @ "/shields/" positionteam @ "/safeguard" }cat getprop targettype @ "target" smatch user @ "ability" fget "Infiltrator" smatch not and and if { "^[o^[c" target @ id_name "^[y was safeguarded from the effect of the attack!" }cat notify_watchers continue then
   target @ "status/frozen"    get if continue then
   target @ "status/paralyzed" get if continue then
   target @ "status/asleep"    get if continue then
   target @ "status/poisoned"  get if continue then
   target @ "status/toxic"     get if continue then
   target @ "status/burned"    get if continue then
   target @ "ability" fget "limber" smatch
   caster @ moldbreaker
   if continue then
   move @ attack_type "electric" smatch  target @ typelist "ground" array_findval array_count and if continue then
   target @ "ability" fget "leaf guard" smatch bid @ check_weather "sunny day" smatch and caster @ moldbreaker  if continue then
   target @ "status/fainted"   get if continue then
   startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
             target @ "status/paralyzed"
          1 setto
 
     loc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
     tempref @ awake? not if continue then
     tempref @ location loc @ = not if continue then
 
     tempref @ { "^[o^[c" target @ id_name "^[y has been ^[yparalyzed^[y!" }cat notify
         repeat
 
          continue
       then
 
     effect @ "Poisoned" smatch if
   loc @ { "@battle/" BID @ "/shields/" positionteam @ "/safeguard" }cat getprop targettype @ "target" smatch user @ "ability" fget "Infiltrator" smatch not and and if { "^[o^[c" target @ id_name "^[y was safeguarded from the effect of the attack!" }cat notify_watchers continue then
   target @ "status/frozen"    get if continue then
   target @ "status/paralyzed" get if continue then
   target @ "status/asleep"    get if continue then
   target @ "status/poisoned"  get if continue then
   target @ "status/toxic"     get if continue then
   target @ "status/burned"    get if continue then
   target @ "ability" fget "leaf guard" smatch bid @ check_weather "sunny day" smatch and caster @ moldbreaker  if continue then
   target @ "status/fainted"   get if continue then
   startsub @ target @ caster @ smatch not and if ({ "^[o^[c" position @ "." target @ id_name "'s^[y substitute protected it from the attack's effect!" }cat notify_watchers) continue then
             target @ typelist "poison" array_findval array_count if continue then
             target @ typelist "steel" array_findval array_count if continue then
             target @ "ability" fget "immunity" smatch
             caster @ moldbreaker
             if continue then
             target @ "status/Poisoned"
          1 setto
     loc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
     tempref @ awake? not if continue then
     tempref @ location loc @ = not if continue then
 
     tempref @ { "^[o^[c" target @ id_name "^[y has been ^[mPoisoned^[y!" }cat notify
         repeat
          continue
       then
 
  effect @ "foresight" smatch if
  target @ "status/statmods/foresight" 1 setto
  continue
 
  then
  effect @ "Miracle Eye" smatch if
  target @ "status/statmods/forsight" 1 setto
  target @ "status/statmods/Miracle Eye" 1 setto
  continue
  then
 
   effect @ "Weather*" smatch if
 
                 effect @ " " "Weather-" subst strip effect !
                 
                 effect @ bid @ check_weather smatch if
                        "^[o^[yBut it failed..." notify_watchers
                 continue
                 then
                 loc @ { "@battle/" bid @ "/roomweather" }cat effect @ setprop
                 6 temp !
                 effect @ "rain dance" smatch caster @ "holding" get "Damp Rock" smatch and position @ caster @ can_use_hold_item and if 9 temp ! then
                 effect @ "Hail" smatch caster @ "holding" get "Icy Rock" smatch and position @ caster @ can_use_hold_item and if 9 temp ! then
                 effect @ "sunny day" smatch caster @ "holding" get "Heat Rock" smatch and position @ caster @ can_use_hold_item and if 9 temp ! then
                 effect @ "sandstorm" smatch caster @ "holding" get "Smooth Rock" smatch and position @ caster @ can_use_hold_item and if 9 temp ! then
                 loc @ { "@battle/" bid @ "/roomweather/length" }cat temp @ setprop
                 {
                  effect @ "Hail" smatch if
                  "^[y^[oThe battle is hit with hail."
                  else
                    effect @ "Rain Dance" smatch if
       "^[y^[oRain begins to fall overhead."
      else
        effect @ "Sandstorm" smatch if
         "^[y^[oA harsh Sandstorm covers the battle."
        else
          effect @ "Sunny Day" smatch if
           "^[y^[oThe sun shines brightly."
                        then
                      then
                    then
                  then
 
                 }cat notify_watchers
        { "A1" "A2" "B1" "B2" }list foreach swap pop temp !
        loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop temp2 !
        temp2 @ if
                temp2 @ "ability" fget "forecast" smatch if temp2 @ forecast then
        then
        repeat
                 continue
 
        then
        effect @ "roar" smatch if
        target @ "status/hp" get not if continue then
        
        startsub @ POKEDEX { "moves/" move @ "/power" }cat getprop atoi and if
        (if the target started with a sub, and the move has power, this shoulden't trigger)
        continue
        then
        
        target @ "ability" fget "Suction Cups" smatch
        caster @ moldbreaker
        if
        { "^[o^[c" target @ id_name "^[y can't be forced from battle because of its ability ^[c" target @ "ability" fget cap "^[y!" }cat notify_watchers
        continue
        then
        target @ "status/statmods/ingrain/move" get if
        { "^[o^[c" target @ id_name "^[y can't be forced from battle because of the effects of ^[c" target @ "status/statmods/ingrain/move" get "^[y!"  }cat notify_watchers
        continue
        then
 
        loc @ { "@battle/" BID @ "/AItype" }cat getprop "wild" smatch
        loc @ { "@battle/" BID @ "/howmany" }cat getprop "1" smatch
        and
        if
 
        move @ "roar" smatch if
        target @ FindPokeLevel caster @ FindPokeLevel >= if
        { "^[o^[c" position @ "." target @ id_name "^[y was not impressed...!" }cat notify_watchers
        continue
        else
        { "^[o^[cTeam " position @ 1 1 midstr "^[y runs away!" }cat notify_watchers
        then
        else
        move @ "whirlwind" smatch if
        { "^[o^[cTeam " position @ 1 1 midstr "^[y was blown away from the battle!" }cat notify_watchers
        else
        { "^[o^[cTeam " position @ 1 1 midstr "^[y was thrown from the battle!" }cat notify_watchers
        then
        then
        loc @ { "@battle/" BID @ "/abort" }cat 1 setprop
        else
        loc @ { "@battle/" BID @ "/repeats/" position @ }cat remove_prop
        position @ forceswitch
        then
        continue
        then
 
        effect @ "lock-on" smatch if
                target @ { "status/statmods/lock-on/" pos @ "/user" }cat caster @ setto
                target @ { "status/statmods/lock-on/" pos @ "/count" }cat 2 setto
                { "^[o^[c" caster @ id_name "^[y is targeting ^[c" target @ id_name }Cat notify_watchers
                continue
        then
 
        effect @ "batonpass" smatch if
 
                bid @ pos @ switch_check not if
                "^[y^[oBut it failed..." notify_watchers
                continue then
                loc @ { "@battle/" BID @ "/control/team" pos @ 1 1 midstr "/" caster @ }cat getprop DBref? if
                loc @ { "@battle/" BID @ "/pause" }cat pos @ setprop
                loc @ { "@battle/" BID @ "/control/team" pos @ 1 1 midstr "/" caster @ }cat getprop "@battle/batonpass" pos @ setprop
                else
                loc @ { "@battle/" BID @ "/batonpass/" pos @ }cat 1 setprop
                then
 
                continue
        then
 
        (effect @ "beatup" smatch if
 
                loc @ { "@battle/" BID @ "/beatup/" pos @ }cat getprop if continue then
                loc @ { "@battle/" bid @ "/beatup/" pos @ }cat "yes" setprop
 
                continue
        then)
 
 
       effect @ "recoil*" smatch if
       caster @ "ability" fget "Rock Head" smatch if continue then
       caster @ "ability" fget "Magic Guard" smatch if continue then
                       effect @ " " "Recoil" subst strip atoi effect !
                    damage @ effect @ / var! rec
                    damage @ not if continue then
                    rec @ not if 1 rec ! then
                    caster @ "status/hp" caster @ "status/hp" get atoi rec @ - setto
 
                 { "^[o^[c" caster @ id_name " ^[ywas hurt by recoil!" }cat notify_watchers
                    caster @ "status/hp" get atoi 0 <= if
                    POKESTORE { "@pokemon/" caster @ "/@RP/status" }cat remove_prop
           caster @ "status/hp" 0 setto
                caster @ "status/fainted" 1 setto
                    { "^[o^[c" caster @ id_name " ^[yhas fainted due to recoil!" }cat notify_watchers
                    then
                    continue
       then
 
        effect @ "substitute" smatch if
        target @ "status/statmods/substitute" get if
        { "^[o^[yBut it failed..." }cat notify_watchers
        continue then
        target @ "maxhp" calculate 4 target @ "pvp/hpboost" fget dup if atoi * else pop then / var! subhp
        target @ "maxhp" calculate 1 =
        target @ "status/hp" get atoi subhp @ <= or
        if
        { "^[o^[yBut it failed..." }cat notify_watchers
        continue
        then
        target @ "status/hp" over over get atoi subhp @ - setto
        target @ "status/statmods/substitute" subhp @ 1 + setto
        { "^[o^[c" position @ "." caster @ id_name "^[y makes a little substitute target of itself!" }cat notify_watchers
        continue
        then
 
        effect @ "spite" smatch if
 
 
        target @ "status/statmods/MoveContinued/movename" get lastmove !
        lastmove @ not
        lastmove @ stringify "skip"  smatch or
        if
        "^[o^[yBut it failed..." notify_watchers
        continue
        then
 
        target @ { "/movesknown/" lastmove @ "/pp" }cat over over fget atoi 4 - fsetto
        { "^[o^[c" lastmove @ cap "^[y was lowered by 4 PP!" }cat notify_watchers
        target @ { "/movesknown/" lastmove @ "/pp" }cat fget atoi 1 < if
        target @ { "/movesknown/" lastmove @ "/pp" }cat 0
        then
        continue
        then
 
        effect @ "gravity" smatch if
                loc @ { "@battle/" BID @ "/gravity" }cat 6 setprop
        continue
        then
 
        effect @ "roost" smatch if
                caster @ "status/statmods/roost" 1 setto
        continue
        then
        
        effect @ "smackdown" smatch if
                caster @ "status/statmods/smackdown" 1 setto
        continue
        then
 
        effect @ "MagnetRise" smatch if
                target @ "status/statmods/ingrain/move" get
                target @ "ability" fget "levitate" smatch or
                if
                "^[o^[yBut it failed..." notify_watchers
                continue
                then
 
                caster @ "status/statmods/Magnet Rise" 6 setto
        continue
        then
 
        effect @ "removeability" smatch if
        startsub @ if continue then
        POKESTORE { "@pokemon/" target @ fid "/@temp/ability" }Cat "Disabled" setprop
        target @ "status/statmods/abilityremoved" 1 setto
        { "^[o^[c" target @ id_name "^[y had its ability disabled!" }cat notify_watchers
        continue
        then
 
        effect @ "followme" smatch if
        position @ "A*" smatch if
        "B" temp !
        else
        "A" temp !
        then
        loc @ { "@battle/" BID @ "/followme/" temp @ }cat position @ setprop
        { "^[o^[cTeam " temp @ "^[y must now target ^[c" caster @ id_name "^[y." }cat notify_watchers
        continue
        then
 
        var helditem
        effect @ "switcheroo" smatch if
        startsub @ if continue then
                target @ "holding" get "Nothing" smatch
                caster @ "holding" get "Nothing" smatch and not
                target @ "ability" fget "sticky hold" smatch
                caster @ moldbreaker
                not and
                target @ "ability" fget "multitype" smatch
                target @ "holding" get "*plate" smatch and
                not and
                if
 
                target @ "holding" get helditem !
                POKESTORE { "@pokemon/" target @ "/@long/holding" }cat caster @ "holding" get setprop
                loc @ { "@battle/" BID @ "/recycle/" tposition @  }cat caster @ "holding" get setprop
                POKESTORE { "@pokemon/" caster @ "/@long/holding" }cat helditem @ setprop
                loc @ { "@battle/" BID @ "/recycle/" position @ }cat helditem @ setprop
                target @ "status/statmods/choice item/" wipe
                caster @ "status/statmods/choice item/" wipe
                { "^[o^[c" caster @ id_name "^[y and ^[c" target @ id_name "^[y had its hold items switched!" }cat notify_watchers
                
                else
                "^[o^[yBut it failed..." notify_watchers
                then
                continue
        then
 
        effect @ "encore" smatch if
                target @ "status/statmods/encore/move" get if
                "^[o^[yBut it failed..." notify_watchers
                continue
                then
 
                target @ "status/statmods/movecontinued/movename" get temp !
                temp @ not if
                        "^[o^[yBut it failed..." notify_watchers
                        continue
                then
 
                temp @ "encore" smatch
                temp @ "mimic" smatch or
                temp @ "transform" smatch or
                temp @ "sketch" smatch or
                temp @ "mirror move" smatch or
                temp @ "struggle" smatch or if
                        "^[o^[yBut it failed..." notify_watchers
                        continue
                then
                (remember, anything with turns give one more than it needs since you deduct the turns at the end of the turn)
                target @ "status/statmods/encore/turns" 4 setto
                target @ "status/statmods/encore/move" temp @ setto
                { "^[o^[c" target @ id_name "^[y is in Encore." }cat notify_watchers
        continue
        then
 
        effect @ "knockoff" smatch if
                startsub @ if continue then
                target @ "holding" get "Nothing" smatch not
                target @ "ability" fget "sticky hold" smatch
                caster @ moldbreaker
                not and
                target @ "ability" fget "multitype" smatch
                target @ "holding" get "*plate" smatch and
                not
                and if
                target @ "holding" get helditem !
                POKESTORE { "@pokemon/" target @ "/@long/holding" }cat "Nothing" setprop
                { "^[o^[c" caster @ id_name "^[y knocked off ^[c" target @ id_name "'s " helditem @ "^[y!" }cat notify_watchers
                else
                ( "^[o^[yBut it failed..." notify_watchers )
                then
                continue
        then
 
        effect @ "thief" smatch if
        startsub @ if continue then
                caster @ "holding" get "Nothing" smatch
                target @ "holding" get "Nothing" smatch not and
                target @ "ability" fget "sticky hold" smatch
                caster @ moldbreaker
                not and
                target @ "ability" fget "multitype" smatch
                target @ "holding" get "*plate" smatch and
                not and if
                target @ "holding" get helditem !
                POKESTORE { "@pokemon/" target @ "/@long/holding" }cat "Nothing" setprop
                POKESTORE { "@pokemon/" caster @ "/@long/holding" }Cat helditem @ setprop
                { "^[o^[c" caster @ id_name "^[y has stolen ^[c" target @ id_name "'s " helditem @ "^[y!" }cat notify_watchers
                else
                "^[o^[yBut it failed..." notify_watchers
                then
 
 
                continue
        then
 
        effect @ "magiccoat" smatch if
                loc @ { "@battle/" BID @ "/magic coat/" position @ }cat "yes" setprop
                continue
        then
 
        effect @ "stockpile" smatch if
                target @ "status/statmods/stockpile" get atoi 3 = if
                        "^[o^[yBut it failed..." notify_watchers
                        break break (stop the loop)
                then
 
        target @ "status/statmods/stockpile" over over get atoi 1 + setto
        continue
        then
 
        effect @ "swallow" smatch if
        target @ "status/statmods/stockpile" get not if
                "^[o^[yBut it failed..." notify_watchers
                break break (stop the loop)
        then
        target @ "status/statmods/stockpile" get atoi stockpile !
        stockpile @ 1 = if target @ "status/hp" over over get atoi target @ "maxhp" calculate 4 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage + setto then
        stockpile @ 2 = if target @ "status/hp" over over get atoi target @ "maxhp" calculate 2 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage + setto then
        stockpile @ 3 = if target @ "status/hp" over over get atoi target @ "maxhp" calculate 1 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage + setto then
        target @ "status/hp" get atoi target @ "maxhp" calculate > if
        target @ "status/hp" target @ "maxhp" calculate setto then
        continue
        then
 
        effect @ "removestockpile" smatch if
        target @ "status/statmods/stockpile" get atoi stockpile !
        target @ "status/statmods/stockpile" 0 setto
        continue
        then
 
        effect @ "Imprison" smatch if
 
                target @ "status/statmods/imprisoned/user" get if
                "^[y^[oBut it failed..." notify_watchers
 
                continue
                then
                target @ "movesknown" fgetvals temp !
                caster @ "movesknown" fgetvals temp2 !
 
                (i shoulden't have to do this)
                { temp @ foreach pop cap repeat }list temp !
                { temp2 @ foreach pop cap repeat }list temp2 !
                (end stupid part)
 
                0 counter !
                temp2 @
                temp @
                array_intersect
                arrayx !
                arrayx @ not if
                "^[o^[yBut it failed..." notify_watchers
 
                continue
                then
                arrayx @ 0 array_getitem not if
                "^[o^[yBut it failed..." notify_watchers
 
                continue
                then
                target @ "status/statmods/imprisoned/user" caster @ setto
                arrayx @ array_count var! truemax
                var max
                truemax @ max !
 
                max @ 2 / max !
                max @ 4 < if 4 max ! then
                truemax @ 4 < if truemax @ max ! then
                arrayx @ 4 array_sort foreach swap pop temp !
                counter @ max @ >= if break then
                counter @ 1 + counter !
                { "^[o^[c" target @ id_name "^[y had ^[c" temp @ cap "^[y imprisoned!" }cat notify_watchers
                target @ { "status/statmods/imprisoned/move/" temp @ }cat 1 setto
 
                repeat
 
        continue
        then
        effect @ "torment" smatch if
                target @ "status/statmods/torment" get if
                "^[o^[yBut it failed..." notify_watchers
                continue
                then
 
                target @ "status/statmods/torment" 1 setto
                { "^[o^[c" target @ id_name "^[y is now tormented!" }cat notify_watchers
 
        continue
        then
 
        effect @ "sketch" smatch if
              loc @ { "@battle/" BID @ "/xp" }cat getprop not if
              "^[o^[yBut it failed... can't sketch in non xp earning battle." notify_watchers
              continue
              then
              (check the current movesknown, first see if @temp is populated so it works for ditto, then check  @custom then @RP, skip @long)
              
              var layer
              
              { "@temp" "@custom" "@RP" }list foreach layer ! pop
              POKESTORE { "@pokemon/" attacker @ fid "/" layer @ "/movesknown" }cat propdir? if break then
              repeat
              POKESTORE { "@pokemon/" attacker @ fid "/" layer @ "/movesknown" }cat array_get_propvals array_count 1 - temp !
              
              temp @
              attacker @ FindPokeLevel 5 / dup 4 < if pop 4 then
 
              >= if
              "^[o^[yBut it failed because it knows too many moves for now." notify_watchers
                continue
              then
              target @ "status/statmods/movecontinued/movename" get var! newmove (to get the last move used)
              newmove @ not if
              "^[o^[yBut it failed..." notify_watchers
              continue
              then
 
              attacker @ { "movesknown/" newmove @ }cat fget if
                { "^[o^[yBut they already know ^[c" newmove @ cap "^[y..." }Cat notify_watchers
                continue
              then
 
              (Make sure to include some check against a list of moves that can't be sketched)
              newmove @ "skip" smatch
              newmove @ "struggle" smatch or
              newmove @ "sketch" smatch or if
              "^[o^[yBut it failed..." notify_watchers
              continue
              then
 
              POKESTORE { "@pokemon/" attacker @ fid "/" layer @ "/movesknown/" newmove @ }cat 1 setprop
              POKESTORE { "@pokemon/" attacker @ fid "/" layer @ "/movesknown/" newmove @ "/pp" }cat
              POKEDEX { "moves/" newmove @ "/pp" }cat getprop
              setprop
              
              POKESTORE { "@pokemon/" attacker @ fid "/" layer @ "/movesknown/sketch" }cat remove_prop
              
              loc @ { "@battle/" BID @ "/4moves" }cat getprop if
                loc @ { "@battle/" BID @ "/movesets/" attacker @ }cat getprop temp !
                
                { "A" "B" "C" "D" }list foreach temp2 ! pop
                
                attacker @ { "movesets/" temp @ "/" temp2 @ }cat fget temp3 ! temp3 @ if temp3 @ "sketch" smatch if 
                        loc @ { "@battle/" BID @ "/movesets/" attacker @ "/" temp2 @ }cat newmove @ setprop
                        attacker @ { "movesets/" temp @ "/" temp2 @ }cat newmove @ fsetto break then else then
                repeat
                
                POKESTORE { "@pokemon/" attacker @ fid "/" layer @ "/movesknown/" newmove @ }cat 1 setprop
                POKESTORE { "@pokemon/" attacker @ fid "/" layer @ "/movesknown/" newmove @ "/pp" }cat  POKEDEX { "moves/" newmove @ "/pp" }cat getprop setprop
                POKESTORE { "@pokemon/" attacker @ fid "/" layer @ "/movesknown/Sketch" }cat 0 setprop
                
              then
              
              { "^[o^[yJust learned ^[c" newmove @ cap "^[y!" }cat notify_watchers
              continue
    then
 
        effect @ "disable" smatch if
                target @ "status/statmods/disabled/move" get if
                "^[o^[yBut it failed..." notify_watchers
                continue
                then
                target @ "status/statmods/movecontinued/movename" get temp !
                temp @ not if
                        "^[o^[yBut it failed..." notify_watchers
                        continue
                then
                target @ "status/statmods/encore/turns" "" setto
                target @ "status/statmods/encore/move" "" setto
                target @ "status/statmods/disabled/move" temp @ setto
                (remember, anything with turns give one more than it needs since you deduct the turns at the end of the turn)
                target @ "status/statmods/disabled/turns" random 8 % 2 + setto
                        { "^[o^[c" temp @ cap "^[y is now disabled!" }cat notify_watchers
        continue
        then
 
        effect @ "Healblock" smatch if
        startsub @ if continue then
                target @ "status/statmods/healblock" get if
                "^[o^[yBut it failed..." notify_watchers
                continue
                then
                target @ "status/statmods/healblock" 6 setto
                { "^[o^[c" target @ id_name "^[y is now unable to use healing moves." }cat notify_watchers
        continue
        then
 
        effect @ "taunt" smatch if
                target @ "Status/statmods/taunted" get 
                target @ "ability" fget "Oblivious" smatch or
                if
                "^[o^[yBut it failed..." notify_watchers
                continue
                then
                target @ "status/statmods/taunted" 4 setto
                { "^[o^[c" target @ id_name "^[y is now forced to only use damaging moves." }cat notify_watchers
        continue
        then
 
        effect @ "Conversion" smatch if
 
        target @ "fusion" get if
         target @ "fusion" get temp2 ! else target @ temp2 ! then
 
         target @ "movesknown" fgetvals arrayx !
        random arrayx @ array_count % 1 + movenum !
        0 counter !
        arrayX @ foreach pop temp !
        counter @ 1 + counter !
        POKEDEX { "/moves/" temp @ "/type" }cat getprop dup "???" smatch if pop "Normal" then effect !
        counter @ movenum @ = if break then
        repeat
 
        { "^[o^[c" target @ id_name "^[y changed its type to ^[c" effect @ cap "^[y."}cat notify_watchers
        target @ "status/statmods/type" effect @ setto
        continue
        then
 
 
        effect @ "Conversion2" smatch if
 
        loc @ { "@battle/" BID @ "/position/" tposition @ }cat getprop effect !
        effect @ "status/statmods/MoveContinued/MoveName" get effect !
        effect @ not if "^[y^[oBut it failed..." notify_watchers continue then
        effect @ "???" smatch if "^[y^[oBut it failed..." notify_watchers continue then
 
        {
        POKEDEX { "typetable/" effect @ "/" }cat array_get_propvals foreach
 
        strtof 0 > if pop 0 then
        temp !
        temp @ if
        target @ typelist foreach swap pop temp @ smatch if 0 temp ! break then repeat
 
        temp @ if
        temp @
        then
        then
        repeat
        }list arrayx !
        arrayx @ not if
        "^[y^[oBut it failed..." notify_watchers  continue
        then
 
        arrayx @ 4 array_sort foreach swap pop effect !
        break
        repeat
 
        { "^[o^[c" target @ id_name "^[y changed its type to ^[c" effect @ cap "^[y."}cat notify_watchers
        target @ "status/statmods/type" effect @ setto
 
        continue
        then
 
        effect @ "guardswap" smatch if
                caster @ "status/statmods/PhysDef" get temp !
                caster @ "status/statmods/PhysDef"  target @ "status/statmods/PhysDef" get setto
                target @ "status/statmods/PhysDef" temp @ setto
 
                caster @ "status/statmods/SpecDef" get temp !
                caster @ "status/statmods/SpecDef"  target @ "status/statmods/SpecDef" get setto
                target @ "status/statmods/SpecDef" temp @ setto
 
                { "^[o^[c" caster @ id_name "^[y and ^[c" target @ id_name "^[y had its def boosts swapped!" }Cat notify_watchers
 
        continue
        then
 
        effect @ "powerswap" smatch if
                caster @ "status/statmods/PhysAtk" get temp !
                caster @ "status/statmods/PhysAtk"  target @ "status/statmods/PhysAtk" get setto
                target @ "status/statmods/PhysAtk" temp @ setto
 
                caster @ "status/statmods/SpecAtk" get temp !
                caster @ "status/statmods/SpecAtk"  target @ "status/statmods/SpecAtk" get setto
                target @ "status/statmods/SpecAtk" temp @ setto
 
                { "^[o^[c" caster @ id_name "^[y and ^[c" target @ id_name "^[y had its atk boosts swapped!" }Cat notify_watchers
 
        continue
        then
        effect @ "powertrick" smatch if
                caster @ "status/statmods/powertrick" 1 setto
                { "^[o^[c" caster @ id_name "^[y swaps attack and defense stats!" }Cat notify_watchers
        continue
        then
 
        effect @ "heartswap" smatch if
                { "PhysAtk" "PhysDef" "SpecAtk" "SpecDef" "Speed" }list foreach swap pop temp !
                caster @ { "status/statmods/" temp @ }cat get temp2 !
                caster @ { "status/statmods/" temp @ }cat target @ { "status/statmods/" temp @ }cat get setto
                target @ { "status/statmods/" temp @ }cat temp2 @ setto
                repeat
                { "^[o^[c" caster @ id_name "^[y and ^[c" target @ id_name "^[y had its stat boosts swapped!" }Cat notify_watchers
        continue
        then
 
        effect @ "HealingWish" smatch if
                loc @ { "@battle/" BID @ "/HealingWish/" position @ }cat "yes" setprop
        continue
        then
 
        effect @ "wish" smatch if
                loc @ { "@battle/" BID @ "/Wish/" position @ }cat getprop if
                "^[y^[oBut it failed..." notify_watchers
                continue
                then
                loc @ { "@battle/" BID @ "/Wish/" position @ }cat 2 setprop
        continue
        then
        effect @ "lunardance" smatch if
                loc @ { "@battle/" BID @ "/LunarDance/" position @ }cat "yes" setprop
        continue
        then
 
        effect @ "haze" smatch if
                { "A1" "A2" "A3" "B1" "B2" "B3" }list foreach temp ! pop
                loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop not if continue then
                loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop temp2 !
                { "PhysAtk" "PhysDef" "Speed" "SpecAtk" "SpecDef" "Accuracy" "Evasion" }list foreach swap pop temp3 !
                        temp2 @ { "status/statmods/" temp3 @ }cat 0 setto
                repeat
                repeat
                "^[y^[oThe entire field's stat changes were removed!" notify_Watchers
        continue
        then
 
         effect @ "reflecttype" smatch if
                target @ "ability" "multitype" smatch if
                 "^[o^[yBut it failed..." notify_watchers
                 continue
                 then
                 
                 caster @ "status/statmods/type" target @ typelist temp ! 
                 temp @ array_count 1 = if 
                        temp @
                 else
                        0 temp2 !
                        temp @ foreach swap pop 
                                temp2 @ not if temp2 ! else { swap temp2 @ swap ":" swap }cat temp2 ! then
                        repeat temp2 @
                then setto
                 { "^[o^[c" caster @ id_name "'s ^[ytype changed to match ^[c" target @ id_name "^[y!" }cat notify_watchers
                 
         continue
        then
 
        effect @ "Camouflage" smatch if
 
        loc @ "@locationtype" getprop env !
        env @ not if "none" env ! then
 
 
        begin
        env @ "grass*" smatch if
        "Grass"
        break
        then
 
        env @ "snow" smatch if
        "Ice"
        break
        then
 
        env @ "water" smatch if
        "Water"
        break
        then
 
        env @ "rock" smatch if
        "Rock"
        break
        then
 
        env @ "building" smatch if
        "Normal"
        break
        then
 
        env @ "path" smatch if
        "Normal"
        break
        then
 
        env @ "sand" smatch if
        "Ground"
        break
        then
 
        "Normal"
        break repeat
 
        effect !
        { "^[o^[c" target @ id_name "^[y changed its type to ^[c" effect @ cap "^[y."}cat notify_watchers
        target @ "status/statmods/type" effect @ setto
        continue
        then
 
        effect @ "destinybond" smatch if
        loc @ { "@battle/" BID @ "/destinybond/" caster @ }cat "yes" setprop
 
        continue
        then
 
        effect @ "grudge" smatch if
        loc @ { "@battle/" BID @ "/grudge/" caster @ }cat "yes" setprop
        continue
        then
 
        effect @ "curse" smatch if
 
                caster @ typelist foreach swap pop dup temp !
                temp @ "Ghost" smatch if "Ghost" effect ! then
                repeat
 
                effect @ "ghost" smatch if
                caster @ "status/hp" over over get atoi caster @ "maxhp" calculate 2 caster @ "pvp/hpboost" fget dup if atoi * else pop then divdamage - setto
                caster @ "status/hp" get atoi 0 <= if
                          POKESTORE { "@pokemon/" caster @ "/@RP/status" }cat remove_prop
                          caster @ "status/hp" 0 setto
                caster @ "status/fainted" 1 setto
                then
                target @ "status/statmods/cursed" 1 setto
                { "^[o^[c" target @ id_name "^[y is now cursed!" }cat notify_watchers
                else
 
                { "^[o^[c" caster @ id_name "^[y raised its PhysAtk and PhysDef stat by sacrificing its Speed!" }cat notify_watchers
                caster @ "status/statmods/PhysAtk" over over get atoi 1 + dup 6 > if pop
                { "^[o^[y" caster @ id_name "'s ^[yPhysical Attack can't go any higher." }cat notify_watchers 6 then setto
                caster @ "status/statmods/PhysDef" over over get atoi 1 + dup 6 > if pop
                { "^[o^[y" caster @ id_name "'s ^[yPhysical Defense can't go any higher." }cat notify_watchers 6 then setto
                caster @ "status/statmods/Speed" over over get atoi 1 - dup -6 < if pop
                { "^[o^[y" caster @ id_name "'s ^[ySpeed can't go any lower." }cat notify_watchers -6 then setto
                then
        continue
        then
 
   repeat
 
  (do another effect)
  repeat
then
 
;
 
$libdef damage_calc
: damage_calc
cap pos ! cap tpos ! BID ! attacker ! who ! move !

(set debug prop)
#0 "@debug" getprop if 1 debug ! then
 
attacker @ user !
user @ "status/fainted" get if exit then
 
who @ check_status majorstatus !
0 heal !
0 misshurtself !
0 noeffect !

 
who @ "status/hp" get atoi who @ "maxhp" calculate = if 1 else 0 then StartedFullHP !
who @ "status/statmods/substitute" get if 1 else 0 then startsub !
 
(check if its a target must be sleeping move)
POKEDEX { "moves/" move @ "/mustasleep" }cat getprop if
        who @ "status/asleep" get not if
        { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y but fails because ^[c" tpos @ "." who @ id_name " ^[yisn't asleep!" }Cat notify_watchers
        exit
        then
then
(check if the move has to be used first only)
POKEDEX { "moves/" move @ "/firstonly" }cat getprop if
        attacker @ "status/statmods/turns-out" get atoi 1 > if
        { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y but fails because it isn't its first move!" }Cat notify_watchers
        exit
        then
then
 
(check if other moves were used first, this is for last resort)
 
move @ "last resort" smatch if
        attacker @ "status/statmods/SuccessfulMoves" getvals array_count temp !
        temp @
        attacker @ "movesknown" fgetvals array_count temp2 !
        temp2 @ 1 = if
        { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y but fails because it can't be its only move!" }Cat notify_watchers
        exit
        then
        temp2 @ 4 > if 4 temp2 ! then
        temp2 @ 1 - temp2 !
        temp2 @ temp @ > if
        { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y but fails because it needs to use more moves first!" }Cat notify_watchers
        exit
        then
then
 
(check for sound proof)
POKEDEX { "moves/" move @ "/soundproof" }cat getprop if POKEDEX { "moves/" move @ "/soundproof" }cat getprop "yes" smatch if 1 else 0 then else 0 then
(for now until a better solution, just check if move has properity of soundbell and ignore its soundproofing here.)
POKEDEX { "moves/" move @ "/effects" }cat getprop if POKEDEX { "moves/" move @ "/effects" }cat getprop "*healbell*" smatch not if 1 else 0 then else 0 then and
if
        who @ "ability" fget "soundproof" smatch
        attacker @ moldbreaker
        if
        { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y but fails because ^[c" tpos @ "." who @ id_name " ^[yis soundproof!" }Cat notify_watchers
        exit
        then
then
 
(check for Motor Drive ability)
who @ "ability" fget "Motor Drive" smatch
attacker @ moldbreaker
if
        who @ typelist "ground" array_findval array_count not if
                attacker @ { "moves/" move @ "/type" }cat get "electric" smatch if
                { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y but ^[c" tpos @ "." who @ id_name "^[y absorbs its energy because of its ability ^[c " who @ "ability" fget cap "^[y!" }Cat notify_watchers
                who @ "status/statmods/Speed" over over get atoi 1 + setto
                exit
                then
        then
then
1 var! semi-inv-breaker
 (since triple kick is special and has to be accuracy checked 3 times, we put its modification here)
 move @ "triple kick" smatch if 3 tkcount ! -10 tkdamage ! else 1 tkcount ! then
 1 tkcount @ 1 for pop
 move @ "triple kick" smatch if tkdamage @ 10 + tkdamage ! then
 
 
(set recharging moves)
loc @ { "@battle/" BID @ "/charge/" pos @ "/recharge" }cat
POKEDEX { "moves/" move @ "/recharge" }cat getprop atoi
setprop
(endrecharging)
move @ "future attack" smatch not if
POKEDEX { "moves/" move @ "/target" }cat getprop "self" smatch not if
 (here goes the rod abilities)
 loc @ { "@battle/" BID @ "/followme/" tpos @ 1 1 midstr }cat getprop not if
   user @ { "moves/" move @ "/type" }cat get movetype !
   who @ "ability" fget "Storm Drain" smatch
   movetype @ "water" smatch and
   who @ "ability" fget "Lightningrod" smatch
   movetype @ "electric" smatch and
  or
  user @ moldbreaker
  if
  { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y but it is drawn to ^[c" tpos @ "." who @ id_name "^[y because of its ability ^[c" who @ "ability" fget cap "^[y!" }Cat notify_watchers
  
  
  
 
then
then
 
(loc @ { "@battle/" BID @ "/beatup/" pos @ }cat getprop not if)
 
move @ "feint" smatch if
        who @ "status/statmods/protected" get if
                { "^[o^[c" tpos @ "." who @ id_name "[y fell for the Feint!" }cat notify_watchers
                who @ "status/statmods/protected" "" setto
        then
        tpos @ 1 1 midstr pos @ 1 1 midstr smatch not if
                loc @ { "@battle/" BID @ "/shields/" tpos @ 1 1 midstr "/" }cat remove_prop
        then
then
 
POKEDEX { "/moves/" move @ "/nothurt" }cat getprop
loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn/" pos @ }cat getprop and if
        { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y on ^[c" tpos @ "." who @ id_name "^[y but it failed!" }Cat notify_watchers
exit
then
 
move @ "future sight" smatch
move @ "doom desire" smatch or not if
 
 POKEDEX { "moves/" move @  "/accuracy" }cat getprop atoi accuracy !
 user @ "holding" get "wide lens" smatch if accuracy @ 1.10 * floor accuracy ! then 
 move @ "future attack" smatch if  POKEDEX { "moves/" loc @ { "@battle/" BID @ "/future attack/" pos @ "/attack" }cat getprop "/accuracy" }cat getprop atoi accuracy ! then
 
 user @ FindPokeLevel var! level
 who @ findpokelevel var! tarlevel
 
 (here is wher we apply the accuracy modifications)
 (OHKO moves have their own rules)
 POKEDEX { "moves/" move @ "/OHKO" }cat getprop dup not if pop "no" then "yes" smatch if
 
  who @ "status/statmods/protected" get if
        POKEDEX { "moves/" move @ "/protect?" }cat getprop "yes" smatch if
        { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y on ^[c" tpos @ "." who @ id_name "^[y but they were protected and unaffected!" }Cat notify_watchers
        exit
        then
 
  then
 who @ "ability" fget "sturdy" smatch
 attacker @ moldbreaker
 if
         { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y on ^[c" tpos @ "." who @ id_name "^[y but they have the ability ^[c" who @ "ability" fget cap "^[y!" }Cat notify_watchers
         exit
 then
 level @ tarlevel @ < if
 { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y on ^[c" tpos @ "." who @ id_name "^[y but it failed..." }Cat notify_watchers
 exit
 else
 level @ tarlevel @ - 30.0 + 100 / accuracy !
 
 then
 
 else
 
 (before accuracy is taken into consideration, we use the protected status check)
 
 (check if the move is gravity disabled, fail if it is)
 
 loc @ { "@battle/" BID @ "/gravity" }cat getprop if
        POKEDEX { "moves/" move @ "/gravityfail" }cat getprop if
        { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y on ^[c" tpos @ "." who @ id_name "^[y but the gravity stopped them!" }Cat notify_watchers
        exit
 then
 then
 
 user @ "Accuracy" calculate var! UserAcc
        POKEDEX { "moves/" move @ "/class" }cat getprop "physical" smatch if
          user @ "ability" fget "Hustle" smatch if
          UserAcc @ 0.8 * UserAcc !
          then
        then
 
 1 who @ "Evasion" move @ "IgnoreStatMods" get if basecalculate else calculate then -
 who @ "ability" fget "Sand veil" smatch bid @ check_weather "sandstorm" smatch and
 who @ "ability" fget "snow cloak" smatch bid @ check_weather "hail" smatch and or
 user @ moldbreaker
 if
 1.20 /
 then
 
 who @ "ability" fget "tangled feet" smatch
 who @ "status/statmods/confused" get and 
 user @ moldbreaker
 if 1.20 /  then
 
  var! WhoEva
 
 who @ "holding" get "brightpowder" smatch tpos @ who @ can_use_hold_item and if WhoEva @ 0.10 - WhoEva ! then
 who @ "holding" get "lax incense" smatch tpos @ who @ can_use_hold_item and if WhoEva @ 0.05 - WhoEva ! then
 who @ "status/statmods/foresight" get WhoEva @ 1.0 < and if
 1.0 WhoEva ! then
 
 
 var moveaccuracy
 accuracy @ moveaccuracy !
 
 bid @ check_weather weather !
 
 move @ "blizzard" smatch if
        weather @ "hail" smatch if
        100000 moveaccuracy !
        then
 then
 
 move @ "thunder" smatch if
        weather @ "rain dance" smatch if
        100000 moveaccuracy !
        then
        
        weather @ "sunny day" smatch if
        50 moveaccuracy !
        then
 then
 
 move @ "hurricane" smatch if
         weather @ "rain dance" smatch if
         100000 moveaccuracy !
         then
         
         weather @ "sunny day" smatch if
         50 moveaccuracy !
        then
 then
 
 user @ "ability" fget "Compoundeyes" smatch if
 moveaccuracy @ 1.3 * floor moveaccuracy !
 then
 
 moveaccuracy @ UserAcc @ * WhoEva @ * 0.01 * accuracy !
 
 then
 
 loc @ { "@battle/" BID @ "/gravity" }cat getprop if
 accuracy @ 1.67 * accuracy !
 then
 
 bid @ check_weather "fog" smatch if
 accuracy @ 0.9 * accuracy !
 then
 
 
 POKEDEX { "moves/" move @ "/ignoreaccuracy?" }cat getprop if
 1.0 accuracy !
 then
 
 (force accuracy to 1.0 if no move accuracy is set)
 POKEDEX { "moves/" move @ "/accuracy" }cat getprop not if
 1.0 accuracy !
 then

 
 who @ "status/statmods/freehit/caster" get attacker @ stringify smatch if
 1.0 accuracy !
 then
 who @ "status/statmods/semi-inv" get if
         POKEDEX { "moves/" move @ "/semi-inv-breaker/" who @ "status/statmods/semi-inv" get }cat getprop if
 
                 POKEDEX { "moves/" move @ "/semi-inv-breaker/" who @ "status/statmods/semi-inv" get }cat getprop atoi semi-inv-breaker !
                 (for smackdown break the move from happening)
                 move @ "smack down" smatch if
                        { "bounce" "fly" }list who @ "status/statmods/semi-inv" get array_findval array_count if
                                POKESTORE { "@pokemon/" who @ "/@RP/status/statmods/semi-inv" }cat remove_prop
                                loc @ { "@battle/" BID @ "/declare/" tpos @ }cat remove_prop
                        then
                 
                 then
         else
                 0 accuracy !
         then
 then
 who @ { "status/statmods/lock-on/" pos @ "/count" }cat get if
 1.0 accuracy !
 
 else
 
  who @ "status/statmods/protected" get if
  1 protected !
  move @ "thunder" smatch weather @ "rain dance" smatch and frand 0.3 <= and if
        0 protected !
        { "^[o^[c" pos @ "." attacker @ id_name "'s^[y Thunder successfully broke the protection because of ^[cRain Dance^[y!" }cat notify_watchers
  then
  
  protected @ if
        POKEDEX { "moves/" move @ "/protect?" }cat getprop stringify "yes" smatch if
        { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y on ^[c" tpos @ "." who @ id_name "^[y but they were protected and unaffected!" }Cat notify_watchers
          POKEDEX { "moves/" move @ "/effects" }cat getprop dup if "*faintafter*" smatch
          POKEDEX { "moves/" move @ "FaintBeforeUse" }cat getprop or if
          loc @ { "@battle/" BID @ "/FaintAfterTurn/" pos @ }cat "yes" setprop
          then else pop then
          POKEDEX { "moves/" move @ "/misshurtself" }cat getprop if
          1 misshurtself !
          else
          exit
          then
        then
        then
then
 
 then

(Victory Star)

pos @ 1 1 midstr "Victory Star" bid @ team_ability if
accuracy @ 1.1 * accuracy !
then
 
 user @ "status/hp" get atoi user @ "maxhp" calculate 4 / <= if
        POKEDEX { "items/" who @ "holding" get "/holdeffect" }cat getprop berryeffect !
        berryeffect @
        pos @ user @ can_use_hold_item and
        if
                berryeffect @ ":" explode_array foreach effect ! pop
                effect @ "accuracy" smatch if
                1.0 accuracy !
                { "^[o^[c" user @ id_name "^[y ate its ^[c" user @ "holding" get "^[y and made its attack accurate!" }cat notify_watchers
                user @ eatberry
                then
                repeat
        then
 then



(no guard)
who @ "ability" fget "no guard" smatch
user @ "ability" fget "no guard" smatch or if
1.0 accuracy !
then

(wonder skin)
who @ "ability" fget "wonder skin" smatch POKEDEX { "moves/" move @ "/power" }cat getprop atoi not and if
accuracy @ 0.5 > if 0.5 accuracy ! then
then

(Telepathy)
pos @ 1 1 midstr tpos @ 1 1 midstr smatch who @ "ability" fget "telepathy" smatch and if
        POKEDEX { "moves/" move @ "/power" }cat getprop if
                { "^[o^[c" who @ id_name "^[y predicted ^[c" user @ id_name "'s^[y attack and dodged it!" }cat notify_watchers
                0 accuracy !
        then
then
 
 ( { "^[o^[cAccuracy: " moveaccuracy @ "  user acc: " useracc @ "  whoeva: " whoeva @ "  accuracy: " accuracy @ }Cat "Debug" pretty notify_watchers )
 
 
 frand accuracy @ > if
         attacker @ "status/statmods/movecontinued/times" 0 setto
         POKEDEX { "moves/" move @ "/missprotection" }cat getprop not if
         loc @ { "@battle/" BID @ "/repeats/" POS @ }cat remove_prop
         then
          POKEDEX { "moves/" move @ "/misshurtself" }cat getprop if
          1 misshurtself !
          else
          { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y on ^[c" tpos @ "." who @ id_name "^[y and missed!" }Cat notify_watchers
          1 sleep
          move @ "Relic Song" smatch 
          attacker @ "species" fget "648" smatch and if
          POKESTORE { "@pokemon/" attacker @ fid "/@temp/species" }cat "648p" setprop
          { "^[o^[c" pos @ "." attacker @ id_name "^[y transforms into ^[c" POKEDEX { "pokemon/" attacker @ "species" fget "/Name" "^[y on ^[c" tpos @ "." who @ id_name "^[y and missed!" }Cat notify_watchers
          then
                  POKEDEX { "moves/" move @ "/missprotection" }cat getprop if
                         effects
                  then
 
          exit
          then
 else
 (do the powerlevel stamping on this now)
 pos @ 1 1 midstr
 tpos @ 1 1 midstr smatch not if
 attacker @ who @ powerlevelset
 then
 who @ "ability" fget "pressure" smatch if
         POKEDEX { "moves/" move @ "/target" }cat getprop var! t-type
         t-type @ "ally" smatch
         t-type @ "allies" smatch or
         t-type @ "team-member" smatch or
         not
         loc @ { "@battle/" BID @ "/pressure/" pos @ }cat getprop not and
         if
                { "^[o^[c" tpos @ "." who @ id_name "^[y is asserting its Pressure!" }cat notify_watchers
                attacker @ { "/movesknown/" move @ "/pp" }cat over over fget atoi 1 - fsetto
                loc @ { "@battle/" BID @ "/pressure/" pos @ }cat "yes" setprop
         then
 then
then
then
then
then
 
(then)
 
 
move @ "future attack" smatch not if
(loc @ { "@battle/" BID @ "/beatup/" pos @ }cat getprop not if)
        attacker @ "status/statmods/MoveContinued/MoveName" get if
         attacker @ { "status/statmods/SuccessfulMoves/" attacker @ "status/statmods/MoveContinued/MoveName" get }cat 1 setto
 then
then
(then)

(to make sure movetype is written, have it write here, it may be overwriten later, but this prevents errors)
user @ { "moves/" move @ "/type" }cat get movetype !
 
POKEDEX { "moves/" move @ "/power" }cat getprop stringify "0" smatch
move @ "future sight" smatch or
move @ "doom desire" smatch or
if
 
        move @ "future sight" smatch
        move @ "doom desire" smatch or
        if
 
                { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y on ^[c" tpos @ "." who @ id_name "^[y!" }cat notify_watchers
 
                loc @ { "@battle/" BID @ "/future attack/" tpos @ }cat propdir? if
                "^[o^[yBut it failed..." notify_watchers
                exit
                else
 
                { "^[o^[c" pos @ "." attacker @ id_name "^[y predicts a future attack..." }cat notify_watchers
 
                loc @ { "@battle/" BID @ "/future attack/" tpos @ "/count" }Cat 3 setprop
                loc @ { "@battle/" BID @ "/future attack/" tpos @ "/move" }Cat move @ setprop
                loc @ { "@battle/" BID @ "/future attack/" tpos @ "/caster" }Cat attacker @ setprop
                loc @ { "@battle/" BID @ "/future attack/" tpos @ "/casterpos" }cat pos @ 1 1 midstr setprop
 
                exit
                then
 
 
        else
                pos @ tpos @ smatch not if
                 { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y on ^[c" tpos @ "." who @ id_name "^[y!" }cat notify_watchers
                else
                 { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y on itself!" }cat notify_watchers
                then
        then
 
 (check the guard moves now)
 
 (Quick Guard)
 loc @ { "@battle/" BID @ "/guards/" tpos @ 1 1 midstr "/Quick Guard" }cat getprop if
 POKEDEX { "moves/" move @ "/priority" }cat getprop atoi
    attacker @ "ability" fget "Prankster" smatch 
    POKEDEX { "moves/" move @ "/power" }cat getprop atoi not and
    if
    1 + (add one to the priority)
  then
  0 > if
  { "^[o^[c" move @ cap "^[y was blocked by ^[cQuick Guard^[y!" }cat notify_watchers
      attacker @ "status/statmods/movecontinued/movename" 0 setto
       exit
  then
 then
 
 loc @ { "@battle/" BID @ "/guards/" tpos @ 1 1 midstr "/Wide Guard" }cat getprop if
 { "self" "enemy" "Ally" "Random-enemy" }list
 POKEDEX { "moves/" move @ "/target" }cat getprop array_findval array_count not if
        { "^[o^[c" move @ cap "^[y was blocked by ^[cWide Guard^[y!" }cat notify_watchers
              attacker @ "status/statmods/movecontinued/movename" 0 setto
               exit
  then
 then
 
        move @ "helping hand" smatch if
                loc @ { "@Battle/" BID @ "/helping hand/" tpos @ }cat 1 setprop
        then
 
        { "detect" "protect" "endure" "quick guard" "wide guard" "king's shield" "spiky shield" }list temp !
        temp @ move @ array_findval array_count if
                attacker @ "status/statmods/MoveContinued/lastmove" get var! lastmove
                temp @ lastmove @ array_findval array_count
                { "detect" "protect" "endure" "king's shield" "spiky shield" }list move @ array_findval array_count and
                if
                    (random 2 % if)
                    (every time the move is used it is half as likely)
                     attacker @ "status/statmods/movecontinued/times" get atoi temp2 !
                     2 temp2 @ 1 - exp temp2 ! 
                     temp2 @ 128 > if 4294967296 temp2 ! then
                     frand 1.0 temp2 @ / > if
                    (this means it failed)
                    { "^[o^[c" move @ cap "^[y failed..." }cat notify_watchers
                    attacker @ "status/statmods/movecontinued/movename" 0 setto
 
                    exit
                    then
                    then
                move @ "endure" smatch if
                attacker @ "status/statmods/enduring" 1 setto
                then
                move @ "detect" smatch
                move @ "protect" smatch or if
                attacker @ "status/statmods/protected" 1 setto
                then
                
                move @ "*guard" smatch if
                loc @ { "@battle/" BID @ "/guards/" tpos @ 1 1 midstr "/" move @ }cat 1 setprop
                then
        then
else

(do round similar to pledges)

move @ "round" smatch if
        pos @ findrank 1 + loc @ { "@battle/" bid @ "/speed/rank/" }cat array_get_propvals array_count 1 for temp !
                loc @ { "@battle/" BID @ "/speed/rank/" temp @ }cat getprop temp2 !
                pos @ 1 1 midstr temp2 @ 1 1 midstr smatch if
                        loc @ { "@battle/" BID @ "/declare/" temp2 @ }cat getprop  " " split swap pop "round" smatch if
                                (this is to change rank)
                                temp2 @ findrank pos @ findrank rankchange
                                loc @ { "@battle/" BID @ "/temp/round_boost/" temp2 @ }cat "yes" setprop
                        then
                then
        
        repeat
then

(
When a combo is happening, the first pokemon does nothing.  Then the second goes right after and the combo happens, the move power is doubled and it has its effect.
Grass + Fire will come out as fire pledge.  It doesn't matter what order they come in.  Because that's the combo that causes 'sea of fire'
grass + water comes out as grass pledge
and water + fire comes out as water pledge

Fire + Grass creates sea of fire on opponents side of the field.  All pokemon over there take 1/8th max HP damage per turn, effect negated by rain"
fire + water creates rainbow on users side of the field.  Rainbow doubles chance of secondary effects from moves.  [same effect as serene grace, does not stack]
Grass + water creates creates swamp on opponents side of the field, all pokemon speed over there is halved
These effects all last 4 turns
Also, only one pokemon does the move, and it comes out as double powered.
)

{ "Fire Pledge" "Water Pledge" "Grass Pledge" }list move @  array_findval array_count if
        loc @ { "@battle/" BID @ "/active pledge/" pos @ 1 1 midstr }cat getprop not if
                pos @ findrank 1 + loc @ { "@battle/" bid @ "/speed/rank/" }cat array_get_propvals array_count 1 for temp ! 
                        loc @ { "@battle/" BID @ "/speed/rank/" temp @ }cat getprop temp2 !
                        pos @ 1 1 midstr temp2 @ 1 1 midstr smatch if
                                loc @ { "@battle/" BID @ "/declare/" temp2 @ }cat getprop  " " split swap pop temp3 !
                                temp3 @ move @ smatch not if
                                        { "Fire Pledge" "Water Pledge" "Grass Pledge" }list temp3 @  array_findval array_count 
                                        move @ temp3 @ smatch not and
                                        if
                                                (once all of this is found to be true, change the place of this pokemon to after the user)
                                                temp2 @ findrank pos @ findrank rankchange
                                                move @ "fire pledge" smatch if
                                                        temp3 @ "water pledge" smatch if
                                                                "water pledge"
                                                        else
                                                                "fire pledge"
                                                        then
                                                then
                                                move @ "water pledge" smatch if
                                                        temp3 @ "fire pledge" smatch if
                                                                "water pledge"
                                                        else
                                                                "grass pledge"
                                                        then
                                                then
                                                
                                                move @ "grass pledge" smatch if
                                                        temp3 @ "fire pledge" smatch if
                                                                "fire pledge"
                                                        else
                                                                "grass pledge"
                                                        then
                                                then
                                                temp2 !
                                                loc @ { "@battle/" BID @ "/active pledge/" pos @ 1 1 midstr }cat temp2 @ setprop
                                                { "^[o^[c" pos @ "."attacker @ id_name "^[y uses ^[c" move @ cap "^[y." }cat notify_watchers
                                                exit
                                        then
                                then
                        then
                repeat
        else
        
                (effects)
                loc @ { "@battle/" BID @ "/active pledge/" pos @ 1 1 midstr }cat getprop temp !
                loc @ { "@battle/" bid @ "/active pledge/" pos @ 1 1 midstr }cat remove_prop
                temp @ "water pledge" smatch if
                pos @ 1 1 midstr temp2 !
                else
                        pos @ 1 1 midstr temp2 !
                        temp2 @ "A" smatch if
                                "B" temp2 !
                        else
                                "A" temp2 !
                        then
                then
                loc @ { "@battle/" BID @ "/pledge field/" temp2 @ "/move" }cat temp @ setprop
                loc @ { "@battle/" BID @ "/pledge field/" temp2 @ "/turns" }cat 4 setprop
                { "^[o^[yA ^[c" temp @ cap " field^[y has been created on ^[cTeam " temp2 @ "^[y's side!" }cat notify_watchers
        then
then
 
move @ "sucker punch" smatch if (this needs to be fixed so it properly checks if a move was used.)
 
 loc @ { "@battle/" BID @ "/declare/" tpos @ }cat getprop if
         loc @ { "@battle/" BID @ "/declare/" tpos @ }cat getprop " " split tmove ! ttype !
 else
         "none" tmove !
         "none" ttype !
 then
 ttype @ "attack" smatch not
 POKEDEX { "moves/" tmove @ "/power" }cat getprop atoi not tmove @ "Me first" smatch not and or
 loc @ { "@Battle/" BID @ "/declare/finished/" tpos @ }cat getprop or
 if
  { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y on ^[c" tpos @ "." who @ id_name "^[y, but fails!" }cat notify_watchers
 exit
 then
then
 
move @ "future attack" smatch if
{ "^[o^[yThe predicted attack hits ^[c" tpos @ "." who @ id_name "^[y!" }cat notify_watchers
then
 
(use here to set up the multi hit moves, which are moves that hit more than once per turn) (put the new beatup mechanics here)
1 var! hittimes
POKEDEX { "moves/" move @ "/multihit" }Cat getprop if
user @ "ability" fget "Skill Link" smatch if
        5 hittimes !
else
        frand
        dup 0.875 >  if 5 hittimes ! then
        dup 0.875 <= if 4 hittimes ! then
        dup 0.750 <= if 3 hittimes ! then
            0.375 <= if 2 hittimes ! then
 
then
then
 
POKEDEX { "moves/" move @ "/sethit" }Cat getprop if
POKEDEX { "moves/" move @ "/sethit" }Cat getprop atoi hittimes !
then

pos @ 1 1 midstr var! team 
(beatup)
move @ "beat up" smatch if
(store in a temp somewhere the power values, doing the math as needed and such)
        (loop though your team and get the power values as needed)
        
        loc @ { "@battle/" bid @ "/temp/beatup/" team @ }cat remove_prop
        0 temp3 !
        loc @ { "@battle/" bid @ "/teams/" team @ "/" }cat array_get_propvals foreach temp2 ! pop
        temp3 @ 6 = if break then
        temp2 @ "status/hp" get atoi if "ok" temp ! then
         
            temp2 @ "status/frozen"    get if  "status" temp ! then
            temp2 @ "status/paralyzed" get if  "status" temp ! then
            temp2 @ "status/asleep"    get if  "status" temp ! then
            temp2 @ "status/poisoned"  get if  "status" temp ! then
            temp2 @ "status/toxic"     get if  "status" temp ! then
            temp2 @ "status/burned"    get if  "status" temp ! then
         
        temp2 @ "status/hp" get atoi not if "fainted" temp ! then
        
        temp @ "ok" smatch if
        temp3 @ 1 + temp3 !
                loc @ { "@Battle/" BID @ "/temp/beatup/" team @ "/" temp3 @  }cat temp2 @ "physatk" BaseCalculate 10 / 5 + setprop
        then
        repeat
        temp3 @ hittimes !
then
1 hittimes @ 1 for turncount !
        (endmulti)
          (do sap sipper)
          who @ "ability" fget "sap sipper" smatch
          who @ "status/statmods/substitute" get not and
          move @  "Aromatherapy" smatch not and
          user @ { "moves/" move @ "/type" }cat get "grass" smatch and
          if
           (add the attack, say it was sucked, end turn of attack)
           
           { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y on ^[c" tpos @ "." who @ id_name "^[y!" }cat notify_watchers
           { "^[o^[c" tpos @ "." who @ id_name "'s^[y ability ^[cSap Sipper^[y protected it!"  }cat notify_watchers
           who @ "status/statmods/PhysAtk" get atoi 6 < if
                who @ "status/statmods/PhysAtk" over over get atoi 1 + setto
                { "^[o^[c" who @ id_name "'s ^[yPhysAtk raised!"  }cat notify_watchers
           then
           
          1 sleep
          exit
         then
         
         
         
        var CH
 
        1 CH !
        (this is critical hit)
        move @ "future attack" smatch not if
                var CHlev
 
                1 chlev !
 
                (hardcode the critical level changes)
                user @ "holding" get "Scope Lens" smatch
                user @ "holding" get "Razor Claw" smatch
                or
                pos @ user @ can_use_hold_item and
                if
                chlev @ 1 + chlev ! then
 
                user @ "ability" fget "Super Luck" smatch if
                chlev @ 1 + chlev ! then
 
                user @ "holding" get "Stick" smatch
                user @ "species" fget "083" smatch and
                user @ "holding" get "Luckey Punch" smatch
                user @ "species" fget "113" smatch and
                or
                pos @ user @ can_use_hold_item and
                if
                chlev @ 2 + chlev ! then
 
                user @ "status/statmods/critical" get atoi 0 > if
                chlev @ 2 + chlev ! then
 
                POKEDEX { "/moves/" move @ "/critical" }cat getprop atoi chlev @ + chlev !
 
                (done chlev changes)
 
                var chper
 
                chlev @ 1 <= if 0.0625       chper ! then
                chlev @ 2  = if 0.125        chper ! then
                chlev @ 3  = if 0.5          chper ! then
                chlev @ 4 >= if 1            chper ! then
                
                
                POKEDEX { "/moves/" move @ "/alwayscrit?" }cat getprop stringify dup if "yes" smatch if 1.0 chper ! then else pop then
 
 
                frand chper @ <= if
                (later make it set up for sniper to make it 2.25 instead of 1.5)
 
                        user @ "ability" fget "sniper" smatch if
                        2.25 CH !
                        else
                        1.5 CH !
                        then
                then
        then
        loc @ { "@battle/" BID @ "/shields/" tpos @ 1 1 midstr "/lucky chant" }cat getprop if
        1 CH !
        then
 
        who @ "ability" fget "battle armor" smatch
        who @ "ability" fget "shell armor" smatch or
        user @ moldbreaker
        if
        1 CH !
        then
 
        (end critical hit)
        var temp
        var PhysAtk
        var SpecAtk
        var PhysDef
        var SpecDef
 
        CH @ 1 > if
 
        who @ "ability" fget "unaware" smatch
        user @ moldbreaker
        if
                user @ "status/statmods/PhysAtk" get atoi  temp ! user @ "status/statmods/PhysAtk" 0 setto
                user @ "PhysAtk" Calculate PhysAtk !
                user @ "status/statmods/PhysAtk" temp @ setto
 
                user @ "status/statmods/SpecAtk" get atoi  temp ! user @ "status/statmods/SpecAtk" 0 setto
                user @ "SpecAtk" Calculate SpecAtk !
                user @ "status/statmods/SpecAtk" temp @ setto
        else
 
                user @ "status/statmods/PhysAtk" get atoi dup temp ! 0 < if user @ "status/statmods/PhysAtk" 0 setto then
                user @ "PhysAtk" Calculate PhysAtk !
                user @ "status/statmods/PhysAtk" temp @ setto
 
                user @ "status/statmods/SpecAtk" get atoi dup temp ! 0 < if user @ "status/statmods/SpecAtk" 0 setto then
                user @ "SpecAtk" Calculate SpecAtk !
                user @ "status/statmods/SpecAtk" temp @ setto
        then
        

 
 
        who @ "status/statmods/PhysDef" get atoi dup temp ! 0 > if who @ "status/statmods/PhysDef" 0 setto then
        who @ "PhysDef" move @ "IgnoreStatMods" get if basecalculate else calculate then PhysDef !
        who @ "status/statmods/PhysDef" temp @ setto
 
        who @ "status/statmods/SpecDef" get atoi dup temp ! 0 > if who @ "status/statmods/SpecDef" 0 setto then
        who @ "Specdef" move @ "IgnoreStatMods" get if basecalculate else calculate then SpecDef !
        who @ "status/statmods/SpecDef" temp @ setto
 
 
        else
        var beforestockpile
        who @ "ability" fget "unaware" smatch
        user @ moldbreaker
        if
                user @ "status/statmods/PhysAtk" get atoi dup temp ! 0 > if user @ "status/statmods/PhysAtk" 0 setto then
                user @ "PhysAtk" Calculate PhysAtk !
                user @ "status/statmods/PhysAtk" temp @ setto
 
                user @ "status/statmods/SpecAtk" get atoi dup temp ! 0 > if user @ "status/statmods/SpecAtk" 0 setto then
                user @ "SpecAtk" Calculate SpecAtk !
                user @ "status/statmods/SpecAtk" temp @ setto
 
        else
 
        user @ "PhysAtk" Calculate PhysAtk !
 
        user @ "SpecAtk" Calculate SpecAtk !
 
        then
        
        move @ "foul play" smatch if
          who @ "PhysAtk" Calculate PhysAtk !
        then
        (this is so mold breaker works in the stat calculator for simple)
        1 user @ moldbreaker not if
 
        who @ "status/statmods/Mold Broken" 1 setto
        then
 
        user @ "ability" fget "unaware" smatch
        if
 
        who @ "status/statmods/PhysDef" get atoi beforestockpile !
        who @ "status/statmods/PhysDef" over over get atoi who @ "status/statmods/stockpile" get atoi + setto
 
        (add in the check for moves that raise def while charging)
        loc @ { "@battle/" bid @ "/charge/" pos @ "/charging/" tpos @ }Cat getprop if
                loc @ { "@battle/" bid @ "/charge/" pos @ "/charging/" tpos @ "/move" }Cat getprop "Skull Bash" smatch if
                        who @ "status/statmods/PhysDef" over over get atoi 1 + setto
                then
        then
 
        who @ "status/statmods/PhysDef" get atoi 0 > if who @ "status/statmods/PhysDef" 0 setto then
 
        who @ "PhysDef" move @ "IgnoreStatMods" get if basecalculate else calculate then PhysDef !
        who @ "status/statmods/PhysDef" beforestockpile @ setto
 
        who @ "status/statmods/SpecDef" get atoi beforestockpile !
        who @ "status/statmods/SpecDef" over over get atoi who @ "status/statmods/stockpile" get atoi + setto
 
        who @ "status/statmods/SpecDef" get atoi 0 > if who @ "status/statmods/SpecDef" 0 setto then
 
        who @ "SpecDef" move @ "IgnoreStatMods" get if basecalculate else calculate then SpecDef !
        who @ "Status/statmods/Specdef" beforestockpile @ setto
 
        else
 
        who @ "status/statmods/PhysDef" get atoi beforestockpile !
        who @ "status/statmods/PhysDef" over over get atoi who @ "status/statmods/stockpile" get atoi + setto
 
        who @ "PhysDef" move @ "IgnoreStatMods" get if basecalculate else calculate then PhysDef !
        who @ "status/statmods/PhysDef" beforestockpile @ setto
 
        who @ "status/statmods/SpecDef" get atoi beforestockpile !
        who @ "status/statmods/SpecDef" over over get atoi who @ "status/statmods/stockpile" get atoi + setto
 
        who @ "SpecDef" move @ "IgnoreStatMods" get if basecalculate else calculate then SpecDef !
        who @ "Status/statmods/Specdef" beforestockpile @ setto
 
        then
 
       then
       
       move @ "beat up" smatch if
       user "Physatk" basecalculate PhysAtk !
       then
        who @ "status/statmods/Mold Broken" 0 setto
        (stat changing abilities go here)
        user @ "ability" fget "slow start" smatch if
                user @ "status/statmods/ability/slow start" get atoi 5 > not if
                PhysAtk @ 0.5 * floor PhysAtk !
                then
        then
 
        pos @ "Flower Gift" bid @ team_ability if
        PhysAtk @ 1.5 * floor PhysAtk !
        then
 
        user @ "ability" fget "Huge power" smatch
        user @ "Ability" fget "pure power" smatch or
        if
        PhysAtk @ 2 * PhysAtk !
        then
 
        user @ "ability" fget "hustle" smatch if
        PhysAtk @ 1.5 * floor PhysAtk !
        then
 
        user @ "ability" fget "rivalry" smatch if
                user @ "gender" fget temp !
                who @ "gender" fget temp2 !
 
                temp @ "male" smatch
                temp @ "female" smatch or
                temp2 @ "male" smatch
                temp2 @ "female" smatch or and if
 
                        temp @ temp2 @ smatch if
                        PhysAtk @ 1.25 * floor PhysAtk !
                        else
                        PhysAtk @ 0.75 * floor PhysAtk !
                        then
 
                then
 
        then
 
       user @ "ability" fget "guts" smatch if
                user @ check_status if
                PhysAtk @ 1.5 * floor PhysAtk !
                then
       then
 
        user @ "ability" fget "Solar Power" smatch if
                SpecAtk @ 1.5 * floor SpecAtk !
        then
        
        user @ "ability" fget "plus" smatch
        user @ "ability" fget "minus" smatch or if
        
                pos @ "plus" bid @ team_ability pos @ "minus" bid @ team_ability + 2 >= if
                        SpecAtk @ 1.5 * floor SpecAtk !
                then
        then 
        who @ "ability" fget "marvel scale" smatch
        user @ moldbreaker
        if
                user @ check_Status if
                PhysDef @ 1.5 * floor PhysDef !
                then
        then
 
        tpos @ "Flower Gift" bid @ team_ability
        user @ moldbreaker
        if
                SpecDef @ 1.5 * floor SpecDef !
        then
 
        who @ typelist "rock" array_findval array_count
        bid @ check_weather "sandstorm" smatch and
        if
                SpecDef @ 1.5 * floor SpecDef !
        then
        
        loc @ { "@battle/" BID @ "/wonderroom" }cat getprop if
        SpecDef @ temp !
        PhysDef @ SpecDef !
        Temp @ PhysDef !
        then
        
        (abilities end)
 
        var level
        var basepower
        var mod1
        var mod2
        var mod3
        var shield
 
        var Rand
        var STAB
 
        move @ "future attack" smatch if
        loc @ { "@battle/" BID @ "/future attack/" tpos @ "/move" }cat getprop move !
        then
 
        POKEDEX { "moves/" move @ "/class" }cat getprop "none" smatch if
        0 attack !
        0 defense !
        then
 
        POKEDEX { "moves/" move @ "/class" }cat getprop "physical" smatch if
        PhysAtk @  attack !
        PhysDef @  defense !
        ch @ 1 = if
        loc @ { "@battle/" BID @ "/shields/" tpos @ 1 1 midstr "/reflect" }cat getprop  user @ "Ability" fget "Infiltrator" smatch not and if 1 shield ! then then
        then
 
        POKEDEX { "moves/" move @ "/class" }cat getprop "special" smatch if
        SpecAtk @  attack !
        POKEDEX { "moves/" move @ "/usedef" }cat getprop not if
        SpecDef @  defense !
        else
        PhysDef @  defense !
        then
        ch @ 1 = if
        loc @ { "@battle/" BID @ "/shields/" tpos @ 1 1 midstr "/light screen" }cat getprop user @ "Ability" fget "Infiltrator" smatch not and if 1 shield ! then then
        then
        
        POKEDEX { "moves/" move @ "/effects" }cat getprop dup if "*Shieldbreaker*" smatch if 0 shield ! then else pop then
        
        POKEDEX { "moves/" move @ "/halftargetdef" }cat getprop if
                defense @ 2 / defense !
                defense @ not if
                        1 defense !
                then
        then
        
        (choice items go here)
        
        user @ "holding" get "Choice Band" smatch POKEDEX { "moves/" move @ "/class" }cat getprop "physical" smatch and if attack @ 1.5 * floor attack ! then
        user @ "ability" fget "Flare boost" smatch POKEDEX { "moves/" move @ "/class" }cat getprop "special" smatch and if attack @ 1.5 * floor attack ! then
        user @ "holding" get "Choice Specs" smatch POKEDEX { "moves/" move @ "/class" }cat getprop "special" smatch and if attack @ 1.5 * floor attack ! then
        
        (defeatest goes here)
        user @ "ability" fget "Defeatist" smatch if
        user @ "status/hp" get atoi 100 * user @ "maxhp" calculate / 50 <= if
                attack @ 2 / attack !
                attack @ not if 1 attack ! then
                then
        then
        var temp1
 
        user @ FindPokeLevel level !
 
        level @ 2 * 5 / 2 + temp1 !
        (define weather here so it can be used in the base power formula)
        bid @ check_weather weather !
 
 
        POKEDEX { "moves/" move @ "/power" }cat getprop atoi basepower !
        (make sure items that are consumed to boost basepower are used before the variable attack segment)
        
        basepower @ variable_attack basepower !
        
        basepower @ 0 < if
        { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y on ^[c" tpos @ "." who @ id_name "^[y but it failed!" }Cat notify_watchers
        exit then
 
        ( user @ basepower @ intostr "BasePower" CheckTriggers atoi basepower ! )
        move @ "triple kick" smatch if basepower @ tkdamage @ + basepower ! then
 
 
        loc @ { "@Battle/" BID @ "/helping hand/" pos @ }cat getprop if
                basepower @ 1.5 * floor basepower !
        then
        
        (Sheer Force)
        user @ "ability" fget "Sheer Force" smatch if
        basepower @ 1.3 * floor basepower !
        then
 
         user @ "status/statmods/MoveContinued/lastmove" get "charge" smatch
         move @ attack_type "electric" smatch and
         if
         basepower @ 2 * basepower !
 
         then
 
         basepower @ semi-inv-breaker @ * basepower !
 
        (do element here so you can modify basepower more directly)
 
                move @ "hidden power" smatch if
                        attacker @ hidden_power_type movetype !
                else
                        user @ { "moves/" move @ "/type" }cat get movetype !
                then
                user @ "ability" fget "pixilate" smatch movetype @ "Normal" smatch and if
                        "Fairy" movetype ! basepower @ 1.3 * floor basepower !
                then
                
                user @ "ability" fget "Refrigerate" smatch movetype @ "Normal" smatch and if
                        "Ice" movetype ! basepower @ 1.3 * floor basepower !
                then
                
                user @ "ability" fget "Aerilate" smatch movetype @ "Normal" smatch and if
                        "Flying" movetype ! basepower @ 1.3 * floor basepower !
                then
                
                user @ "ability" fget "normalize" smatch if "Normal" movetype ! then
 
                move @ "weather ball" smatch if
                weather @ if
                        weather @ "rain dance" smatch if "water" movetype ! then
                        weather @ "hail" smatch if "ice" movetype ! then
                        weather @ "sandstorm" smatch if "rock" movetype ! then
                        weather @ "sunny day" smatch if "fire" movetype ! then
                then
                then
 
                move @ "natural gift" smatch if
                        POKEDEX { "items/" attacker @ "holding" get "/NaturalGift" }cat getprop if
                        POKEDEX { "items/" attacker @ "holding" get "/NaturalGift" }cat getprop
                        "-" explode
                        pop
                        pop
                        movetype !
                        attacker @ "holding" "Nothing" setto
                        then
                then
 
                move @ "judgment" smatch if
                user @ { "items/" user @ "holding" get "/judgment" }cat get dup if movetype ! else pop then
                then
                
                move @ "techno blast" smatch if
                user @ { "items/" user @ "holding" get "/technoblast" }cat get dup if movetype ! else pop then
                then
 
                user @ { "items/" user @ "holding" get "/typeboost" }cat get if
                        user @ { "items/" user @ "holding" get "/typeboost" }cat get  movetype @ smatch if basepower @ 1.2 * floor basepower ! then
        then
 
                (for technician)
                user @ "ability" fget "Technician" smatch if
                        basepower @ 60 <= if
 
                                basepower @ 1.5 * floor basepower !
                        then
        then
                (for sand force)
                user @ "ability" fget "sand force" smatch 
                weather @ "sandstorm" smatch and 
                { "Rock" "Ground" "Steel" }list movetype @ array_findval array_count and
                if
                        basepower @ 1.3 * floor basepower !
                then
        loc @ { "@battle/" BID @ "/temp/mefirst/" pos @ }cat getprop if
                loc @ { "@battle/" BID @ "/temp/mefirst/" pos @ }cat remove_prop
                basepower @ 1.5 * floor basepower !
        then
 
                user @ "ability" fget "iron fist" smatch if
                { "Bullet Punch" "Comet Punch" "Dizzy Punch" "Drain Punch" "DynamicPunch"
                "Fire Punch" "Focus Punch" "Hammer Arm" "Ice Punch" "Mach Punch" "Mega Punch"
                "Meteor Mash" "Shadow Punch" "Sky Uppercut" "ThunderPunch" }list
                move @ array_findval array_count if
                basepower @ 1.2 * floor basepower !
                then
        then
        
                attacker @ "ability" fget "Analytic" smatch if
                loc @ { "@battle/" BID @ "/declare/finished/" tpos @ }cat getprop if
                        basepower @ 1.3 * floor basepower !
                then
                then
        
        
        var lifeorb
 
        user @ "holding" get "Life Orb" smatch
        pos @ user @ can_use_hold_item and
        if
        user @ "ability" fget "Magic Guard" smatch 
        user @ "ability" fget "sheer force" smatch or
        if
        0 lifeorb !
        else
        1 lifeorb !
        then
        basepower @ 1.3 * floor basepower !
        then
 
        var temp2
        temp1 @ basepower @ * attack @ * 50 / defense @ / temp2 !
 
        1 mod1 !
 
        (start adding in the mod1 modifications)
 
        loc @ { "@battle/" BID @ "/temp/othertargets" }cat getprop 1 > if mod1 @ 0.75 * mod1 ! then
 
        shield @ if
                loc @ { "@battle/" BID @ "howmany" }cat getprop atoi 1 = if
                0.5 mod1 @ * mod1 !
                else
                2.0 3.0 / mod1 @ * mod1 !
                then
        then
 
        (weather mods, weather is defined earlier)
 
        weather @ "none" smatch not if
                weather @ "Rain Dance" smatch if
                movetype @ "water" smatch if
                mod1 @ 1.5 * mod1 ! then
                movetype @ "fire" smatch if
                mod1 @ 0.5 * mod1 ! then
                then
                weather @ "Sunny Day" smatch if
                movetype @ "water" smatch if
                mod1 @ 0.5 * mod1 ! then
                movetype @ "fire" smatch if
                mod1 @ 1.5 * mod1 ! then
                then
        then
        loc @ { "@battle/" BID @ "/dull/" movetype @ }cat getprop if
        mod1 @ 0.5 * mod1 ! then
        (end mod1 modifications)
 
 
        1 mod2 !
        (this one will be 1 for now)
 
        random 16 % 85 + rand !
        (this is for random)
 
        var temp3
        temp2 @ mod1 @ * 2 + CH @ * mod2 @ * Rand @ * 100 / temp3 !
 
 
        user @ typelist
          movetype @
        array_findval array_count if
          user @ "ability" fget "Adaptability" smatch if
          2.0
          else
          1.5
          then
        else
          1.0
        then
        STAB !
 
        tpos @ typetotalcalculate var! typetotal
 
        (typetotal @ 100 * typetotal !)
        ( who @ typetotal @ intostr "DefenseTypeImmunity" CheckTriggers atoi 100.0 / typetotal ! )
 
        POKEDEX { "moves/" move @ "/typeless?" }cat getprop stringify if 1 typetotal ! then
        typetotal @ not
        POKEDEX { "moves/" move @ "/misshurtself" }cat getprop and if
          1 misshurtself !
          1 typetotal !
        then
 
        loc @ { "@battle/" BID @ "/beatup/" pos @ }cat getprop if
        1 typetotal !
        then
 
        1 mod3 !
        (set to 1 so far)
        (do abilities that change typetotal here)
        user @ "ability" fget "Tinted Lens" smatch if
        typetotal @ 1 < if typetotal @ 2 * typetotal ! then
        then
 
        who @ "ability" fget "Wonder Guard" smatch
        user @ moldbreaker
        POKEDEX { "moves/" move @ "/typeless?" }cat getprop stringify not and
                if     
                typetotal @ 2 < if 
        0 typetotal ! then
        then
        
        (items that trigger before damage)
        user @ "holding" get "Expert Belt" smatch if
        typetotal @ 1 > if temp3 @ 1.2 * temp3 ! then
        then
        (end items)
        
        temp3 @ STAB @ * typetotal @ * mod3 @ * floor damage !
        damage @ not typetotal @ and if 1 damage ! then
 
        (this is to check if an ability that absorbes damage and restores hp is in effect, if not it'll do damage)
        who @ "ability" fget "Water Absorb" smatch movetype @ "water" smatch and
        who @ "ability" fget "Volt Absorb" smatch movetype @ "electric" smatch and
        or
        user @ moldbreaker
        if
          { "^[o^[c" pos @ "."attacker @ id_name "^[y uses ^[c" move @ cap "^[y against ^[c" tpos @ cap "." who @ id_name "^[y, but because of its ability ^[c" who @ "ability" fget cap "^[y, it was absorbed!"
         }cat notify_watchers
         who @ "MaxHP"   Calculate var! maxhp
         maxhp @ 4 who @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
         who @ "status/hp" over over get atoi damage @ + setto
         who @ "status/hp" get atoi maxhp @ > if
         who @ "status/hp" maxhp @ setto then
         0 typetotal !
 
 
 
        else
 
         (ability mod - flash fire boost)
 
         user @ "status/statmods/damageboost/fire" get atoi 1 >= if
         move @ attack_type "fire" smatch if
 
         damage @ dup 0.5 * + damage !
         then
         then
 
        (in a pinch element boosts)
        user @ "status/hp" get atoi 1.0 * user @ "maxhp" calculate  / 1.0 3.0 / <= if
                user @ "ability" fget "Blaze" smatch
                movetype @ "fire" smatch and
                if
                damage @ 1.5 * damage !
                then
 
                user @ "ability" fget "Overgrow" smatch
                movetype @ "grass" smatch and
                if
                damage @ 1.5 * damage !
                then
 
                user @ "ability" fget "Swarm" smatch
                movetype @ "bug" smatch and
                if
                damage @ 1.5 * damage !
                then
 
                user @ "ability" fget "Torrent" smatch
                movetype @ "Water" smatch and
                if
                damage @ 1.5 * damage !
                then
 
        then
 
        (for reckless)
        user @ "ability" fget "reckless" smatch
        move @ { "moves/" move @ "/effects" }cat get "*recoil*" smatch and
        if
        damage @ 1.2 * damage !
 
        then
 
        (for any other damage effecting abilities)
        who @ "ability" fget "Filter" smatch
        who @ "ability" fget "Solid Rock" smatch or
        attacker @ moldbreaker
        if
                typetotal @ 1 > if damage @ 3 * 4 divdamage damage ! then
        then
        

        who @ "ability" fget "Heatproof" smatch
        attacker @ moldbreaker
        if
                movetype @ "fire" smatch if damage @ 2 divdamage damage ! then
        then
 
        damage @ 1.0 * floor damage !
        (set damage moves)
        move @ "counter" smatch if
        0 lifeorb !
                { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y!" }Cat notify_watchers
                loc @ { "@battle/" BID @ "/lasthit/" pos @ "/class" }cat getprop stringify "physical" smatch not if
                        "^[o^[yBut it failed..." notify_watchers exit
                then
                loc @ { "@battle/" BID @ "/lasthit/" pos @ "/damage" }cat getprop 2 * damage !
                loc @ { "@battle/" BID @ "/lasthit/" pos @ "/target" }cat getprop tpos !
                loc @ { "@battle/" BID @ "/position/" tpos @ }cat getprop who !
                who @ not if
                        "^[o^[yBut it failed..." notify_watchers exit
                then
                typetotal @ not if 0 damage !  else 1 typetotal ! then
        then
 
        move @ "mirror coat" smatch if
        0 lifeorb !
                { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y!" }Cat notify_watchers
                loc @ { "@battle/" BID @ "/lasthit/" pos @ "/class" }cat getprop stringify "special" smatch not if
                        "^[o^[yBut it failed..." notify_watchers exit
                then
                loc @ { "@battle/" BID @ "/lasthit/" pos @ "/damage" }cat getprop 2 * damage !
                damage @ not if
                        "^[o^[yBut it failed..." notify_watchers exit
                then
                loc @ { "@battle/" BID @ "/lasthit/" pos @ "/target" }cat getprop tpos !
                loc @ { "@battle/" BID @ "/position/" tpos @ }cat getprop who !
                who @ not if
                        "^[o^[yBut it failed..." notify_watchers exit
                then
                typetotal @ not if 0 damage !  else 1 typetotal ! then
        then
 
        move @ "metal burst" smatch if
        0 lifeorb !
                { "^[o^[c" pos @ "." attacker @ id_name "^[y uses ^[c" move @ cap "^[y!" }Cat notify_watchers
                loc @ { "@battle/" BID @ "/lasthit/" pos @ "/class" }cat getprop not if
                        "^[o^[yBut it failed..." notify_watchers exit
                then
                loc @ { "@battle/" BID @ "/lasthit/" pos @ "/damage" }cat getprop 2 * damage !
                loc @ { "@battle/" BID @ "/lasthit/" pos @ "/target" }cat getprop tpos !
                loc @ { "@battle/" BID @ "/position/" tpos @ }cat getprop who !
                who @ not if
                        "^[o^[yBut it failed..." notify_watchers exit
                then
                1 typetotal !
        then
 
        move @ "bide" smatch if
        0 lifeorb !
                loc @ { "@Battle/" BID @ "/bide/" pos @ "/damage" }cat getprop 2 * damage !
                loc @ { "@battle/" BID @ "/bide/" pos @ }cat remove_prop
                1 typetotal !
        then
 
        POKEDEX { "moves/" move @ "/setdamage" }cat getprop if
        0 lifeorb !
        1 ch !
                typetotal @ if
                1 typetotal !
                POKEDEX { "moves/" move @ "/setdamage" }cat getprop stringify "level" smatch if
                attacker @ findpokelevel damage !
                then
                POKEDEX { "moves/" move @ "/setdamage" }cat getprop stringify "hp" smatch if
                attacker @ "status/hp" get atoi damage !
                then
                
                POKEDEX { "moves/" move @ "/setdamage" }cat getprop stringify "vlevel" smatch if
                attacker @ findpokelevel damage !
 
                random 11 % 5 +
                damage @ 0.1 * * floor damage !
                then
 
                POKEDEX { "moves/" move @ "/setdamage" }cat getprop atoi if
                POKEDEX { "moves/" move @ "/setdamage" }cat getprop atoi damage !
                then
                else
                0 damage !
                then
        then
 
        POKEDEX { "moves/" move @ "/OHKO" }cat getprop dup not if pop "no" then "yes" smatch if
                typetotal @ not if
                { "^[o^[c" pos @ "."attacker @ id_name "^[y uses ^[c" move @ cap "^[y against ^[c" tpos @ cap "." who @ id_name "^[y, but it failed..." }cat notify_watchers exit
                else
                1 typetotal !
                who @ "maxhp" calculate damage !
                then
        then
        (end set damage)
 
        (special damage)
        move @ "Endeavor" smatch if
        0 lifeorb !
                typetotal @ not if
                { "^[o^[c" pos @ "."attacker @ id_name "^[y uses ^[c" move @ cap "^[y against ^[c" tpos @ cap "." who @ id_name "^[y, but it failed..." }cat notify_watchers exit
                then
                1 typetotal !
                attacker @ "status/hp" get atoi
                who @ "status/hp" get atoi > if
                        { "^[o^[c" pos @ "."attacker @ id_name "^[y uses ^[c" move @ cap "^[y against ^[c" tpos @ cap "." who @ id_name "^[y, but it failed..." }cat notify_watchers exit
                then
                who @ "status/hp" get atoi
                attacker @ "status/hp" get atoi - damage !
        then
 
        move @ "super fang" smatch if
        0 lifeorb !
                typetotal @ not if
                { "^[o^[c" pos @ "."attacker @ id_name "^[y uses ^[c" move @ cap "^[y against ^[c" tpos @ cap "." who @ id_name "^[y, but it failed..." }cat notify_watchers exit
                then
                1 typetotal !
                who @ "status/hp" get atoi 2 who @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
        then
 
        (end special)
        
        (Friend Guard Ability)
        attacker @ "ability" fget "Friend Guard" smatch tpos @ 1 1 midstr pos @ 1 1 midstr smatch and if
                damage @ damage @ 0.25 * - damage !
        then
 
        heal @ if
        0 lifeorb !
        (this is where the present's heal goes into play)
        who @ "status/hp" over over get atoi heal @ + setto
        who @ "status/hp" get atoi who @ "maxhp" calculate > if
        who @ "status/hp" who @ "maxhp" calculate setto
        then
        { "^[o^[c" pos @ "."attacker @ id_name "^[y uses ^[c" move @ cap "^[y against ^[c" tpos @ cap "." who @ id_name "^[y, and healed some of its health!" }cat notify_watchers
        else
        misshurtself @ if
        (this is where moves that hurt yourself when you miss do the damage)
        0 misshurtself !
        (gen 4 way to do damage is commented out
        who @ "status/hp" get atoi damage @ <= if who @ "status/hp" get atoi damage ! then
 
        damage @ 2 divdamage damage ! )
        
        who @ "maxhp" calculate 2 divdamage damage !
        
        { "^[o^[c" pos @ "."attacker @ id_name "^[y uses ^[c" move @ cap "^[y against ^[c" tpos @ cap "." who @ id_name "^[y but missed and hurt itself!" }cat notify_watchers
        attacker @ "status/hp" over over get atoi damage @ - setto
                 attacker @ "status/hp" get atoi 0 <= if
                 POKESTORE { "@pokemon/" attacker @ "/@RP/status" }cat remove_prop
                 attacker @ "status/hp" 0 setto
                attacker @ "status/fainted" 1 setto
 
                then
        else
        who @ "ability" fget "Dry skin" smatch movetype @ "water" smatch and
        attacker @ moldbreaker
        if
        0 damage !
        who @ "status/hp" over over get atoi who @ "maxhp" calculate 4 who @ "pvp/hpboost" fget dup if atoi * else pop then divdamage + setto
        who @ "status/hp" get atoi who @ "maxhp" calculate > if
                who @ "status/hp" who @ "maxhp" calculate setto
        then
        1 noeffect !
        { "^[o^[c" pos @ "."attacker @ id_name "^[y uses ^[c" move @ cap "^[y against ^[c" tpos @ cap "." who @ id_name "^[y, but because of its ability ^[c" who @ "ability" fget cap "^[y, they were healed!"
         }cat notify_watchers
 
        else
 
        who @ "ability" fget "flash fire" smatch movetype @ "fire" smatch and
        attacker @ moldbreaker
        (who @ "status/frozen" get not and)
        if
        0 damage !
        1 noeffect !
        who @ "status/statmods/damageboost/fire" get not if
        who @ "status/statmods/damageboost/fire" 1 setto
        { "^[o^[c" tpos @ "." who @ id_name "'s^[y ability ^[cFlash Fire^[y has been activated!"  }cat notify_watchers
        then
        then
        
        who @ "ability" fget "Storm Drain" smatch movetype @ "water" smatch and 
        who @ "ability" fget "Lightningrod" smatch movetype @ "electric" smatch and or
        attacker @ moldbreaker
        if
        { "^[o^[c" tpos @ "." who @ id_name "^[y is immune to damage!" }cat notify_watchers
        0 damage !
        who @ "status/statmods/Specatk" get atoi 6 > not if
                who @ "status/statmods/Specatk" over over get atoi 1 + setto
                { "^[o^[c" tpos @ "." who @ id_name "'s^[y Specal Attack Boosted!" }cat notify_watchers
        
        then
        then
        
        attacker @ "ability" fget "Tough Claws" smatch if
        damage @ 1.33 * floor damage !
        then
        
        who @ "ability" fget "dry skin" smatch movetype @ "fire" smatch and
        attacker @ moldbreaker
        if
        damage @ 1.25 * floor damage !
        then
 
        who @ "ability" fget "thick fat" smatch
        movetype @ "fire" smatch
        movetype @ "ice" smatch or and
        attacker @ moldbreaker
        if
        damage @ 0.5 * floor damage !
        then
 
         movetype @ "fire" smatch
         who @ "status/frozen" get and
         if
                who @ "status/frozen" 0 setto
                { "^[o^[c" pos @ "." who @ id_name "^[y was unfrozen by the attack!" }cat notify_watchers
         then
 
         var damper
         damage @ 100 * who @ "maxhp" calculate / damper !
         var damphrase
         damper @ 100 >= if "EPIC" damphrase ! then
         damper @ 99  <= if "extreme" damphrase ! then
         damper @ 75  <= if "heavy" damphrase ! then
         damper @ 50  <= if "considerable" damphrase ! then
         damper @ 25  <= if "moderate" damphrase ! then
         damper @ 15  <= if "light" damphrase ! then
         damper @ 5   <= if "puny" damphrase ! then
         damage @ 0    = if "no" damphrase ! then
         (this is a log)
         POKESTORE { "@logs/damagelogs/phrases/" damphrase @ }Cat over over getprop 1 + setprop
         POKESTORE { "@logs/damagelogs/percents/" damper @ }Cat over over getprop 1 + setprop
         (end log)
 
        (cap damage at current hp)
 
        damage @ not typetotal @ and noeffect @ not and if 1 damage ! then
        damage @ var! RealDamage
        var truemaxhp
        who @ "status/statmods/substitute" get if
        who @ "status/statmods/substitute" get atoi truemaxhp !
        else
        who @ "status/hp" get atoi truemaxhp !
        then
                  truemaxhp @  damage @ <= if
                  move @ "false swipe" smatch
                  who @ "status/statmods/enduring" get or
                  who @ "status/statmods/substitute" get not and
                  if
                         truemaxhp @ 1 - damage !  (make sure to make this not work with substitutes)
                         else
                         truemaxhp @ damage !
                         then
         then
 
         { "^[o^[c" pos @ "."attacker @ id_name "^[y uses ^[c" move @ cap "^[y against ^[c" tpos @ cap "." who @ id_name "^[y, "
         typetotal @ 1 > if
         "its SUPER EFFECTIVE "
         then
         typetotal @ 2 > if
         "x2 "
         then
         typetotal @ not if "they are immune..."
         else
         typetotal @ 1 < if
         "its not very effective... "
         then
         typetotal @ 0.5 < if
         "x2 "
         then
         then
 
         "and deals ^[o^[r" damphrase @ 
         debug @ if "^[c[Debug: " realdamage @ ": " damper @ "%" "BP: " basepower @ " CL: " chlev @ " "  shield @ if " shielded" then who @ "status/statmods/substitute" get if "Sub: " who @ "status/statmods/substitute" get then "]" then
 
         CH @ 1 > if
         "^[y CRITICAL"
         then
 
         "^[y damage!"
         }cat notify_watchers   
         (do relic song)
                   move @ "Relic Song" smatch 
                   attacker @ "species" fget "648" smatch and if
                   POKESTORE { "@pokemon/" attacker @ fid "/@temp/species" }cat "648p" setprop
                   { "^[o^[c" pos @ "." attacker @ id_name "^[y transforms into ^[c" POKEDEX { "pokemon/" attacker @ "species" fget "/Name" "^[y on ^[c" tpos @ "." who @ id_name "^[y and missed!" }Cat notify_watchers
          then
         
         (do justified)
         who @ "ability" fget "Justified" smatch
         who @ "status/statmods/substitute" get not and
         user @ { "moves/" move @ "/type" }cat get "dark" smatch and if
                
                    who @ "status/statmods/PhysAtk" get atoi 6 < if
                         who @ "status/statmods/PhysAtk" over over get atoi 1 + setto
                         { "^[o^[c" tpos @ "." who @ id_name "'s^[y ability ^[cJustified^[y activated!"  }cat notify_watchers
                         { "^[o^[c" who @ id_name "'s ^[yPhysAtk raised!"  }cat notify_watchers
           then
         then
         (do cursed body)
         who @ "ability" fget "cursed body" smatch 
         who @ "status/statmods/substitute" get not and
         if
                random 100 % 1 + 30 <= if
                { "^[o^[c" who @ id_name "^[y's ^[cCursed Body ^[yhas now disabled the attack!" }cat notify_Watchers
                attacker @ "status/statmods/disabled/turns" random 8 % 2 + setto
                then
                
         then
       
         
          user @ "ability" fget "Stench" smatch
               user @ "holding" get "King's Rock" smatch or
               user @ "holding" get "Razor Fang" smatch or
               POKEDEX { "moves/" move @ "/effects" }cat getprop stringify "*flench*" smatch not and
               if
                random 100 % 1 + user @ "ability" fget "Serene Grace" smatch if 20 else 10 then <= if
                 (you can only flinch someone if they haven't attacked yet)
                 who @ "ability" fget "inner focus" smatch
                 user @ moldbreaker
                 if
                 { "^[o^[c" who @ id_name "^[y was protected from flinching by its ability ^[cInner Focus^[y!" }cat notify_watchers
                 else
                 
                 loc @ { "@battle/" BID @ "/declare/finished/" tpos @ }cat getprop not who @ "status/hp" get atoi 0 > and 
                 who @ "status/statmods/substitute" get not and
                 if
                 loc @ { "@battle/" BID @ "/flinched/" tpos @ }cat who @ setprop
                 { "^[o^[c" who @ id_name "^[y flinched!" }cat notify_watchers
                 then
                 then
                 then
        then
         
         
         user @ "status/fainted" get not if
                 lifeorb @ turncount @ = 1 and
                 if
                         user @ "status/hp" over over get atoi
                         user @ "maxhp" calculate 10 user @ "pvp/hpboost" fget dup if atoi * else pop then divdamage - setto
                         { "^[o^[c" user @ id_name " ^[ywas hurt by ^[cLife Orb ^[yrecoil!" }cat notify_watchers
         
                         user @ "status/hp" get atoi 0 <= if
                         user @ "status/hp" 0 setto
                         user @ "status/fainted" 1 setto
         
                         then
                 then
then

        
         loc @ { "@battle/" BID @ "/DamageDeltTurn/" pos @ }cat over over getprop damage @ + setprop
         who @ "status/statmods/substitute" get 
         who @ "ability" fget "Infiltrator" smatch not and
         if
         damage @ substitute_damage
         else
         damage @ if
                loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn/" tpos @ }cat 1 setprop
                who @ "ability" fget "illusion" smatch if 
                        who @ "status/statmods/illusion/broken" get not if
                                { "^[o^[c" who @ id_name "'s^[y illusion is broken!" }cat notify_watchers
                                who @ "status/statmods/illusion/broken" 1 setto 
                        then
                then
         then
         who @ "status/hp" over over get atoi damage @ - setto
                        (enndure check)
                  who @ "status/statmods/enduring" get
                  who @ "status/hp" get atoi 1 = and if
                  { "^[o^[c" who @ id_name "^[y has Endured the attack!" }cat notify_watchers then
                  
                  (do splash damage)
                  POKEDEX { "moves/" move @ "/splashdamage" }cat getprop if
                         { -1 1 }list foreach swap pop temp3 !
                         { tpos @ 1 1 midstr tpos @ 2 1 midstr atoi temp3 @ + }cat temp !
                         loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop temp2 !
                         
                         temp2 @ not if continue then
                         
                         temp2 @ "status/hp" over over get atoi temp2 @ "maxhp" calculate 16 / - setto
                         temp2 @ "status/hp" get atoi 0 <= if
                                POKESTORE { "@pokemon/" temp2 @ "/@RP/status" }cat remove_prop
                                temp2 @ "status/hp" 0 setto
                                temp2 @ "status/fainted" 1 setto
                                loc @ { "@battle/" BID @ "/declare/" temp @ }cat remove_prop
                         then
                         repeat
                         
         then
         
         who @ "status/hp" get atoi 0 <= if
         
         (Multiscale)
         who @ "ability" fget "multiscale" smatch
         attacker @ moldbreaker 
         StartedFullHP @ and if
                damage @ 2 / damage !
                { "^[o^[c" who @ id_name "^[y has the ability ^[c" who @ "ability" fget cap "^[y and halved the attack!" }Cat notify_watchers
         then
         
                  (check for sturdy and set hp to 1 if it is)
          who @ "ability" fget "sturdy" smatch
          attacker @ moldbreaker 
          StartedFullHP @ and
          
          POKEDEX { "moves/" move @ "/multihit" }Cat getprop not and
          POKEDEX { "moves/" move @ "/sethit" }cat getprop not and
          
          if
          who @ "status/hp" 1 setto
                  { "^[o^[c" who @ id_name "^[y has the ability ^[c" who @ "ability" fget cap "^[y and withstood the attack!" }Cat notify_watchers
            else      
         who @ "holding" get "Focus Band" smatch frand 0.1 <= and tpos @ who @ can_use_hold_item and if
         who @ "status/hp" 1 setto
         who @ "holding" "Nothing" setto
         { "^[o^[c" who @ id_name "^[y was protected from fainting by their ^[cFocus Band^[y!" }cat notify_watchers
         else
         who @ "holding" get "Focus Sash" smatch StartedFullHP @ and tpos @ who @ can_use_hold_item and if
         who @ "status/hp" 1 setto
         who @ "holding" "Nothing" setto
         { "^[o^[c" who @ id_name "^[y was protected from fainting by their ^[cFocus Sash^[y!" }cat notify_watchers
         else
         POKESTORE { "@pokemon/" who @ "/@RP/status" }cat remove_prop
         who @ "status/hp" 0 setto
         who @ "status/fainted" 1 setto
         loc @ { "@battle/" BID @ "/Declare/" tpos @ }cat remove_prop
         (break)
         then
         then
         then
        else
        who @ "status/statmods/movecontinued/movename" get dup not if pop else "rage" smatch who @ "status/fainted" get not and if
        who @ "status/statmods/PhysAtk" get atoi oldval !
                    who @ "status/statmods/PhysAtk" over over get atoi 1 + temp !
                    temp @ 6 > if 6 temp ! then
                    temp @ -6 < if -6 temp ! then
                    temp @ setto
                    {
                      oldval @ temp @ = if
                      "^[o^[c" who @ id_name "'s ^[yPhysAtk can't go any higher from rage."
                      else
 
 
                "^[o^[c" who @ id_name "'s ^[yPhysAtk raised from its rage."
                then
        }cat notify_watchers
 
         then
 
        who @ "ability" fget "Anger Point" smatch if
                CH @ 1 > if
                        who @ "status/statmods/PhysAtk" 6 setto
                        { "^[o^[c" who @ id_name "'s^[y ability " who @ "ability" fget cap "^[y activated!" }cat notify_watchers
                then
        then
 
        then
        then then then then then then
 
POKEDEX { "moves/" move @ "/FaintBeforeUse" }cat getprop  user @ "status/fainted" get not and if
               
                   POKESTORE { "@pokemon/" user @ "/@RP/status" }cat remove_prop
                   POKESTORE { "@pokemon/" user @ "/@temp/" }cat remove_prop
                    user @ "status/hp" 0 setto
                   user @ "status/fainted" 1 setto
                   (
                   { "^[o^[c" pos @ cap "." user @ id_name " ^[yFainted!!" }cat notify_watchers
                                   user @ "happiness" over over fget atoi 1 - fsetto
                user @ "happiness" over over fget atoi 0 < if 0 fsetto else pop pop then)
 


then
 
who @ "status/fainted" get not user @ "status/fainted" get not and if
 
        POKEDEX { "items/" who @ "holding" get "/holdeffect" }cat getprop berryeffect !
        berryeffect @
        tpos @ who @ can_use_hold_item and
        user @ "ability" fget "Magic Guard" smatch not and
        if
                berryeffect @ ":" explode_array foreach effect ! pop
                effect @ "recoil*" smatch if
                        effect @ " " "Recoil" subst strip effect !
                        POKEDEX  { "moves/" move @ "/class" }cat getprop effect @ smatch if
                                { "^[o^[c" who @ id_name "^[y ate its ^[c" who @ "holding" get "^[y and caused damage to ^[c" user @ id_name "^y!" }cat notify_watchers
                                user @ "status/hp" over over get atoi
                                user @ "maxhp" calculate 8 user @ "pvp/hpboost" fget dup if atoi * else pop then divdamage - setto
 
                                user @ "status/hp" get 0 <= if
                                user @ "status/hp" 0 setto
                                user @ "status/fainted" 1 setto
                                then
                                who @ eatberry
                        then
                then
                repeat
                then
then
 
repeat (this is for multi hit)
 
hittimes @ 1 > if
        { "^[o^[c" pos @ "."attacker @ id_name "^[y hit ^[c" turncount @ "^[y time[s]!" }cat notify_watchers
then
 
then
 
repeat (this is for triple kick)


 
(store data of last hit)
 
tpos @ stringify pos @ stringify smatch not if
loc @ { "@battle/" BID @ "/lasthit/" tpos @ "/damage" }cat damage @ setprop
loc @ { "@battle/" BID @ "/lasthit/" tpos @ "/class" }cat POKEDEX { "moves/" move @ "/class" }Cat getprop setprop
loc @ { "@battle/" BID @ "/lasthit/" tpos @ "/target" }cat pos @ setprop
loc @ { "@battle/" BID @ "/lasthit/" tpos @ "/type" }cat POKEDEX { "moves/" move @ "/type" }cat getprop setprop
then
 
(do color change)
who @ "ability" fget "Color Change" smatch if
        who @ "status/statmods/type" movetype @ setto
        { "^[o^[c" who @ id_name "^[y changed its type to ^[c" movetype @ cap "^[y because of its ability ^[cColor Change^[y." }cat notify_watchers
then
 
loc @ { "@Battle/" BID @ "/bide/" tpos @ }cat getprop if
        loc @ { "@Battle/" BID @ "/bide/" tpos @ "/damage" }cat over over getprop damage @ + setprop
then
(effects)
 
POKEDEX { "moves/" move @ "/class" }cat getprop "none" smatch if
effects (call the effects)
else
 
 
 
loc @ { "@battle/" BID @ "/beatup/" pos @ }cat getprop not
if
 
typetotal @
POKEDEX { "moves/" move @ "/AlwaysEffect" }cat getprop dup not if pop "no" then "yes" smatch or
noeffect @ not and 
if
effects (call the effects)
then
 
then then

(Weak Armor)
POKEDEX { "moves/" move @ "/class" }cat getprop "physical" smatch who @ "ability" fget "weak armor" smatch and if
        { "^[o^[c" who @ id_name "'s^[y ^[cSpeed ^[ywas raised while its ^[cDefense ^[ywas lowered due to ^[yits ability ^[c" who @ "ability" fget cap "^[y!" }cat notify_watchers
        who @ "status/statmods/physdef" over over get atoi 1 - setto
        who @ "status/statmods/physdef" get atoi -6 < if
                who @ "status/statmods/physdef" -6 setto
        then
        who @ "status/statmods/speed" over over get atoi 1 + setto
                who @ "status/statmods/speed" get atoi 6 > if
                        who @ "status/statmods/speed" 6 setto
                then
        
then
(do abilities that involve being touched)
POKEDEX { "moves/" move @ "/contact?" }cat getprop stringify "yes" smatch
misshurtself @ not and
if
 
who @ "holding" get "Sticky Barb" smatch user @ "ability" fget "Magic Guard" smatch not and if
                
                        user @ "status/hp" over over get atoi user @ "maxhp" calculate 8 user @ "pvp/hpboost" fget dup if atoi * else pop then divdamage - setto
                        { "^[o^[c" user @ id_name "^[y has been ^[rDamaged^[y by ^[c" who @ id_name "'s^[y item ^[c" who @ "holding" get "^[y!" }cat notify_watchers
                        
                        user @ "holding" get "nothing" smatch if
                        POKESTORE { "@pokemon/" user @ "/@long/holding" }cat "Sticky Barb" setprop
                        POKESTORE { "@pokemon/" who @ "/@long/holding" }cat "Nothing" setprop
                        { "^[o^[c" user @ "holding" get "^[y is now stuck on ^[c" user @ id_name "^[y!"  }cat notify_watchers
                        then
                then
 var oppability
 who @ "Ability" fget oppability !
 var ability
 user @ "ability" fget ability !
 
 
 ability @ "Poison Touch" smatch oppability @ "shield dust" smatch not and if
         frand 0.3 <= if
         begin
            who @ "status/frozen"    get if break then
            who @ "status/paralyzed" get if break then
            who @ "status/asleep"    get if break then
            who @ "status/poisoned"  get if break then
            who @ "status/toxic"     get if break then
            who @ "status/burned"    get if break then
            who @ "status/fainted"   get if break then
            who @ "ability" fget "leaf guard" smatch bid @ check_weather "sunny day" smatch and if break then
            who @ typelist "poison" array_findval array_count if break then
            who @ typelist "steel" array_findval array_count if break then
            who @ "ability" fget "immunity" smatch if break then
           who @ "status/poisoned" 1 setto
               { "^[o^[c" who @ id_name "^[y has been ^[ypoisoned^[y by ^[c" user @ id_name "^[y because of its ability ^[c" ability @ cap "^[y!" }cat notify_watchers
               break
               repeat
         then
 then
 
 oppability @ "mummy" smatch if
        user @ "multitype" smatch not 
        user @ "mummy" smatch not and
        if
        POKESTORE { "@pokemon/"user @ fid "/@temp/ability" }cat "Mummy" setprop
         { "^[o^[c" user @ id_name "'s ^[yability was changed to ^[cmummy^[y from contact!" }cat notify_watchers
        then
 then
 
 oppability @ "Rough Skin" smatch 
 oppability @ "iron barbs" smatch or
 if
        { "^[o^[c" user @ id_name "^[y takes damage because of ^[c" who @ id_name "'s ^[yability ^[c" who @ "ability" fget cap "^[y!" }cat notify_watchers
        user @ "status/hp" over over get atoi user @ "maxhp" calculate 16 user @ "pvp/hpboost" fget dup if atoi * else pop then divdamage - setto
        user @ "status/hp" get atoi 0 <= if
           POKESTORE { "@pokemon/" user @ "/@RP/status" }cat remove_prop
           user @ "status/hp" 0 setto
           user @ "status/fainted" 1 setto
                    then
 then
 
 frand var! randomchance
 randomchance @ 0.3 <= if
 begin
  oppability @ "Flame Body" smatch if
   user @ "status/frozen"    get if break then
   user @ "status/paralyzed" get if break then
   user @ "status/asleep"    get if break then
   user @ "status/poisoned"  get if break then
   user @ "status/toxic"     get if break then
   user @ "status/burned"    get if break then
   user @ "status/fainted"   get if break then
   user @ "ability" fget "leaf guard" smatch bid @ check_weather "sunny day" smatch and if break then
   user @ "ability" fget "water veil" smatch if break then
   user @ typelist "fire" array_findval array_count if break then
   user @ "status/burned" 1 setto
   { "^[o^[c" user @ id_name "^[y has been ^[rBurned^[y by ^[c" who @ id_name " ^[ybecause of its ability ^[c" oppability @ cap "^[y!" }cat notify_watchers
 
  then
  oppability @ "Static" smatch if
   user @ "status/frozen"    get if break then
   user @ "status/paralyzed" get if break then
   user @ "status/asleep"    get if break then
   user @ "status/poisoned"  get if break then
   user @ "status/toxic"     get if break then
   user @ "status/burned"    get if break then
   user @ "status/fainted"   get if break then
   user @ "ability" fget "leaf guard" smatch bid @ check_weather "sunny day" smatch and if break then
   user @ "ability" fget "limber" smatch if break then
   user @ "status/paralyzed" 1 setto
   { "^[o^[c" user @ id_name "^[y has been ^[yparalyzed^[y by ^[c" who @ id_name "^[y because of its ability ^[c" oppability @ cap "^[y!" }cat notify_watchers
 
  then
  oppability @ "Poison Point" smatch if
   user @ "status/frozen"    get if break then
   user @ "status/paralyzed" get if break then
   user @ "status/asleep"    get if break then
   user @ "status/poisoned"  get if break then
   user @ "status/toxic"     get if break then
   user @ "status/burned"    get if break then
   user @ "status/fainted"   get if break then
   user @ "ability" fget "leaf guard" smatch bid @ check_weather "sunny day" smatch and if break then
   user @ typelist "poison" array_findval array_count if break then
   user @ typelist "steel" array_findval array_count if break then
   user @ "ability" fget "immunity" smatch if break then
   user @ "status/poisoned" 1 setto
   { "^[o^[c" user @ id_name "^[y has been ^[mPoisoned^[y by ^[c" who @ id_name "^[y because of its ability ^[c" oppability @ cap "^[y!" }cat notify_watchers
 
 
  then
  var tempeffect
  oppability @ "Cute Charm" smatch if
 
   user @ "status/statmods/attracted" get if break then
     who @ "gender" fget "male" smatch if
       user @ "gender" fget "female" smatch if
       1 tempeffect !
       then then
     who @ "gender" fget "female" smatch if
       user @ "gender" fget "male" smatch if
       1 tempeffect !
       then then
 
     tempeffect @ if
     user @ "ability" fget "oblivious" smatch not if
     user @ "status/statmods/attracted" who @ setto
 
     { "^[o^[c"user @ id_name "^[y is now attracted because of ^[c" who @ id_name "'s^[y ability ^[c" oppability @ cap "^[y!" }cat notify_watchers
     
     user @ "holding" get "Destiny Knot" smatch if
     who @ "status/statmods/attracted" user @ setto
     { "^[o^[c"who @ id_name "^[y is now attracted because of ^[c" user @ id_name "'s^[y item ^[c" user @ "holding" get @ cap "^[y!" }cat notify_watchers
     then
     
     then
    then
  then
  oppability @ "Effect Spore" smatch if
     user @ "status/frozen"    get if break then
     user @ "status/paralyzed" get if break then
     user @ "status/asleep"    get if break then
     user @ "status/poisoned"  get if break then
     user @ "status/toxic"     get if break then
     user @ "status/burned"    get if break then
     user @ "ability" fget "leaf guard" smatch bid @ check_weather "sunny day" smatch and if break then
     user @ "status/fainted"   get if break then
  var effectspore
   randomchance @ 0.3 <= if
   "poison" effectspore !
   then
   randomchance @ 0.2 <= if
   "paralyze" effectspore !
   then
   randomchance @ 0.1 <= if
   "sleep" effectspore !
   then
   effectspore @ not if
   "none" effectspore !
   then
   effectspore @ "poison" smatch
   user @ typelist "poison" array_findval array_count if 0 else 1 then and
   user @ typelist "steel" array_findval array_count if 0 else 1 then and
   user @ "ability" fget "immunity" smatch and
   if
   user @ "status/poisoned" 1 setto
   { "^[o^[c" user @ id_name "^[y has been ^[mPoisoned^[y by ^[c" who @ id_name "^[y because of its ability ^[c" oppability @ cap "^[y!" }cat notify_watchers
   then
   effectspore @ "paralyze" smatch
   user @ "ability" fget "limber" smatch not and
   if
   user @ "status/paralyzed" 1 setto
   { "^[o^[c" user @ id_name "^[y has been ^[yParalyzed^[y by ^[c" who @ id_name "^[y because of its ability ^[c"oppability @ cap "^[y!" }cat notify_watchers
   then
   effectspore @ "sleep" smatch if
        user @ "ability" fget "Vital Spirit" smatch
        user @ "ability" fget "Insomnia" smatch or
        if
           { "^[o^[c" user @ id_name "^[y would have fallen ^[bAsleep^[y because of ^[c" who @ id_name "'s ^[yability ^[c"oppability @ cap "^[y but couldn't due to its ability ^[c" user @ "ability" fget cap "^[y!" }cat notify_watchers
        else
           loc @ { "@battle/" BID @ "/uproar" }cat propdir? if
           { "^[o^[c" user @ id_name "^[y would have fallen ^[bAsleep^[y because of ^[c" who @ id_name "'s ^[yability ^[c"oppability @ cap "^[y but couldn't due to the effect of uproar!" }cat notify_watchers
           else
                   user @ "status/asleep" random 7 % 2 +
                   user @ "ability" fget "early bird" smatch if dup 2 / - then
                   setto
                   { "^[o^[c" user @ id_name "^[y is now ^[bAsleep^[y because of ^[c" who @ id_name "'s ^[yability ^[c"oppability @ cap "^[y!" }cat notify_watchers
           then
        then
   then
 
  then
 break
 repeat
 then
then
 
who @ "status/fainted" get if
 
        (moved the happiness change to the endbattle.muf)
         { "^[o^[c" tpos @ cap "." who @ id_name " ^[yFainted!!" }cat notify_watchers
         
         user @ "ability" fget "moxie" smatch if
                         user @ "status/statmods/PhysAtk" get atoi 6 < if
                                 user @ "status/statmods/PhysAtk" over over get atoi 1 + setto
                                 { "^[o^[c" pos @ cap "." user @ id_name "'s ^[y^[cPsysAtk ^[ystat raised from its ability ^[cMoxie^[y!" }cat notify_watchers
                         then
         then
         
         who @ "ability" fget "Aftermath" smatch
         POKEDEX { "moves/" move @ "/contact?" }cat getprop stringify "yes" smatch and if
                "Damp" bid @ onfield_ability if
                { "^[o^[c" attacker @ id_name "^[y tried to use its ability ^[cAftermath^[y but it failed due to ^[cDamp ^[yability on field." }cat bid @ notify_watchers
                else
                 user @ "status/hp" over over get atoi
                 user @ "maxhp" calculate 4 user @ "pvp/hpboost" fget dup if atoi * else pop then divdamage - setto
                 { "^[o^[c" pos @ cap "." user @ id_name " ^[ytook damage from ^[cAftermath ^[yability!" }cat notify_watchers
                 user @ "status/hp" get atoi 0 <= if
                        user @ "status/hp" 0 setto
                        user @ "status/fainted" 1 setto
 
                 then
 
         then
         
         
         
 then
 
 loc @ { "@battle/" BID @ "/grudge/" who @ }cat getprop if
 user @ { "/movesknown/" move @ "/pp" }cat 1 fsetto
 { "^[o^[c" pos @ cap "." user @ id_name " ^[yran out of PP in ^[c" move @ cap "^[y because of ^[c" tpos @ "." who @ id_name "'s^[y grudge!!" }cat notify_watchers
 then
 
 loc @ { "@battle/" BID @ "/destinybond/" who @ }cat getprop if
 POKESTORE { "@pokemon/" user @ "/@RP/status/" }Cat remove_prop
 user @ "status/fainted" 1 setto
 user @ "status/hp" 0 setto
 { "^[o^[c" pos @ cap "." user @ id_name " ^[yFainted Because of Destiny Bond!!" }cat notify_watchers
 then
then
 
 
(have berries that remove status effect go into place here, do this for both sides)
who @ "status/fainted" get not if
        POKEDEX { "items/" who @ "holding" get "/holdeffect" }cat getprop berryeffect !
        berryeffect @
        tpos @ who @ can_use_hold_item and if
                berryeffect @ ":" explode_array foreach effect ! pop
                effect @ "Heal*" smatch if
                        effect @ " " "Heal" subst strip effect !
                        who @ { "status/" effect @ }cat get if
                                who @ { "status/" effect @ }cat 0 setto
                                { "^[o^[c" who @ id_name "^[y was healed from being ^[c" effect @ "^[y by eating its ^[c" who @ "holding" get "^[y!" }cat notify_watchers
                                who @ eatberry
                        then
 
                then
                repeat
        then
then
 
user @ "status/fainted" get not if
        POKEDEX { "items/" user @ "holding" get "/holdeffect" }cat getprop berryeffect !
        berryeffect @
        pos @ user @ can_use_hold_item and if
                berryeffect @ ":" explode_array foreach effect ! pop
                effect @ "Heal*" smatch if
                        effect @ " " "Heal" subst strip effect !
                        user @ { "status/" effect @ }cat get if
                                user @ { "status/" effect @ }cat 0 setto
                                { "^[o^[c" user @ id_name "^[y was healed from being ^[c" effect @ "^[y by eating its ^[c" user @ "holding" get "^[y!" }cat notify_watchers
                                user @ eatberry
                        then
 
                then
                repeat
        then
then
 
who @ "status/hp" get atoi who @ "maxhp" calculate 0.5 * <=
who @ "status/fainted" get not and if
        POKEDEX { "items/" who @ "holding" get "/holdeffect" }cat getprop berryeffect !
                berryeffect @
                tpos @ who @ can_use_hold_item and if
                        berryeffect @ ":" explode_array foreach effect ! pop
 
                                        effect @ "Restore/*" smatch if
                                        POKEDEX { "items/" who @ "holding" get "/conditional" }cat getprop if continue then
                                                effect @ " " "Restore/" subst strip atoi effect !
                                                who @ "status/hp" over over get atoi who @ "maxhp" calculate effect @ who @ "pvp/hpboost" fget dup if atoi * else pop then / + setto
                                                { "^[o^[c" who @ id_name "^[y regained some health by eating its ^[c" who @ "holding" get "^[y!" }cat notify_watchers
                                                who @ eatberry
 
                                                continue
                                        then
                                        effect @ "Restore *" smatch if
                                                POKEDEX { "items/" who @ "holding" get "/conditional" }cat getprop if continue then
                                                effect @ " " "Restore" subst strip atoi effect !
                                                who @ "status/hp" over over get atoi effect @ + setto
                                                { "^[o^[c" who @ id_name "^[y regained some health by eating its ^[c" who @ "holding" get "^[y!" }cat notify_watchers
                                                who @ eatberry
                                        continue
                                        then
                                        effect @ "confused" smatch if
 
                                                POKEDEX { "items/" who @ "holding" get "/" POKEDEX { "natures/" who @ "nature" get "/dislikes" }cat getprop }cat getprop if
                                                who @ "ability" fget "Own Tempo" smatch if
                                                { "^[o^[c" who @ id_name "^[y would of been confused, but can't be due to its ability ^[cOwn Tempo^[y." }cat notify_watchers
                                                continue then
                                                { "^[o^[c" who @ id_name "^[y is now confused!" }cat notify_watchers
                                                       who @ "status/statmods/confused"  random 4 % 2 + setto
                                                then
                                        then
                        repeat
                then
then
 
POKEDEX { "items/" who @ "holding" get "/Conditional" }cat getprop stringify "supereffective" smatch
who @ "status/fainted" get not and
if
        POKEDEX { "items/" who @ "holding" get "/holdeffect" }cat getprop berryeffect !
                berryeffect @
                tpos @ who @ can_use_hold_item and if
                        berryeffect @ ":" explode_array foreach effect ! pop
                                        effect @ "Restore*" smatch if
                                        (POKEDEX { "items/" who @ "holding" get "/conditional" }cat getprop if continue then) (I don't know why this was here)
                                                effect @ " " "Restore" subst strip atoi effect !
                                                who @ "status/hp" over over get atoi who @ "maxhp" calculate effect @ / + setto
                                                { "^[o^[c" who @ id_name "^[y regained some health by eating its ^[c" who @ "holding" get "^[y!" }cat notify_watchers
                                                who @ eatberry
 
                                                continue
                                        then
                                        repeat
                        then
then
 
who @ "ability" fget "Gluttony" smatch if
who @ "status/hp" get atoi who @ "maxhp" calculate 0.50 * <=
else
who @ "status/hp" get atoi who @ "maxhp" calculate 0.25 * <=
then
who @ "status/fainted" get not and if
POKEDEX { "items/" who @ "holding" get "/holdeffect" }cat getprop berryeffect !
                berryeffect @
                tpos @ who @ can_use_hold_item and if
                        berryeffect @ ":" explode_array foreach effect ! pop
 
                        effect @ "move first" smatch if
                                 { "^[o^[c" who @ id_name "^[y is attacking sooner next turn by eating its ^[c" who @ "holding" get "^[y!" }cat notify_watchers
                                 who @ "status/statmods/movefirst" 1 setto
                                 who @ eatberry
                                 continue
                        then
 
        effect @ "raise*" smatch if
                        effect @ " " "Raise" subst strip effect !
                        effect @ " " "stat" subst strip effect !
                        effect @ "random" smatch if
                        random 5 % 1 +
                        dup 1 = if "PhysAtk" effect ! then
                        dup 2 = if "PhysDef" effect ! then
                        dup 3 = if "SpecAtk" effect ! then
                        dup 4 = if "SpecDef" effect ! then
                            5 = if "Speed"   effect ! then
                        then
                        effect @ "critical*" smatch if "critical" effect ! then
                        who @ { "status/statmods/" effect @ }cat over over get atoi 1 + setto
                        { "^[o^[c" who @ id_name "^[y raised its ^[c" effect @ "^[y stat by eating its ^[c" who @ "holding" get "^[y!" }cat notify_watchers
                        who @ eatberry
                        continue
        then
        repeat
        then
 
 
then
 
majorstatus @ not
who @ check_status and
who @ "ability" fget "Synchronize" smatch and
user @ check_status not and
user @ "ability" fget "leaf guard" smatch bid @ check_weather "sunny day" smatch and if 0 else 1 then and
if
        who @ "status/poisoned" get
        who @ "Status/toxic" get or
        user @ typelist "poison" array_findval array_count if 0 else 1 then and
        user @ typelist "steel" array_findval array_count if 0 else 1 then and
        if
                (who @ "status/poisoned" get if)
                user @ "status/poisoned" 1 setto
                { "^[o^[c" user @ id_name "^[y was ^[mpoisoned ^[ydue to the effects of Synchronize!" }cat notify_watchers
                (then)
                ( this is for generation V)
                (
                who @ "status/toxic" get if
                user @ "status/toxic" 1 setto
                { "^[o^[c" user @ id_name "^[y was ^[mbadly poisoned ^[ydue to the effects of Synchronize!" }cat notify_watchers
                then )
        then
 
        who @ "status/burned" get
 
        user @ typelist "fire" array_findval array_count if 0 else 1 then and
        if
                user @ "Status/burned" 1 setto
                { "^[o^[c" user @ id_name "^[y was ^[rburned ^[ydue to the effects of Synchronize!" }cat notify_watchers
        then
 
        who @ "status/paralyzed" get
        user @ "ability" fget "limber" smatch if 0 else 1 then and
        if
                user @ "status/paralyzed" 1 setto
                { "^[o^[c" user @ id_name "^[y was ^[yparalyzed ^[ydue to the effects of Synchronize!" }cat notify_watchers
 
        then
then
1 sleep
 
; PUBLIC damage_calc
 
 
 
: main
 
;