$include $lib/ansi
$include $lib/useful
$include $rp/combat/CalcStats
$include $rp/combat/AI
$include $rp/combat/Damage
$include $rp/combat/Pokeball
($include $rp/combat/BattleTypes)
$include $rp/combat/End
$include $rp/combat/Triggers
$include $rp/combat/Modder
 
(this code includes the main code for battles.  This doesn't do the damage and doesn't set up the types of battles but it does everything else.)
var arg
var tempref
 
var weather
var targettype
var immune
var id
var effect
var berryeffect
 
var oteam
 
var damage
var maxhp
var smaxhp
var seeder
var partner
var othertargets
 
var temp
var temp2
var temp3
var temp4

var wascharging
 
: notify_watchers
var! bid
var! msg
      loc @ { "@battle/" bid @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
         tempref @ awake? not if continue then
  tempref @ location loc @ = not if continue then
 
         tempref @ { msg @ }cat notify
         repeat
;

: moldbreaker (this is done after the ability smatch, if it has a 0 then skip this and return 0, if it has a 1 then do the check for the ability. return a 0 if broken and a 1 if not)
var! BID
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
          { "^[o^[y" targ @ id_name " breaks the mold!" }cat bid @ notify_watchers
          then

             uabil @ "Turboblaze" smatch if
            { "^[o^[y" targ @ id_name " is radiating a blazing aura!" }cat bid @ notify_watchers
          then
             uabil @ "Teravolt" smatch if
            { "^[o^[y" targ @ id_name " is radiating a bursting aura!" }cat bid @ notify_watchers
          then
  
  0
  else
  1
  then
  else
1
then
;
 
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
 
; 
 
: PercentDisplay
 
var! percent
var howmany
var count
percent @ 10 / howmany !
 
{
1 10 1 for count !
count @ howmany @ <= if
"^[o"
count @ 3 < if
"^[r" else
count @ 6 < if
"^[y" else
"^[g"
then
then
"|"
else
" "
then
repeat
 
}cat
 
 
;

: verifycontrol (this is to help fix issues where the system bugs out due to an AI issue or something else)


;

 
: divdamage (this is just used to change the division to decimals, round up, then make back into int)
var! div
var! hp
 
hp @ div @ / dup 1 < if pop 1 then
;
 
: checkothers
(this code segment is used to check if the other players in the battle have picked their attacks. You shoulden't need to edit this.)
var! pos var! BID
var partner
var opp
 
loc @ { "@battle/" BID @ "/howmany" }cat getprop "2" smatch if
pos @ "*1" smatch if
{ pos @ 1 1 midstr "2" }cat partner !
else
{ pos @ 1 1 midstr "1" }cat partner !
then
 
 
 
loc @ { "@battle/" BID @ "/position/" partner @ }cat getprop if
 loc @ { "@Battle/" BID @ "/declare/" partner @ }cat getprop not if
  loc @ { "@battle/" BID @ "/control/team" pos @ 1 1 midstr "/" loc @ { "@Battle/" BID @ "/position/" partner @ }cat getprop }cat getprop me @ = not if
   "^[o^[yWaiting on your partner to decide what they will do." "Battle" pretty tellme
   exit
  then
 
 then
then
then
 
pos @ "A*" smatch if
"B" opp !
else
"A" opp !
then
 
var oppid
loc @ { "@battle/" BID @ "/position/" opp @ "1" }cat getprop if
loc @ { "@battle/" BID @ "/position/" opp @ "1" }cat getprop oppid !
loc @ { "@battle/" BID @ "/control/team" opp @ "/" oppid @ }cat getprop stringify "AI" smatch not if
loc @ { "@battle/" BID @ "/declare/" opp @ "1" }cat getprop not if
 "^[o^[yWaiting on the other team to decide what they will do." "Battle" pretty tellme
 exit
 then
then
then
 
loc @ { "@battle/" BID @ "/position/" opp @ "2" }cat getprop if
loc @ { "@battle/" BID @ "/position/" opp @ "2" }cat getprop oppid !
loc @ { "@battle/" BID @ "/control/team" opp @ "/" oppid @ }cat getprop stringify "AI" smatch not if
loc @ { "@battle/" BID @ "/declare/" opp @ "2" }cat getprop not if
 "^[o^[yWaiting on the other team to decide what they will do." "Battle" pretty tellme
 exit
 then
then
then
 
;

: levelupmoves
(this shoulden't run anymore, decided to have the prompt behave differently and not pause combat.)
var! BID
var team
var controller
var lp

(this is the code segment for checking if a pokemon has a move that needs to be learned and prompts accordingly.)
{ "A" "B" }list foreach team ! pop
        loc @ { "@battle/" BID @ "/teams/" team @ "/" }cat array_get_propvals foreach id ! pop
                POKESTORE { "@pokemon/" ID @ "/@RP/abletolearn/" }cat propdir? if
                        1 lp !
                        
                        loc @ { "@battle/" BID @ "/control/team" team @ "/" id @ }cat getprop controller !

                        controller @ dbref? if
                                controller @ { "@learning pending/" id @  }cat getprop if continue then
                                loc @ { "@battle/" BID @ "/levelmovepending/" ID @ }cat controller @ setprop
                                controller @ { "^[o^[c" id @ id_name "^[y is able to learn something from levelup.  Type +learn to see what it is.  The Battle is paused until you decide." }cat "Battle" pretty notify
                                controller @ "@learning pending" "yes" setprop
                                controller @ { "@learning pending/" id @  }cat id @ setprop
                        then
                then
        repeat
repeat
lp @ if
(message if something has a learning pending)

then
;
 
: fainted_pokemon
(this is the code segment for what happens when a pokemon is fainted.  This is used to check for fainted pokemon and remove as needed.  This is also what is what is used to replace the fainted.  Odds are you won't need to do any changes to this.)
var! BID
 
var id
var counter
var notvalid
var maxhp
var percent
var pos_list
var team
 
loc @ { "@battle/" BID @ "/fainted/" }cat propdir? not if
 
loc @ { "@battle/" bid @ "/howmany" }cat getprop atoi 2 = if
 { "A1" "B1" "A2" "B2" }list
 else
 { "A1" "B1" }list
 then
 
 pos_list !
 var pos
 
 pos_list @ foreach POS ! pop
  pos @ 1 1 midstr team !
  team @ "A" smatch if
  "B" oteam !
  else
  "A" oteam !
  then
 
  loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop if
  continue then
 
  var controller
 
  loc @ { "@battle/" BID @ "/control/team" team @ "/" loc @ { "@battle/" BID @ "/Begin Position/" pos @ }cat getprop }cat getprop controller !
 
  loc @ { "@battle/" BID @ "/temp/validstats/" team @ }cat remove_prop
  loc @ { "@battle/" BID @ "/charge/" pos @ }cat remove_prop
  0 counter !
  loc @ { "@battle/" BID @ "/teams/" team @ "/" }cat array_get_propvals foreach id ! pop
   counter @ 1 + counter !
   0 notvalid !
   loc @ { "@battle/" BID @ "/position/" team @ "1" }cat getprop stringify id @ smatch if 1 notvalid ! then
   loc @ { "@battle/" BID @ "/position/" team @ "2" }cat getprop stringify id @ smatch if 1 notvalid ! then
   id @ "status/hp" get not if 3 notvalid ! then
   loc @ { "@battle/" BID @ "/temp/validstats/" team @ "/" id @ }cat notvalid @ setprop
  repeat
 
 
  var switchable
  0 switchable !
  loc @ { "@battle/" BID @ "/teams/" team @ "/" }cat array_get_propvals foreach id ! pop
  loc @ { "@battle/" BID @ "/temp/validstats/" team @ "/" id @ }cat getprop not if 1 switchable ! break then
  repeat
 
  switchable @ not if 
  loc @ { "@battle/" BID @ "/needtoswitch/" team @ }cat remove_prop
  continue then
 
  loc @ { "@battle/" BID @ "/temp/validstats/" oteam @ }cat remove_prop
  0 counter !
  loc @ { "@battle/" BID @ "/teams/" oteam @ "/" }cat array_get_propvals foreach id ! pop
   counter @ 1 + counter !
   0 notvalid !
   id @ "status/hp" get not if 3 notvalid ! then
   loc @ { "@battle/" BID @ "/temp/validstats/" oteam @ "/" id @ }cat notvalid @ setprop
  repeat
 
 
  0 switchable !
  loc @ { "@battle/" BID @ "/teams/" oteam @ "/" }cat array_get_propvals foreach id ! pop
  loc @ { "@battle/" BID @ "/temp/validstats/" oteam @ "/" id @ }cat getprop not if 1 switchable ! break then
  repeat
 
  switchable @ not if continue then
    loc @ { "@battle/" BID @ "/repeats/" POS @ }cat remove_prop
    loc @ { "@battle/" BID @ "/uproar/" POS @ }cat remove_prop
   loc @ { "@battle/" BID @ "/DamageDeltTurn/" POS @ }cat remove_prop
  controller @ dbref? if
 
   loc @ { "@battle/" BID @ "/fainted/" POS @ }cat controller @ setprop
   controller @ { "^[o^[c" loc @ { "@battle/" BID @ "/begin position/" pos @ }cat getprop id_name "^[y has fainted.  Select a new pokemon with '+switch' or run with '+run'. "}cat "Battle" pretty notify
   loc @ { "@battle/" BID @ "/fainted/" POS @ "/ID" }cat loc @ { "@battle/" BID @ "/begin position/" pos @ }cat getprop setprop
   loc @ { "@battle/" BID @ "/fainted/" POS @ "/controller" }cat controller @ setprop
   continue then (uses continue so it doesn't do the AI segment)
 
(this part here is where the AI does its switching)

"AI" BID @ pos @ moveswitch
BID @ pos @ "A*" smatch if "B" else "A" then endbattle
(
  loc @ { "@battle/" BID @ "/teams/" team @ "/" }cat array_get_propvals foreach id ! pop
  loc @ { "@battle/" BID @ "/temp/validstats/" team @ "/" id @ }cat getprop if continue then
  break
  repeat
Pos @ BID @ id @ switch_handler )

 
repeat
 
else
var controller
me @ controller !
var contname
var switched
loc @ { "@battle/" BID @ "/fainted/" }Cat array_get_propvals foreach contname ! pos !
 
contname @ controller @ = not if continue then
1 switched !
pos @ 1 1 midstr team !
  var counter
        var trainer1
        var trainer2
        var fusionnudge
 
        loc @ { "@battle/" BID @ "/teams/" team @ "/A" }cat getprop trainer1 !
        loc @ { "@battle/" BID @ "/teams/" team @ "/B" }cat getprop trainer2 !
 
        trainer1 @ if 1 fusionnudge ! then
        trainer2 @ if fusionnudge @ 1 + fusionnudge !
        then
 
  var othercont
  0 counter !
  controller @ { "^[y^[oSwitching for ^[c" loc @ { "@battle/" BID @ "/fainted/" pos @ "/id" }cat getprop id_name }cat notify
  bid @ pos @ switch_check pop
  controller @ { "^[y^[o------------------------------------------------------------------------" }cat notify
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
   id @ "gender" fget "M*" smatch if
   "^[o^[c" { id @ "gender" fget 1 1 midstr }cat
   then
 
   id @ "gender" fget "F*" smatch if
   "^[o^[r" { id @ "gender" fget 1 1 midstr }cat
   then
 
   id @ "gender" fget "N*" smatch id @ "gender" fget "O*" smatch or if
   "^[o^[m" { id @ "gender" fget 1 1 midstr }cat
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
   "^[y<On Field>"
   then
 
   notvalid @ 2 = if
   "^[y<To be switched>"
   then
 
   notvalid @ 3 = if
   "^[r<Fainted>"
   then
 
   loc @ { "@Battle/" BID @ "/control/team" team @ "/" id @ }cat getprop othercont !
   othercont @ controller @ = not if
   { "  ^[g<" othercont @ name ">" }cat
   then
 
   }cat notify
   repeat
   controller @ { "^[y^[o------------------------------------------------------------------------" }cat notify
 
   var choice
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
   loc @ { "@battle/" BID @ "/fainted/" pos @ }cat remove_prop
     loc @ { "@battle/" BID @ "/repeats/" POS @ }cat remove_prop
  loc @ { "@battle/" BID @ "/uproar/" pos @ }cat remove_prop
 BID @ pos @ "A*" smatch if "B" else "A" then endbattle 
 
switched @ not if
"^[o^[rWe arn't waiting for you to switch in a pokemon.  Wait for the round to begin." "Battle" pretty tellme
then
repeat
then
 
;
 
: ItemHandler ( s s - bool )  (this is what is taken into consideration for items to be used.)
cap var! item var! who var! pos var! BID
var effect
var stat
var temp
var what
var total
 
0 var! consume?
 
who @ { "items/" item @ "/UseEffect" }cat get ":" explode_array foreach effect ! pop
 
  effect @ "Consume" smatch if
    1 consume? !
    continue
  then
 
  effect @ "Cure *" smatch if
    
    effect @ " " split swap pop temp !
    who @ "status/hp" over over get atoi temp @ atoi + setto
    who @ "MaxHP" Calculate
    dup who @ "status/hp" get atoi < if
      who @ swap "status/hp" swap setto
    else
      pop
    then
    {
      "^[o^[c" item @ " ^[gcured ^[c" who @ ID_name " ^[gfor ^[w" temp @ " ^[gHP!"
    }cat bid @ notify_watchers
    continue
  then
 
  effect @ "Cure/*" smatch if
    effect @ "/" split swap pop atoi who @ "pvp/hpboost" fget dup if atoi * else pop then temp !
    who @ "MaxHP" Calculate var! maxhp
    who @ "status/hp" over over get atoi maxhp @ 1.0 * temp @ / 0 round floor dup not if pop 1 then + setto
    maxhp @ who @ "status/hp" get atoi < if
      who @ "status/hp" maxhp @ setto
    then
 
    {
      "^[o^[c" item @ " ^[gcured ^[c" who @ ID_name " ^[gfor ^[w" maxhp @ 1.0 * temp @ / 0 round floor intostr " ^[gHP!"
    }cat bid @ notify_watchers
    continue
  then
 
  effect @ "Heal *" smatch if
 
    effect @ " " split swap pop temp !
        temp @ "Poisoned" smatch if
          who @ "status/Toxic" get if
            who @ "status/Toxic" 0 setto
            {
              "^[o^[c" item @ " ^[gremoved ^[wToxic ^[gstatus from ^[c" who @ ID_name "^[g!"
            }cat bid @ notify_watchers
            continue
          then
    then
    who @ { "status/" temp @ }cat get if
      who @ { "status/" temp @ }cat 0 setto
 
      {
        "^[o^[c" item @ " ^[gremoved ^[w" temp @ " ^[gstatus from ^[c" who @ ID_name "^[g!"
      }cat bid @ notify_watchers
    else
    who @ { "status/statmods/" temp @ }cat get if
        who @ { "status/statmods/" temp @ }cat 0 setto
        {
                "^[o^[c" item @ " ^[gremoved ^[w" temp @ " ^[gstatus from ^[c" who @ ID_name "^[g!"
      }cat bid @ notify_watchers
    else
          { "^[o^[yThere's no ^[w" temp @ " ^[ycondition to remove!" }cat bid @ notify_watchers
    then
    then
 
    continue
  then
  
    effect @ "HealAll" smatch if
      0 temp !
      who @ "status/Asleep" get if 1 temp ! who @ "status/Asleep" 0 setto then
      who @ "status/Burned" get if 1 temp ! who @ "status/Burned" 0 setto then
      who @ "status/Frozen" get if 1 temp ! who @ "status/Frozen" 0 setto then
      who @ "status/Paralyzed" get if 1 temp ! who @ "status/Paralyzed" 0 setto then
      who @ "status/Poisoned" get if 1 temp ! who @ "status/Poisoned" 0 setto then
      who @ "status/Toxic" get if 1 temp ! who @ "status/Toxic" 0 setto then
      who @ "status/statmods/confused" get if 1 temp ! who @ "status/statmods/confused" 0 setto then
      
      { "^[o^[yStatus Cleared from ^[c" who @ ID_name "^[y!" }cat bid @ notify_watchers
      continue
  then
  
    effect @ "FullRestore" smatch if
      0 temp !
      who @ "status/Asleep" get if 1 temp ! who @ "status/Asleep" 0 setto then
      who @ "status/Burned" get if 1 temp ! who @ "status/Burned" 0 setto then
      who @ "status/Frozen" get if 1 temp ! who @ "status/Frozen" 0 setto then
      who @ "status/Paralyzed" get if 1 temp ! who @ "status/Paralyzed" 0 setto then
      who @ "status/Poisoned" get if 1 temp ! who @ "status/Poisoned" 0 setto then
      who @ "status/Toxic" get if 1 temp ! who @ "status/Toxic" 0 setto then
      who @ "status/statmods/confused" get if 1 temp ! who @ "status/statmods/confused" 0 setto then
      who @ "status/hp" get atoi who @ "MaxHP" Calculate < if
        1 temp !
        who @ "status/hp" who @ "MaxHP" Calculate
                who @ "pvp/hpboost" fget dup if atoi / else pop then
        setto
      then
 
      { "^[o^[c" who @ Id_name "^[y is Fully Restored!" }Cat bid @ notify_watchers
      continue
  then
  
   effect @ "PP-One *" smatch if
     effect @ " " split swap pop atoi temp !
     loc @ { "@battle/" BID @ "/Declare/" pos @ "/attackpp" }cat getprop what !
     who @ { "movesknown/" what @ }cat fget atoi var! ppup
     who @ { "moves/" what @ "/pp" }cat get atoi 5 ppup @ + 1 - * 5 / total !
     who @ { "movesknown/" what @ "/pp" }cat
       over over fget atoi temp @ +
       dup total @ > if pop total @ then
     fsetto
     { "^[o^[wRestored energy in ^[c" what @ "!" }cat bid @ notify_watchers
     continue
   then
 
   effect @ "PP-All *" smatch if
     effect @ " " split swap pop atoi temp !
     var ppup
     who @ "movesknown" fgetvals foreach ppup ! what !
       who @ { "moves/" what @ "/pp" }cat get atoi 5 ppup @ + 1 - * 5 / total !
       who @ { "movesknown/" what @ "/pp" }cat
         over over fget atoi temp @ +
         dup total @ > if pop total @ then
       fsetto
     repeat
     "^[o^[wRestored energy in all moves!" bid @ notify_watchers
     continue
   then
 
  effect @ "Happy -*" smatch if
    effect @ " -" split swap pop atoi temp !
    who @ "holding" get "sooth bell" smatch if temp @ 2 * temp ! then
    who @ "happiness" fget atoi temp @ -
    dup 0 >= if
      who @ swap "happiness" swap fsetto
    else
      who @ "happiness" 0 fsetto
    then
    continue
  then
 
  effect @ "Happy +*" smatch if
    effect @ " +" split swap pop atoi temp !
    who @ "happiness" fget atoi temp @ +
    who @ "holding" get "Soothe Bell" smatch
    who @ "status/statmods/embargo" get not and if 1 else 0 then +
    dup 255 <= if
      who @ swap "happiness" swap fsetto
    else
      pop who @ "happiness" 255 fsetto
    then
    continue
  then
 
  effect @ "{PhysAtk|PhysDef|Speed|SpecAtk|SpecDef|Critical|Accuracy} +*" smatch if
    effect @ " +" split atoi temp ! stat !
    who @ { "status/statmods/" stat @ }cat get atoi temp @ +
    dup 6 <= if
      who @ swap { "status/statmods/" stat @ }cat swap setto
    else
      pop who @ { "status/statmods/" stat @ }cat 6 setto
    then
    {
      "^[o^[c" item @ " ^[g"
      temp @ 1 > if "greatly " then
      "raised ^[c" who @ ID_name "^[g's ^[w" stat @ "^[g!"
    }cat bid @ notify_watchers
  then
 
 
repeat
consume? @
;
 
$libdef new_battle_id
: new_battle_id (this is used to get the battle ID)
 
 
loc @ { "/@battle/" me @ }cat propdir? not if
 
me @ intostr
exit
then
 
"^[r^[oYour personal battle ID is in use right now, contact staff for help." tellme
"full"
 
; PUBLIC new_battle_id
 
$libdef abortbattle
: abortbattle
var bid
var! aborter 
(this eventully will only be used by admins to abort battles that need aborting, but for now its good for testing)
(me @ "@huntingteam/following" getprop if "^[o^[rFollowers can't abort." tellme exit then)
me @ "@battle/battleid" getprop BID !
aborter @ "player" smatch if
{ "^[r^[oThe battle was aborted by ^[c" me @ name "^[r." }cat BID @ notify_watchers
then
aborter @ "error" smatch if
{ "^[r^[oThe battle was aborted by ^[can error^[r." }cat BID @ notify_watchers
then
BID @ removebattle
loc @ { "@battle/" bid @ }cat remove_prop

; PUBLIC abortbattle
 
: abortprecheck
var choice
"^[r^[oYou are about to abort this battle.  Are you sure?" tellme
read choice !
choice @ "y*" smatch not if exit then
"^[r^[oPlease state the reasion why you are aborting this battle so that the staff may fix the reasion for the needed abort."
var abortreasion
(not finished)
;
 
: set_init  (this is used to set initutitive.  )
var! bid
var type
var move
var POS
var pos_list
var tpos
 
loc @ { "@battle/" BID @ "/speed" }Cat remove_prop
loc @ { "@battle/" bid @ "/howmany" }cat getprop atoi temp !
temp @ 2 = if
        { "A1" "B1" "A2" "B2" }list
else
        temp @ 3 = if
                { "A1" "B1" "A2" "B2" "A3" "B3" }list
        else
        { "A1" "B1" }list
        then
then
 
pos_list !
 
pos_list @ foreach POS ! pop
loc @ { "@battle/" bid @ }Cat propdir? not if
exit
then
 
loc @ { "@battle/" bid @ "/position/" POS @ }cat getprop not if
continue
then
 
loc @ { "@battle/" bid @ "/declare/" POS @ }cat getprop " " split move ! type !
type @ "item" smatch if
loc @ { "@battle/" bid @ "/speed/" POS @ "/Priority" }cat 8 setprop
then
type @ "run" smatch if
loc @ { "@battle/" bid @ "/speed/" POS @ "/Priority" }cat 9 setprop
then
type @ "switch" smatch if
loc @ { "@battle/" bid @ "/speed/" POS @ "/Priority" }cat 6 setprop
then
type @ "recharge" smatch if
loc @ { "@battle/" bid @ "/speed/" POS @ "/Priority" }cat 6 setprop
then
type @ "attack" smatch if
 loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat getprop tpos !
 move @ "pursuit" smatch
 tpos @ and if
  loc @ { "@battle/" bid @ "/declare/" TPOS @ }cat getprop " " split pop "switch" smatch  if
  loc @ { "@battle/" bid @ "/speed/" POS @ "/Priority" }cat 7 setprop
  else
  loc @ { "@battle/" bid @ "/speed/" POS @ "/Priority" }cat POKEDEX { "moves/" move @ "/priority" }cat getprop atoi setprop
  then
 else
 
 loc @ { "@battle/" bid @ "/speed/" POS @ "/Priority" }cat POKEDEX { "moves/" move @ "/priority" }cat getprop atoi 
  
  (Prankster)
   loc @ { "@battle/" bid @ "/position/" POS @ }cat getprop temp !
  temp @ "ability" fget "Prankster" smatch 
  POKEDEX { "moves/" move @ "/power" }cat getprop atoi not and
  if
  1 + (add one to the priority)
  then
 setprop
 then
then
 
var user
loc @ { "@battle/" bid @ "/position/" POS @ }cat getprop user !
 
user @ if
 
user @ "Speed" Calculate temp !
        POKEDEX { "items/" user @ "holding" get "/halfspeed" }cat getprop if
        temp @ 2 / temp !
        then

loc @ { "@battle/" BID @ "/pledge field/" pos @ 1 1 midstr "/move" }cat getprop if
        loc @ { "@battle/" BID @ "/pledge field/" pos @ 1 1 midstr "/move" }cat getprop "grass pledge" smatch if
                temp @ 2 / temp !
        then
then
 
user @ "ability" fget "slow start" smatch if
        user @ "status/statmods/ability/slow start" get atoi 5 > not if
        temp @ 0.5 * floor temp !
        then
then
 
user @ "Ability" fget "quick feet" smatch
user @ check_status and if
temp @ 1.5 floor * temp !
( temp @ 999 > if 999 temp ! then )
then
 
user @ "Ability" fget "Unburden" smatch
user @ "holding" get "nothing" smatch and
user @ "Ability" fget "Chlorophyll" smatch
bid @ check_weather "sunny day" smatch and or
user @ "ability" fget "Swift Swim" smatch
bid @ check_weather "rain dance" smatch and or
if
temp @ 2 * temp !
( temp @ 999 > if 999 temp ! then )
 
then
loc @ { "@battle/" BID @ "/tailwind/" pos @ 1 1 midstr }cat getprop if
temp @ 2 * temp !
( temp @ 999 > if 999 temp ! then )
then
 
loc @ { "@battle/" bid @ "/speed/" POS @ "/Speed" }cat temp @ setprop
 
var trickroom
loc @ { "@battle/" bid @ "/trickroom" }cat getprop if
 (if trick room, then last goes first)
 1 trickroom !
then
 
(mark priorities are 'gofirst' 'normal' 'stall' and 'lag', instead of using words, use 4 3 2 1 respectively, larger the faster)
 
loc @ { "@battle/" bid @ "/speed/" pos @ "/mark" }cat
        3
        user @ "ability" fget "stall" smatch if
                pop 2
        then
 
        user @ "holding" get "lagging tail" smatch
        user @ "holding" get "full incense" smatch or if
                pop 1
        then
 
        user @ "holding" get "quick claw" smatch if
        frand 0.2 <= if
                pop 4
                then
        then
 
        user @ "status/statmods/movefirst" get if
                user @ "status/statmods/movefirst" 0 setto
                pop 4
        then
 
setprop
 
then
 
repeat
loc @ { "@battle/" BID @ "/tailwind/A" }cat getprop if
        loc @ { "@battle/" BID @ "/tailwind/A" }cat over over getprop 1 - setprop
then
 
loc @ { "@battle/" BID @ "/tailwind/B" }cat getprop if
        loc @ { "@battle/" BID @ "/tailwind/B" }cat over over getprop 1 - setprop
then
 
 
loc @ { "@battle/" bid @ "/speed/rank/" }cat remove_prop
 
var rank
0 rank !
var currank
var rankpos
var posval
var rankval
var shift
 
pos_list @ foreach pos ! pop
        rank @ 1 + rank !
        1 rank @ 1 for currank !
                0 shift !
                loc @ { "@battle/" bid @ "/speed/rank/" currank @ }cat getprop not if
                        loc @ { "@battle/" bid @ "/speed/rank/" currank @ }cat pos @ setprop
                        break
                else
                        loc @ { "@battle/" bid @ "/speed/rank/" currank @ }cat getprop rankpos !
                        loc @ { "@battle/" bid @ "/speed/" pos @ "/priority" }cat getprop posval !
                        loc @ { "@battle/" bid @ "/speed/" rankpos @ "/priority" }cat getprop rankval !
                        posval @ rankval @ < if
                        continue
                        then
 
                        posval @ rankval @ > if
                        (replace and shift the rest down)
                        1 shift !
                        then
 
                        shift @ not if
                                posval @ rankval @ = if
                                        loc @ { "@battle/" bid @ "/speed/" pos @ "/mark" }cat getprop posval !
                                        loc @ { "@battle/" bid @ "/speed/" rankpos @ "/mark" }cat getprop rankval !
                                        posval @ rankval @ > if
                                        1 shift !
                                        then
                                        posval @ rankval @ < if
                                        continue
                                        then
                                        posval @ rankval @ = if
                                                loc @ { "@battle/" bid @ "/speed/" pos @ "/speed" }cat getprop posval !
                                                loc @ { "@battle/" bid @ "/speed/" rankpos @ "/speed" }cat getprop rankval !
 
                                                posval @ rankval @ = if
                                                random 2 % shift !
                                                then
                                                shift @ not if
                                                        trickroom @ if
                                                        posval @ rankval @ < if
                                                        1 shift !
                                                        then
                                                        else
                                                        posval @ rankval @ > if
                                                        1 shift !
                                                        then
                                                then
                                        then
                                then
                        then
                then
 
                shift @ if
                        (shift everything down by one)
                        pos @ temp3 !
                        currank @ rank @ 1 + 1 for temp !
                                loc @ { "@battle/" bid @ "/speed/rank/" temp @ }cat getprop temp2 !
                                loc @ { "@battle/" bid @ "/speed/rank/" temp @ }cat temp3 @ setprop
                                temp2 @ temp3 !
                        repeat
                        break
                then
                then
        repeat
repeat
 
 
;
 
: battle_handler  (this is to notify the players when its time for them to do their declares, also known as choosing the item attack or switch or run command.)
var! bid
var pos
var conid
var posid
( this is to help decide declares)
loc @ { "@battle/" BID @ "/BattleReady" }Cat getprop if exit then
(this bit is for gen 5, not finished)
(loc @ { "@battle/" BID @ "/howmany" }cat getprop atoi temp !

{ "A" "B" }cat list foreach temp2 ! pop
0 conid !
1 temp @ 1 for temp3 !

{ temp2 @ temp3 @ }cat posid !

repeat
repeat
)
 
loc @ { "@battle/" BID @ "/Declare/A1" }cat getprop not if
loc @ { "@battle/" BID @ "/Position/A1" }cat getprop if
loc @ { "@battle/" BID @ "/Position/A1" }cat getprop pos !
loc @ { "@battle/" BID @ "/control/teamA/" pos @ }cat getprop conid !
 
conid @ stringify "AI" smatch not if
conid @ "@battle/control" getprop not if
conid @ "@battle/control" getprop stringify "A1" smatch not if
conid @ { "^[y^[oInput command for ^[c" pos @ id_name "^[y. +attack +item +switch +run" }cat "Battle" pretty notify
conid @ "@battle/control" "A1" setprop
then then then then then
 
loc @ { "@battle/" BID @ "/Declare/A2" }cat getprop not if
loc @ { "@battle/" BID @ "/Position/A2" }cat getprop if
loc @ { "@battle/" BID @ "/Position/A2" }cat getprop pos !
loc @ { "@battle/" BID @ "/control/teamA/" pos @ }cat getprop stringify conid @ stringify smatch not if
loc @ { "@battle/" BID @ "/control/teamA/" pos @ }cat getprop conid !
 
conid @ stringify "AI" smatch not if
conid @ "@battle/control" getprop not if
conid @ "@battle/control" getprop stringify "A2" smatch not if
conid @ { "^[y^[oInput command for ^[c" pos @ id_name "^[y. +attack +item +switch +run" }cat "Battle" pretty notify
conid @ "@battle/control" "A2" setprop
 
then then then then then then
 
0 conid !
 
loc @ { "@battle/" BID @ "/Declare/B1" }cat getprop not if
loc @ { "@battle/" BID @ "/Position/B1" }cat getprop if
loc @ { "@battle/" BID @ "/Position/B1" }cat getprop pos !
loc @ { "@battle/" BID @ "/control/teamB/" pos @ }cat getprop conid !
 
conid @ stringify "AI" smatch not if
conid @ "@battle/control" getprop not if
conid @ "@battle/control" getprop stringify "B1" smatch not if
conid @ { "^[y^[oInput command for ^[c" pos @ id_name "^[y. +attack +item +switch +run" }cat "Battle" pretty notify
conid @ "@battle/control" "B1" setprop
then then then then then
 
loc @ { "@battle/" BID @ "/Declare/B2" }cat getprop not if
loc @ { "@battle/" BID @ "/Position/B2" }cat getprop if
loc @ { "@battle/" BID @ "/Position/B2" }cat getprop pos !
loc @ { "@battle/" BID @ "/control/teamB/" pos @ }cat getprop stringify conid @ stringify smatch not if
loc @ { "@battle/" BID @ "/control/teamB/" pos @ }cat getprop conid !
 
conid @ stringify "AI" smatch not if
conid @ "@battle/control" getprop not if
conid @ "@battle/control" getprop stringify "B2" smatch not if
conid @ { "^[y^[oInput command for ^[c" pos @ id_name "^[y. +attack +item +switch +run" }cat "Battle" pretty notify
conid @ "@battle/control" "B2" setprop
then then then then then then
 
 
;
 
: combatdisplay2 (this is for the meat of the display so that it only calls the same thing once)
var! bid
var! pos
var! tempref
 
var status
var curpoke
var maxhp
var percent
var hpcolor
var temppos
var tempteam
 
pos @ 1 1 midstr var! team
team @ "a" smatch if
"^[u"
else
"^[r"
then
var! tc (for team color)
pos @ 2 1 midstr var! tnum
 
loc @ { "@battle/" bid @ "/position/" pos @ }cat getprop if
loc @ { "@battle/" bid @ "/position/" pos @ }cat getprop curpoke !

curpoke @ temp !
curpoke @ bid @ team @ illusion curpoke !

tempref @ { "^[o" tc @ tnum @ " ^[y"
curpoke @ { "/pokemon/" curpoke @ "species" fget "/name" }cat fget dup not if pop "??????????" then 1 15 midstr 15 " " padr
" "
 
(this segment is for displaying if the pokemon has been caught before)
curpoke @ "Original Trainer" get not if
      tempref @ { "/@achieve/poke-owned/" curpoke @ "species" get }cat getprop
        if "^[r*" else " " then
        
else
" "
then
 
" " tc @ "| "
 
curpoke @ "gender" fget "M*" smatch if
"^[o^[c" { curpoke @ "gender" fget 1 1 midstr }cat
then
 
curpoke @ "gender" fget "F*" smatch if
"^[o^[r" { curpoke @ "gender" fget 1 1 midstr }cat
then
 
curpoke @ "gender" fget "N*" smatch curpoke @ "gender" fget "O*" smatch or if
"^[o^[m" { curpoke @ "gender" fget 1 1 midstr }cat
then

" " tc @ "| ^[y"
curpoke @ id_name 1 14 midstr 14 " " padr
temp @ curpoke ! 
" " tc @ "| ^[yLv "
curpoke @ FindPokeLevel intostr 3 " " padr
" " tc @ "| ^[y"

loc @ { "@battle/" bid @ "/position/" pos @ }cat getprop curpoke !
"^[wNRM"
    curpoke @ "status/frozen"    get if pop "^[cFRZ"    then
    curpoke @ "status/paralyzed" get if pop "^[yPRZ"    then
    curpoke @ "status/asleep"    get if pop "^[bSLP"    then
    curpoke @ "status/poisoned"  get if pop "^[mPSN"    then
    curpoke @ "status/toxic"     get if pop "^[mTOX"    then
    curpoke @ "status/burned"    get if pop "^[rBRN"    then
 
" " tc @ "| ^[yHP: ^[r"
curpoke @ "MaxHP"   Calculate maxhp !
 
    curpoke @ "status/hp" get atoi 100 * maxhp @ / percent !
    loc @ { "@battle/" BID @ "/battling/" tempref @ }cat getprop stringify team @ smatch if    
    percent @ 51 >= if "^[o^[g" hpcolor ! then
    percent @ 50 <= percent @ 26 >= and if "^[o^[y" hpcolor ! then
    percent @ 25 <= if "^[o^[r" hpcolor ! then
hpcolor @
curpoke @ "status/hp" get dup not if pop "0" then 3 " " padl
"^[x^[o/" hpcolor @
maxhp @ intostr 3 " " padl
"    "
else
percent @ 10 < if curpoke @ "status/hp" get atoi 100.0 * maxhp @ / 1 round percent ! then
percent @ percentdisplay " "
then
percent @ intostr 3 " " padl
"% " tc @ tnum @ }cat notify then
 
;
 
: teamdisplay (the ball count and title)
var! bid
var! team
var! tempref
 
var ballcount
var who
var status
 
team @ "a" smatch if
"^[u"
else
"^[r"
then
var! tc (for team color)
loc @ { "@battle/" BID @ "/AItype" }cat getprop "wild" smatch 
team @ "b" smatch and 
if
 tempref @ { "^[o"tc @ "=====================================^[yWILD" tc @ "=^[yPokemon" tc @ "==============================" }cat notify
else
0 ballcount !
tempref @ { "^[o" tc @ "==^[r" {
loc @ { "@battle/" bid @ "/teams/" team @ "/" }cat array_get_propvals foreach who ! pop
who @ "status/hp" get atoi if "ok" status ! then
 
    who @ "status/frozen"    get if  "status" status ! then
    who @ "status/paralyzed" get if  "status" status ! then
    who @ "status/asleep"    get if  "status" status ! then
    who @ "status/poisoned"  get if  "status" status ! then
    who @ "status/toxic"     get if  "status" status ! then
    who @ "status/burned"    get if  "status" status ! then
 
who @ "status/hp" get atoi not if "fainted" status ! then
 
 
status @ "ok" smatch if
"^[rO"
ballcount @ 1 + ballcount !
then
 
status @ "status" smatch if
"^[mS"
ballcount @ 1 + ballcount !
then
 
status @ "fainted" smatch if
"^[x^[oX"
ballcount @ 1 + ballcount !
then
 
repeat
}cat "" tc @ "" 17 ballcount @ - "=" padr
"" tc @ "=====================^[yTeam" tc @ "=^[y" team @ tc @ "=================================" }cat notify
then
;

 
: combatdisplay  (this is the display)
var! bid
var who
 
var counter
var watcherarray
var pos
 
var status
 
me @ "@temp/JustMeWatching/" propdir? if
 
 me @ "@temp/JustmeWatching" array_get_propvals watcherarray !
 me @ "@temp/justmewatching/" remove_prop
 else
loc @ { "@battle/" BID @ "/watching/" }cat array_get_propvals watcherarray !
 
then
 
 
watcherarray @ foreach pop stod tempref !
 
  tempref @ awake? not if continue then
  tempref @ location loc @ = not if continue then
( tempref @ { "^[o^[yBattle " BID @ }cat notify )
 
tempref @ "A" BID @ teamdisplay
 
loc @ { "@battle/" BID @ "/aitype" }cat getprop "wild" smatch not if
tempref @ 
{ "^[o^[uA ^[y" loc @ { "@battle/" BID @ "/trainers/A" }cat getprop 1 75 midstr 75 " " padr " ^[uA" }cat
notify
then
{ "A1" "A2" "A3" }list foreach pos ! pop
 
tempref @ pos @ bid @ combatdisplay2 repeat
 
tempref @ { "^[o^[m-------------------------------------------------------------------------------" }cat notify
tempref @ { "^[o^[m| ^[o^[yWeather: "
(12345678901234567890)
{ bid @ check_weather cap 20 " " padr }cat
" ^[o^[m| ^[o^[yField: "
(12345678901234567890)
{ loc @ "@locationtype" getprop dup not if pop "Normal" then  cap 20 " " padr }cat
" ^[o^[m| ^[o^[yRound: "
(123456)
{ loc @ { "@battle/" bid @ "/turn" }cat getprop stringify 6 " " padr }cat
" ^[o^[m|" }cat notify
tempref @ { "^[o^[m-------------------------------------------------------------------------------" }cat notify

loc @ { "@battle/" BID @ "/aitype" }cat getprop "wild" smatch not if
tempref @ 
{ "^[o^[rB ^[y" loc @ { "@battle/" BID @ "/trainers/B" }cat getprop 1 75 midstr 75 " " padr " ^[rB" }cat
notify
then
 
{ "B1" "B2" "B3" }list foreach pos ! pop
 
tempref @ pos @ bid @ combatdisplay2 repeat
 
tempref @ "B" bid @ teamdisplay
 
(weather alert)
var effect
loc @ { "@battle/" BID @ "/roomweather" }cat getprop effect !
effect @ if
tempref @ {
 effect @ "Hail" smatch if
 "^[y^[oHail Continues to fall."
 else
 effect @ "Rain Dance" smatch if
 "^[y^[oIt is raining."
 else
 effect @ "Sandstorm" smatch if
 "^[y^[oThe sandstorm rages."
 else
 effect @ "Sunny Day" smatch if
 "^[y^[oThe sunlight is strong."
 else
 effect @ "fog" smatch if
 "^[y^[oIt is foggy."
 then
 then
 then
 then
 then
 }cat notify
then
(end weather alert)
 
(gravity alert)
loc @ { "@battle/" BID @ "/gravity" }cat getprop if
tempref @ { "^[o^[mThe gravity is harsh right now..." }cat notify
then
 
(trick room alert)
loc @ { "@battle/" BID @ "/trickroom" }cat getprop if
tempref @ "^[o^[cTrick Room^[y is in effect..."  notify
then          
 
repeat
 
;
 
 
: battle_ready (this is going to be where it checks the declares and makes sure the battle is ready)
 
var bid
var ready
var pos
var conid
var lpos
var pos_list
1 ready ! (this stays 1 if the battle is ready)
 
me @ "@battle/battleID" getprop bid !
 
loc @ { "@battle/" BID @ "/BattleReady" }Cat getprop not if  (this is to make sure declares haven't happened yet)
        loc @ { "@battle/" bid @ "/howmany" }cat getprop atoi 2 = if
        { "A1" "B1" "A2" "B2" }list pos_list !
        else
        { "A1" "B1" }list pos_list !
        then
 
        pos_list @ foreach lpos ! pop
                loc @ { "@battle/" BID @ "/Position/" lpos @ }cat getprop pos !
                pos @ if
                        loc @ { "@battle/" BID @ "/control/team" lpos @ 1 1 midstr "/" pos @ }cat getprop conid !
 
                        conid @ stringify "AI" smatch not if
                                loc @ { "@battle/" bid @ "/declare/" lpos @ }cat getprop not if (if not an AI, and no declare, its not ready)
                        0 ready !
                        then else
                        (if an AI, let it do its declare if there isn't one already)
                                loc @ { "@battle/" bid @ "/declare/" lpos @ }cat getprop not if
                                        loc @ { "@battle/" bid @ "/declare/" lpos @ }cat bid @ lpos @ loc @ { "@battle/" bid @ "/position/" lpos @ }cat getprop
                                        AI_handler temp ! temp @ setprop
                               loc @ { "@battle/" bid @ "/declare/" lpos @ "/target" }cat bid @ lpos @ temp @ AI_target setprop
                               
 
                then then then
        repeat
 
        ready @ not if
        ready @
                exit
        else
                loc @ { "@battle/" BID @ "/BattleReady" }cat "yes" setprop 
                (remove any learning props from the players)
                loc @ contents_array foreach temp ! pop
                 temp @ "@battle/battleID" getprop stringify BID @ smatch if
                 temp @ "@learning pending" remove_prop
                 then
                 
 repeat
        then
 
        (this section is for things that need to tick down at the start of the round)
        (weather)
        loc @ { "@battle/" bid @ "/roomweather" }cat getprop if
                loc @ { "@battle/" bid @ "/roomweather/length" }cat over over getprop 1 - setprop
                loc @ { "@battle/" bid @ "/roomweather/length" }cat getprop 0 <= if
                        loc @ { "@battle/" bid @ "/roomweather" }cat remove_prop
                        loc @ { "@weather/current" }cat getprop if
                                loc @ { "@battle/" BID @ "/roomweather" }cat loc @ { "@weather/current" }cat getprop setprop
                                loc @ { "@battle/" BID @ "/roomweather/length" }cat 999 setprop
                                                        loc @ { "@battle/" BID @ "/roomweather" }cat getprop effect !
                                                        effect @ if
                                                        {
                                                         effect @ "Hail" smatch if
                                                         "^[y^[oHail Continues to fall."
                                                         else
                                                         effect @ "Rain Dance" smatch if
                                                         "^[y^[oIt is raining"
                                                         else
                                                         effect @ "Sandstorm" smatch if
                                                         "^[y^[oThe sandstorm rages."
                                                         else
                                                         effect @ "Sunny Day" smatch if
                                                         "^[y^[oThe sunlight is strong"
                                                         then
                                                         then
                                                         then
                                                         then
                                                         }cat bid @ notify_watchers
                                                        then
 
                        then
                then
        then
        (gravity)
        loc @ { "@battle/" BID @ "/gravity" }cat getprop if
                loc @ { "@battle/" BID @ "/gravity" }cat over over getprop 1 - setprop
        then
 
 
(remove these values here so you can read them for debugging)
  loc @ { "@battle/" BID @ "/magic coat/" }cat remove_prop
  loc @ { "@battle/" BID @ "/DamageDeltTurn/" }cat remove_prop
  loc @ { "@battle/" BID @ "/lasthit/" }cat remove_prop
(end removal)
        bid @ set_init (this calles the set_init function)  
        (this is to set what pokemon started the battle, some moves need this information)
        pos_list @ foreach lpos ! pop
                loc @ { "@battle/" BID @ "/Begin Position/" lpos @ }cat loc @ { "@battle/" BID @ "/Position/" lpos @ }cat getprop setprop
        repeat
 
        (this is to store who battled who at the start of the battle, this is for exp distribution)
        var oteam
        var opos
        pos_list @ foreach lpos ! pop
                loc @ { "@battle/" BID @ "/Position/" lpos @ }cat getprop if
                        lpos @ "A*" smatch if
                                "B" oteam !
                        else
                                "A" oteam !
                        then
 
                        { "1" "2" }list foreach opos ! pop
                                loc @ { "@battle/" BID @ "/Position/" oteam @ opos @ }cat getprop if
                                        loc @ { "@battle/" BID @ "/Battled/Team" oteam @ "/" loc @ { "@battle/" BID @ "/Position/" oteam @ opos @ }cat getprop "/" loc @ { "@battle/" BID @ "/Position/" lpos @ }cat getprop }cat 1 setprop then
                        repeat
                then
        repeat
        (end section)
then
 
var move
var type
var aborted
 
var counter
var pos
 
(loc @ { "@battle/" bid @ "/speed/rank/" }cat array_get_propvals foreach pos ! pop)
1 loc @ { "@battle/" bid @ "/speed/rank/" }cat array_get_propvals array_count 1 for counter !
        loc @ { "@battle/" BID @ "/speed/rank/" counter @ }cat getprop pos !
        loc @ { "@battle/" bid @ "/lastrank" }cat getprop counter @ < if
                loc @ { "@battle/" bid @ "/lastrank" }cat counter @ setprop
        else
                continue
        then
 
        aborted @ if
                bid @ removebattle
                1
                exit
        then
        loc @ { "@battle/" BID @ }cat propdir? not if
                1
                exit
        then
        loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop not if continue then
 
        loc @ { "@battle/" BID @ "/grudge/" pos @ }Cat remove_prop
 
                loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "ability" fget "Truant" smatch if
                 loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "status/statmods/Truant" get if
                        loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "status/statmods/Truant" over over get atoi 1 - setto
                 then
                then
        loc @ { "@battle/" BID @ "/destinybond/" loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop }cat remove_prop
        loc @ { "@battle/" BID @ "/declare/" pos @ }cat getprop not if continue then
        loc @ { "@battle/" BID @ "/declare/" pos @ }cat getprop " " split move ! type !
        loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "status/statmods/turns-out" over over get atoi 1 + setto
 
        (use begin here, so you can use break to end the loop)
        begin
                loc @ { "@battle/" BID @ "/temp/moldbreakermessage" }cat remove_prop
                var item
                var target
                var controller
                var iuser
                var tpos
                (item handler)
                type @ "item" smatch if
                        move @ item !
                        loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop controller !
                        controller @ "status/statmods/movecontinued/times" 0 setto
                        controller @ "status/statmods/movecontinued/movename" 0 setto
                        loc @ { "@battle/" BID @ "/declare/" pos @ "/itemuser" }cat getprop iuser !
                        iuser @ { "inventory/" item @ }cat get atoi 0 <= if
                        { "^[o^[c" iuser @ id_name "^[y wanted to use ^[c" item @ cap AorAn "^[y but they gave it away..." }cat bid @ notify_watchers
                        break
                        then
                        loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat getprop target !
                        POKEDEX { "/items/" item @ "/capture" }cat getprop if  (this section is to figure out if the item is a pokeball)
                         target @ tpos !
                         loc @ { "@battle/" BID @ "/position/" tpos @ }cat getprop not if
                          tpos @ "?1" smatch if
                           { tpos @ 1 1 midstr "2" }cat tpos !
                          else
                           tpos @ "?2" smatch if
                            { tpos @ 1 1 midstr "1" }cat tpos !
                           then
                          then
                         then
                        loc @ { "@battle/" BID @ "/position/" tpos @ }cat getprop target !
                        target @ not if break then
 
                        else
 
                         target @ tpos !
                        pos @ "A*" smatch if
                        loc @ { "@battle/" BID @ "/teams/A/" tpos @ }cat getprop target !
                        else
                        loc @ { "@battle/" BID @ "/teams/B/" tpos @ }cat getprop target !
                        then
                        then
                        pos @ "A*" smatch if
                        loc @ { "@battle/" BID @ "/control/teamA/" controller @ }cat getprop controller !
                        else
                        loc @ { "@battle/" BID @ "/control/teamB/" controller @ }cat getprop controller !
                        then
                        controller @ stringify "AI" smatch if
                                loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "Current Trainer" fget controller !
                        then
                        POKEDEX { "/items/" item @ "/capture" }cat getprop if
 
                        { "^[o^[c"controller @ id_name "^[y threw "
 
                        "^[c" item @ cap AorAn " ^[yat ^[c" tpos @ "." target @ id_name "^[c." }cat bid @ notify_watchers
 
                        controller @ { "inventory/" item @ }cat over over get atoi 1 - setto
                        controller @ { "inventory/" item @ }cat get atoi -1 < if
                        controller @ { "inventory/" item @ }cat -1 setto then
                        var hp
                        var maxhpbefore
                        var maxhpafter
                        target @ "status/hp" get atoi hp !
                        item @ controller @ "@RP/id" getprop tpos @ BID @ pokeballcatch if
                        target @ "MaxHP" Calculate maxhpbefore !
                        POKESTORE { "@pokemon/" target @ "/@temp/status/fainted" }cat 1 setprop 
                        BID @ pos @ endbattle
                        POKESTORE { "@pokemon/" target @ "/@temp" }cat remove_prop
                        POKESTORE { "@pokemon/" target @ "/@long" }cat remove_prop
                        target @ "MaxHP" Calculate maxhpafter !
                        target @ "status/hp" hp @ maxhpafter @ * maxhpbefore @ / setto
                        1 sleep
                        
 
                        then
                        
                        else
 
                        { "^[o^[c" controller @ id_name "^[y used ^[c" item @ cap " ^[yon ^[c" tpos @ "." target @ id_name "^[c." }cat bid @ notify_watchers
                        BID @ pos @ target @ item @ ItemHandler if
                        controller @ { "inventory/" item @ }cat over over get atoi 1 - setto
                        controller @ { "inventory/" item @ }cat get atoi -1 < if
                        controller @ { "inventory/" item @ }cat -1 setto then
                        1 sleep
                        then
                        then
                        BID @ pos @ endbattle
                        break
                then
        (end items)
        (switch handler)
        type @ "switch" smatch if
          Pos @ BID @ move @ switch_handler
            1 sleep
          break
             then
         (end switch)
 
          (run goes here)
         type @ "run" smatch if
                        0 target !
                        var team
                        var oteam
 
 
                        loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop target !
                        target @ not if break then
 
                        pos @ "A*" smatch if
                        "A" team !
                        "B" oteam !
                        else
                        "B" team !
                        "A" oteam !
                        then
 
                        (check for run preventers)
 
                        (end preventers)
                        loc @ { "@battle/" BID @ "/control/team" team @ "/" target @ }cat getprop controller !
                        target @ "ability" fget "run away" smatch if
                                1 aborted !
                                { "^[o^[c" team @ "." controller @ name "^[y ran from the battle! Battle Over!!!" }cat bid @ notify_watchers
                                bid @ removebattle
                                break
                        then
 
 
                        loc @ { "@battle/" BID @ "/RunTries/" team @ }cat over over getprop 1 + setprop
 
                        loc @ { "@battle/" BID @ "/position/" oteam @ "1" }cat getprop
                        loc @ { "@battle/" BID @ "/position/" oteam @ "2" }cat getprop and if
                                { "^[o^[c" controller @ name "^[y tried to run but failed, both opponents are still on field." }cat bid @ notify_watchers
                        else
                                (the run formula goes here)
 
                                var a
                                var b
                                var c
                                var f
                                var oppspeed
                                var yourspeed
 
                                loc @ { "@battle/" BID @ "/position/" oteam @ "1" }cat getprop if
                                        loc @ { "@battle/" BID @ "/position/" oteam @ "1" }cat getprop temp !
                                        temp @ "Speed" calculate oppspeed !
                                        POKEDEX { "items/" temp @ "holding" get "/halfspeed" }cat getprop if
                                        oppspeed @ 2 / oppspeed !
                                        then
                                        temp @ "ability" fget "Unburden" smatch
                                        temp @ "holding" get "nothing" smatch and
                                        temp @ "Ability" fget "Chlorophyll" smatch
                                        bid @ check_weather "sunny day" smatch and or
                                        temp @ "Ability" fget "Swift Swim" smatch
                                        bid @ check_weather "rain dance" smatch and or
                                        if
                                        oppspeed @ 2 * oppspeed !
                                        oppspeed @ 999 > if 999 oppspeed ! then
 
                                        then
                                        loc @ { "@battle/" BID @ "/tailwind/" oteam @ }cat getprop if
                                        oppspeed @ 2 * oppspeed !
                                        oppspeed @ 999 > if 999 oppspeed ! then
                                        then
 
                                else
                                        loc @ { "@battle/" BID @ "/position/" oteam @ "2" }cat getprop temp !
                                        temp @ "speed" calculate oppspeed !
                                        POKEDEX { "items/" temp @ "holding" get "/halfspeed" }cat getprop if
                                        oppspeed @ 2 / oppspeed !
                                        then
                                        temp @ "ability" fget "Unburden" smatch
                                        temp @ "holding" get "nothing" smatch and
                                        temp @ "Ability" fget "Chlorophyll" smatch
                                        bid @ check_weather "sunny day" smatch and or
                                        temp @ "ability" fget "Swift Swim" smatch
                                        bid @ check_weather "rain dance" smatch and or
                                        if
                                        oppspeed @ 2 * oppspeed !
                                        oppspeed @ 999 > if 999 oppspeed ! then
 
                                        then
                                        loc @ { "@battle/" BID @ "/tailwind/" oteam @ }cat getprop if
                                        oppspeed @ 2 * oppspeed !
                                        oppspeed @ 999 > if 999 oppspeed ! then
                                        then
                                then
 
                                temp @ "ability" fget "slow start" smatch if
                                        temp @ "status/statmods/ability/slow start" get atoi 5 > not if
                                        oppspeed @ 0.5 * floor oppspeed !
                                        then
                                then
 
                                loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "speed" calculate yourspeed !
                                        POKEDEX { "items/" loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "holding" get "/halfspeed" }cat getprop if
                                        yourspeed @ 2 / yourspeed !
                                        then
                                loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "ability" fget "slow start" smatch if
                                        loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "status/statmods/ability/slow start" get atoi 5 > not if
                                        yourspeed @ 0.5 * floor yourspeed !
                                        then
                                then
 
                                loc @ { "@battle/" bid @ "/position/" POS @ }cat getprop "ability" fget "Unburden" smatch
                                loc @ { "@battle/" bid @ "/position/" POS @ }cat getprop "holding" get "nothing" smatch and
                                loc @ { "@battle/" bid @ "/position/" POS @ }cat getprop "Ability" fget "Chlorophyll" smatch
                                bid @ check_weather "sunny day" smatch and or
                                loc @ { "@battle/" BID @ "/position/" POS @ }cat getprop "ability" fget "Swift Swim" smatch
                                bid @ check_weather "rain dance" smatch and or
                                if
                                yourspeed @ 2 * yourspeed !
                                yourspeed @ 999 > if 999 yourspeed ! then
 
                                loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "ability" fget "quick feet" smatch
                                loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop check_status and if
                                yourspeed @ 1.5 * floor yourspeed !
                                yourspeed @ 999 > if 999 yourspeed ! then
                                then
 
 
 
                                then
                                loc @ { "@battle/" BID @ "/tailwind/" pos @ 1 1 midstr }cat getprop if
                                yourspeed @ 2 * yourspeed !
                                yourspeed @ 999 > if 999 yourspeed ! then
                                then
 
 
                                oppspeed @ 4 / 255 % B !
 
                                yourspeed @ A !
 
                                loc @ { "@battle/" bid @ "/RunTries/" team @ }cat getprop C !
 
                                A @ 32 * B @ / 30 + C @ * F !
 
                                random 255 % 1 + F @ <= if
                                        1 aborted !
                                        { "^[o^[c" team @ "." controller @ name "^[y ran from the battle! Battle Over!!!" }cat bid @ notify_watchers
                                        bid @ removebattle
 
                                else
                                        { "^[o^[c" team @ "." controller @ name "^[y tried to run but failed!" }cat bid @ notify_watchers
 
                                then
                                1 sleep
                                break
 
                        then
                        break (to exit the repeat loop)
                then
         (run ends here)
 
        (now we add in the sections of code that represent the combat portion)
 
             loc @ { "@battle/" BID @ "/flinched/" pos @ }cat getprop if  (this is used for if they are flinched)
                loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "status/statmods/movecontinued/times" 0 setto
          loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "status/statmods/movecontinued/movename" 0 setto
          loc @ { "@battle/" BID @ "/charge/" pos @ }cat remove_prop
          loc @ { "@battle/" BID @ "/repeats/" pos @ }cat remove_prop
          { "^[c^[o" loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop id_name "^[y couldn't attack due to flinch!" }cat bid @ notify_watchers
          loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "ability" fget "steadfast" smatch if
                loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "status/statmods/speed" over over get atoi 1 + setto
                loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "status/statmods/speed" get atoi 6 > if
                        loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "status/statmods/speed" 6 setto
                        else
                        { "^[c^[o" loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop id_name "^[y gained speed due to their ability ^[cSteadfast^[y!" }cat bid @ notify_watchers
                then
          then
 
        break
        then
        (everything else should be affected by moves that stop you from doing stuff)
 
         loc @ { "@battle/" BID @ "/position/" POS @ }cat getprop target !
 
             type @ "recharge" smatch if
             { "^[o^[c" pos @ "." target @ id_name "^[y is recharging." }Cat bid @ notify_watchers
             break
             then
         target @ "ability" fget "Truant" smatch if
         target @ "status/statmods/Truant" get if
         { "^[o^[c" pos @ "." target @ id_name "^[y is resting this turn." }cat bid @ notify_watchers
         break
         then
         target @ "status/statmods/Truant" 2 setto
         then
        var randchance
        frand randchance !
         target @ "status/frozen" get if
         POKEDEX { "moves/" move @ "/icemelt" }cat getprop if
                  target @ "status/frozen" 0 setto
                  { "^[o^[c" pos @ "." target @ id_name "^[y melted its ice with its attack!" }cat bid @ notify_watchers
         else
                  randchance @ 0.1 <= if
                        {  "^[o^[c" pos @ "." target @ id_name "^[y managed to unfreeze itself!" }cat bid @ notify_watchers
 
                   target @ "status/frozen" 0 setto
                  else
 
                   { "^[o^[c" pos @ "." target @ id_name "^[y is frozen solid!" }cat bid @ notify_watchers
 
                  break
                  then
                 then
         then
         target @ "status/paralyzed" get if
         randchance @ 0.25 <= if
           { "^[o^[c" pos @ "." target @ id_name "^[y is fully paralyzed!" }cat bid @ notify_watchers
           (paralized also removes repeat moves)
           loc @ { "@battle/" BID @ "/repeats/" pos @ }cat remove_prop
          break
         then
         then
 
         target @ "status/asleep" get if
          target @ "status/asleep" over over get atoi 1 - setto
          target @ "status/asleep" get if
        {  "^[o^[c" pos @ "." target @ id_name "^[y is sound asleep!" }cat bid @ notify_watchers
           move @ "snore" smatch move @ "sleep talk" smatch or not if
          break then
 
          else
        {  "^[o^[c" pos @ "." target @ id_name "^[y woke up!" }cat bid @ notify_watchers
          then
         then
 
         (put attracted here)
          target @ "status/statmods/attracted" get if
           var attracted
           target @ "status/statmods/attracted" get attracted !
           pos @ "A*" smatch if
           "B" oteam !
           else
           "A" oteam !
           then
           
           loc @ { "@battle/" BID @ "/position/" oteam @ "1" }cat getprop dup not if pop "0" then  attracted @ smatch
           loc @ { "@battle/" BID @ "/position/" oteam @ "2" }cat getprop dup not if pop "0" then  attracted @ smatch or if
           { "^[o^[c" pos @ "." target @ id_name "^[y is attracted to " attracted @ id_name "." }cat BID @ notify_watchers
            frand 0.5 <= if
            { "^[o^[c" pos @ "." target @ id_name "^[y is too distracted by ^[mattraction^[y to attack!" }cat BID @ notify_watchers
                  loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "status/statmods/movecontinued/times" 0 setto
              loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "status/statmods/movecontinued/movename" 0 setto
          loc @ { "@battle/" BID @ "/charge/" pos @ }cat remove_prop
            break
            then
           else
           target @ "status/statmods/attracted" 0 setto
           then
 
        then
 
 
          target @ "status/statmods/confused" get if
          { "^[o^[c" pos @ "." target @ id_name "^[y is ^[mconfused^[y..." }cat bid @ notify_watchers
            1 sleep
           target @ "status/statmods/confused" over over get atoi 1 - setto
           target @ "status/statmods/confused" get if
           frand 0.5 <= if
            target @ bid @ pos @ confusion_damage
            (confusion also removes repeat moves)
            loc @ { "@battle/" BID @ "/repeats/" pos @ }cat remove_prop
            break
           then
           else
            { "^[o^[c" target @ id_name "^[y snapped out of its confusion!" }cat bid @ notify_watchers
           then
          then
 
          (skip handler)
                     type @ "skip" smatch if
 
                     loc @ { "@battle/" BID @ "/position/" POS @ }cat getprop target !
 
                          { "^[o^[c" pos @ "." target @ id_name "^[y decided to do nothing." }cat BID @ notify_watchers
                         target @ "status/statmods/MoveContinued/MoveName" 0 setto
                 1 sleep
                 break
                     then
 
        target @ "status/statmods/encore/move" get if
        target @ "status/statmods/encore/move" get move !
        then
        var repeats
        loc @ { "@battle/" BID @ "/repeats/" pos @ "/move" }cat getprop if
        loc @ { "@battle/" BID @ "/repeats/" pos @ "/move" }cat getprop move !
        1 repeats !
        else
        0 repeats !
        then
 
        var origionalmove
        move @ origionalmove !
          target @ "status/statmods/taunted" get if
        POKEDEX { "moves/" move @ "/power" }cat getprop atoi not if
                { "^[o^[c" target @ id_name "^[y tried to use ^[c" move @ cap "^[y but it can't because of ^[cTaunt^[y." }cat bid @ notify_watchers
        break
        then then
 
                        target @ "status/statmods/torment" get
                        repeats @ not and
                        if
                        target @ "status/statmods/MoveContinued/MoveName" get stringify move @ smatch
                        loc @ { "@battle/" BID @ "/repeats/" pos @ }cat propdir? not and
                        loc @ { "@battle/" BID @ "/charge/" pos @ "/charging" }cat propdir? not and
                        if
 
                        { "^[o^[c" target @ id_name "^[y tried to use ^[c" move @ cap "^[y but it can't because of ^[cTorment^[y." }cat bid @ notify_watchers
                        break
                        then
                then
 
         target @ "status/statmods/MoveContinued/Lastmove" target @ "status/statmods/MoveContinued/MoveName" get dup not if pop "none" then setto
         target @ "status/statmods/MoveContinued/MoveName" get dup not if pop "none" then move @ smatch not if
         target @ "status/statmods/MoveContinued/times" 0 setto
         then
         target @ "status/statmods/MoveContinued/times" target @ "status/statmods/movecontinued/times" get atoi 1 + setto
         target @ "status/statmods/MoveContinued/MoveName" move @ setto
 
        move @ "mimic" smatch if
                target @ "status/statmods/mimic/move" get if
                target @ "status/statmods/mimic/move" get move !
                then
        then
 
        move @ "Nature Power" smatch if
                loc @ "@locationtype" getprop temp !
                temp @ not if
                "other" temp !
                then
                begin
 
                                temp @ "Snow" smatch if
                                "Blizzard" move !
                                break
                                then
 
                                temp @ "Water" smatch if
                                "Hydro Pump" move !
                                break
                                then
 
                                temp @ "Grass" smatch if
                                "Seed Bomb" move !
                                break
                                then
 
                                temp @ "Rock" smatch if
                                "Rock Slide" move !
                                break
                                then
 
                                temp @ "Sand" smatch if
                                "Earthquake" move !
                                break
                                then
 
                                temp @ "Building" smatch if
                                "Tri Attack" move !
                                break
                                then
 
                                temp @ "Path" smatch if
                                "Earthquake" move !
                                break
                                then
 
                                "Earthquake" move !
                break repeat
 
                { "^[o^[c" pos @ "." target @ id_name "^[y uses ^[cNature Power^[y!" }cat bid @ notify_watchers
        then
 
        move @ "Me First" smatch if
                loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat getprop temp !
                loc @ { "@battle/" BID @ "/declare/" temp @ }cat getprop if
                loc @ { "@battle/" BID @ "/declare/" temp @ }cat getprop " " split temp2 ! temp3 !
                else
                "none" temp2 ! "none" temp3 !
                then
                temp3 @ "attack" smatch not
                POKEDEX { "moves/" temp2 @ "/power" }cat getprop atoi not or
                loc @ { "@Battle/" BID @ "/declare/finished/" temp @ }cat getprop or
                if
                { "^[o^[c" pos @ "." target @ id_name "^[y uses ^[c" move @ cap "^[y on ^[c" temp @ "." loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop id_name "^[y, but it failed!" }cat bid @ notify_watchers
                break
                then
                { "^[o^[c" pos @ "." target @ id_name "^[y uses ^[c" move @ cap "^[y on ^[c" temp @ "." loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop id_name "^[y!" }cat bid @ notify_watchers
                temp2 @ move !
                loc @ { "@battle/" BID @ "/temp/mefirst/" pos @ }cat "yes" setprop
        then
 
        move @ "Mirror move" smatch if
        loc @ { "@battle/" BID @ "/position/" loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat getprop }cat getprop "status/statmods/MoveContinued/MoveName" get move !
                move @ not if
                      target @ { "/movesknown/" origionalmove @ "/pp" }cat over over fget atoi 1 - fsetto
                      { "^[o^[c" pos @ "." target @ id_name "^[y uses ^[c" origionalmove @ cap "^[y." }Cat bid @ notify_watchers
 
 
                else
                      { "^[o^[c" pos @ "." target @ id_name "^[y uses ^[c" origionalmove @ cap "^[y." }Cat bid @ notify_watchers
                then
        then
 
 
        move @ "teleport" smatch if
                target @ { "/movesknown/" origionalmove @ "/pp" }cat over over fget atoi 1 - fsetto
                        loc @ { "@battle/" BID @ "/AItype" }cat getprop stringify "wild" smatch if
                        1 aborted !
                        { "^[o^[c" pos @ "." target @ id_name "^[y uses ^[c" move @ cap "^[y." }Cat bid @ notify_watchers
                        { "^[o^[c" pos @ "." target @ id_name "^[y teleported from the battle. Battle Over." }cat bid @ notify_watchers
                        bid @ removebattle
 
                        break
                        else
                        { "^[o^[c" pos @ "." target @ id_name "^[y uses ^[c" move @ cap "^[y." }Cat bid @ notify_watchers
                        { "^[o^[cBut it failed..." }cat bid @ notify_watchers
                        break
                        then
        then
 
        move @ "copycat" smatch if
                { "^[o^[c" pos @ "." target @ id_name "^[y uses ^[cCopycat^[y!" }cat bid @ notify_watchers
                loc @ { "@battle/" BID @ "/lastmove" }cat getprop not
                loc @ { "@battle/" BID @ "/lastmove" }cat getprop stringify "copycat" smatch or if
                        { "^[o^[yBut it failed..." }cat bid @ notify_watchers
                        break
                        then
                loc @ { "@battle/" BID @ "/lastmove" }cat getprop move !
        then
        (assist)
        move @ "Assist" smatch if
        { "^[o^[c" pos @ "." target @ id_name "^[y uses ^[cAssist^[y!" }cat bid @ notify_watchers
              {
              loc @ { "@battle/" BID @ "/teams/" pos @ 1 1 midstr }cat array_get_propvals foreach
                swap pop dup target @ smatch if pop then
              repeat
              }list var! assist
            (This creates a list array of teammates that are not the attacker)
              assist @ array_count not if
                (Do the thing where it makes you lose your turn for the move not working)
              then
              assist @ random assist @ array_count % array_getitem assist !
              (assist now stores the ID of the teammate you're drawing from)
              { assist @ "movesknown" fgetvals foreach pop repeat }list assist !
              (this list is the moves that assist can't call)
              { 
              "Assist" 
              "Chatter"
              "Circle Throw"
              "Copycat"
              "Counter"
              "Covet"
              "Destiny Bond"
              "Detect"
              "Dragon Tail"
              "Endure"
              "Feint"
              "Focus Punch"
              "Follow Me"
              "Helping Hand"
              "Nature Power"
              "Me First"
              "Metronome"
              "Mimic"
              "Mirror Coat"
              "Mirror Move"
              "Protect"
              "Sketch"
              "Sleep Talk"
              "Snatch"
              "Struggle"
              "Switcheroo"
              "Thief"
              "Transform"
              "Trick"

              
              }list assist @ array_diff assist !
            (assist now stores a list array of legal moves known by the selected pokemon)
              assist @ array_count not if
                (Do the thing where it makes you lose your turn for the move not working)
                { "^[o^[yBut it fails..." }cat bid @ notify_watchers
                target @ { "/movesknown/" origionalmove @ "/pp" }cat over over fget atoi 1 - fsetto
              break
              then
              assist @ random assist @ array_count % array_getitem move !
            then
        (end assist)
 
        (metronome goes here so if it pulls the sleep moves, they will fail if you wern't sleeping)
        move @ "metronome" smatch if
        {
            "Counter"
            "Covet"
            "Destiny Bond"
            "Detect"
            "Endure"
            "Focus Punch"
            "Follow Me"
            "Helping Hand"
            "Metronome"
            "Mimic"
            "Mirror Coat"
            "Protect"
            "Sketch"
            "Sleep Talk"
            "Snatch"
            "Struggle"
            "Thief"
            "Trick"
            "bynumber"
            }list var! dont_use
            { POKEDEX "/moves/" array_get_propdirs foreach swap pop repeat }list var! full_list
            {  target @ "movesknown" fgetvals foreach pop repeat }list var! knownmoves
            dont_use @ full_list @ array_diff knownmoves @ swap array_diff
            dup random swap array_count % array_getitem move !
            { "^[o^[c" pos @ "." target @ id_name "^[y uses ^[cMetronome^[y!" }cat bid @ notify_watchers
        then
        move @ not if
        "^[o^[yBut it failed..." BID @ notify_watchers
        break
        then
        (end metronome)
        (must be asleep moves go here)
        move @ "snore" smatch move @ "sleep talk" smatch or if
         target @ "status/asleep" get not if
         { "^[o^[c" pos @ "." target @ id_name "^[y tried to use ^[c" move @ cap "^[y but is awake!" }Cat bid @ notify_watchers
         target @ { "/movesknown/" origionalmove @ "/pp" }cat over over fget atoi 1 - fsetto
         break then
 
         move @ "sleep talk" smatch if
         {
        "Assist"
        "Bide"
        "Bounce"
        "Chatter"
        "Copycat"
        "Dig"
        "Dive"
        "Fly"
        "Focus Punch"
        "Me First"
        "Metronome"
        "Mirror Move"
        "Shadow Force"
        "Skull Bash"
        "Sky Attack"
        "Sleep Talk"
        "SolarBeam"
        "Razor Wind"
        "Uproar"
            }list var! dont_use
 
            { target @ "movesknown" fgetvals foreach pop temp !
            target @ { "movesknown/" temp @ "/pp" }cat fget if
                temp @
            then
            repeat }list var! knownmoves
 
            knownmoves @ not if
            { "^[o^[c" pos @ "." target @ id_name "^[y uses ^[cSleep Talk^[y but it failed!" }Cat bid @ notify_watchers
            target @ { "/movesknown/" origionalmove @ "/pp" }cat over over fget atoi 1 - fsetto
            break
            else
 
            dont_use @ knownmoves @ array_diff dup random swap array_count % array_getitem move !
 
 
             { "^[o^[c" pos @ "." target @ id_name "^[y uses ^[cSleep Talk^[y!" }Cat bid @ notify_watchers
 
             move @ "rest" smatch if
         { "^[o^[c" pos @ "." target @ id_name "^[y tried to use ^[c" move @ cap "^[y but is already asleep!" }Cat bid @ notify_watchers
         target @ { "/movesknown/" origionalmove @ "/pp" }cat over over fget atoi 1 - fsetto
         break then
         then
 then then
 
        (end sleep moves)
 
 
        (effects part 1 ended)
 
 
             type @ "attack" smatch if
                (attack handler)
                0 target !
                var team
                var oteam
                var attacker
                var tpos
 
 
                loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop attacker !
 
                loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat getprop target !
                pos @ "A*" smatch if
                 "A" team !
                 "B" oteam !
                 then
 
                 pos @ "B*" smatch if
                 "B" team !
                 "A" oteam !
                then
 
                (check if the move got disabled or imprisoned)
                attacker @ { "status/statmods/imprisoned/move/" move @ }cat get if
                { "^[o^[c" attacker @ id_name "^[y tried to use ^[c" move @ cap "^[y but it was imprisoned." }cat bid @ notify_watchers
                break
                then
                attacker @ "status/statmods/disabled/move" get move @ smatch if
                { "^[o^[c" attacker @ id_name "^[y tried to use ^[c" move @ cap "^[y but it was disabled." }cat bid @ notify_watchers
                break
                then
 
                attacker @ "status/statmods/block/move" get stringify move @ smatch if
                { "^[o^[c" attacker @ id_name "^[y tried to use ^[c" move @ cap "^[y but it was disabled." }cat bid @ notify_watchers
                break
                then
                attacker @  "status/statmods/healblock" get if
                POKEDEX { "moves/" move @ "effects" }cat getprop stringify "*cure*"  smatch if
                { "^[o^[c" attacker @ id_name "^[y tried to use ^[c" move @ cap "^[y but it was heal blocked." }cat bid @ notify_watchers
                break
                then
                then
 
                loc @ { "@battle/" BID @ "/charge/" pos @ "/charging/" }cat propdir? not
                loc @ { "@battle/" BID @ "/repeats/" pos @ }cat propdir? not and
                        if
                        attacker @ { "/movesknown/" origionalmove @ "/pp" }cat over over fget atoi 1 - fsetto
                then
 
                (first thing's first, you need to check if a move is a charging move or not.  Let it execute if the charging is 0)
                (moves like fly also are considered charging moves)
                (current list of charging moves, fly, dig, bounce, sky attack, bide and solarbeam)
                (on the attacks that charge, have two extra props inside, /charging:int to tell how long it charges for, ex fly is a 1, and /chargingtext for what is said when charging)
                
                0 wascharging !
                loc @ { "@battle/" bid @ "/charge/" pos @ "/charging/turns" }Cat getprop if
                1 wascharging !
                loc @ { "@battle/" bid @ "/charge/" pos @ "/charging/turns" }Cat over over getprop 1 - setprop
                loc @ { "@battle/" bid @ "/charge/" pos @ "/charging/turns" }Cat getprop not if
                loc @ { "@battle/" BID @ "/charge/" pos @ "/charging/turns" }cat remove_prop then
                then
 
                wascharging @ not if
                loc @ { "@battle/" bid @ "/charge/" pos @ "/charging/turns" }cat POKEDEX { "moves/" move @ "/charging" }cat getprop atoi
                POKEDEX { "moves/" move @ "/charging/weatherchange/" bid @ check_weather }cat getprop atoi +
                setprop
                loc @ { "@battle/" BID @ "/Declare/" pos @ }cat { "Attack "  move @ }cat setprop
                then
 
                loc @ { "@battle/" bid @ "/charge/" pos @ "/charging/turns" }Cat getprop if
                        loc @ { "@battle/" BID @ "/charge/" pos @ "/charging/turns" "/move" }cat move @ setprop
                        { "^[o^[c" pos @  "." attacker @ id_name  "^[y " POKEDEX { "moves/" move @ "/chargingtext" }cat getprop }cat bid @ notify_watchers
                        POKEDEX { "moves/" move @ "/semi-inv" }cat getprop if
                                attacker @ { "status/statmods/semi-inv" }cat move @ setto
                        then
                        move @ "bide" smatch if
                                loc @ { "@battle/" BID @ "/bide/" pos @ }cat "yes" setprop
                        then
 
                break
                else
                attacker @ { "status/statmods/semi-inv" }cat 0 setto
                then
 
                (endcharging)
 
                move @ "Explosion" smatch
                move @ "Selfdestruct" smatch or if
                        "Damp" bid @ onfield_ability
                        attacker @ bid @ moldbreaker
                        if
                        { "^[o^[c" attacker @ id_name "^[y tried to use ^[c" move @ cap "^[y but it failed due to ^[cDamp ^[yability on field." }cat bid @ notify_watchers
                        break
                        then
                then
 
                var t-type
                POKEDEX { "moves/" move @ "/target" }cat getprop t-type !
 
                t-type @ "*enemy" smatch
                t-type @ "team-member" smatch or
                if
                loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat getprop tpos !
                tpos @ not if { oteam @ 1 }cat tpos ! then
         loc @ { "@battle/" BID @ "/position/" tpos @ }cat getprop not if  (this retargets if you targeted an enemy that isn't there)
        ({ "Tpos: " tpos @  " Move: " move @  " t-type: " t-type @ }cat "Debug" pretty bid @ notify_watchers )
         (this is where a bug comes in)
         tpos @ var! oldpos
         { oteam @ tpos @ "*1" smatch if "2" else "1" then }cat tpos ! then
(          loc @ { "@battle/" BID @ "/charge/" pos @ "/charging/" oldpos @ }cat getprop if
                  loc @ { "@battle/" BID @ "/charge/" pos @ "/charging/" tpos @ }cat
                    loc @ { "@battle/" BID @ "/charge/" pos @ "/charging/" oldpos @ }cat getprop
                    setprop
                  loc @ { "@battle/" BID @ "/charge/" pos @ "/charging/" tpos @ "/move" }cat
                    loc @ { "@battle/" BID @ "/charge/" pos @ "/charging/" oldpos @ "/move" }cat getprop
                    setprop
 
                  loc @ { "@battle/" BID @ "/charge/" pos @ "/charging/" oldpos @ }cat remove_prop
          then )
          (around here is where abilities that would change the target will come into play)
                  (check for rod type abilities)
          loc @ { "@battle/" BID @ "/position/" tpos @ }cat getprop target !
          target @ not if break then
 
          var otarget
          var otpos
          loc @ { "@battle/" BID @ "/followme/" team @ }cat getprop if
                loc @ { "@battle/" BID @ "/followme/" team @ }Cat getprop otpos !
                loc @ { "@battle/" BID @ "/position/" otpos @ }cat getprop otarget !
                otarget @ if
                otarget @ target !
                otpos @ tpos !
                then
          else
                var movetype
                move @ "hidden power" smatch if
                attacker @ hidden_power_type movetype !
                else
                attacker @ { "moves/" move @ "/type" }cat get movetype !
                then
                
                target @ "ability" fget "Storm Drain" smatch movetype @ "water" smatch and
                target @ "ability" fget "Lightningrod" smatch movetype @ "electric" smatch and
                or
                attacker @ bid @ moldbreaker
                if
                        loc @ { "@battle/" BID @ "/position/" tpos @ }cat getprop target !
                else (if the target doesn't have the ability, check the opposing team then your partner)
                               pos @ "?1" smatch if
                               { team @ "2" }cat partner !
                               else
                               { team @ "1" }cat partner !
                               then
                        { { oteam @ "1" }cat { oteam @ "2" }cat partner @ }list foreach otpos ! pop
 
                        loc @ { "@battle/" BID @ "/position/" otpos @ }cat getprop otarget !
                        otarget @ if
                                target @ "ability" fget "Storm Drain" smatch movetype @ "water" smatch and
                                target @ "ability" fget "Lightningrod" smatch movetype @ "electric" smatch and
                                or if
                                otarget @ target !
                                otpos @ tpos !
                                break
                                then
                        then
                        repeat
                then
          then
 
 
                move @ target @ attacker @ BID @ tpos @ pos @ damage_calc
 
                                loc @ { "@battle/" BID @ "/beatup/" pos @ }cat getprop if
 
                                loc @ { "@battle/" BID @ "/teams/" team @ "/" }cat array_get_propvals foreach id ! pop
                                        loc @ { "@battle/" bid @ "/position/" pos @ }cat getprop stringify id @ smatch if continue then
                                           id @ "Current Trainer" get attacker @ "Current Trainer" get smatch not if continue then
                                           id @ "status/hp" get not if continue then
                                           id @ "status/frozen"    get if continue then
                                           id @ "status/paralyzed" get if continue then
                                           id @ "status/asleep"    get if continue then
                                           id @ "status/poisoned"  get if continue then
                                           id @ "status/toxic"     get if continue then
                                           id @ "status/burned"    get if continue then
                                           id @ "status/fainted"   get if continue then
                                           target @ "status/fainted" get if break then
                                           move @ target @ id @ BID @ tpos @ pos @ damage_calc
 
                                repeat
 
 
                                loc @ { "@battle/" bid @ "/beatup/" pos @ }cat remove_prop
                                loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop attacker !
                then
                then
                0 othertargets !
                t-type @ "enemies" smatch if
 
 
                loc @ { "@battle/" BID @ "/position/" oteam @ "1" }cat getprop if othertargets @ 1 + othertargets ! then
                loc @ { "@battle/" BID @ "/position/" oteam @ "2" }cat getprop if othertargets @ 1 + othertargets ! then
 
                loc @ { "@Battle/" BID @ "/temp/othertargets" }cat othertargets @ setprop
 
                loc @ { "@battle/" BID @ "/position/" oteam @ "1" }cat getprop target !
                target @ if
                { oteam @ "1" }cat tpos !
                move @ target @ attacker @ BID @ tpos @ pos @ damage_calc  then
                0 target !
                loc @ { "@battle/" BID @ "/position/" oteam @ "2" }cat getprop target !
                target @ if
                { oteam @ "2" }cat tpos !
                move @ target @ attacker @ BID @ tpos @ pos @ damage_calc then
                loc @ { "@Battle/" BID @ "/temp/othertargets" }cat remove_prop
 
                then
 
 
         t-type @ "ally" smatch if
         pos @ "?1" smatch if
         { team @ "2" }cat partner !
         else
         { team @ "1" }cat partner !
                then
                loc @ { "@battle/" BID @ "/position/" partner @ }Cat getprop dup if
                target !
                move @ target @ attacker @ BID @ partner @ pos @ damage_calc
                else
                pop
                { "^[o^[c" pos @ "." attacker @ id_name "^[y tried to use ^[c" move @ cap "^[y but had no ally to use it on." }cat bid @ notify_watchers
                then
 
         then
 
                t-type @ "others" smatch if
 
                 loc @ { "@battle/" BID @ "/position/" oteam @ "1" }cat getprop if othertargets @ 1 + othertargets ! then
                 loc @ { "@battle/" BID @ "/position/" oteam @ "2" }cat getprop if othertargets @ 1 + othertargets ! then
 
                  pos @ "?1" smatch if
                  { team @ "2" }cat partner !
                  else
                  { team @ "1" }cat partner !
                  then
                         loc @ { "@battle/" BID @ "/position/" partner @ }cat getprop if othertargets @ 1 + othertargets ! then
                loc @ { "@Battle/" BID @ "/temp/othertargets" }cat othertargets @ setprop
 
                loc @ { "@battle/" BID @ "/position/" oteam @ "1" }cat getprop target !
                 target @ if
                 { oteam @ "1" }cat tpos !
                 move @ target @ attacker @ BID @ tpos @ pos @ damage_calc  then
                 0 target !
                 loc @ { "@battle/" BID @ "/position/" oteam @ "2" }cat getprop target !
                 target @ if
                 { oteam @ "2" }cat tpos !
                 move @ target @ attacker @ BID @ tpos @ pos @ damage_calc then
                0 target !
 
                pos @ "?1" smatch if
                { team @ "2" }cat partner !
                else
                { team @ "1" }cat partner !
                then
                        loc @ { "@battle/" BID @ "/position/" partner @ }cat getprop target !
                  target @ if
                  move @ target @ attacker @ BID @ partner @ pos @ damage_calc then
         loc @ { "@Battle/" BID @ "/temp/othertargets" }cat remove_prop
 
               then
 
               t-type @ "self" smatch if
               move @ attacker @ attacker @ BID @ pos @ pos @ damage_calc then
 
               t-type @ "all" smatch if
               pos_list @ foreach tpos ! pop
               loc @ { "@battle/" BID @ "/position/" tpos @ }cat getprop target !
 
               move @ target @ attacker @ bid @ tpos @ pos @ damage_calc
               repeat
 
               then
 
               t-type @ "Allies" smatch if (works on entire field of team, not just active)
               loc @ { "@battle/" BID @ "/teams/" team @ "/" }cat array_get_propvals foreach attacker ! pop
               move @ attacker @ attacker @ BID @ pos @ pos @ damage_calc
               repeat

 
               then
 
 
               attacker @ "status/fainted" get if
                { "^[o^[c" pos @ cap "." attacker @ id_name " ^[yFainted!!" }cat bid @ notify_watchers
                attacker @ "happiness" over over fget atoi 1 - fsetto
                 attacker @ "happiness" over over fget atoi 0 < if 0 fsetto else pop pop then
 
               then
 
               loc @ { "@battle/" BID @ "/FaintAfterTurn/" pos @ }cat getprop if
                   POKESTORE { "@pokemon/" attacker @ "/@RP/status" }cat remove_prop
                   POKESTORE { "@pokemon/" attacker @ "/@temp/" }cat remove_prop
                    attacker @ "status/hp" 0 setto
                   attacker @ "status/fainted" 1 setto
                   loc @ { "@battle/" BID @ "/FaintAfterTurn/" pos @ }cat remove_prop
                   { "^[o^[c" pos @ cap "." attacker @ id_name " ^[yFainted!!" }cat bid @ notify_watchers
                                   attacker @ "happiness" over over fget atoi 1 - fsetto
                attacker @ "happiness" over over fget atoi 0 < if 0 fsetto else pop pop then
 
               then
 
 
               (berry that raises PP)
               attacker @ { "/movesknown/" origionalmove @ "/pp" }cat over over fget atoi 0 < if 0 fsetto else pop pop then
                attacker @ "status/fainted" get not
                attacker @ { "/movesknown/" origionalmove @ "/pp" }cat fget not and if
                        attacker @ "status/statmods/embargo" get not attacker @ "ability" fget "klutz" smatch not and if
                        POKEDEX { "items/" attacker @ "holding" get "/holdeffect" }cat getprop berryeffect !
                                berryeffect @ if
                                        berryeffect @ ":" explode_array foreach effect ! pop
 
                                        effect @ "pp*" smatch if
                                        move @ "sketch" smatch if continue then
                                        effect @ " " "pp" subst strip atoi effect !
                                        attacker @ { "/movesknown/" origionalmove @ "/pp" }cat over over fget atoi effect @ + fsetto
                                        attacker @ { "/movesknown/" origionalmove @ "/pp" }cat over over fget atoi POKEDEX { "moves/" origionalmove @ "/pp" }cat fget atoi < if
                                        POKEDEX { "moves/" origionalmove @ "/pp" }cat fget atoi fsetto
                                        else
                                        pop
                                        then
                                        { "^[o^[c" attacker @ id_name "^[y regained some PP for ^[c" origionalmove  @ "^[y by eating its ^[c" attacker @ "holding" get "^[y." }cat bid @ notify_watchers
 
                                        attacker @ eatberry
                                        then
                                        repeat
                                then
                then then
               loc @ { "@battle/" BID @ "/lastmove" }cat move @ setprop
 
                attacker @ "holding" get "shell bell" smatch
                loc @ { "@battle/" BID @ "/DamageDeltTurn/" pos @ }cat getprop and
                if
                       loc @ { "@battle/" BID @ "/DamageDeltTurn/" pos @ }cat getprop 8 divdamage damage !
                       attacker @ "status/hp" over over get atoi damage @ + setto
                       attacker @ "maxhp" calculate maxhp !
                               attacker @ "status/hp" get atoi maxhp @ > if attacker @ "status/hp" maxhp @ setto then
                       { "^[o^[c" pos @ "." attacker @ id_name "^[y regained some health from its ^[cShell Bell^[y." }cat bid @ notify_watchers
                 then
               1 sleep
               break
               then
 
        break repeat (this repeat should never run)
 
               (do repeater moves counter here so it will always be run)
 
                       loc @ { "@battle/" BID @ "/repeats/" pos @ }cat propdir? if
                       loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop attacker !
                       loc @ { "@battle/" BID @ "/repeats/" pos @ "/turns" }cat over over getprop 1 - setprop
                       loc @ { "@battle/" BID @ "/repeats/" pos @ "/turns" }cat getprop not if
                               loc @ { "@battle/" BID @ "/repeats/" pos @ }cat remove_prop
                               POKEDEX { "moves/" move @ "/repeats/EndingEffect" }cat getprop if
                                       POKEDEX { "moves/" move @ "/repeats/EndingEffect" }cat getprop effect !
                                       effect @ "confused" smatch if
 
                                               attacker @ "ability" fget "Own Tempo" smatch if
                                               { "^[o^[c" pos @ "." attacker @ id_name "^[y would of been confused, but can't be due to its ability ^[cOwn Tempo^[y." }cat bid @ notify_watchers
                                                   else
                                               { "^[o^[c" pos @ "." attacker @ id_name "^[y is now confused!" }cat bid @ notify_watchers
                                                      attacker @ "status/statmods/confused"  random 4 % 2 + setto
                                                      
                                                              POKEDEX { "items/" attacker @ "holding" get "/holdeffect" }cat getprop dup not if pop " " then "*Heal Confused*" smatch if
                                                              1 sleep
                                                                      attacker @ "status/statmods/confused" 0 setto
                                                                      { "^[o^[c" attacker @ id_name "^[y was healed from being ^[c" effect @ "^[y by eating its ^[c" attacker @ "holding" get "^[y!" }cat bid @ notify_watchers
                                                                then
                                                then
                                        then
                               then
 
                        then
                        then
 
        loc @ { "@battle/" BID @ "/abort" }cat getprop if
         bid @ removebattle
             1
         exit
        then
 
        loc @ { "@Battle/" BID @ }cat propdir? not if 1 exit then
        loc @ { "@Battle/" BID @ "/declare/finished/" pos @ }cat "yes" setprop
           BID @ pos @ endbattle
        loc @ { "@battle/" BID @ "/moveswitch/" pos @ }cat getprop if
                loc @ { "@battle/" BID @ "/moveswitch/" pos @ }cat remove_prop
                "AI" bid @ pos @ moveswitch
        then
        loc @ { "@battle/" BID @ "/batonpass/" pos @ }cat getprop if
                "AI" bid @ pos @ batonpass
                 loc @ { "@battle/" BID @ "/batonpass/" pos @ }cat remove_prop
        then
        loc @ { "@battle/" BID @ "/pause" }cat getprop if
        var caster
        loc @ { "@battle/" BID @ "/begin position/" POS @ }cat getprop caster !
        caster @ not if
        loc @ { "@battle/" BID @ "/position/" POS @ }cat getprop caster !
        then
                { "^[y^[oWaiting on ^[c"
                loc @ { "@battle/" BID @ "/control/team" loc @ { "@battle/" BID @ "/pause" }cat getprop 1 1 midstr "/"  caster @ }cat getprop name
                "^[y to ^[r+switch^[y pokemon."
                }cat bid @ notify_watchers
                loc @ { "@battle/" BID @ "/pause" }cat remove_prop
                0 exit
        then
repeat
 
loc @ { "@battle/" bid @ "/lastrank" }cat remove_prop
loc @ { "@battle/" bid @ "/pressure" }cat remove_prop
 
(end of turn)
 (
 1.0 weather ends
 
 2.0 Sandstorm damage, Hail damage, Rain Dish, Dry Skin, Ice Body
 
 3.0 Future Sight, Doom Desire
 
 4.0 Wish
 
 5.0 Fire Pledge + Grass Pledge damage
 5.1 Shed Skin, Hydration, Healer
 5.2 Leftovers, Black Sludge
 
 6.0 Aqua Ring
 
 7.0 Ingrain
 
 8.0 Leech Seed
 
 9.0 (bad) poison damage, burn damage, Poison Heal
 9.1 Nightmare
 
 10.0 Curse (from a Ghost-type)
 
 11.0 Bind, Wrap, Fire Spin, Clamp, Whirlpool, Sand Tomb, Magma Storm
 
 12.0 Taunt ends
 
 13.0 Encore ends
 
 14.0 Disable ends, Cursed Body ends
 
 15.0 Magnet Rise ends
 
 16.0 Telekinesis ends
 
 17.0 Heal Block ends
 
 18.0 Embargo ends
 
 19.0 Yawn
 
 20.0 Perish Song
 
 21.0 Reflect ends
 21.1 Light Screen ends
 21.2 Safeguard ends
 21.3 Mist ends
 21.4 Tailwind ends
 21.5 Lucky Chant ends
 21.6 Water Pledge + Fire Pledge ends, Fire Pledge + Grass Pledge ends, Grass Pledge + Water Pledge ends
 
 22.0 Gravity ends
 
 23.0 Trick Room ends
 
 24.0 Wonder Room ends
 
 25.0 Magic Room ends
 
 26.0 Uproar message
 26.1 Speed Boost, Bad Dreams, Harvest, Moody
 26.2 Toxic Orb activation, Flame Orb activation, Sticky Barb
 
 27.0 Zen Mode
 
 28.0 Pokémon is switched in (if previous Pokémon fainted)
 28.1 Healing Wish, Lunar Dance
 28.2 Spikes, Toxic Spikes, Stealth Rock (hurt in the order they are first used)
 
 29.0 Slow Start
 
40.0 Roost
 )
(now do the other effects that damage people)
loc @ { "@battle/" BID @ }cat propdir? not if ready @ exit then
 
        loc @ { "@battle/" bid @ "/howmany" }cat getprop atoi 2 = if
        { "A1" "B1" "A2" "B2" }list pos_list !
        else loc @ { "@battle/" bid @ "/howmany" }cat getprop atoi 3 = if
                { "A1" "B1" "A2" "B2" "A3" "B3" }list pos_list !
                else
                { "A1" "B1" }list pos_list !
                then
        then
 
pos_list @ foreach pos ! pop
 loc @ { "@battle/" BID @ "/Position/" pos @ }cat getprop target !
 (wish has to go first because I have it skipping if something isn't there)
 loc @ { "@battle/" BID @ "/Wish/" pos @ }cat getprop if
         loc @ { "@battle/" BID @ "/Wish/" pos @ }cat over over getprop 1 - setprop
         loc @ { "@battle/" BID @ "/Wish/" pos @ }cat getprop not if
         loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop if
         { "^[o^[yThe wish came true and ^[c" pos @ "." target @ id_name "^[y was healed!" }cat bid @ notify_watchers
         target @ "MaxHP"   Calculate maxhp !
         maxhp @ 2 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
         target @ "status/hp" over over get atoi damage @ + setto
         target @ "status/hp" get atoi maxhp @ > if target @ "status/hp" maxhp @ setto then
         then
         then
 then
 loc @ { "@battle/" BID @ "/Position/" pos @ }cat getprop not if continue then
 
 target @ "status/fainted" get if continue then
 target @ "MaxHP"   Calculate maxhp !
 
 
(Let heal moves go first, then poison moves)
 target @ "status/statmods/healovertime/move" get if
 target @ "status/statmods/healblock" get not if
        maxhp @ 16 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
        target @ "status/hp" over over get atoi damage @ + setto
        target @ "status/hp" get atoi maxhp @ > if target @ "status/hp" maxhp @ setto then
        { "^[o^[c" pos @ "." target @ id_name "^[y regained some health from ^[c" target @ "status/statmods/healovertime/move" get cap "^[y." }cat bid @ notify_watchers
 then then
 
 
 target @ "holding" get "leftovers" smatch 
        target @ "status/statmods/embargo" get not target @ "ability" fget "klutz" smatch not and and if
        maxhp @ 16 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
        target @ "status/hp" over over get atoi damage @ + setto
        target @ "status/hp" get atoi maxhp @ > if target @ "status/hp" maxhp @ setto then
        { "^[o^[c" pos @ "." target @ id_name "^[y regained some health from its ^[cLeftovers^[y." }cat bid @ notify_watchers
 then
 
 target @ "status/statmods/ingrain/move" get if
 target @ "Status/statmods/healblock" get not if
        maxhp @ 16 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
        target @ "status/hp" over over get atoi damage @ + setto
        target @ "status/hp" get atoi maxhp @ > if target @ "status/hp" maxhp @ setto then
        { "^[o^[c" pos @ "." target @ id_name "^[y regained some health from ^[c" target @ "status/statmods/ingrain/move" get cap "^[y." }cat bid @ notify_watchers
 
 then then
 
 target @ "status/statmods/seeded" get
 target @ "ability" fget "magic guard" smatch not and
        if
        loc @ { "@battle/" bid @ "/position/" target @ "status/statmods/seeded" get }cat getprop if
                loc @ { "@battle/" bid @ "/position/" target @ "status/statmods/seeded" get }cat getprop seeder !
                maxhp @ 8 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
                target @ "status/hp" over over get atoi damage @ - setto
                loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn/" pos @ }cat 1 setprop
                target @ "status/statmods/healblock" get not if
                seeder @ "status/hp" over over get atoi damage @ + setto
                seeder @ "maxhp" calculate smaxhp !
                seeder @ "status/hp" get atoi smaxhp @ > if seeder @ "status/hp" smaxhp @ setto then
 
                { "^[o^[c" pos @ "." target @ id_name "^[y is seeded and had some health drained to ^[c" target @ "status/statmods/seeded" get "." seeder @ id_name "^[y." }cat bid @ notify_watchers
                else
                { "^[o^[c" pos @ "." target @ id_name "^[y is seeded and had some health drained to ^[c" target @ "status/statmods/seeded" get "." seeder @ id_name "^[y, but they couldn't gain health due to Heal Block." }cat bid @ notify_watchers
                then
        then
 then
 
(damaging hold items)
target @ "ability" fget "klutz" smatch not target @ "status/statmods/embargo" get not and if
        target @ "holding" get temp !
 
                temp @ "Sticky Barb" smatch target @ "ability" fget "Magic Guard" smatch not and if
                
                        target @ "status/hp" over over get atoi maxhp 8 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage - setto
                        { "^[o^[c" target @ id_name "^[y has been ^[rDamaged^[y by holding the item ^[c" target @ "holding" get "^[y!" }cat bid @ notify_watchers
                then
                
                temp @ "Black Sludge" smatch if
                        target @ typelist "poison" array_findval array_count if 
                        target @ "status/hp" over over get atoi maxhp @ 16 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage + setto
                        target @ "status/hp" get atoi maxhp @ > if target @ "Status/hp" maxhp @ setto then
                        { "^[o^[c" target @ id_name "^[y has ^[gregained some health^[y by holding the item ^[c" target @ "holding" get "^[y!" }cat bid @ notify_watchers
 
                        else 
                        target @ "ability" fget "Magic Guard" smatch not if
                                target @ "status/hp" over over get atoi maxhp @ 16 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage - setto
                                { "^[o^[c" target @ id_name "^[y has been ^[rDamaged^[y by holding the item ^[c" target @ "holding" get "^[y!" }cat bid @ notify_watchers
                        then
 
                        then
                
                then
        
  target @ "status/frozen"    get not
  target @ "status/paralyzed" get not and
  target @ "status/asleep"    get not and
  target @ "status/poisoned"  get not and
  target @ "status/toxic"     get not and
  target @ "status/burned"    get not and
  target @ "status/fainted"   get not and if
                temp @ "Flame Orb" smatch if
                        target @ "status/burned" 1 setto
                        { "^[o^[c" target @ id_name "^[y has been ^[rBurned^[y by holding the item ^[c" target @ "holding" get "^[y!" }cat bid @ notify_watchers
                then
                
                temp @ "Toxic Orb" smatch
                target @ typelist "poison" array_findval array_count not and
                    target @ typelist "steel" array_findval array_count not and
                     target @ "ability" fget "immunity" smatch not and if
                        target @ "status/toxic" 1 setto
                        { "^[o^[c" target @ id_name "^[y has been ^[mbadly Poisoned^[y by holding the item ^[c" target @ "holding" get "^[y!" }cat bid @ notify_watchers
                then
                
        then
then
(end damanging hold items)

(fire pledge)
loc @ { "@battle/" BID @ "/pledge field/" pos @ 1 1 midstr "/move" }cat getprop dup if "fire pledge" smatch else 0 then
bid @ check_weather "rain dance" smatch and if
        { "^[o^[yThe rain removed ^[cFire Pledge's^[y field from ^[cTeam " pos @ 1 1 midstr "'s ^[yside." }cat bid @ notify_watchers
        loc @ { "@battle/" BID @ "/pledge field/" pos @ 1 1 midstr "/move" }cat remove_prop
then

loc @ { "@battle/" BID @ "/pledge field/" pos @ 1 1 midstr "/move" }cat getprop dup if "fire pledge" smatch else 0 then if
        maxhp @ 8 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
        target @ "status/hp" over over get atoi damage @ - setto
        { "^[o^[c" pos @ "." target @ id_name "^[y took some damage from ^[cFire Pledge's^[y field." }cat bid @ notify_watchers
then

 
(do status removal abilities here)
0 temp !
    target @ "status/frozen"    get if  "frozen" temp ! then
    target @ "status/paralyzed" get if  "paralyzed" temp ! then
    target @ "status/asleep"    get if  "asleep" temp ! then
    target @ "status/poisoned"  get if  "poisoned" temp ! then
    target @ "status/toxic"     get if  "toxic" temp ! then
    target @ "status/burned"    get if  "burned" temp ! then
 
temp @ if
        target @ "ability" fget "Shed Skin" smatch if
                frand 0.3 <= if
                        target @ { "status/" temp @ }cat 0 setto
                        { "^[o^[c" pos @ "." target @ id_name "^[y's ability ^[c" target @ "ability" fget "^[y removed its status effect!" }cat bid @ notify_watchers
                then
        then
 
then

target @ "ability" fget "healer" smatch if
        { { pos @ 1 1 midstr pos @ 2 1 midstr atoi 1 + }cat { pos @ 1 1 midstr pos @ 2 1 midstr atoi 1 - }cat }list foreach temp ! pop
                loc @ { "@battle/" BID @ "/position/" temp @ }cat getprop temp2 !
                temp2 @ not if continue then
                frand 0.3 <= if
                        temp2 @ check_status temp3 !
                        temp3 @ if
                                temp2 @ { "status/" temp3 @ }cat 0 setto
                                { "^[o^[c" pos @ "." target @ id_name "^[y's ability ^[c" target @ "ability" fget "^[y removed ^[c" temp "." temp2 @ id_name "'s^[y status effect!" }cat bid @ notify_watchers
                        then
                then
                
        
        repeat
then
(end abilities)
 
 target @ "ability" fget "Poison Heal" smatch if
        target @ "status/poisoned" get
        target @ "status/toxic" get or if
                maxhp @ 8 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
                target @ "status/hp" over over get atoi damage @ + setto
                target @ "status/hp" get atoi maxhp @ > if target @ "status/hp" maxhp @ setto then
              { "^[o^[c" target @ id_name "^[y was healed some from ^[mpoison^[y due to its ability ^[c" target @ "ability" fget cap "^[y." }cat bid @ notify_watchers
        then
 else
 
         target @ "status/poisoned"  get
         target @ "ability" fget "magic guard" smatch not and
         if
 
          target @ "ability" fget "immunity" smatch if
                 target @ "status/poisoned" 0 setto
                 { "^[o^[c" target @ id_name "^[y is no longer poisoned due to its ability ^[cImmunity^[y."  }cat bid @ notify_watchers
         else
 
         maxhp @ 8 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
         target @ "status/hp" over over get atoi damage @ - setto
         loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn/" pos @ }cat 1 setprop
              { "^[o^[c" target @ id_name "^[y took some damage from ^[mpoison^[y." }cat bid @ notify_watchers
 
         then
         then
 
         target @ "status/toxic"     get if
         target @ "ability" fget "immunity" smatch if
                target @ "status/toxic" 0 setto
                { "^[o^[c" target @ id_name "^[y is no longer ^[mpoisoned ^[ydue to its ability ^[cImmunity^[y."  }cat bid @ notify_watchers
         else
         maxhp @ target @ "status/toxic" get atoi 16.0 target @ "pvp/hpboost" fget dup if atoi * else pop then / * floor damage !
         damage @ 1 < if 1 damage ! then
         target @ "status/toxic" over over get atoi 1 + setto
         target @ "ability" fget "magic guard" smatch not if
         target @ "status/hp" over over get atoi damage @ - setto
         loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn/" pos @ }cat 1 setprop
              { "^[o^[c" target @ id_name "^[y took some damage from ^[mtoxic^[y." }cat bid @ notify_watchers
         then
         then
         then
 then
 
 target @ "status/frozen" get target @ "ability" fget "Magma Armor" smatch and if
        target @ "status/frozen" 0 setto
        { "^[o^[c" target @ id_name "^[y is no longer ^[cfrozen^[y due to its ability ^[c" target @ "ability" fget "^[y."  }cat bid @ notify_watchers
 then
 
  target @ "status/paralyzed" get target @ "ability" fget "Limber" smatch and if
         target @ "status/paralyzed" 0 setto
         { "^[o^[c" target @ id_name "^[y is no longer Paralyzed due to its ability ^[c" target @ "ability" fget "^[y."  }cat bid @ notify_watchers
 then
 
 target @ "status/statmods/confused" get target @ "ability" fget "Own Tempo" smatch and if
        target @ "status/statmods/confused" 0 setto
        { "^[o^[c" target @ id_name "^[y is no longer Confused due to its ability ^[c" target @ "ability" fget "^[y."  }cat bid @ notify_watchers
 then
 
 target @ "status/burned"    get
 target @ "ability" fget "magic guard" smatch not and
 if
 target @ "Ability" fget "Water veil" smatch if
 target @ "status/burned" 0 setto
      { "^[o^[c" target @ id_name "^[y is no longer ^[rburned^[y because of the ability ^[cWater Veil^[y." }cat bid @ notify_watchers
 else
 maxhp @ 8 target @ "ability" fget "heatproof" smatch if 2 * then target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
 target @ "status/hp" over over get atoi damage @ - setto
 loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn/" pos @ }cat 1 setprop
      { "^[o^[c" target @ id_name "^[y took some damage from ^[rburn^[y." }cat bid @ notify_watchers
 then
 
 then
 
 target @ "status/asleep" get
 target @ "ability" fget "vital spirit" smatch
 target @ "ability" fget "insomnia" smatch or
 and if
        target @ "status/asleep" 0 setto
        { "^[o^[c" target @ id_name "^[y is no longer ^[basleep because of the ability ^[c" target @ "ability" fget cap "^[y." }cat bid @ notify_watchers
 then
 
 target @ "status/statmods/cursed" get
 target @ "ability" fget "magic guard" smatch not and
 if
 maxhp @ 4 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
 target @ "status/hp" over over get atoi damage @ - setto
 loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn/" pos @ }cat 1 setprop
       { "^[o^[c" target @ id_name "^[y took some damage from its ^[mcurse^[y." }cat bid @ notify_watchers
 
 then
 
 target @ "status/statmods/nightmare" get
 target @ "ability" fget "magic guard" smatch not and
 if
        target @ "status/asleep" get if
        maxhp @ 4 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
        target @ "status/hp" over over get atoi damage @ - setto
        loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn/" pos @ }cat 1 setprop
       { "^[o^[c" target @ id_name "^[y took some damage from its ^[xnightmare^[o^[y." }cat bid @ notify_watchers
 
        else
        target @ "status/statmods/nightmare" 0 setto
        then
 then
 
 (bad dreams)
 target @ "ability" fget "magic guard" smatch not if
 pos @ "A*" smatch if
 "B" temp !
 else
 "A" temp !
 then
 
 temp @ "Bad Dreams" bid @ team_ability temp2 !
 temp2 @ if
        target @ "status/asleep" get if
                maxhp @ 8 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage temp2 @ * damage !
                target @ "status/hp" over over get atoi damage @ - setto
                loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn/" pos @ }cat 1 setprop
                { "^[o^[c" target @ id_name "^[y took some damage from the ability ^[cBad Dreams" temp2 @ 1 > if " 2x" then "^[y." }cat bid @ notify_watchers
        then
 then
 
 then
 
 target @ "ability" fget "speed boost" smatch if
 target @ "status/statmods/speed" get atoi 6 < if
 target @ "status/statmods/speed" over over get atoi 1 + setto
 { "^[o^[c" target @ id_name "^[y had its speed raised due to its ability ^[cSpeed Boost^[y!" }cat bid @ notify_watchers
 then
 target @ "status/statmods/speed" get atoi 6 > if target @ "status/statmods/speed" 6 setto then
 then
 
 (weather damage)
target @ "status/statmods/semi-inv" get not if
 bid @ check_weather weather !
 target @ "ability" fget "sand veil" smatch target @ "ability" fget "Sand Rush" smatch or target @ "ability" fget "Sand Force" smatch or weather @ "sandstorm" smatch and not
 target @ "ability" fget "ice body" smatch weather @ "hail" smatch and not and
 target @ "ability" fget "snow cloak" smatch weather @ "hail" smatch and not and
 target @ "ability" fget "magic guard" smatch not and
 target @ "ability" fget "Overcoat" smatch not and
 if
 
         POKEDEX { "/weather/" weather @ "/DamageOverTime" }Cat getprop if
                0 immune !
                target @ typelist foreach swap pop targettype !
                POKEDEX { "/weather/" weather @ "/DamageOverTime/immunetype/" targettype @ }cat getprop
                if "yes" immune ! then repeat
 
                immune @ not if
                maxhp @ 16 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
                target @ "status/hp" over over get atoi damage @ - setto
                loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn/" pos @ }cat 1 setprop
 
                { "^[o^[c" pos @ "." target @ id_name "^[y took some damage from the weather." }cat bid @ notify_watchers
                then
         then
 then
 (weather related abilities)
 weather @ "sunny day" smatch target @ "ability" fget "dry skin" smatch and if
        maxhp @ 8 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
        target @ "status/hp" over over get atoi damage @ - setto
        { "^[o^[c" pos @ "." target @ id_name "^[y took some damage from drying out by the weather." }cat bid @ notify_watchers
 then
 
 weather @ "sunny day" smatch target @ "ability" fget "solar power" smatch and if
        maxhp @ 8 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
        target @ "status/hp" over over get atoi damage @ - setto
        { "^[o^[c" pos @ "." target @ id_name "^[y took some damage from the hot weather." }cat bid @ notify_watchers
 then
 
 weather @ "rain dance" smatch target @ "ability" fget "dry skin" smatch and if
        maxhp @ 8 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
        target @ "status/hp" over over get atoi damage @ + setto
        target @ "status/hp" get atoi maxhp @ > if target @ "status/hp" maxhp @ setto then
        { "^[o^[c" pos @ "." target @ id_name "^[y healed some from the wet weather." }cat bid @ notify_watchers
 then
 
 weather @ "rain dance" smatch target @ "ability" fget "rain dish" smatch and if
        maxhp @ 16 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
        target @ "status/hp" over over get atoi damage @ + setto
        target @ "status/hp" get atoi maxhp @ > if target @ "status/hp" maxhp @ setto then
        { "^[o^[c" pos @ "." target @ id_name "^[y healed some from the wet weather." }cat bid @ notify_watchers
 then
 
 weather @ "hail" smatch target @ "ability" fget "ice body" smatch and if
        maxhp @ 16 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
        target @ "status/hp" over over get atoi damage @ + setto
        target @ "status/hp" get atoi maxhp @ > if target @ "status/hp" maxhp @ setto then
        { "^[o^[c" pos @ "." target @ id_name "^[y healed some from the icy weather." }cat bid @ notify_watchers
 then
 
 weather @ "rain dance" smatch target @ "ability" fget "Hydration" smatch and if
         begin
         0 temp !
            target @ "status/frozen"    get if "frozen" temp ! break then
            target @ "status/paralyzed" get if "paralyzed" temp ! break then
            target @ "status/asleep"    get if "asleep" temp ! break then
            target @ "status/poisoned"  get if "poisoned" temp ! break then
            target @ "status/toxic"     get if "toxic" temp ! break then
            target @ "status/burned"    get if "burned" temp ! break then
        break repeat
        temp @ if
                target @ { "status/" temp @ }cat 0 setto
                { "^[o^[c" pos @ "." target @ id_name "^[y healed from being " temp @ cap " because of the wet weather." }cat bid @ notify_watchers
        then
 then
 
then
 (weather abilities end)
 (harvest ability)
 target @ "ability" fget "harvest" smatch if
        target @ "holding" get "Nothing" smatch not if
                loc @ { "@battle/" BID @ "/EatenBerry/" target @ }cat getprop if
                        random 2 % if
                                 "^[o^[c" pos @ "." target @ id_name "^[y harvested a new ^[c" loc @ { "@battle/" BID @ "/EatenBerry/" target @ }cat getprop cap "^[y with its ability ^[cHarvest^[y!" }cat bid @ notify_watchers
                                 target @ "holding" loc @ { "@battle/" BID @ "/EatenBerry/" target @ }cat getprop setto
                        then
                then
        then
 then
 
 (moody ability)
 target @ "ability" fget "moody" smatch if
        { "PhysAtk" "PhysDef" "SpecAtk" "SpecDef" "Speed" }list temp !
        0 temp3 !
                temp @ foreach swap pop temp2 !
        target @ { "status/statmods/" temp2 @ }cat get atoi 6 >= if continue then
                temp2 @ temp3 !
                target @ { "status/statmods/" temp3 @ }cat over over get atoi 2 + setto
                "^[o^[c" pos @ "." target @ id_name "^[y's ^[c" temp3 @ "^[y stat raised sharply due to its ability ^[cMoody^[y!" }cat bid @ notify_watchers
                break
        repeat
        temp @ foreach swap pop temp2 !
                target @ { "status/statmods/" temp2 @ }cat get atoi -6 <= if continue then
                temp2 @ temp3 @ smatch if continue then
                target @ { "status/statmods/" temp2 @ }cat over over get atoi 1 - setto
                "^[o^[c" pos @ "." target @ id_name "^[y's ^[c" temp2 @ "^[y stat lowered due to its ability ^[cMoody^[y!" }cat bid @ notify_watchers
                break
        repeat
        
 then
 
 target @ "status/statmods/block/move" get if
                target @ "status/statmods/block/user" get loc @ { "@battle/" BID @ "/position/" target @ "status/statmods/block/userposition" get }cat getprop stringify smatch not if
                        target @ "status/statmods/block/user" 0 setto
                        target @ "status/statmods/block/move" 0 setto
                        target @ "status/statmods/block/userposition" 0 setto
                then
 then
 
 target @ "status/statmods/vortex/turns" get if
                target @ "status/statmods/vortex/holder" get loc @ { "@battle/" BID @ "/position/" target @ "status/statmods/vortex/holderposition" get }cat getprop stringify smatch not if
                target @ "status/statmods/vortex/turns" 0 setto
                target @ "status/statmods/vortex/holder" 0 setto
                target @ "status/statmods/vortex/holderposition" 0 setto
                target @ "status/statmods/vortex/move" 0 setto
        else
                target @ "status/statmods/vortex/turns" over over get atoi 1 - setto
                maxhp @ 16 target @ "pvp/hpboost" fget dup if atoi * else pop then divdamage damage !
                target @ "status/hp" over over get atoi damage @ - setto
                loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn/" pos @ }cat 1 setprop
                { "^[o^[c" pos @ "." target @ id_name "^[y took some damage from ^[c" target @ "status/statmods/vortex/holder" get id_name "'s " target @ "status/statmods/vortex/move" get cap "^[y attack." }cat bid @ notify_watchers
 
                target @ "status/statmods/vortex/turns" get not if
                { "^[o^[c" pos @ "." target @ id_name "^[y has gotten free from ^[c" target @ "status/statmods/vortex/holder" get id_name "'s " target @ "status/statmods/vortex/move" get cap "^[y attack!" }cat bid @ notify_watchers
                target @ "status/statmods/vortex/turns" 0 setto
                target @ "status/statmods/vortex/holder" 0 setto
                target @ "status/statmods/vortex/holderposition" 0 setto
                target @ "status/statmods/vortex/move" 0 setto
 
                then
        then
 then
 
 target @ "status/statmods/perishsong" get if
        { "^[o^[c" pos @ "." target @ id_name "^[y still hears the eerie song..."  }cat bid @ notify_watchers
        target @ "status/statmods/perishsong" over over get atoi 1 - setto
        target @ "status/statmods/perishsong" get not if
        target @ "ability" get "soundproof" smatch not if
                target @ "status/hp" 0 setto
                { "^[o^[c" pos @ "." target @ id_name "^[y has been affected by Perish Song!" }cat bid @ notify_Watchers
                else
                { "^[o^[c" pos @ "." target @ id_name "^[y isn't affected by Perish Song because of Soundproof!" }cat bid @ notify_Watchers
                then
        then
 then
 
 target @ "status/hp" get atoi 0 <= if
 POKESTORE { "@pokemon/" target @ "/@RP/status" }cat remove_prop
 POKESTORE { "@pokemon/" target @ "/@temp/" }cat remove_prop
 target @ "status/hp" 0 setto
 target @ "status/fainted" 1 setto
then
 
 target @ "status/fainted" get if
  loc @ { "@battle/" BID @ "/watching/" }cat array_get_propvals foreach pop stod tempref !
 tempref @ awake? not if continue then
 tempref @ location loc @ = not if continue then
  tempref @ { "^[o^[c" pos @ cap "." target @ id_name " ^[yFainted!!"
  }cat notify
  repeat
 loc @ { "@battle/" bid @ "/pursuit/" pos @ }cat getprop not if
 BID @ pos @ endbattle  (calls the end battle program which is in BattleTypes.muf)
 else
 loc @ { "@battle/" bid @ "/pursuit/" pos @ }cat remove_prop
 then
   then
repeat
 
 
(end effects 2)
 
        (shields)
        var team
        var shield
        { "A" "B" }list foreach team ! pop
                { "safeguard" "reflect" "light screen" "mist" "lucky chant" }list foreach shield ! pop
                        loc @ { "@battle/" BID @ "/shields/" team @ "/" shield @ }cat getprop if
                                loc @ { "@battle/" BID @ "/shields/" team @ "/" shield @ }cat over over getprop 1 - setprop
                                loc @ { "@battle/" BID @ "/shields/" team @ "/" shield @ }cat getprop not if
                                        { "^[o^[cTeam " team @ "'s " shield @ cap "^[y wore off." }cat bid @ notify_watchers
                                then
                        then
                repeat
                (fields)
                loc @ { "@battle/" BID @ "/pledge field/" temp2 @ "/turns" }cat over over getprop 1 - setprop
                loc @ { "@battle/" BID @ "/pledge field/" temp2 @ "/turns" }cat getprop not if
                        { "^[o^[yThe ^[c" loc @ { "@battle/" BID @ "/pledge field/" temp2 @ "/move" }cat getprop  " field^[y has worn off for on ^[cTeam " team @ "^[y." }cat bid @ notify_watchers
                then
        repeat
        (end shields)
        
        (guards)
        loc @ { "@battle/" BID @ "/guards/" }cat remove_prop
pos_list @ foreach pos ! pop
var pos2
loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop not if
        loc @ { "@battle/" BID @ "/charge/" pos @ }cat remove_prop
then
repeat
 
(remove declares folder)
loc @ { "@battle/" BID @ "/flinched/" }cat remove_prop
pos_list @ foreach pos ! pop
loc @ { "@battle/" BID @ "/lastdeclare/" pos @ }cat loc @ { "@battle/" BID @ "/declare/" pos @ }cat getprop setprop
 
loc @ { "@battle/" BID @ "/repeats/" pos @ "/move" }cat getprop if
        loc @ { "@battle/" BID @ "/repeats/" pos @ "/move" }cat getprop stringify
        loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "status/statmods/disabled/move" get stringify  smatch if
                loc @ { "@battle/" BID @ "/declare/" pos @ }cat remove_prop
                loc @ { "@battle/" BID @ "/uproar/" pos @ }cat remove_prop
        then
then
 
loc @ { "@battle/" BID @ "/charge/" pos @ "/charging" }cat propdir? not
loc @ { "@battle/" BID @ "/repeats/" pos @ }cat propdir? not and
if
        loc @ { "@battle/" BID @ "/declare/" pos @ }cat remove_prop
        loc @ { "@battle/" BID @ "/uproar/" pos @ }cat remove_prop
then
loc @ { "@battle/" BID @ "/charge/" pos @ "/charging" }cat propdir? if
        loc @ { "@battle/" BID @ "/declare/" pos @ }cat getprop " " split temp ! pop
        POKEDEX { "moves/" temp @ "gravityfail" }cat getprop if
        loc @ { "@battle/" BID @ "/declare/" pos @ }cat remove_prop
        then
 
then
(fix repeats so you don't get into a flinching combo)
 
(fix the charge and recharges)
loc @ { "@battle/" BID @ "/charge/" pos @ "/charging/thisturn" }cat remove_prop
loc @ { "@battle/" BID @ "/charge/" pos @ "/charging/textsaid" }cat remove_prop
loc @ { "@battle/" BID @ "/charge/" pos @ "/charging/remove-me" }cat getprop if
loc @ { "@battle/" BID @ "/charge/" pos @ }cat remove_prop
then
 
loc @ { "@battle/" BID @ "/charge/" pos @ "/recharge" }cat getprop if
 loc @ { "@battle/" BID @ "/charge/" pos @ "/recharge" }cat loc @ { "@battle/" BID @ "/charge/" pos @ "/recharge" }cat getprop 1 -  setprop
 loc @ { "@battle/" BID @ "/declare/" pos @ }cat "recharge me" setprop
then
 
loc @ { "@Battle/" BID @ "/helping hand/" pos @ }cat remove_prop
loc @ { "@Battle/" BID @ "/magic coat/" pos @ }cat remove_prop
 
loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop if
 
loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop temp !
temp @ "status/statmods/yawn" get if
        var failed
        var temptarget
        loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop temptarget !
        loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "status/statmods/yawn" over over get atoi 1 - setto
        { "^[o^[c" pos @ "." temptarget @ id_name "^[y is looking sleepy." }cat bid @ notify_watchers
        loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop "status/statmods/yawn" get not if
 
                           temptarget @ "status/frozen"    get if 1 failed ! then
                           temptarget @ "status/paralyzed" get if 1 failed ! then
                           temptarget @ "status/asleep"    get if 1 failed ! then
                           temptarget @ "status/poisoned"  get if 1 failed ! then
                           temptarget @ "status/toxic"     get if 1 failed ! then
                           temptarget @ "status/burned"    get if 1 failed ! then
                           temptarget @ "status/fainted"   get if 1 failed ! then
                           failed @ not if
                           loc @ { "@battle/" BID @ "/uproar" }cat propdir? if
                                   { "^[o^[c" pos @ "." temptarget @ id_name "^[y would have fallen ^[bAsleep^[y but couldn't due to the effect of uproar." }cat bid @ notify_watchers else
                                        temptarget @ "status/asleep"
                                        random 5 % 2 + setto
                                        { "^[o^[c" pos @ "." temptarget @ id_name "^[y is now ^[basleep." }cat bid @ notify_watchers
                                        then
                           then
        then
 
then
 
 temp @ "status/statmods/freehit/count" get if
        temp @ "status/statmods/freehit/count" over over get atoi 1 - setto
 
        temp @ "status/statmods/freehit/count" get not if
                temp @ "status/statmods/freehit/count" 0 setto
                temp @ "status/statmods/freehit/caster" 0 setto
        then
 then
 
 temp @ "status/statmods/enduring" 0 setto
 temp @ "status/statmods/protected" 0 setto
 loc @ { "@battle/" BID @ "/future attack/" pos @ }Cat propdir? if
  loc @ { "@battle/" BID @ "/future attack/" pos @ "/count" }Cat over over getprop 1 - setprop
  loc @ { "@battle/" BID @ "/future attack/" pos @ "/count" }Cat getprop not if
  { "^[o^[yThe future attack strikes!" }cat bid @ notify_watchers
   "Future Attack"
   temp @
   loc @ { "@battle/" BID @ "/future attack/" pos @ "/caster" }cat getprop
   bid @
   pos @
   loc @ { "@battle/" BID @ "/future attack/" pos @ "/casterpos" }cat getprop
   damage_calc
  loc @ { "@battle/" BID @ "/future attack/" pos @ }cat remove_prop
  then
  then
  temp @ "status/statmods/taunted" get if
  temp @ "status/statmods/taunted" over over get atoi 1 - setto
  then
 
  temp @ "status/statmods/roost" 0 setto
 
  temp @ "ability" fget "slow start" smatch if
        temp @ "status/statmods/ability/slow start" get not if
         temp @ "status/statmods/ability/slow start" 1 setto
         then
         temp @ "status/statmods/ability/slow start" over over get atoi 1 + setto
         temp @ "status/statmods/ability/slow start" get atoi 5 > not if
                { "^[o^[c" pos @ "." target @ id_name "^[y is still under the effects of the ability ^[cSlow Start^[y."}cat bid @ notify_watchers
         then
  then
 
  temp @ "status/statmods/Magnet Rise" get if
        temp @ "status/statmods/Magnet Rise" over over get atoi 1 - setto
  then
  temp @ "status/statmods/encore/turns" get if
        temp @ "status/statmods/encore/turns" over over get atoi 1 - setto
        temp @ "status/statmods/encore/turns" get not
        temp @ { "movesknown/" temp @ "status/statmods/encore/move" get "/pp" }cat fget not or
        if
        temp @ "status/statmods/encore/turns" "" setto
        temp @ "status/statmods/encore/move" "" setto
        { "^[o^[c" pos @ "." temp @ id_name "^[y is no longer under the effect of Encore." }cat bid @ notify_watchers
        then
  then
  temp @ "status/statmods/disabled/turns" get if
          temp @ "status/statmods/disabled/turns" over over get atoi 1 - setto
          temp @ "status/statmods/disabled/turns" get not if
          { "^[o^[c" pos @ "." temp @ id_name "'s " temp @ "status/statmods/disabled/move" get "^[y is no longer disabled!" }cat BID @ notify_watchers
          temp @ "status/statmods/disabled/move" "" setto
          temp @ "status/statmods/disabled/turns" "" setto
          then
  then
 
  temp @ "status/statmods/healblock" get if
  temp @ "status/statmods/healblock" over over get atoi 1 - setto
  then
 
  temp @ "status/statmods/embargo" get if
        temp @ "status/statmods/embargo" over over get atoi 1 - setto
  then
 
 loc @ { "@battle/" BID @ "/temp/round_boost/" }cat remove_prop
 
  BID @ pos @ endbattle
 
 then
 
 
 
 
repeat
 
  var pos3
  pos_list @ foreach pos2 ! pop
        loc @ { "@battle/" BID @ "/position/" pos2 @ }cat getprop temptarget !
        pos_list @ foreach pos3 ! pop
                temptarget @ { "status/statmods/lock-on/" pos3 @ "/count" }cat get if
                        temptarget @ { "status/statmods/lock-on/" pos3 @ "/count" }cat over over get atoi 1 - setto
                        temptarget @ { "status/statmods/lock-on/" pos3 @ "/count" }cat get not if
                                temptarget @ { "status/statmods/lock-on/" pos3 @ }cat remove_prop
                        then
                then
        repeat
  repeat
  loc @ { "@battle/" BID @ "/trickroom" }cat getprop if
          loc @ { "@battle/" BID @ "/trickroom" }cat over over getprop 1 - setprop
          loc @ { "@battle/" BID @ "/trickroom" }cat getprop not if
          "^[y^[oThe effect of ^[cTrick Room^[y has ENDED." bid @ notify_Watchers
          then
  then
  
  loc @ { "@battle/" BID @ "/MagicRoom" }cat getprop if
        loc @ { "@battle/" BID @ "/MagicRoom" }cat over over getprop 1 - setprop
        loc @ { "@battle/" BID @ "/MagicRoom" }cat getprop not if
        "^[y^[oThe effect of ^[cMagic Room^[y has ENDED." bid @ notify_Watchers
        then
  then
  
    loc @ { "@battle/" BID @ "/WonderRoom" }cat getprop if
          loc @ { "@battle/" BID @ "/WonderRoom" }cat over over getprop 1 - setprop
          loc @ { "@battle/" BID @ "/WonderRoom" }cat getprop not if
          "^[y^[oThe effect of ^[cWonder Room^[y has ENDED." bid @ notify_Watchers
          then
  then
 
 
 
(remove dulling if the pokemon that caused it left)
loc @ { "@battle/" BID @ "/dull/" }cat array_get_propvals foreach var! cause var! element
loc @ { "@battle/" BID @ "/position/A1" }cat getprop dup not if pop "none" then cause @ smatch
loc @ { "@battle/" BID @ "/position/A2" }cat getprop dup not if pop "none" then cause @ smatch or
loc @ { "@battle/" BID @ "/position/B1" }cat getprop dup not if pop "none" then cause @ smatch or
loc @ { "@battle/" BID @ "/position/B2" }cat getprop dup not if pop "none" then cause @ smatch or not if
 loc @ { "@battle/" BID @ "/dull/" element @ }cat remove_prop
then
repeat
 
loc @ { "@battle/" BID @ "/BattleReady" }cat remove_prop
loc @ { "@Battle/" BID @ "/tempvalues/displayed" }cat remove_prop
 
 
 
ready @
;
 
: firstturn
(this is used for all the abilitys that go into effect on the first turn, and for everything that is set the first turn)
var! BID
var pos
var target
var effect
(to make my life easier, set the 'last battle' prop in firstturn so that every battle has it.)
var temp
loc @ { "@battle/" BID @ "/teams/" }cat propdir? not if
{ "^[o^[rTeam folders didn't write, notify Yang.  Battle Aborted." }cat "ERROR" pretty bid @ notify_watchers
"error" abortbattle
exit
then
loc @ { "@battle/" BID @ "/position/" }cat propdir? not if
{ "^[o^[rPosition folders didn't write, notify Yang.  Battle Aborted." }cat "ERROR" pretty bid @ notify_watchers
"error" abortbattle
exit
then


loc @ { "@battle/" BID @ "/battling/" }cat array_get_propvals foreach pop stod temp !
temp @ "@lastbattle" systime setprop  (leave this disabled unless you want a timeout for battles)
repeat

(set the room's weather)
loc @ { "@weather/current" }cat getprop if
        loc @ { "@battle/" BID @ "/roomweather" }cat loc @ { "@weather/current" }cat getprop setprop
        loc @ { "@battle/" BID @ "/roomweather/length" }cat 999 setprop
 
        loc @ { "@battle/" BID @ "/roomweather" }cat getprop effect !
        effect @ if
        {
         effect @ "Hail" smatch if
         "^[y^[oHail falls from the sky."
         else
         effect @ "Rain Dance" smatch if
         "^[y^[oIt is raining"
         else
         effect @ "Sandstorm" smatch if
         "^[y^[oThe sandstorm rages."
         else
         effect @ "Sunny Day" smatch if
         "^[y^[oThe sunlight is strong"
         then
         then
         then
         then
 }cat bid @ notify_watchers
 then
then
{ "A1" "A2" "B1" "B2" }list foreach swap pop pos !
loc @ { "@battle/" BID @ "/position/" pos @ }cat getprop target !
target @ not if continue then
pos @ bid @ placed_abilities
loc @ { "@battle/" BID @ "/recycle/" pos @ }cat target @ "holding" get setprop
repeat
 
;

: 4movesverifier
(make sure the current moveset is valid, if not adjust)
var! BID
var trueid
var omove
var slot
var tmove

var pos_list
var pos
{ "A1" "B1" "A2" "B2" }list pos_list !
pos_list @ foreach pos ! pop

loc @ { "@battle/" BID @ "/position/" POS @ }cat getprop id !
id @ not if continue then

        LOC @ { "@battle/" BID @ "/movesets/" ID @ }cat getprop var! moveset
       POKESTORE { "@pokemon/" id @ fid "/@temp/movesets/" }cat propdir? not if (make sure moves are current and replace if not)
        { "A" "B" "C" "D" }list foreach slot ! pop
                         id @ { "movesets/" moveset @ "/" slot @ }cat fget tmove ! 
                         loc @ { "@battle/" BID @ "/movesets/" ID @ "/" slot @ }cat getprop omove !
                         tmove @ not if "nothing" tmove ! then
                         omove @ not if "nothing" omove ! then
                         
                         tmove @ omove @ smatch not if
                                 omove @ "nothing" smatch not if
                                 (POKESTORE { "@pokemon/" id @ fid "/@RP/movesknown/" omove @ "/pp" }cat 
                                   id @ { "movesknown/" omove @ "/pp" }cat fget setprop )
                                 POKESTORE { "@pokemon/" id @ fid "/@long/movesknown/" omove @ }cat remove_prop
                                 then
                                 POKESTORE { "@pokemon/" id @ fid "/@long/movesknown/" tmove @ }cat
                                  POKESTORE { "@pokemon/" id @ fid "/@rp/movesknown/" tmove @ }cat getprop setprop
                                 (POKESTORE { "@pokemon/" id @ fid "/@long/movesknown/" tmove @ "/pp" }cat
                                  POKESTORE { "@pokemon/" id @ fid "/@rp/movesknown/" tmove @ "/pp" }cat getprop setprop   )
                                 LOC @ { "@battle/" BID @ "/movesets/" ID @ "/" slot @ }cat tmove @ setprop
                         then
                         

        repeat
        then


repeat


;
 
$libdef battlelooper
: battlelooper  (this is used to have the program loop as needed to have the battle run continuously.)
var! BID
 
begin
 
loc @ { "@battle/" BID @ }cat propdir? not if
exit
then

( Don't let this run 
BID @ levelupmoves
loc @ { "@battle/" BID @ "/levelmovepending/" }cat propdir? if
exit
then
)
begin
BID @ fainted_pokemon
loc @ { "@battle/" BID @ "/fainted/" }Cat propdir? if
exit
then
loc @ { "@battle/" BID @ "/needtoswitch" }cat propdir? not if break then
repeat

loc @ { "@battle/" BID @ }cat propdir? not if exit then

loc @ { "@battle/" BID @ "/tempvalues/displayed" }cat getprop not if
loc @ { "@battle/" BID @ "/Begin Position/" }cat remove_prop
loc @ { "@battle/" BID @ "/declare/switch/" }cat remove_prop
loc @ { "@battle/" BID @ "/declare/finished/" }cat remove_prop
loc @ { "@battle/" BID @ "/turn" }cat over over getprop 1 + setprop
loc @ { "@battle/" BID @ "/tempvalues/HurtThisTurn" }cat remove_prop
loc @ { "@battle/" BID @ "/tempvalues/storedtemp" }cat remove_prop
loc @ { "@battle/" BID @ "/snatch/" }cat remove_prop
loc @ { "@battle/" BID @ "/specialbattle" }cat getprop if
        "^[o^[M^[r><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>"  bid @ notify_watchers
        "^[o^[M^[r<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><"  bid @ notify_watchers
        "^[o^[M^[r><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>"  bid @ notify_watchers
        "^[o^[M^[r<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><"  bid @ notify_watchers
        "^[o^[M^[r><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>"  bid @ notify_watchers
        "^[o^[M^[r<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><"  bid @ notify_watchers
        "^[o^[M^[r><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>"  bid @ notify_watchers
        "^[o^[M^[r<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><"  bid @ notify_watchers
        loc @ { "@battle/" BID @ "/specialbattle" }cat remove_prop
then

BID @ combatdisplay
loc @ { "@battle/" BID @ "/tempvalues/displayed" }cat 1 setprop
then
 
loc @ { "@battle/" BID @ "/firstturn" }cat getprop not if
BID @ firstturn

loc @ { "@battle/" BID @ "/firstturn" }cat "taken" setprop
then

loc @ { "@battle/" BID @ "/4moves" }cat getprop if
BID @ 4movesverifier
then
 
BID @ battle_handler
loc @ { "@battle/" BID @ }Cat propdir? not if exit then
battle_ready not if break then
 
 
 
 
 
repeat
 
; PUBLIC battlelooper
 
 
: watchingfight  (this is what is used to allow someone to watch a battle)
var! who
var BID
 
  who @ pmatch who !
  who @ not who @ #-2 = or if "I don't know who that is!" tellme exit then
who @ "@battle/battleID" getprop BID !
 
BID @ not if
"^[o^[rThere isn't a battle by that ID right now." tellme
exit
then
 
loc @ { "@battle/" BID @ }cat propdir? not if
"^[o^[rThere isn't a battle by that ID right now." tellme
exit
then
 
loc @ { "@battle/" BID @ "/battling/" me @ }cat getprop if
"^[o^[rYou are in this battle, you are already watching it." tellme
exit
then
 
loc @ { "@battle/" BID @ "/watching/" me @ }cat getprop if
"^[o^[rYou are already watching this battle, use +unwatch to stop watching." tellme
exit
then
{ "^[o^[c" me @ name "^[y is now watching ^[c" who @ name "'s ^[ybattle." }cat bid @ notify_watchers
loc @ { "@battle/" BID @ "/watching/" me @ }cat 1 setprop
{ "^[o^[rYou are now watching ^[y" who @ name "'s ^[rbattle." }cat tellme
 
me @ { "@temp/JustMeWatching/" me @ }cat BID @ setprop
bid @ combatdisplay
;
 
: unwatchfight  (This is used to remove someone from watching a fight)
var! who
var BID
 
  who @ pmatch who !
  who @ not who @ #-2 = or if "I don't know who that is!" tellme exit then
who @ "@battle/battleID" getprop BID !
 
BID @ not if
"^[o^[rThere isn't a battle by that ID right now." tellme
exit
then
 
loc @ { "@battle/" BID @ }cat propdir? not if
"^[o^[rThere isn't a battle by that ID right now." tellme
exit
then
 
loc @ { "@battle/" BID @ "/battling/" me @ }cat getprop if
"^[o^[rYou are in this battle, you can't unwatch it." tellme
exit
then
 
loc @ { "@battle/" BID @ "/watching/" me @ }cat getprop if
loc @ { "@battle/" BID @ "/watching/" me @ }cat remove_prop
{ "^[o^[rYou are no longer watching ^[y" who @ name "'s ^[rbattle now." }cat tellme
{ "^[o^[c" me @ name "^[y is no longer watching ^[c" who @ name "'s ^[ybattle." }cat bid @ notify_watchers
exit
then
 
loc @ { "@battle/" BID @ "/watching/" me @ }cat getprop not if
"^[o^[rYou wern't watching that battle to begin with." tellme
exit
then
 
;
 
: ItemUseableHandler ( s s - bool )  (this is to check if the item is usable)
cap var! item var! who
var effect
var stat
var temp
var what
var total
1 var! useable
 
who @ { "items/" item @ "/UseEffect" }cat get ":" explode_array foreach effect ! pop
 
 
    effect @ "Heal *" smatch if
      effect @ " " split swap pop temp !
            temp @ "Poisoned" smatch if
                who @ "status/Toxic" get if
                continue
          then
          then
      
      who @ { "status/" temp @ }cat get if
 
      else
      who @ { "status/statmods/" temp @ }cat get if
 
      else
            { "^[o^[yThere's no ^[w" temp @ " ^[ycondition to remove!" }cat tellme
            0 useable !
      then
    then
    continue
  then
 
  effect @ "Cure/*" smatch if
  who @ "status/fainted" get
  item @ "*revive" smatch not
  item @ "sacred fire" smatch not and and
  if
  { "^[o^[yThis pokemon is fainted!  You need to revive it first!" }cat tellme
  0 useable !
  then
  continue
  then
 
  effect @ "Cure*" smatch if
    who @ "status/fainted" get
    item @ "*revive" smatch not
    item @ "sacred fire" smatch not and and
    if
    { "^[o^[yThis pokemon is fainted!  You need to revive it first!" }cat tellme
    0 useable !
    then
    continue
    then
  
  
      effect @ "HealAll" smatch if
        0 temp !
        who @ "status/Asleep" get if 1 temp ! then
        who @ "status/Burned" get if 1 temp ! then
        who @ "status/Frozen" get if 1 temp ! then
        who @ "status/Paralyzed" get if 1 temp ! then
        who @ "status/Poisoned" get if 1 temp ! then
        who @ "status/Toxic" get if 1 temp ! then
        who @ "status/statmods/confused" get if 1 temp ! then
        temp @ not if "^[o^[yYou don't need to use this item right now!"  tellme 0 useable ! then
 
        continue
    then
 
  
   effect @ "FullRestore" smatch if
         0 temp !
         who @ "status/Asleep" get if 1 temp ! then
         who @ "status/Burned" get if 1 temp ! then
         who @ "status/Frozen" get if 1 temp ! then
         who @ "status/Paralyzed" get if 1 temp ! then
         who @ "status/Poisoned" get if 1 temp !  then
         who @ "status/Toxic" get if 1 temp ! then
         who @ "status/statmods/confused" get if 1 temp ! then
         who @ "status/hp" get atoi who @ "MaxHP" Calculate < if
        1 temp !
        who @ "status/fainted" get if 0 temp ! then
        then
         temp @ not if "^[o^[yYou don't need to use this item right now!" tellme 0 useable ! then
   continue
   then
 
repeat
useable @
;

: 4movesdisplay
var! move2letter
var! move1letter
var! BID
var! who

loc @ { "@battle/" BID @ "/movesets/" who @ }cat getprop var! moveset
who @ { "movesets/" moveset @ "/" move1letter @ }cat fget cap var! move1 
who @ { "movesets/" moveset @ "/" move2letter @ }cat fget cap var! move2 

var m1element
var m1class
var m1ppmax
var m1ppcur
var m1power
var m1accuracy
var m2element
var m2class
var m2ppmax
var m2ppcur
var m2power
var m2accuracy

var ppup
move1 @ not if
"None" move1 !
" " m1element !
" " m1class !
"0" m1ppmax !
"0" m1ppcur !
"0" m1power !
"0" m1accuracy !
else

POKEDEX { "/moves/" move1 @ "/Type" }cat     getprop m1element !
POKEDEX { "/moves/" move1 @ "/Class" }cat    getprop m1class !
POKEDEX { "/moves/" move1 @ "/power" }cat    getprop m1power !
POKEDEX { "/moves/" move1 @ "/accuracy" }cat getprop m1accuracy !
who @ { "/movesknown/" move1 @ }cat fget atoi 1 - ppup !
POKEDEX { "/moves/" move1 @ "/pp" }cat getprop atoi 5 ppup @ + * 5 /
                                                    stringify m1ppmax !
who @ { "/movesknown/" move1 @ "/pp"}cat    fget m1ppcur !
then

move2 @ not if
"None" move2 !
" " m2element !
" " m2class !
"0" m2ppmax !
"0" m2ppcur !
"0" m2power !
"0" m2accuracy !
else
POKEDEX { "/moves/" move2 @ "/Type" }cat     getprop m2element !
POKEDEX { "/moves/" move2 @ "/Class" }cat    getprop m2class !
POKEDEX { "/moves/" move2 @ "/power" }cat    getprop m2power !
POKEDEX { "/moves/" move2 @ "/accuracy" }cat getprop m2accuracy !
who @ { "/movesknown/" move2 @ }cat fget atoi 1 - ppup !
POKEDEX { "/moves/" move2 @ "/pp" }cat getprop atoi 5 ppup @ + * 5 /
                                                     stringify m2ppmax !
who @ { "/movesknown/" move2 @ "/pp"}cat     fget m2ppcur !

then

{ "^[o^[w/-----------------" move1letter @ "------------------\\ /-----------------" move2letter @ "------------------\\" }cat tellme
{ "^[o^[w|  ^[g" move1 @ 13 " " padr "                     ^[w| |  ^[g" move2 @ 13 " " padr "                     ^[w|" }cat tellme
{ "^[o^[w|  ^[g" m1element @ 14 " " padr "  " m1class @ 14 " " padr " ^[w   | |  ^[g" m2element @ 14 " " padr "  " m2class @ 14 " " padr "^[w    |" }cat tellme
{ "^[o^[w|  ^[gPP:  ^[w" m1ppcur @ 2 "0" padl "^[g/^[w" m1ppmax @ 2 "0" padl "                        | |  ^[gPP:  ^[w" m2ppcur @ 2 "0" padl "^[g/^[w" m2ppmax @ 2 "0" padl "                        |" }cat tellme
{ "^[o^[w|  ^[gPower: ^[w" m1power @ 3 " " padr "^[g      ^[gAccuracy: ^[w" m1accuracy @ 3 " " padr "     ^[w| |  ^[gPower: ^[w" m2power @ 3 " " padr "^[g      Accuracy: ^[w" m2accuracy @ 3 " " padr "     ^[w|" }cat tellme
{ "^[o^[w\\------------------------------------/ \\------------------------------------/" }cat tellme

;
 
: attackhandler  (this is used for the input of attacks. its declare function)

verifycontrol

me @ "@battle/control" getprop not if
"^[o^[rWe aren't waiting for you to command right now." tellme
exit then
 
var pos
me @ "@battle/control" getprop pos !
 
 
var bid
me @ "@battle/BattleID" getprop bid !
 
var who
var team
var oppteam
pos @ "A*" smatch if
"A" team !
"B" oppteam !
then
 
pos @ "B*" smatch if
"B" team !
"A" oppteam !
then
var move
loc @ { "@battle/" BID @ "/Position/" pos @ }cat getprop who !

(make sure the current moveset is valid, if not adjust)

var trueid
var omove
var slot
var tmove
who @ id !
loc @ { "@battle/" BID @ "/4moves" }cat getprop if
        LOC @ { "@battle/" BID @ "/movesets/" ID @ }cat getprop var! moveset
       POKESTORE { "@pokemon/" id @ fid "/@temp/movesets/" }cat propdir? not if (make sure moves are current and replace if not)
        { "A" "B" "C" "D" }list foreach slot ! pop
                         id @ { "movesets/" moveset @ "/" slot @ }cat fget tmove ! 
                         loc @ { "@battle/" BID @ "/movesets/" ID @ "/" slot @ }cat getprop omove !
                         tmove @ not if "nothing" tmove ! then
                         omove @ not if "nothing" omove ! then
                         
                         tmove @ omove @ smatch not if
                                 omove @ "nothing" smatch not if
                                 (POKESTORE { "@pokemon/" id @ fid "/@RP/movesknown/" omove @ "/pp" }cat 
                                   id @ { "movesknown/" omove @ "/pp" }cat fget setprop )
                                 POKESTORE { "@pokemon/" id @ fid "/@long/movesknown/" omove @ }cat remove_prop
                                 then
                                 POKESTORE { "@pokemon/" id @ fid "/@long/movesknown/" tmove @ }cat
                                  POKESTORE { "@pokemon/" id @ fid "/@rp/movesknown/" tmove @ }cat getprop setprop
                                 (POKESTORE { "@pokemon/" id @ fid "/@long/movesknown/" tmove @ "/pp" }cat
                                  POKESTORE { "@pokemon/" id @ fid "/@rp/movesknown/" tmove @ "/pp" }cat getprop setprop   )
                                 LOC @ { "@battle/" BID @ "/movesets/" ID @ "/" slot @ }cat tmove @ setprop
                         then
                         

        repeat
        then
then 



 
        var totalmoves
        who @ "status/statmods/encore/move" get if
        { "^[o^[c" who @ id_name "^[r is under the effect of Encore, picking ^[c" who @ "status/statmods/encore/move" get "^[r." }cat tellme
        who @ "status/statmods/encore/move" get arg !
        { arg @ }list
        else
        who @ "status/statmods/choice item/move" get loc @ { "@battle/" BID @ "/MagicRoom" }cat getprop not and if
                who @ "status/statmods/choice item/struggle?" get not if
                        who @  { "movesknown/" who @ "status/statmods/choice item/move" get "/pp" }cat fget not if
                        who @ "status/statmods/choice item/struggle?" "yes" setto
                         { "^[o^[c" who @ id_name "^[r is under the effect of ^[c" who @ "holding" get "^[r, they are also out of PP in ^[c" who @ "status/statmods/choice item/move" get "^[r, they must struggle." }cat tellme
                        "struggle" arg ! 
                        else
                        
                        { "^[o^[c" who @ id_name "^[r is under the effect of ^[c" who @ "holding" get "^[r, picking ^[c" who @ "status/statmods/choice item/move" get "^[r." }cat tellme
                        who @ "status/statmods/choice item/move" get arg !
                        then
                else
                        who @  { "movesknown/" who @ "status/statmods/choice item/move" get "/pp" }cat fget not if
                        { "^[o^[c" who @ id_name "^[r is under the effect of ^[c" who @ "holding" get "^[r, they are also out of PP in ^[c" who @ "status/statmods/choice item/move" get "^[r, they must struggle." }cat tellme
                        "struggle" arg ! 
                        else
                        { who @ "movesknown" fgetvals foreach pop cap
                                
                repeat }list 
                        then
                then
                { arg @ }list
        else
        
                        { who @ "movesknown" fgetvals foreach pop cap
        
                repeat }list 
        then then

                totalmoves !

                {  totalmoves @ foreach swap pop move !
                  who @ { "status/statmods/imprisoned/move/" move @ }cat get if continue then
                  who @ "status/statmods/disabled/move" get stringify move @ smatch if continue then
                  who @ "status/statmods/healblock" get if
                        POKEDEX { "moves/" move @ "effects" }cat getprop stringify "*cure*"  smatch if
                        continue
                        then
                        then
                  who @ "status/statmods/torment" get if
                  who @ "status/statmods/MoveContinued/MoveName" get stringify move @ smatch if
                  continue
                  then
                  then

                  who @ "status/statmods/taunted" get if
                        POKEDEX { "moves/" move @ "/power" }cat getprop atoi not if
                        continue
                        then
                then
                who @ { "/movesknown/" move @ "/pp" }cat fget atoi not if continue then
                move @
                repeat
                }list var! validmoves

                arg @ not if
                loc @ { "@battle/" BID @ "/4moves" }cat getprop if
                 who @ bid @ "A" "B" 4movesdisplay
                 who @ bid @ "C" "D" 4movesdisplay

                else

                { "^[o^[g-- ^[cMove List ^[g" "" 65 "-" padr }cat tellme

                 0 var! count
                 0 var! token
                 validmoves @ foreach swap pop move !
                    1 token !
                    count @ 1 + 4 % count !
                    count @ 1 = if
                      { "^[o^[g| ^[w"
                    else
                      "^[g | ^[w"
                    then
                    move @ 13 " " padr "^[y:^[w"
                    who @ { "/movesknown/" move @ "/pp" }cat fget 2 " " padl
                    count @ 0 = if
                      "  ^[g|" }cat tellme
                      0 token !
                    then
                  repeat
                  count @ if " ^[g| " "" 16 " " padr count @ 1 + 4 % count ! then
                  count @ if " ^[g| " "" 16 " " padr count @ 1 + 4 % count ! then
                  count @ if " ^[g| " "" 16 " " padr count @ 1 + 4 % count ! then
                  count @ not token @ and if "  ^[g|" }cat tellme then

                  
                  { "^[o^[g" "" 78 "-" padr }cat tellme
        then 
        validmoves @ not if "^[r^[oOut of moves, can only 'Struggle'" tellme then
        "^[o^[rPick an attack, use '.abort' to cancel:" "Battle" pretty tellme
        read arg !
        arg @ ".abort" smatch if "^[r^[oAborting" tellme exit then

then

arg @ strip arg !

arg @ "A" smatch if who @ { "movesets/" moveset @ "/A" }cat fget arg ! then
arg @ "B" smatch if who @ { "movesets/" moveset @ "/B" }cat fget arg ! then
arg @ "C" smatch if who @ { "movesets/" moveset @ "/C" }cat fget arg ! then
arg @ "D" smatch if who @ { "movesets/" moveset @ "/D" }cat fget arg ! then
(arg @ "skip" smatch if
 loc @ { "@battle/" BID @ "/Declare/" pos @ }cat { "Skip" }cat setprop
 me @ "@battle/control" remove_prop
 BID @ pos @ checkothers
 BID @ battlelooper
exit then
)

validmoves @ not if "struggle" arg ! then
 
arg @ "struggle" smatch
validmoves @ and if
"^[o^[rYou can't use struggle while you have other moves available. Aborting." tellme
exit
then
 
who @ { "/movesknown/" arg @ "/pp" }cat fget not
arg @ "struggle" smatch not and
if
POKEDEX { "moves/" arg @ }cat propdir? if
        { "^[o^[rThere isn't any PP in the move ^[c" arg @ cap "^[r. Aborting."}cat tellme
        else
        { "^[o^[rThere is no move called ^[c" arg @ cap "^[r. Aborting."}cat tellme
then
exit
then

validmoves @ arg @ array_findval array_count not 
arg @ "struggle" smatch not and
if
{ "^[o^[rThey don't currently know the move ^[c" arg @ cap "^[r. Aborting."}cat tellme
exit
then
 
 
who @ { "status/statmods/imprisoned/move/" arg @ }cat get if
{ "^[o^[c" arg @ cap "^[r is imprisoned. Aborting."}cat tellme
exit
then
 
who @ "status/statmods/disabled/move" get stringify arg @ smatch if
{ "^[o^[c" arg @ cap "^[r is disabled. Aborting."}cat tellme
exit
then
 
who @ "status/statmods/healblock" get if
POKEDEX { "moves/" arg @ "effects" }cat getprop stringify "*cure*"  smatch if
{ "^[o^[c" arg @ cap "^[r is heal blocked. Aborting."}cat tellme
exit
then
then
 
who @ "status/statmods/torment" get if
  who @ "status/statmods/MoveContinued/MoveName" get stringify arg @ smatch if
  { "^[o^[c" arg @ cap "^[r is tormented. Aborting."}cat tellme
  exit
then
then
 
who @ "status/statmods/taunted" get if
POKEDEX { "moves/" arg @ "/power" }cat getprop atoi not if
{ "^[o^[c" arg @ cap "^[r is taunted. Aborting."}cat tellme
exit
then
then
 
 who @ "holding" get "choice band" smatch 
 who @ "holding" get "choice scarf" smatch or
 who @ "holding" get "choice specs" smatch or
 who @ "status/statmods/choice item/move" get not and if
        who @ "status/statmods/choice item/move" arg @ setto
then

(DON'T FORGET TO CHECK THE TARGET AND SET IF NESSARY)
var mimic
arg @ "mimic" smatch if
who @ "status/statmods/mimic/move" get if
1 mimic !
who @ "status/statmods/mimic/move" get arg !
then then
var target
 
POKEDEX { "/moves/" arg @ "/target" }cat getprop "random-enemy" smatch if
        loc @ { "@battle/" BID @ "/position/" oppteam @ "1" }cat getprop
        loc @ { "@battle/" BID @ "/position/" oppteam @ "2" }cat getprop and if
                loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat { oppteam @ random 2 % 1 + }cat setprop
        else
                loc @ { "@battle/" BID @ "/position/" oppteam @ "1" }cat getprop if
                loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat { oppteam @ "1" }cat setprop
                else
                loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat { oppteam @ "2" }cat setprop
                then
        then
then
 
POKEDEX { "/moves/" arg @ "/target" }cat getprop "team-member" smatch if
 var partner
 pos @ "*1" smatch if
  { pos @ 1 1 midstr "2" }cat partner !
 else
  { pos @ 1 1 midstr "1" }cat partner !
 then
 
 loc @ { "@battle/" BID @ "/position/" partner @ }cat getprop not if
  loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat pos @ setprop
 else
 begin
 loc @ { "@battle/" BID @ "/position/" }Cat propdir? not if exit then
    "^[r^[oWhich target will you aim for?" "Battle" pretty tellme
    { "^[o^[r" pos @ 1 1 midstr  "1: ^[c" loc @ { "@battle/" BID @ "/Position/" pos @ 1 1 midstr "1" }cat getprop id_name }cat "Battle" pretty tellme
    { "^[o^[r" pos @ 1 1 midstr  "2: ^[c" loc @ { "@battle/" BID @ "/Position/" pos @ 1 1 midstr "2" }cat getprop id_name }cat "Battle" pretty tellme
 
    read target !
    loc @ { "@battle/" BID @ "/Position/" target @ }cat getprop not if
    { "^[o^[rNot a valid target! Try again!" }cat "Battle" pretty tellme
    else
    loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat target @ setprop
    break
    then
   repeat
 
 then
then
 
POKEDEX { "/moves/" arg @ "/target" }cat getprop "enemy" smatch if
 
pos @ "*1" smatch if
"2" partner !
else
"1" partner !
then
 begin
  loc @ { "@battle/" BID @ "/Position/" oppteam @ "1" }cat getprop
  loc @ { "@battle/" BID @ "/Position/" oppteam @ "2" }cat getprop not
  loc @ { "@battle/" BID @ "/Position/" team @ partner @ }cat getprop not and and if
  loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat { oppteam @ "1" }Cat setprop break then
 
  loc @ { "@battle/" BID @ "/Position/" oppteam @ "1" }cat getprop not
  loc @ { "@battle/" BID @ "/Position/" oppteam @ "2" }cat getprop
  loc @ { "@battle/" BID @ "/Position/" team @ partner @ }cat getprop not and and if
  loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat { oppteam @ "2" }Cat setprop break then
 
  begin
   "^[r^[oWhich target will you aim for?" "Battle" pretty tellme
   loc @ { "@battle/" BID @ "/Position/" oppteam @ "1" }cat getprop if
   { "^[o^[r" oppteam @ "1: ^[c" loc @ { "@battle/" BID @ "/Position/" oppteam @ "1"}cat getprop id_name }cat "Battle" pretty tellme
   then
   loc @ { "@battle/" BID @ "/Position/" oppteam @ "2" }cat getprop if
   { "^[o^[r" oppteam @ "2: ^[c" loc @ { "@battle/" BID @ "/Position/" oppteam @ "2"}cat getprop id_name }cat "Battle" pretty tellme
   then
   loc @ { "@battle/" BID @ "/Position/" team @ partner @ }cat getprop if
   { "^[o^[r" team @ partner @ ": ^[c" loc @ { "@battle/" BID @ "/Position/" team @ partner @ }cat getprop id_name }cat "Battle" pretty tellme
   then
   read target !
   loc @ { "@battle/" BID @ "/Position/" target @ }cat getprop not
   pos @ target @ smatch or
   if
   { "^[o^[rNot a valid target! Try again!" }cat "Battle" pretty tellme
   else
   loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat target @ setprop
   break
   then
  repeat
  break
 repeat
then
 
 mimic @ if
 "mimic" arg !
 then
 
loc @ { "@battle/" BID @ "/Declare/" pos @ }cat { "Attack "  arg @ }cat setprop
me @ "@battle/control" remove_prop
 
 
BID @ pos @ checkothers
BID @ battlelooper
;
 
 
: itemhandler2  (used for picking an item)
me @ "@battle/control" getprop not if
 "^[o^[rWe aren't waiting for you to command right now." tellme
exit then
 
var target
var pos
me @ "@battle/control" getprop pos !
 
 
var bid
me @ "@battle/BattleID" getprop bid !
 
var who
var team
 
me @ "@RP/ID" getprop who !
 
pos @ "A*" smatch if
"A" team !
then
 
pos @ "B*" smatch if
"B" team !
then
 
var count
var token
 
arg @ not if
{ "^[o^[g-- ^[cInventory ^[g" "" 65 "-" padr }cat tellme
 var item
 var amount
 0 count !
 0 token !
 who @ "inventory" getvals foreach stringify amount ! cap item !
    POKEDEX { "/items/" item @ "/battle" }cat getprop not if continue then
   1 token !
   count @ 1 + 3 % count !
   count @ 1 = if
     { "^[o^[g| ^[w"
   else
     "^[g | ^[w"
   then
   item @ 18 " " padr "^[y:^[w"
   amount @ 3 " " padl
   count @ 0 = if
     " ^[g| |" }cat tellme
     0 token !
   then
 repeat
 count @ if " ^[g| " "" 22 " " padr count @ 1 + 3 % count ! then
 count @ if " ^[g| " "" 22 " " padr count @ 1 + 3 % count ! then
 count @ not token @ and if " ^[g| |" }cat tellme then
 { "^[o^[g" "" 78 "-" padr }cat tellme
 "^[o^[rPick an item, use '.abort' to cancel:" "Battle" pretty tellme
 read arg !
 arg @ ".abort" smatch if "^[r^[oAborting" tellme exit then
 
then
 
arg @ strip arg !
arg @ item !
{ me @ "inventory" getvals foreach pop cap repeat }list var! totalitems
me @ { "inventory/" item @ }cat get atoi 0 <=
totalitems @ arg @ array_findval array_count not or
if
{ "^[o^[rYou don't have a ^[c" item @ cap ". Aborting."}cat tellme
exit
then
 
POKEDEX { "/items/" item @ "/battle" }cat getprop not if
"^[o^[rThis can't be used in battle!" "Battle" pretty tellme
exit then
 
POKEDEX { "/items/" item @ "/capture" }cat getprop if
loc @ { "@battle/" BID @ "/AItype" }cat getprop "wild" smatch not if
"^[o^[rThis isn't a wild battle! No balls!" "Battle" pretty tellme
exit
then
 var count
 var count2
 var foundspot
 var maxbox
 var lastbox
 1 6 1 for count !
  who @ { "slot/" count @ }cat get not if
   1 foundspot !
   break
  then
 repeat
 
 foundspot @ not if
 
  POKESTORE { "@pokemon/" who @ "/@rp/lastbox" }cat getprop not if
  POKESTORE { "@pokemon/" who @ "/@rp/lastbox" }cat 1 setprop then
  POKESTORE { "@pokemon/" who @ "/@rp/maxbox" }cat getprop not if
  POKESTORE { "@pokemon/" who @ "/@rp/maxbox" }cat 1 setprop then
  POKESTORE { "@pokemon/" who @ "/@rp/maxbox" }cat getprop maxbox !
  POKESTORE { "@pokemon/" who @ "/@rp/lastbox" }cat getprop lastbox !
 
  var count2
 
  1 30 1 for count2 !
  PC { "@pokeStorage/" who @ "/@RP/box" lastbox @ "/" count2 @ }cat getprop not if
   1 foundspot !
   break
   then
  repeat
  foundspot @ not if
   1 maxbox @ 1 for count !
    1 30 1 for count2 !
    PC { "@pokeStorage/" who @ "/@RP/box" count @ "/" count2 @ }cat getprop not if
     1 foundspot !
     break
     then
    repeat
   repeat
  then
 then
foundspot @ not if "^[o^[rYou have no space for another pokemon." tellme exit then
 
 team @ "A" smatch if
  loc @ { "@battle/" BID @ "/Position/B1" }Cat getprop
  loc @ { "@battle/" BID @ "/Position/B2" }Cat getprop not and if
  loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat "B1" setprop then
 
  loc @ { "@battle/" BID @ "/Position/B2" }Cat getprop
  loc @ { "@battle/" BID @ "/Position/B1" }Cat getprop not and if
  loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat "B2" setprop then
 
  loc @ { "@battle/" BID @ "/Position/B1" }Cat getprop
  loc @ { "@battle/" BID @ "/Position/B2" }Cat getprop and if
 
 
  begin
  "^[r^[oWhich target will you aim for?" "Battle" pretty tellme
  { "^[o^[rB1: ^[c" loc @ { "@battle/" BID @ "/Position/B1"}cat getprop id_name }cat "Battle" pretty tellme
  { "^[o^[rB2: ^[c" loc @ { "@battle/" BID @ "/Position/B2"}cat getprop id_name }cat "Battle" pretty tellme
 
  read target !
  target @ "B1" smatch
  target @ "B2" smatch or if
 
  loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat target @ setprop
 
  break
  else
  "^[o^[rNot a valid target! Try again!" }cat "Battle" pretty tellme
  then
  repeat
  then
 
 else
 
  loc @ { "@battle/" BID @ "/Position/A1" }Cat getprop
  loc @ { "@battle/" BID @ "/Position/A2" }Cat getprop not and if
  loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat "A1" setprop then
 
  loc @ { "@battle/" BID @ "/Position/A2" }Cat getprop
  loc @ { "@battle/" BID @ "/Position/A1" }Cat getprop not and if
  loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat "A2" setprop then
 
  loc @ { "@battle/" BID @ "/Position/A1" }Cat getprop
  loc @ { "@battle/" BID @ "/Position/A2" }Cat getprop and if
 
  begin
  "^[r^[oWhich target will you aim for?" "Battle" pretty tellme
  { "^[o^[rA1: ^[c" loc @ { "@battle/" BID @ "/Position/A1"}cat getprop id_name }cat "Battle" pretty tellme
  { "^[o^[rA2: ^[c" loc @ { "@battle/" BID @ "/Position/A2"}cat getprop id_name }cat "Battle" pretty tellme
 
  read target !
  target @ "A1" smatch
  target @ "A2" smatch or if
 
  loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat target @ setprop
  break
  else
  "^[o^[rNot a valid target! Try again!" }cat "Battle" pretty tellme
  then
  repeat
  then
 then
 
 
loc @ { "@battle/" BID @ "/Declare/" pos @ }cat { "Item "  item @ }cat setprop
loc @ { "@battle/" BID @ "/Declare/" pos @ "/itemuser" }cat me @ setprop
else
 
 var id
 var counter
 var notvalid
 var maxhp
 var percent
 var hpcolor
 var othercont
 var what
 
           var trainer1
           var trainer2
           var fusionnudge
 
           loc @ { "@battle/" BID @ "/teams/" team @ "/A" }cat getprop trainer1 !
           loc @ { "@battle/" BID @ "/teams/" team @ "/B" }cat getprop trainer2 !
 
           trainer1 @ if 1 fusionnudge ! then
           trainer2 @ if fusionnudge @ 1 + fusionnudge !
           then
 
 
 { "^[y^[o------------------------------------------------------------------------" }cat tellme
1 loc @ { "@battle/" BID @ "/teams/" team @ "/" }cat array_get_propvals array_count 1 for id !
 
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
 
 0 notvalid !
 loc @ { "@battle/" BID @ "/position/" team @ "1" }cat getprop stringify id @ smatch if 1 notvalid ! then
 loc @ { "@battle/" BID @ "/position/" team @ "2" }cat getprop stringify id @ smatch if 1 notvalid ! then
 loc @ { "@battle/" BID @ "/declare/switch/" id @ }Cat getprop if 2 notvalid ! then
 id @ "status/hp" get not if 3 notvalid ! then
 id @ "status/fainted" get if 3 notvalid ! then
 id @ "egg?" get if 4 notvalid ! then
 
 { "^[r^[o" counter @ ". "
 id @ id_name 12 " " padr
 id @ { "/pokemon/" id @ "species" fget "/name" }cat fget dup not if pop "??????????" then 10 " " padr
 " "
 id @ "gender" fget "M*" smatch if
 "^[o^[c" { id @ "gender" fget 1 1 midstr }cat
 then
 
 id @ "gender" fget "F*" smatch if
 "^[o^[r" { id @ "gender" fget 1 1 midstr }cat
 then
 
 id @ "gender" fget "N*" smatch id @ "gender" fget "O*" smatch or if
 "^[o^[m" { id @ "gender" fget 1 1 midstr }cat
 then
 " "
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
othercont @ me @ = not if
{ "  ^[g<" othercont @ name ">" }cat
then
 
 }cat tellme
 repeat
 { "^[y^[o------------------------------------------------------------------------" }cat tellme
 var item
 arg @ item !
 
 "^[o^[rUse item on whom?" "Battle" pretty tellme
           read arg !
                arg @ strip arg !
 
                arg @ "A" smatch
                arg @ "B" smatch or not if
                arg @ atoi arg ! then
 
                arg @ not if
 
 "^[o^[rInvalid pokemon position.  Aborting." "Battle" pretty tellme
 exit
 then
 
 loc @ { "@battle/" BID @ "/teams/" team @ "/" arg @ }cat getprop not if
 "^[o^[rThere isn't a pokemon there. Aborting." "Battle" pretty tellme
 exit
 then
 loc @ { "@battle/" BID @ "/teams/" team @ "/" arg @ }cat getprop "status/statmods/embargo" get if
 "^[o^[rThat pokemon is currently embargoed. Aborting." "Battle" pretty tellme
 exit
 then
loc @ { "@battle/" BID @ "/teams/" team @ "/" arg @ }cat getprop item @ ItemUseableHandler not if
loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat remove_prop
exit then
 loc @ { "@battle/" BID @ "/teams/" team @ "/" arg @ }cat getprop who !
POKEDEX { "items/" item @ "/UseEffect" }cat getprop "PP-one*" smatch if
        POKEDEX { "items/" item @ "/UseEffect" }cat getprop " " split swap pop atoi temp !
 
        { "^[o^[g-- ^[cMove List ^[g" "" 65 "-" padr }cat tellme
        var move
        var totalmoves
          0 var! count
          0 var! token
          who @ "movesknown" fgetvals foreach pop cap move !
            1 token !
            totalmoves @ 1 + totalmoves !
            count @ 1 + 4 % count !
            count @ 1 = if
              { "^[o^[g| ^[w"
            else
              "^[g | ^[w"
            then
            move @ 13 " " padr "^[y:^[w"
            who @ { "/movesknown/" move @ "/pp" }cat fget 2 " " padl
            count @ 0 = if
              "  ^[g|" }cat tellme
              0 token !
            then
          repeat
          count @ if " ^[g| " "" 16 " " padr count @ 1 + 4 % count ! then
          count @ if " ^[g| " "" 16 " " padr count @ 1 + 4 % count ! then
          count @ if " ^[g| " "" 16 " " padr count @ 1 + 4 % count ! then
  count @ not token @ and if "  ^[g|" }cat tellme  then
 
    "^[o^[wWhat move to restore energy in?" "Item" pretty tellme
    read strip cap what !
    what @ ".abort" smatch if "^[rAborted" tellme loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat remove_prop exit then
    loc @ { "@battle/" BID @ "/teams/" team @ "/" arg @ }cat getprop { "movesknown/" what @ }cat fget dup not if pop "^[o^[rTarget doesn't know that move!" "Item" pretty tellme loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat remove_prop exit then
        loc @ { "@battle/" BID @ "/Declare/" pos @ "/attackpp" }cat what @ setprop
then
 
loc @ { "@battle/" BID @ "/Declare/" pos @ }cat { "Item "  item @ }cat setprop
loc @ { "@battle/" BID @ "/declare/" pos @ "/target" }cat arg @ setprop
loc @ { "@battle/" BID @ "/Declare/" pos @ "/itemuser" }cat me @ setprop
 
then
 
me @ "@battle/control" remove_prop
BID @ pos @ checkothers
BID @ battlelooper
;
 
: switchhandler
var bid
me @ "@battle/BattleID" getprop bid !
 
loc @ { "@battle/" BID @ "/pause" }cat getprop not if
loc @ { "@battle/" BID @ "/fainted/" }cat propdir? if
bid @ fainted_pokemon
bid @ battlelooper
exit
then
then
var pos
me @ "@battle/moveswitch" getprop if
        me @ "@battle/moveswitch" getprop pos !
        "player" bid @ pos @ moveswitch
        me @ "@battle/moveswitch" remove_prop
        bid @ battlelooper
        exit
then
 
me @ "@battle/batonpass" getprop if
        me @ "@battle/batonpass" getprop pos !
        "player" bid @ pos @ batonpass
        me @ "@battle/batonpass" remove_prop
        bid @ battlelooper
        exit
then
 
me @ "@battle/control" getprop not if
       bid @ not if
       arg @ "=" split atoi var! pos2 atoi var! pos1
        
       var id1
       var id2
        
       pos1 @ 6 >
       pos1 @ 1 < or if
       "^[r^[oFirst position invalid, must be within 1-6" tellme
       exit
       then
        
       pos2 @ 6 >
       pos2 @ 1 < or if
       "^[r^[oFirst position invalid, must be within 1-6" tellme
       exit
       then
        
       me @ { "slot/" pos1 @ }cat get id1 !
       me @ { "slot/" pos2 @ }cat get id2 !
        
       me @ { "slot/" pos1 @ }cat id2 @ setto
       me @ { "slot/" pos2 @ }cat id1 @ setto
        
{ "^[y^[oYou switched ^[c" pos1 @ "." id1 @ id_name "^[y with ^[c" pos2 @ "." id2 @ id_name "^[y." }cat tellme
exit
       else
"^[o^[rWe aren't waiting for you to command right now." tellme exit
then
then
 
var pos
me @ "@battle/control" getprop pos !
 
var target
loc @ { "@battle/" BID @ "/position/" POS @ }cat getprop target !
target @ "status/statmods/vortex/turns" get if
"^[r^[oThat pokemon is trapped and can't be switched out at this time!" tellme
exit
then
 
target @ "status/statmods/block/move" get if
        { "^[o^[yYou can't switch ^[c" target @ id_name "^[y because of ^[c" target @ "status/statmods/block/user" get id_name "'s " target @ "status/statmods/block/move" get "^[y." }cat tellme
        exit
then
 
 
 
var oteam
pos @ "A*" smatch if
"B1" oteam !
else
"A1" oteam !
then
 
oteam @ "shadow tag" bid @ team_ability
target @ "ability" fget "shadow tag" smatch not and if
{ "^[o^[yYou can't switch with the ability ^[cShadow Tag^[y on field." }cat tellme
exit
then
 
oteam @ "arena trap" bid @ team_ability if
 
         target @ typelist "flying" array_findval array_count if 1 else 0 then
                   target @ "ability" fget "levitate" smatch or
                   target @ "ability" fget "run away" smatch or
                        loc @ { "@battle/"BID @ "/gravity" }cat getprop
                        target @ "holding" get stringify "iron ball" smatch or not and not
           (end cluster) if
           { "^[o^[yYou can't switch with the ability ^[cArena Trap^[y on field." }cat tellme
           exit
 
           then
then
 
oteam @ "magnet pull" bid @ team_ability if
        target @ typelist "steel" array_findval array_count if
                { "^[o^[yYou can't switch with the ability ^[cMagnet Pull^[y on field." }cat tellme
                exit
        then
then
 
var who
var team
 
pos @ "A*" smatch if
"A" team !
then
 
pos @ "B*" smatch if
"B" team !
then
 
var id
var counter
var notvalid
var maxhp
var percent
var othercont
var fusionnudge
 
var trainer1
var trainer2
 
loc @ { "@battle/" BID @ "/teams/" team @ "/A" }cat getprop trainer1 !
loc @ { "@battle/" BID @ "/teams/" team @ "/B" }cat getprop trainer2 !
 
trainer1 @ if 1 fusionnudge ! then
trainer2 @ if fusionnudge @ 1 + fusionnudge !
 
then
 
{ "^[y^[o------------------------------------------------------------------------" }cat tellme
1 loc @ { "@battle/" BID @ "/teams/" team @ "/" }cat array_get_propvals array_count 1 for id !
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
 
0 notvalid !
loc @ { "@battle/" BID @ "/position/" team @ "1" }cat getprop stringify id @ smatch if 1 notvalid ! then
loc @ { "@battle/" BID @ "/position/" team @ "2" }cat getprop stringify id @ smatch if 1 notvalid ! then
loc @ { "@battle/" BID @ "/declare/switch/" id @ }Cat getprop if 2 notvalid ! then
id @ "status/hp" get not if 3 notvalid ! then
id @ "status/fainted" get if 3 notvalid ! then
id @ "egg?" get if 4 notvalid ! then
 
{ "^[y^[o" counter @ ". "
id @ id_name 12 " " padr
id @ { "/pokemon/" id @ "species" fget "/name" }cat fget dup not if pop "??????????" then 10 " " padr
" "
"^[yLv "
id @ FindPokeLevel intostr 3 " " padr
" "
id @ "gender" fget "M*" smatch if
"^[o^[c" { id @ "gender" fget 1 1 midstr }cat
then
 
id @ "gender" fget "F*" smatch if
"^[o^[r" { id @ "gender" fget 1 1 midstr }cat
then
 
id @ "gender" fget "N*" smatch id @ "gender" fget "O*" smatch or if
"^[o^[m" { id @ "gender" fget 1 1 midstr }cat
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
othercont @ me @ = not if
{ "  ^[g<" othercont @ name ">" }cat
then
 
}cat tellme
repeat
 
{ "^[y^[o------------------------------------------------------------------------" }cat tellme
"^[o^[rSwitch with whom?" "Battle" pretty tellme
read arg !
 
 
arg @ strip arg !
 
arg @ "A" smatch
arg @ "B" smatch or not if
arg @ atoi arg ! then
 
arg @ not if
"^[o^[rInvalid pokemon position." "Battle" pretty tellme
exit
then
 
loc @ { "@battle/" BID @ "/teams/" team @ "/" arg @ }cat getprop not if
"^[o^[rThere isn't a pokemon there." "Battle" pretty tellme
exit
then
 
loc @ { "@battle/" BID @ "/teams/" team @ "/" arg @ }cat getprop arg !
 
0 notvalid !
loc @ { "@battle/" BID @ "/position/" team @ "1" }cat getprop stringify arg @ smatch if 1 notvalid ! then
loc @ { "@battle/" BID @ "/position/" team @ "2" }cat getprop stringify arg @ smatch if 1 notvalid ! then
loc @ { "@battle/" BID @ "/declare/switch/" arg @ }Cat getprop if 2 notvalid ! then
arg @ "status/hp" get not if 3 notvalid ! then
 
notvalid @ if
"^[o^[rYou can't switch with that pokemon at this time." "Battle" pretty tellme
exit
then
 
loc @ { "@battle/" BID @ "/declare/switch/" arg @ }cat pos @ setprop
 
 
loc @ { "@battle/" BID @ "/Declare/" pos @ }cat { "Switch "  arg @ }cat setprop
  loc @ { "@battle/" BID @ "/repeats/" POS @ }cat remove_prop
  loc @ { "@battle/" BID @ "/uproar/" pos @ }cat remove_prop
me @ "@battle/control" remove_prop
BID @ pos @ checkothers
BID @ battlelooper
 
 
;
 
: runhandler  (used for running away)
var bid
me @ "@battle/BattleID" getprop bid !
var pos
me @ "@battle/control" getprop pos !
 
loc @ { "@battle/" BID @ "/fainted/" }cat propdir? if
 
loc @ { "@battle/" bid @ "/AItype" }cat getprop "player" smatch if
"^[o^[rYou can't run from this type of battle. You must +concede instead." tellme exit then
 
loc @ { "@battle/" BID @ "/AItype" }cat getprop "wild" smatch not if
 
"^[o^[rYou can't run from this type of battle." tellme exit then
 
 
var pos_list
{ "A1" "B1" "A2" "B2" }list pos_list !
pos_list @ foreach pos ! pop
loc @ { "@battle/" BID @ "/fainted/" pos @ "/controller" }cat getprop stringify me @ stringify smatch if
 
{ "^[o^[c" pos @ 1 1 midstr "." me @ name "^[y ran from the battle. Battle Over." }cat bid @ notify_watchers
bid @ removebattle
exit
then
repeat
then
 
 
 
var target
loc @ { "@battle/" BID @ "/position/" POS @ }cat getprop target !
 
target @ "status/statmods/vortex/turns" get if
"^[r^[oThat pokemon is trapped and you can't run at this time!" tellme
exit
then
 
target @ "status/statmods/block/move" get if
        { "^[o^[yYou can't run with ^[c" target @ id_name "^[y because of ^[c" target @ id_name "'s" target @ "status/statmods/block/move" get "^[y." }cat tellme
        exit
then
 
me @ "@battle/control" getprop not if
"^[o^[rWe aren't waiting for you to command right now." tellme
exit then
 
var oteam
pos @ "A*" smatch if
"B1" oteam !
else
"A1" oteam !
then
 
oteam @ "arena trap" bid @ team_ability if
 
         target @ typelist "flying" array_findval array_count if 1 else 0 then
                   target @ "ability" fget "levitate" smatch or
                   target @ "ability" fget "run away" smatch or
                        loc @ { "@battle/"BID @ "/gravity" }cat getprop
                        target @ "holding" get stringify "iron ball" smatch or not and not
           (end cluster) if
           { "^[o^[yYou can't run with the ability ^[cArena Trap^[y on field." }cat tellme
           exit
 
           then
then
 
oteam @ "magnet pull" bid @ team_ability if
        target @ typelist "steel" array_findval array_count if
                { "^[o^[yYou can't run with the ability ^[cMagnet Pull^[y on field." }cat tellme
                exit
        then
then
 
loc @ { "@battle/" bid @ "/AItype" }cat getprop "player" smatch if
"^[o^[rYou can't run from this type of battle. You must +concede instead." tellme exit then
 
loc @ { "@battle/" BID @ "/AItype" }cat getprop "wild" smatch not if
 
"^[o^[rYou can't run from this type of battle." tellme exit then
 
loc @ { "@battle/" BID @ "/Declare/" pos @ }cat { "Run" }cat setprop
 
me @ "@battle/control" remove_prop
BID @ pos @ checkothers
BID @ battlelooper
;
 
: mefirst
(this is the program to decide if the trainer will go first or last in battles)
me @ "@Fusionorder" getprop not if
me @ "@Fusionorder" "first" setprop
"^[o^[rYou are now going to go first in battles." tellme
else
"^[o^[rYou are now going to go last in battles." tellme
me @ "@Fusionorder" remove_prop
then
;
 
: partnering  (this is used for partnering up with someone)
var! who
me @ "@battle/battleID" getprop if
"^[o^[rYou are in a battle, finish the battle first before joining a party." "Hunting Party" pretty tellme
exit
then
  who @ pmatch who !
  who @ not who @ #-2 = or if "I don't know who that is!" tellme exit then
 
me @ "@valid?/email" getprop who @ "@valid?/email" getprop smatch if
"^[o^[rYou can't partner with your alt." "Hunting Party" pretty tellme
exit
then
 
me @ "@HuntingTeam/leading" getprop if
 { "^[o^[rYou are already in a party leading ^[c" me @ "@huntingteam/leading" getprop name "^[r. Use '+unpartner' to leave the group." }cat "Hunting Party" pretty tellme
 exit
then
me @ "@huntingTeam/following" getprop if
 { "^[o^[rYou are already in a party following ^[c" me @ "@huntingteam/following" getprop name "^[r. Use '+unpartner' to leave the group." }cat "Hunting Party" pretty tellme
 exit
then
me @ "@HuntingTeam/requested" getprop if
 { "^[o^[rYou are waiting on a request to lead ^[c" me @ "@huntingteam/requested" getprop name "^[r. Use '+unpartner' to abort request."
 exit
then
 
who @ "@huntingTeam/requested" getprop if
 who @ "@HuntingTeam/requested" getprop me @ = if
 { "^[o^[gYou are now hunting with ^[c" who @ name "^[g as your leader." }cat "Hunting Party" pretty tellme
 who @ { "^[o^[c" me @ name "^[g accepts.  You are now leading. +hunt when you are ready." }cat "Hunting Party" pretty notify
 who @ "@huntingTeam/requested" remove_prop
 who @ "@huntingTeam/leading" me @ setprop
 me @ "@huntingTeam/following" who @ setprop
 exit
 else
 { "^[o^[c" who @ name "^[r has requested to lead someone, wait for them to undo the request first." }cat "Hunting Party" pretty tellme
 exit
 then
then
 
 
 
me @ "@HuntingTeam/requested" who @ setprop
{ "^[o^[yYou have asked ^[c" who @ name " ^[yto hunt with you." }cat "Hunting Party" pretty tellme
who @ { "^[o^[c" me @ name "^[y would like to hunt with you. type '+partner " me @ name "' to accept." }cat "Hunting Party" pretty notify
;
 
: unpartnering
var partner
me @ "@battle" propdir? if
"^[o^[rYou can't do that while in a battle." tellme
exit
then
me @ "@pvp" propdir? if
"^[o^[rYou can't do that while in a pvp request." tellme
exit
then
me @ "@huntingTeam/leading" getprop if
 me @ "@huntingTeam/leading" getprop partner !
 partner @ { "^[o^[c"me @ name " ^[rhas decided to end the hunting party." }cat "Hunting Party" pretty notify
 me @ { "^[o^[rYou have ended the hunting party with ^[c" partner @ name "^[r." }cat "Hunting Party" pretty notify
 me @ "@huntingTeam" remove_prop
 partner @ "@huntingTeam" remove_prop
 exit
then
 
me @ "@huntingTeam/following" getprop if
 me @ "@huntingteam/following" getprop partner !
 partner @ { "^[o^[c"me @ name " ^[rhas decided to end the hunting party." }cat "Hunting Party" pretty notify
 me @ { "^[o^[rYou have ended the hunting party with ^[c" partner @ name "^[r." }cat "Hunting Party" pretty notify
 partner @ "@HuntingTeam" remove_prop
 me @ "@huntingTeam" remove_prop
 exit
then
 
me @ "@huntingTeam/requested" getprop if
 me @ "@huntingteam/requested" getprop partner !
 partner @ { "^[o^[c"me @ name " ^[rhas changed their mind on hunting with you." }cat "Hunting Party" pretty notify
 me @ { "^[o^[rYou have changed your mind about hunting with ^[c" partner @ name "^[r." }cat "Hunting Party" pretty notify
 me @ "@huntingTeam" remove_prop
 exit
then
"^[r^[oThats nice... but you arent in a party or requested to make one." "Hunting Party" pretty tellme
;
 
$libdef battlereview
: battlereview  (this is used to repaste what is going on in the battle for people battling)
var BID
me @ "@battle/battleid" getprop BID !
me @ { "@temp/JustMeWatching/" me @ }cat BID @ setprop
BID @ combatdisplay
BID @ battle_handler
; PUBLIC battlereview
 
: battlenotify
(this is the program to decide if you will be notified about battles)
me @ "@BattleIgnoreNotify" getprop not if
me @ "@battleignorenotify" "off" setprop
"^[o^[rYou are now ignoring battle notifications." tellme
else
"^[o^[rYou are now listening for battle notifications." tellme
me @ "@battleignorenotify" remove_prop
then
;
 
: battlegiveup
var BID
me @ "@battle/battleid" getprop BID !
loc @ { "@battle/" BID @ "/aitype" }cat getprop "Player" smatch if
"^[o^[rYou are about to give up on the battle." tellme
"^[o^[rThe battle will end instantly." tellme
"^[o^[rAre you sure you want to do this?" tellme
var choice
read choice !
        choice @ "y*" smatch if
                { "^[o^[c" me @ name "^[r has decided to concede this battle.  The battle is now ended." }cat bid @ notify_watchers
                loc @ { "@battle/" BID @ "/battling/" }cat array_get_propvals foreach pop stod temp !
                temp @ "@battle" remove_prop
                repeat
                bid @ removebattle
        then
then
;
 
: itemfindertoggle
me @ "@noitem" getprop if
me @ "@noitem" remove_prop
"^[y^[oYou now ^[gwill ^[ytry to find items when you hunt." tellme
else
me @ "@noitem" "on" setprop
"^[y^[oYou now ^[rwon't ^[ytry to find items when you hunt." tellme
then
;
 
: trainerbattletoggle
me @ "@nonpc" getprop
if
  me @ "@nonpc" remove_prop
  "^[o^[yYou now will ^[gseek ^[ytrainers when you hunt." tellme
else
  me @ "@nonpc" "on" setprop
  "^[o^[yYou now will ^[ravoid ^[ytrainers when you hunt." tellme
then
;
 
: trainerfighttoggle
me @ "@MeNotFight" getprop if
        me @ "@MeNotFight" remove_prop
        "^[y^[oYou ^[gwill ^[yparticipate in wild battles." tellme
else
        me @ "@MeNotFight" "on" setprop
        "^[y^[oYou ^[rwon't ^[yparticipate in wild battles." tellme
then
;
 
: legendaryfighttoggle
me @ "@RandomSpawnTiers/IgnoreLegendFinder" getprop if
        me @ "@RandomSpawnTiers/IgnoreLegendFinder" remove_prop
        "^[y^[oYou ^[gwill ^[ylook for legendaries on tier 4." tellme
else
        me @ "@RandomSpawnTiers/IgnoreLegendFinder" "on" setprop
        "^[y^[oYou ^[rwon't ^[ylook for legendaries on tier 4." tellme
then
;
 
 
: expshare
 (set on the player something to check if expshare is on, then turn it on during the battle)
me @ "@expshare" getprop if
        me @ "@expshare" remove_prop
        "^[y^[oEXP Share is turned ^[rOFF^[y." tellme
else
        me @ "@expshare" "on" setprop
        "^[y^[oEXP Share is turned ^[gON^[y." tellme
then
;

: main
idletimer
strip arg !
command @ "+attack" smatch if attackhandler exit then
command @ "+item" smatch if itemhandler2 exit then
command @ "+switch" smatch if switchhandler exit then
command @ "+run" smatch if runhandler exit then
command @ "+watch" smatch if arg @ watchingfight exit then
command @ "+unwatch" smatch if arg @ unwatchfight exit then
command @ "+mefirst" smatch if mefirst exit then
command @ "+abortbattle" smatch if "player" abortbattle exit then
command @ "+partner" smatch if arg @ partnering exit then
command @ "+unpartner" smatch if unpartnering exit then
command @ "+review" smatch if battlereview exit then
command @ "+bnotify" smatch if battlenotify exit then
command @ "+concede" smatch if battlegiveup exit then
command @ "+itemfinder" smatch if itemfindertoggle exit then
command @ "+trainerbattle" smatch if trainerbattletoggle exit then
command @ "+mefight" smatch if trainerfighttoggle exit then
command @ "+findlegendary" smatch if legendaryfighttoggle exit then
command @ "+expshare" smatch if expshare exit then
;