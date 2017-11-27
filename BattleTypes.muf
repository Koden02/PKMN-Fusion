$include #3 (ansilib.muf)
$include #6 (Useful.muf)
$include #47 (DLadapter.muf)
$include #48 (CalculateStats.muf)
$include #196 (triggers)
$include #200 (RandomPokemonGenerater.muf)
$include #204 (BattleStartInterface.muf)
$include #299 (Daycare.muf / Hatching Code)
$include #598 
$include $RP/combat/NPCGen
 
$def NPCDIR #1125
 
var arg
var startprop
var temp
 
 
: bnotify
var tempref
var! msg
      loc @ contents_array foreach tempref ! pop
         tempref @ player? not if continue then
         tempref @ awake? not if continue then
         tempref @ "@BattleIgnoreNotify" getprop if continue then
         tempref @ { msg @ }cat notify
         repeat
;
 
: MinorNPCBattle
atoi var! mytier
 
var a
var b
var trainertotal
var trainclass
var trainertable
#0 "@war/activewar" getprop if
             #0 "@war/trainertable/" array_get_propvals trainertable !

else
        loc @ "@trainertable/" array_get_propvals trainertable !
then
        trainertable @ foreach atoi b ! a !

        NPCDIR { "@classes/" a @ "/valid" }cat getprop not if continue then

        trainertotal @ b @ + trainertotal !
        repeat

        random trainertotal @ % 1 + var! randtrainer
        0 trainertotal !

        trainertable @ foreach atoi b ! trainclass !
        NPCDIR { "@classes/" trainclass @ "/valid" }cat getprop not if "hobo" trainclass ! (set this as default fail safe) continue then
        trainertotal @ b @ + trainertotal !
        randtrainer @ trainertotal @ <= if
        break
        then
        repeat

me @ trainclass @ mytier @ "wild" maketrainer
;
 
 
: set4moves
var! bid
var team
var id
var moveset
var tmove
var moveA
var moveB
var moveC
var moveD
var pokelev
var pokenum
var count
var lev
var slot
 
var move
var movelev
        { "A" "B" }list foreach team ! pop
                loc @ { "@battle/" bid @ "/teams/" team @ }cat array_get_propvals foreach  id ! pop
                  ID @ "4moveset" fget not if POKESTORE { "@pokemon/" ID @ fid "/@RP/movesets/1" }cat propdir? if POKESTORE { "@pokemon/" ID @ fid "/@RP/4moveset" }cat 1 setprop then then (do this to set it to 1 if 1 is there. )
                  ID @ "4moveset" fget not if  (run if they don't have a default 4moveset, this assumes they have nothing set at all and there shoulden't be a case that this variable doesn't exist with a set existing)
                  (AI trainers will have 4movesets placed in them at some point)
                  (take the pokemon's level and count backwards, defaulting moves to the moves they learned at highest level on down, for neatness, store them in 4 variables)
                  ID @ findpokelevel pokelev !
                  ID @ "species" fget  pokenum !
                  1 pokelev @ 1 for lev !
                          POKEDEX { "pokemon/" pokenum @ "/movelist/" }cat array_get_propvals foreach movelev ! move !
                          movelev @ atoi lev @ = if
                          POKESTORE { "@pokemon/" id @ fid "/@RP/movesknown/" move @ }cat getprop not if continue then
                                (bump up, new -> A -> B -> C -> D)
                                moveC @ moveD !
                                moveB @ moveC !
                                moveA @ moveB !
                                move  @ moveA !
                          then
                          repeat
                  repeat
                  
                
                   POKESTORE { "@pokemon/" ID @ fid "/@RP/movesets/1/A" }cat moveA @ setprop     
                   POKESTORE { "@pokemon/" ID @ fid "/@RP/movesets/1/B" }cat moveB @ setprop
                   POKESTORE { "@pokemon/" ID @ fid "/@RP/movesets/1/C" }cat moveC @ setprop
                   POKESTORE { "@pokemon/" ID @ fid "/@RP/movesets/1/D" }cat moveD @ setprop
                   POKESTORE { "@pokemon/" ID @ fid "/@RP/4moveset" }cat 1 setprop
                then
                
                ID @ "4moveset" fget moveset !
                LOC @ { "@battle/" BID @ "/movesets/" ID @ }cat moveset @ setprop
                 { "A" "B" "C" "D" }list foreach slot ! pop
                 id @ { "movesets/" moveset @ "/" slot @ }cat fget tmove ! 
                 tmove @ not if continue else 
                        LOC @ { "@battle/" BID @ "/movesets/" ID @ "/" slot @ }cat tmove @ setprop
                         POKESTORE { "@pokemon/" id @ fid "/@long/movesknown/" tmove @ }cat  
                           POKESTORE { "@pokemon/" id @ fid "/@RP/movesknown/" tmove @ }cat getprop setprop
                         ( POKESTORE { "@pokemon/" id @ fid "/@long/movesknown/" tmove @ "/pp" }cat 
                           POKESTORE { "@pokemon/" id @ fid "/@RP/movesknown/" tmove @ "/pp" }cat getprop setprop )
                         then
                repeat
                
        repeat
        repeat
;
 
: NPCfight
(currently unused)
(this isn't set for recycle yet. It hasn't been totally decided on how npc battles are being placed in the system.  When finished contact Yang and he will add it in.)
arg @ match var! victim
 
victim @ #-1 dbcmp if "I don't see them here." tellme exit then
victim @ #-2 dbcmp if "I don't know which one you mean." tellme exit then
victim @ #-3 dbcmp if "Now that's just silly." tellme exit then
 
victim @ "@rp/NPC?" getprop not if "That is not an NPC." tellme exit then
victim @ "@battle/battleID" getprop if
{ "^[o^[r" victim @ name "is already in a battle.  Wait for it to finish." }cat tellme exit
then
 
victim @ "$rp/combat/heal" match call
 
me @ "@huntingteam/following" getprop if
 "^[o^[rYou aren't the leader of the group, you can't start the battle." tellme
exit
then
var partner
me @ "@huntingteam/leading" getprop if
 me @ "@huntingteam/leading" getprop partner !
 partner @ location loc @ = not
 partner @ awake? not or
 if
  "^[o^[rYou can't hunt without your partner, wait for them to come back." tellme
 exit
 then
 
then
 
me @ "@battle/battleID" getprop if
"^[o^[rYou are already in a battle.  Finish that one first." tellme
exit
then
var abletofight
 
me @ "fusion" get if me @ "status/hp" get if 1 abletofight ! then then
me @ "slot/1" get "status/hp" get if 1 abletofight ! then
me @ "slot/2" get "status/hp" get if 1 abletofight ! then
me @ "slot/3" get "status/hp" get if 1 abletofight ! then
me @ "slot/4" get "status/hp" get if 1 abletofight ! then
me @ "slot/5" get "status/hp" get if 1 abletofight ! then
me @ "slot/6" get "status/hp" get if 1 abletofight ! then
 
abletofight @ not if
"^[r^[oYou don't have any pokemon in fighting condition." tellme
exit
then
 
var pokeid
 
var mytier
me @ "Tier" get dup not if pop "1" then mytier !
 
new_battle_id var! bid
 
 
(end walking)
 
"1" var! howmany
loc @ { "@battle/" BID @ "/tier" }cat mytier @ setprop 
loc @ { "@battle/" BID @ "/battling/" me @ }cat "A" setprop
loc @ { "@battle/" BID @ "/watching/" me @ }cat 1 setprop
loc @ { "@battle/" bid @ "/AItype" }cat "Trainer" setprop
loc @ { "@battle/" BID @ "/XP" }cat "on" setprop
loc @ { "@battle/" BID @ "/TXP" }cat "on" setprop
 loc @ { "@battle/" bid @ "/howmany" }cat howmany @ setprop
victim @ "@rp/ID" getprop "slot/1" get pokeid !
loc @ { "@battle/" bid @ "/teams/B/1" }cat pokeid @ setprop
loc @ { "@battle/" bid @ "/control/teamB/" pokeid @ }cat "AI" setprop
pokeid @ "battle/BID"  BID @ setto
pokeid @ "battle/Team" "B" setto
 
var lead1
var part1
 
var count1
1 count1 !
var count2
me @ "@Fusionorder" getprop stringify "first" smatch if
me @ "fusion" get if
loc @ { "@battle/" bid @ "/teams/A/" count1 @ }cat me @ "@RP/id" getprop setprop
loc @ { "@battle/" bid @ "/control/teamA/" me @ "@RP/id" getprop }cat me @ setprop
me @ "battle/BID" BID @ setto
me @ "battle/Team" "A" setto
me @ "@RP/ID" getprop "status/hp" get if me @ "@RP/ID" getprop lead1 ! POKESTORE { "@pokemon/" me @ "@RP/ID" getprop "/@RP/status/statmods/" }cat remove_prop  POKESTORE { "@pokemon/" me @ "@RP/ID" getprop "/@temp/" }cat remove_prop then
1 count1 @ + count1 !
then then
 
var idholder
1 6 1 for count2 !
me @ { "slot/" count2 @ }cat get dup if idholder !
idholder @ "Egg?" get not if
loc @ { "@battle/" bid @ "/teams/A/" count1 @ }cat idholder @ setprop
loc @ { "@battle/" bid @ "/control/teamA/" idholder @ }cat me @ setprop
idholder @ "battle/BID" BID @ setto
idholder @ "battle/Team" "A" setto
POKESTORE { "@pokemon/" idholder @ "/@RP/status/statmods/" }cat remove_prop
POKESTORE { "@pokemon/" idholder @ "/@temp/" }cat remove_prop
lead1 @ not if
idholder @ "status/hp" get if idholder @ lead1 ! then
then
 
1 count1 @ + count1 !
then else pop then
repeat
 
me @ "@Fusionorder" getprop stringify "first" smatch not if
me @ "fusion" get if
 
loc @ { "@battle/" bid @ "/teams/A/" count1 @ }cat me @ "@RP/id" getprop setprop
POKESTORE { "@pokemon/" me @ "@RP/ID" getprop "/@RP/status/statmods/" }cat remove_prop
POKESTORE { "@pokemon/" me @ "@RP/ID" getprop "/@temp/" }cat remove_prop
loc @ { "@battle/" bid @ "/control/teamA/" me @ "@RP/id/" getprop }cat me @ setprop
me @ "battle/BID" BID @ setto
me @ "battle/Team" "A" setto
lead1 @ not if
me @ "@RP/id/" getprop "status/hp" get if me @ "@RP/id" getprop lead1 ! then
then
 
1 count1 @ + count1 !
then then
 
(set  battle id on challenger)
me @ "@battle/battleID" bid @ setprop
 
(set the first pokemon to battle)
 
loc @ { "@battle/" bid @ "/teams/A/1" }cat getprop not if
"^[o^[rYou have no pokemon that can fight." tellme
abortbattle
exit
then
 
var temp
var temp2
loc @ { "@battle/" bid @ "/position/A1" }cat
loc @ { "@battle/" bid @ "/teams/A" }cat array_get_propvals foreach temp ! pop
   temp @ "status/hp" get if temp @ temp2 ! break then
repeat temp2 @ setprop
temp2 @ "battle/Position" "A1" setto
0 temp2 !
 
 
loc @ { "@battle/" bid @ "/position/B1" }cat
loc @ { "@battle/" bid @ "/teams/B" }cat array_get_propvals foreach temp ! pop
 
   temp @ "status/hp" get if temp @ temp2 ! break then
repeat temp2 @ setprop
temp2 @ "battle/Position" "B1" setto
0 temp2 !
 
loc @ { "@battle/" bid @ "/howmany" }cat getprop atoi 1 > if
loc @ { "@battle/" bid @ "/position/A2" }cat
 
loc @ { "@battle/" bid @ "/teams/A" }cat array_get_propvals foreach temp ! pop
   temp @ loc @ { "@battle/" bid @ "/position/A1" }cat getprop smatch if continue then
   temp @ "status/hp" get if temp @ temp2 ! break then
repeat temp2 @ setprop
temp2 @ "battle/Position" "A2" setto
0 temp2 !
then
loc @ { "@battle/" bid @ "/position/B2" }cat
loc @ { "@battle/" bid @ "/teams/B" }cat array_get_propvals foreach temp ! pop
   temp @ loc @ { "@battle/" bid @ "/position/B1" }cat getprop smatch if continue then
   temp @ "status/hp" get if temp @ temp2 ! break then
repeat temp2 @ setprop
temp2 @ "battle/Position" "B2" setto
0 temp2 !
 
{ "^[c^[o" me @ name "^[y is battling ^[c^[o" victim @ name "^[y." }cat "NPC-Battle" pretty bnotify
 
bid @ battlelooper
 
;
 
: itemfinder
var rarity
var item
me @ "@itemfinder" remove_prop
POKEDEX "itemfinder" array_get_propvals foreach strip rarity ! strip item !
        me @ { "@itemfinder/" rarity @ "/" item @ }cat item @ setprop
repeat
var item
var count
{
{ "Frequent:35" "Common:15" "Uncommon:10" "Rare:5" "Special:1" }list foreach ":" split atoi count ! rarity ! pop
        rarity @ "blank" smatch not if
        begin
        
                { me @ { "@itemfinder/" rarity @ }cat array_get_propvals foreach swap pop repeat }list 1 10 1 for pop 4 array_sort repeat foreach swap pop item !
                item @
                (item @ tellme ) (not needed, just was to make sure it was sorting properly)
                count @  1 - count !
                count @ not if
                break
                then
 
                repeat
                count @ not if
                break
                then
        repeat
        else
        begin
        "Nothing"
        count @ 1 - count !
        count @ not if
        break
        then
        repeat
        then
repeat
}list 1 10 1 for pop 4 array_sort repeat  foreach  item ! 1 + count !
 
me @ { "@itemfinder/finder/" count @ }cat item @ setprop
 
repeat
 
var left
var choice
var saves
var item
 
me @ "@rp/ID" getprop var! ID
 
(removed for gen 5)
(ID @ "ability" fget "pickup" smatch if 
{ "^[o^[yYour item finder goes off!  There are items nearby!  Pick three numbers between ^[c1 ^[y^[oand ^[c" count @ "^[y, maybe you'll find something!" }cat tellme
3 left !
ID @ FindPokeLevel 20 / 1 + saves !
else)
 
{ "^[o^[yYour item finder goes off!  There are items nearby!  Pick two numbers between ^[c1 ^[y^[oand ^[c" count @ "^[y, maybe you'll find something!" }cat tellme
2 left !
 
(then) (removed for gen 5)
 
 
begin
{ "^[o^[yWhat is your choice? ^[c" left @ "^[y searches left." }cat tellme
read atoi choice !
choice @ not if
"^[o^[rInvalid choice... try again..." tellme continue
then
choice @ 1 >=
choice @ count @ <= and not if
"^[o^[rInvalid choice... try again..." tellme continue
then
 
me @ { "@itemfinder/chosen/" choice @ }cat getprop if
"^[o^[rLocation already picked... try again..." tellme continue
then
 
me @ { "@itemfinder/chosen/" choice @ }cat "yes" setprop
me @ { "@itemfinder/finder/" choice @ }cat getprop item !
 
{ "^[o^[gYou have found ^[c" item @ "nothing" smatch not if item @ AorAn else item @ then
"^[g."
 
}cat tellme
item @ "nothing" smatch if
        saves @ 1 >= if
                { "^[g^[oYou have ^[c" saves @ "^[g saves left!  Look again!" }Cat tellme
                saves @ 1 - saves !
                left @ 1 + left !
        then
else
        ID @ { "inventory/" item @ }cat over over get atoi 1 + setto
then
left @ 1 - left !
 
left @ 1 < if break then
 
repeat
 
(now for pokemon to do it, that have pickup)
(removed for gen 5
var slot
var pokeID
var itemslot
 
1 6 1 for slot !
ID @ { "Slot/" slot @ intostr }cat get dup not if pop continue then pokeID !
pokeID @ "Egg?" get if continue then
pokeID @ "ability" fget "pickup" smatch if
        pokeID @ FindPokeLevel 25 / 1 + saves !
        
        { me @ { "@itemfinder/finder/" }cat array_get_propvals foreach pop repeat }list 4 array_sort foreach itemslot ! pop
                
                me @ { "@itemfinder/chosen/" itemslot @ }cat getprop if continue then
                me @ { "@itemfinder/chosen/" itemslot @ }cat "Yes" setprop
                me @ { "@itemfinder/finder/" itemslot @ }cat getprop item !
                
                item @ "nothing" smatch not if
                        ID @ { "inventory/" item @ }cat over over get atoi 1 + setto
                        break
                then
                
                saves @ 1 - saves !
                saves @ 1 < if break then
        repeat
        { "^[o^[c" pokeID @ id_name "^[g has found ^[c" item @ "nothing" smatch not if  item @ AorAn else item @ then
        "^[g."
        
        }cat tellme
 
then
 
repeat
)
 
 
;
 
$libdef gymfollowerbattle
: gymfollowerbattle
loc @ "@gym" getprop var! gymnum
 
me @ { "@achieve/gymbadges/prechallenge/" gymnum @ "/battles" }cat getprop not if (end battle parts) exit then
 
new_battle_id var! bid
 
POKESTORE "@logs/total number of gym follower battles" over over getprop 1 + setprop
 
(set the battle props here for the battle that is being created)
 
loc @ { "@battle/" BID @ "/battling/" me @ }cat "A" setprop
loc @ { "@battle/" BID @ "/watching/" me @ }cat 1 setprop
loc @ { "@battle/" BID @ "/howmany" }cat "1" setprop
 
(set up the player's team)
var lead1
var part1
 
var count1
1 count1 !
var count2
 
 
var idholder
1 6 1 for count2 !
me @ { "slot/" count2 @ }cat get dup if idholder !
(idholder @ "Egg?" get not if)
loc @ { "@battle/" bid @ "/teams/A/" count1 @ }cat idholder @ setprop
loc @ { "@battle/" bid @ "/control/teamA/" idholder @ }cat me @ setprop
idholder @ "battle/BID" BID @ setto
idholder @ "battle/Team" "A" setto
POKESTORE { "@pokemon/" idholder @ "/@RP/status/statmods/" }cat remove_prop
POKESTORE { "@pokemon/" idholder @ "/@temp/" }cat remove_prop
lead1 @ not if
idholder @ "status/hp" get idholder @ "egg?" get not and if idholder @ lead1 ! then
then
 
1 count1 @ + count1 !
then (else pop then)
repeat
 
 
loc @ { "@battle/" BID @ "/control/teamA/users/" me @ "@rp/id" getprop }cat me @ setprop
 
me @ "@battle/battleID" bid @ setprop
 
loc @ { "@battle/" bid @ "/teams/A/" }cat propdir? not if
"^[o^[rYou have no pokemon that can fight." tellme
abortbattle
exit
then
 
(now create the NPC's trainer and pokemon)
var pokeid
me @ "follower" makegymtrainer var! TID var! Tteam
 
        var slotcount
        Tteam @ foreach pokeid ! pop
                slotcount @ 1 + slotcount !
                loc @ { "@battle/" BID @ "/teams/B/" slotcount @ }cat pokeid @ setprop
                loc @ { "@battle/" BID @ "/control/teamB/" pokeid @ }cat "AI" setprop
                pokeid @ "battle/BID" BID @ setto
                pokeid @ "battle/Team" "B" setto
 
        repeat
        
        loc @ { "@battle/" BID @ "/control/teamB/AItrainer/1" }cat TID @ setprop
 
var partner
var part1
var AIpart
(partner parts, in case I need them later)
 
var id
var team
 
var count1
1 count1 !
var count2
 
var lead1
 
var idholder
1 6 1 for count2 !
me @ { "slot/" count2 @ }cat get dup if idholder !
( idholder @ "Egg?" get not if )
loc @ { "@battle/" bid @ "/teams/A/" count1 @ }cat idholder @ setprop
loc @ { "@battle/" bid @ "/control/teamA/" idholder @ }cat me @ setprop
idholder @ "battle/BID" BID @ setto
idholder @ "battle/Team" "A" setto
POKESTORE { "@pokemon/" idholder @ "/@RP/status/statmods/" }cat remove_prop
POKESTORE { "@pokemon/" idholder @ "/@temp/" }cat remove_prop
lead1 @ not if
idholder @ "status/hp" get idholder @ "egg?" get not and if idholder @ lead1 ! then
then
 
1 count1 @ + count1 !
then (else pop then)
repeat
 
 
loc @ { "@battle/" BID @ "/control/teamA/users/" me @ "@rp/id" getprop }cat me @ setprop
 
        loc @ { "@battle/" BID @ "/AItype" }cat "NPC" setprop
        
var currhp
var maxhp
var newmaxhp
var temp2
 
1 6 1 for count1 !
(reminder note. set this up later to have the control setting on it)
{ "A" "B" }list foreach team ! pop
loc @ { "@battle/" BID @ "/teams/" team @ "/" count1 @ }cat getprop id !
id @ id @ "egg?" get not and  if
        id @ "status/hp" get atoi currhp !
        id @ "MaxHP" Calculate maxhp !
        id @ "level" 50 setto
        id @ "MaxHP" Calculate newmaxhp !
        id @ "status/hp" currhp @ newmaxhp @ * maxhp @ / setto
 
then 
repeat
repeat
 
(set  battle id on challenger)
me @ "@battle/battleID" bid @ setprop
 
loc @ { "@battle/" bid @ "/position/A1" }cat lead1 @ setprop
lead1 @ "battle/Position" "A1" setto
 
loc @ { "@battle/" bid @ "/position/B1" }cat
loc @ { "@battle/" bid @ "/teams/B" }cat array_get_propvals foreach temp ! pop
 
   temp @ "status/hp" get temp @ "egg?" get not and  if temp @ temp2 ! break then
repeat temp2 @ setprop
temp2 @ "battle/Position" "B1" setto
0 temp2 !
 
loc @ { "@battle/" bid @ "/howmany" }cat getprop atoi 1 > if
loc @ { "@battle/" bid @ "/position/A2" }cat
partner @ if
part1 @ setprop
part1 @ "battle/Position" "A2" setto
else
loc @ { "@battle/" bid @ "/teams/A" }cat array_get_propvals foreach temp ! pop
   temp @ loc @ { "@battle/" bid @ "/position/A1" }cat getprop smatch if continue then
   temp @ "status/hp" get temp @ "egg?" get not and if temp @ temp2 ! break then
repeat temp2 @ setprop
temp2 @ "battle/Position" "A2" setto
0 temp2 !
then
loc @ { "@battle/" bid @ "/position/B2" }cat
AIpart @ if
AIpart @ setprop
AIpart @ "battle/Position" "B2" setto
else
loc @ { "@battle/" bid @ "/teams/B" }cat array_get_propvals foreach temp ! pop
   temp @ loc @ { "@battle/" bid @ "/position/B1" }cat getprop smatch if continue then
   temp @ "status/hp" get temp @ "egg?" get not and if temp @ temp2 ! break then
repeat temp2 @ setprop
temp2 @ "battle/Position" "B2" setto
0 temp2 !
then 
then
 
        loc @ { "@battle/" BID @ "/trainers/A" }cat me @ id_name setprop
        loc @ { "@battle/" BID @ "/trainers/B" }cat TID @ id_name setprop
        loc @ { "@battle/" BID @ "/gymbattle" }cat "follower" setprop
        loc @ { "@battle/" BID @ "/challengerID" }cat me @ setprop 
(put this part in last to make sure it has everything it needs)        
loc @ { "@Battle/" BID @ "/4moves" }Cat "enabled" setprop
        bid @ set4moves
 
bid @ battlelooper
 
; PUBLIC gymfollowerbattle
 
 
$libdef gymleaderbattle
: gymleaderbattle
var! who
loc @ "@gym" getprop var! gymnum
 
new_battle_id var! bid
 
POKESTORE "@logs/total number of gym leader battles" over over getprop 1 + setprop
 
(set the battle props here for the battle that is being created)
 
loc @ { "@battle/" BID @ "/battling/" me @ }cat "B" setprop
loc @ { "@battle/" BID @ "/watching/" me @ }cat 1 setprop
loc @ { "@battle/" BID @ "/battling/" who @ }cat "A" setprop
loc @ { "@battle/" BID @ "/watching/" who @ }cat 1 setprop
loc @ { "@battle/" BID @ "/howmany" }cat "1" setprop
 
 
 
(set up the player's team)
var lead1
var part1
var lead2
 
var count1
1 count1 !
var count2
 
 
var idholder
1 6 1 for count2 !
me @ { "slot/" count2 @ }cat get dup if idholder !
(idholder @ "Egg?" get not if)
loc @ { "@battle/" bid @ "/teams/B/" count1 @ }cat idholder @ setprop
loc @ { "@battle/" bid @ "/control/teamB/" idholder @ }cat me @ setprop
idholder @ "battle/BID" BID @ setto
idholder @ "battle/Team" "B" setto
POKESTORE { "@pokemon/" idholder @ "/@RP/status/statmods/" }cat remove_prop
POKESTORE { "@pokemon/" idholder @ "/@temp/" }cat remove_prop
lead1 @ not if
idholder @ "status/hp" get idholder @ "egg?" get not and if idholder @ lead2 ! then
then
 
1 count1 @ + count1 !
then (else pop then)
repeat
 
 
loc @ { "@battle/" BID @ "/control/teamB/users/" me @ "@rp/id" getprop }cat me @ setprop
 
(
loc @ { "@battle/" bid @ "/teams/B/" }cat propdir? not if
"^[o^[rYou have no pokemon that can fight." tellme
abortbattle
exit
then
)
1 count1 !
 
1 6 1 for count2 !
who @ { "slot/" count2 @ }cat get dup if idholder !
( idholder @ "Egg?" get not if )
loc @ { "@battle/" bid @ "/teams/A/" count1 @ }cat idholder @ setprop
loc @ { "@battle/" bid @ "/control/teamA/" idholder @ }cat who @ setprop
idholder @ "battle/BID" BID @ setto
idholder @ "battle/Team" "A" setto
POKESTORE { "@pokemon/" idholder @ "/@RP/status/statmods/" }cat remove_prop
POKESTORE { "@pokemon/" idholder @ "/@temp/" }cat remove_prop
lead1 @ not if
idholder @ "status/hp" get idholder @ "egg?" get not and if idholder @ lead1 ! then
then
 
1 count1 @ + count1 !
then (else pop then)
repeat
 
 
loc @ { "@battle/" BID @ "/control/teamA/users/" who @ "@rp/id" getprop }cat who @ setprop
 
who @ "@battle/battleID" bid @ setprop
 
(loc @ { "@battle/" bid @ "/teams/A/" }cat propdir? not if
"^[o^[rYou have no pokemon that can fight." tellme
abortbattle
exit
then
)
 
(now place the gym leader within - the gym leader is creating the match so me @ is the leader, who @ is the challenger)
var id
var team
 
var count1
1 count1 !
var count2
var gleader
 
 
var partner
var part2
var AIpart
(partner parts, in case I need them later)
 
 
1 count1 !
 
 
        loc @ { "@battle/" BID @ "/AItype" }cat "Player" setprop
        
var currhp
var maxhp
var newmaxhp
var temp2
 
1 6 1 for count1 !
(reminder note. set this up later to have the control setting on it)
{ "A" "B" }list foreach team ! pop
loc @ { "@battle/" BID @ "/teams/" team @ "/" count1 @ }cat getprop id !
id @ id @ "egg?" get not and if
        id @ "status/hp" get atoi currhp !
        id @ "MaxHP" Calculate maxhp !
        id @ "level" 50 setto
        id @ "MaxHP" Calculate newmaxhp !
        id @ "status/hp" currhp @ newmaxhp @ * maxhp @ / setto
 
then 
repeat
repeat
 
(set  battle id on challenger)
me @ "@battle/battleID" bid @ setprop
who @ "@battle/battleID" bid @ setprop
 
loc @ { "@battle/" bid @ "/position/A1" }cat lead1 @ setprop
lead1 @ "battle/Position" "A1" setto
 
loc @ { "@battle/" bid @ "/position/B1" }cat
loc @ { "@battle/" bid @ "/teams/B" }cat array_get_propvals foreach temp ! pop
 
   temp @ "status/hp" get temp @ "egg?" get not and if temp @ temp2 ! break then
repeat temp2 @ setprop
temp2 @ "battle/Position" "B1" setto
0 temp2 !
 
loc @ { "@battle/" bid @ "/howmany" }cat getprop atoi 1 > if
loc @ { "@battle/" bid @ "/position/A2" }cat
partner @ if
part1 @ setprop
part1 @ "battle/Position" "A2" setto
else
loc @ { "@battle/" bid @ "/teams/A" }cat array_get_propvals foreach temp ! pop
   temp @ loc @ { "@battle/" bid @ "/position/A1" }cat getprop smatch if continue then
   temp @ "status/hp" get temp @ "egg?" get not and if temp @ temp2 ! break then
repeat temp2 @ setprop
temp2 @ "battle/Position" "A2" setto
0 temp2 !
then
loc @ { "@battle/" bid @ "/position/B2" }cat
AIpart @ if
AIpart @ setprop
AIpart @ "battle/Position" "B2" setto
else
loc @ { "@battle/" bid @ "/teams/B" }cat array_get_propvals foreach temp ! pop
   temp @ loc @ { "@battle/" bid @ "/position/B1" }cat getprop smatch if continue then
   temp @ "status/hp" get temp @ "egg?" get not and if temp @ temp2 ! break then
repeat temp2 @ setprop
temp2 @ "battle/Position" "B2" setto
0 temp2 !
then 
then
 
        loc @ { "@battle/" BID @ "/trainers/A" }cat who @ id_name setprop
        loc @ { "@battle/" BID @ "/trainers/B" }cat me @ id_name setprop
        loc @ { "@battle/" BID @ "/gymbattle" }cat "leader" setprop
        loc @ { "@battle/" BID @ "/challengerID" }cat who @ setprop 
(put this part in last to make sure it has everything it needs)        
loc @ { "@Battle/" BID @ "/4moves" }Cat "enabled" setprop
        bid @ set4moves
 
bid @ battlelooper
 
; PUBLIC gymleaderbattle
 
 
$libdef challengebattle
: challengebattle (trainer challenge, this is for things like the battle subway and other challenge types.  The first variable may be if you are using a set team or your own, or the type of challenge)
 
(this is a work in progress so the variables required may change)
 
 
; PUBLIC challengebattle
 
 
: huntpokemon
var 4moves
1 4moves !
loc @ "@poketable/" propdir? not if
"^[o^[rThere aren't any pokemon here to hunt for." tellme exit then
 
me @ "@huntingteam/following" getprop if
 "^[o^[rYou aren't the leader of the group, you can't start the battle." tellme
exit
then
var partner
me @ "@huntingteam/leading" getprop if
 me @ "@huntingteam/leading" getprop partner !
 partner @ location loc @ = not
 partner @ awake? not or
 if
  "^[o^[rYou can't hunt without your partner, wait for them to come back." tellme
 exit
 then
 
then
 
me @ "@battle/battleID" getprop if
"^[o^[rYou are already in a battle.  Finish that one first." tellme
exit
then
 
me @ "@lastbattle" getprop if
        3 var! timeout
        (me @ "@battlespam" over over getprop 1 + setprop)
        (me @ "@battlespam" getprop timeout @ + timeout !)
        systime me @ "@lastbattle" getprop - var! timebetween 
        timebetween @ timeout @ < if
                ({ "^[o^[rYou need to rest a moment, wait ^[c" timeout @ timebetween @ - "^[r more seconds then try +hunt again." }cat tellme
 
                exit)
 
                me @ "@battlespam" getprop 5 >= if
                "^[o^[rSlow down, you're moving too fast..." tellme
                exit
 
                else
 
                        "^[o^[ySearching for pokemon.... one moment..." tellme
                        me @ "@battlespam" over over getprop 1 + setprop
                        (timeout @ timebetween @ -) 1 sleep
                then
        else
        me @ "@battlespam" remove_prop
        then
        ( me @ "@battlespam" remove_prop )
then
 
var abletofight
 
var setxp
var settxp
var tpcost
 
loc @ "@nogain" getprop not if
"on" setxp !
"on" settxp !
partner @ if
 8 tpcost !
else
 10  tpcost !
 then
 else
 0 setxp !
 0 settxp !
 0 tpcost !
then
 
(have this part here set tp cost to 0, remove if you don't want all battles to be free) 
0 tpcost !
 
me @ "@MeNotFight" getprop not if 
me @ "fusion" get if me @ "status/hp" get if 1 abletofight ! then then
then
 
me @ "slot/1" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight ! then
me @ "slot/2" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight ! then
me @ "slot/3" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight ! then
me @ "slot/4" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight ! then
me @ "slot/5" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight ! then
me @ "slot/6" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight ! then
 
abletofight @ not if
"^[r^[oYou don't have any pokemon in fighting condition. +Heal or revive first." tellme
exit
then
 
me @ tpcost @ CheckTP not if
"^[o^[rYou don't have enough TP to battle.  RP more." tellme
exit
then
 
partner @ if
0 abletofight !
partner @ "@MeNotFight" getprop not if
partner @ "fusion" get if partner @ "status/hp" get if 1 abletofight ! then then
then
 
partner @ "slot/1" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight ! then
partner @ "slot/2" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight ! then
partner @ "slot/3" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight ! then
partner @ "slot/4" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight ! then
partner @ "slot/5" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight ! then
partner @ "slot/6" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight ! then
 
abletofight @ not if
"^[r^[oYour partner doesn't have any pokemon in fighting condition.  Have them +heal or revive first." tellme
exit
 
then
 
 
partner @ tpcost @ CheckTP not if
"^[o^[rYour partner doesn't have enough TP to battle.  RP more." tellme
exit
then
 
then
 
var pokeid
 
var mytier
me @ "Tier" get dup not if pop "1" then mytier !
 
new_battle_id var! bid
bid @ stringify "full" smatch if exit then
 
loc @ { "@battle/" BID @ "/XP" }cat setxp @ setprop
loc @ { "@battle/" BID @ "/TXP" }cat settxp @ setprop
loc @ { "@battle/" BID @ "/tpcost" }cat tpcost @ setprop
loc @ { "@battle/" BID @ "/tier" }cat mytier @ setprop
 
(do the code for walking and happiness here)
POKESTORE "@logs/total number of battles" over over getprop 1 + setprop
 
var steps
me @ "@RP/total hunts" over over getprop 1 + setprop
random 50 % 10 + steps !
me @ "total walked steps" over over get atoi steps @ + setto
var totalsteps
me @ "fusion" get if me @ "status/hp" get if me @ "walked steps" over over fget atoi steps @ + totalsteps !  totalsteps @ 256 >= if totalsteps @ 256 - totalsteps ! me @ "happiness" over over fget atoi me @ "holding" get "soothe bell" smatch if 2 else 1 then + fsetto then totalsteps @ fsetto  then then
me @ "happiness" over over fget atoi dup 255 > if pop 255 then fsetto
me @ GetHatchingFactor var! hatchingFactor
var count
var poke
1 6 1 for count !
 me @ { "slot/" count @ }cat get poke !
 poke @ "egg?" get if poke @ "egg?" over over get atoi steps @ hatchingFactor @ * - setto 
     poke @ "egg?" get atoi 0 <= if
       me @ "Your egg is hatching!" "Egg" pretty notify
       me @ { "@achieve/poke-owned/" poke @  "species" get  }cat over over getprop 1 + setprop
       poke @ "Original Trainer" me @ "@RP/id" getprop setto
       poke @ "Egg?" 0 setto
       then
 
 continue then
 poke @ "status/hp" get if poke @ "walked steps" over over get atoi steps @ + totalsteps !  totalsteps @ 256 >= if totalsteps @ 256 - totalsteps ! poke @ "happiness" over over get atoi poke @ "holding" get "soothe bell" smatch if 2 else 1 then + setto then totalsteps @ setto 
 poke @ "happiness" over over get atoi dup 255 > if pop 255 then setto
 then
repeat
 
partner @ if
 partner @ "@RP/total hunts" over over getprop 1 + setprop
 partner @ "total walked steps" over over get atoi steps @ + setto
 partner @ "fusion" get if partner @ "status/hp" get if partner @ "walked steps" over over fget atoi steps @ + totalsteps !  totalsteps @ 256 >= if totalsteps @ 256 - totalsteps ! partner @ "happiness" over over fget atoi partner @ "holding" get "soothe bell" smatch if 2 else 1 then + fsetto then totalsteps @ fsetto  then then
 partner @ "happiness" over over fget atoi dup 255 > if pop 255 then fsetto
 var count
 1 6 1 for count !
  partner @ { "slot/" count @ }cat get poke !
 poke @ "egg?" get if poke @ "egg?" over over get atoi steps @ -  setto 
     poke @ "egg?" get atoi 0 <= if
       partner @ "Your egg is hatching!" "Egg" pretty notify
       partner @ { "@achieve/poke-owned/" poke @  "species" get  }cat over over getprop 1 + setprop
       poke @ "Original Trainer" partner @ "@RP/id" getprop setto
       poke @ "Egg?" 0 setto
       then
 
 continue then
  poke @ "status/hp" get if poke @ "walked steps" over over get atoi steps @ + totalsteps !  totalsteps @ 256 >= if totalsteps @ 256 - totalsteps ! poke @ "happiness" over over get atoi poke @ "holding" get "soothe bell" smatch if 2 else 1 then + setto then totalsteps @ setto 
  poke @ "happiness" over over get atoi dup 255 > if pop 255 then setto
  then
 repeat
then
 
(end walking)
 
(first slot pokemon field ability)
 
(set ability)
var firstability
var abilityholder
me @ "@MeNotFight" getprop not if 
        me @ "@Fusionorder" getprop stringify "first" smatch me @ "fusion" get and if
        me @ "Ability" fget firstability !
        me @ abilityholder !
        then
then
 
 
1 6 1 for temp !
 
firstability @ not me @ { "slot/" temp @ }cat get and me @ { "slot/" temp @ }cat get "egg?" get not and if
me @ { "slot/" temp @ }cat get "ability" fget firstability !
me @ { "slot/" temp @ }cat get abilityholder !
then
 
repeat
 
me @ "@Fusionorder" getprop stringify "first" smatch not 
firstability @ not and
if
me @ "Ability" fget firstability !
me @ abilityholder !
then
 
 
loc @ { "@battle/" BID @ "/firstability" }cat firstability @ setprop
loc @ { "@battle/" BID @ "/abilityholder" }cat abilityholder @ setprop
(section for item/npc/wild occurence)
frand temp !
var itemrate
var npcrate
me @ "@forcespawn" getprop not if
        #0 "@battleprops/itemrate" getprop strtof itemrate !
        #0 "@war/activewar" getprop if
                #0 "@war/npcrate" getprop strtof npcrate !
        else
                #0 "@battleprops/npcrate" getprop strtof npcrate !
        then
then
 
 
(part for item finder)
partner @ not
loc @ "@nogain" getprop not and 
me @ "@noitem" getprop not and
if
        temp @ itemrate @ <= if
                itemfinder
                loc @ { "@Battle/" BID @ }cat remove_prop
                me @ tpcost @ SpendTP
                exit
        else
 
        temp @ itemrate @ - temp !
 
        then
 
then
 
var howmany
partner @ if
"2" howmany !
else
"1" howmany !
then
 
loc @ { "@battle/" BID @ "/battling/" me @ }cat "A" setprop
loc @ { "@battle/" BID @ "/watching/" me @ }cat 1 setprop
partner @ if
loc @ { "@battle/" BID @ "/battling/" partner @ }cat "A" setprop
loc @ { "@battle/" BID @ "/watching/" partner @ }cat 1 setprop
then
 
(howmany is used to say if this is a 1v1 or a 2v2 battle)
 
 
 loc @ { "@battle/" bid @ "/howmany" }cat howmany @ setprop
 
 
(set up the player's team)
var lead1
var part1
 
var count1
1 count1 !
var count2
 
 
var idholder
1 6 1 for count2 !
me @ { "slot/" count2 @ }cat get dup if idholder !
(idholder @ "Egg?" get not if )
loc @ { "@battle/" bid @ "/teams/A/" count1 @ }cat idholder @ setprop
loc @ { "@battle/" bid @ "/control/teamA/" idholder @ }cat me @ setprop
idholder @ "battle/BID" BID @ setto
idholder @ "battle/Team" "A" setto
POKESTORE { "@pokemon/" idholder @ "/@RP/status/statmods/" }cat remove_prop
POKESTORE { "@pokemon/" idholder @ "/@temp/" }cat remove_prop
lead1 @ not if
idholder @ "status/hp" get idholder @ "egg?" get not and if idholder @ lead1 ! then
then
 
1 count1 @ + count1 !
then (else pop then)
repeat
 
me @ "fusion" get me @ "@MeNotFight" getprop not and if
loc @ { "@battle/" bid @ "/teams/A/A" }cat me @ "@RP/id" getprop setprop
loc @ { "@battle/" bid @ "/control/teamA/" me @ "@RP/id" getprop }cat me @ setprop
me @ "battle/BID" BID @ setto
me @ "battle/Team" "A" setto
me @ "@RP/ID" getprop "status/hp" get if 
        me @ "@Fusionorder" getprop stringify "first" smatch 
        lead1 @ not or
        if
        me @ "@RP/ID" getprop lead1 ! 
        then
                
        POKESTORE { "@pokemon/" me @ "@RP/ID" getprop "/@RP/status/statmods/" }cat remove_prop POKESTORE { "@pokemon/" me @ "@RP/ID" getprop "/@temp/" }cat remove_prop 
        then
then
 
 
loc @ { "@battle/" BID @ "/control/teamA/users/" me @ "@rp/id" getprop }cat me @ setprop
 
partner @ if
 
 
 var idholder
 1 6 1 for count2 !
 partner @ { "slot/" count2 @ }cat get dup if idholder !
 POKESTORE { "@pokemon/" idholder @ "/@RP/status/statmods/" }cat remove_prop
 POKESTORE { "@pokemon/" idholder @ "/@temp/" }cat remove_prop
 ( idholder @ "Egg?" get not if )
 loc @ { "@battle/" bid @ "/teams/A/" count1 @ }cat idholder @ setprop
 loc @ { "@battle/" bid @ "/control/teamA/" idholder @ }cat partner @ setprop
 idholder @ "battle/BID" BID @ setto
 idholder @ "battle/Team" "A" setto
 part1 @ not if
 idholder @ "status/hp" get idholder @ "egg?" get not and if idholder @ part1 ! then
 then
 
 1 count1 @ + count1 !
 then (else pop then)
 repeat
 
 partner @ "fusion" get partner @ "@MeNotFight" getprop not and if
 POKESTORE { "@pokemon/" partner @ "@RP/ID" getprop "/@RP/status/statmods/" }cat remove_prop
 POKESTORE { "@pokemon/" partner @ "@RP/ID" getprop "/@temp/" }cat remove_prop
 loc @ { "@battle/" bid @ "/teams/A/B" }cat partner @ "@RP/id" getprop setprop
 loc @ { "@battle/" bid @ "/control/teamA/" partner @ "@RP/id" getprop }cat partner @ setprop
 partner @ "battle/BID" BID @ setto
 partner @ "battle/Team" "A" setto
 partner @ "@RP/ID" getprop "status/hp" get if 
 partner @ "@fusionorder" getprop stringify "first" smatch 
 part1 @ not or
 if
 partner @ "@RP/id" getprop part1 ! then
 then
 
 then
 
 loc @ { "@battle/" BID @ "/control/teamA/users/" partner @ "@rp/id" getprop }cat partner @ setprop
 
 
then
 
(set  battle id on challenger)
me @ "@battle/battleID" bid @ setprop
partner @ if partner @ "@battle/battleID" bid @ setprop then
 
(set the first pokemon to battle)
 
loc @ { "@battle/" bid @ "/teams/A/" }cat propdir? not if
"^[o^[rYou have no pokemon that can fight." tellme
abortbattle
exit
then

(check the leader for if the expshare is on, use this option for everyone)
me @ "@expshare" getprop if
        loc @ { "@battle/" bid @ "/expshare/A" }cat "on" setprop
then
 
temp @ npcrate @ <= 
loc @ "@trainertable/" propdir? and (no point if there's no trainer table right?)
me @ "@noNPC" getprop not and 
if
        (if the npcs are AI, do this)
        loc @ { "@battle/" BID @ "/AItype" }cat "NPC" setprop
 
        mytier @ MinorNPCBattle var! TID (trainer ID)  var! Tteam
 
        var slotcount
        Tteam @ foreach pokeid ! pop
                slotcount @ 1 + slotcount !
                loc @ { "@battle/" BID @ "/teams/B/" slotcount @ }cat pokeid @ setprop
                loc @ { "@battle/" BID @ "/control/teamB/" pokeid @ }cat "AI" setprop
                pokeid @ "battle/BID" BID @ setto
                pokeid @ "battle/Team" "B" setto
 
        repeat
        
        loc @ { "@battle/" BID @ "/control/teamB/AItrainer/1" }cat TID @ setprop
        loc @ { "@battle/" BID @ "/wager" }cat TID @ "credits" get atoi setprop
        howmany @ "2" smatch if
        mytier @ MinorNPCBattle var! TPID (trainer partner ID) var! TPteam
        var aipart
        TPteam @ foreach pokeid !
                slotcount @ 1 + slotcount !
                aipart @ not if
                pokeid @ aipart !
                then
                loc @ { "@battle/" BID @ "/teams/B/" slotcount @ }cat pokeid @ setprop
                loc @ { "@battle/" BID @ "/control/teamB/" pokeid @ }cat "AI" setprop
                pokeid @ "battle/BID" BID @ setto
                pokeid @ "battle/Team" "B" setto
 
        repeat  
        loc @ { "@battle/" BID @ "/control/teamB/AItrainer/2" }cat TPID @ setprop
        loc @ { "@battle/" BID @ "/wager" }cat TPID @ "credits" get atoi loc @ { "@battle/" bid @ "/wager" }cat getprop + setprop
        then
        
        partner @ if
        me @ loc @ { "@battle/" BID @ "/tpcost" }cat getprop SpendTP
        partner @ loc @ { "@battle/" BID @ "/tpcost" }cat getprop SpendTP
        { "^[c^[o" me @ name " ^[yand ^[c" partner @ name "^[y are fighting a pair of trainers, ^[c" TID @ id_name "^[y and ^[c" TPID @ id_name "^[y." }cat "Battle" pretty bnotify
        loc @ { "@battle/" BID @ "/trainers/A" }cat { me @ name " & " partner @ name }cat setprop
        loc @ { "@battle/" BID @ "/trainers/B" }cat { TID @ id_name " & " TPID @ id_name }cat setprop
        else
        me @ loc @ { "@battle/" BID @ "/tpcost" }cat getprop SpendTP
        { "^[c^[o" me @ name "^[y is fighting a trainer, ^[c" TID @ id_name "^[y." }cat "Battle" pretty bnotify
        loc @ { "@battle/" BID @ "/trainers/A" }cat me @ name setprop
        loc @ { "@battle/" BID @ "/trainers/B" }cat TID @ id_name setprop
then
else
 
        (wild)
 
 
        loc @ { "@battle/" bid @ "/AItype" }cat "Wild" setprop
 
        (around here is where you would change it for two wild pokemon instead of just one)
 
        BID @ mytier @ generate_pokemon pokeid !
 
        loc @ { "@battle/" bid @ "/teams/B/1" }cat pokeid @ setprop
        loc @ { "@battle/" bid @ "/control/teamB/" pokeid @ }cat "AI" setprop
        pokeid @ "battle/BID"  BID @ setto
        pokeid @ "battle/Team" "B" setto
 
        var pokeid2
        howmany @ "2" smatch if
        BID @ mytier @ generate_pokemon pokeid2 !
        loc @ { "@battle/" bid @ "/teams/B/2" }cat pokeid2 @ setprop
        loc @ { "@battle/" bid @ "/control/teamB/" pokeid2 @ }cat "AI" setprop
        pokeid2 @ "battle/BID" BID @ setto
        pokeid2 @ "battle/Team" "B" setto
        then
 
 
partner @ if
me @ loc @ { "@battle/" BID @ "/tpcost" }cat getprop SpendTP
partner @ loc @ { "@battle/" BID @ "/tpcost" }cat getprop SpendTP
{ "^[c^[o" me @ name " ^[yand ^[c" partner @ name "^[y are fighting wild pokemon." }cat "Battle" pretty bnotify
else
me @ loc @ { "@battle/" BID @ "/tpcost" }cat getprop SpendTP
{ "^[c^[o" me @ name "^[y is fighting wild pokemon." }cat "Battle" pretty bnotify
then
 
then
 
(before the battle begins, check the 4moves vairable and set everyone involved to their moveset)
var temp
var temp2
 
4moves @ if
loc @ { "@Battle/" BID @ "/4moves" }Cat "enabled" setprop
        bid @ set4moves
then
 
 
loc @ { "@battle/" bid @ "/position/A1" }cat lead1 @ setprop
lead1 @ "battle/Position" "A1" setto
 
loc @ { "@battle/" bid @ "/position/B1" }cat
loc @ { "@battle/" bid @ "/teams/B" }cat array_get_propvals foreach temp ! pop
 
   temp @ "status/hp" get temp @ "egg?" get not and if temp @ temp2 ! break then
repeat temp2 @ setprop
temp2 @ "battle/Position" "B1" setto
0 temp2 !
 
loc @ { "@battle/" bid @ "/howmany" }cat getprop atoi 1 > if
loc @ { "@battle/" bid @ "/position/A2" }cat
partner @ if
part1 @ setprop
part1 @ "battle/Position" "A2" setto
else
loc @ { "@battle/" bid @ "/teams/A" }cat array_get_propvals foreach temp ! pop
   temp @ loc @ { "@battle/" bid @ "/position/A1" }cat getprop smatch if continue then
   temp @ "status/hp" get temp @ "egg?" get not and if temp @ temp2 ! break then
repeat temp2 @ setprop
temp2 @ "battle/Position" "A2" setto
0 temp2 !
then
loc @ { "@battle/" bid @ "/position/B2" }cat
AIpart @ if
AIpart @ setprop
AIpart @ "battle/Position" "B2" setto
else
loc @ { "@battle/" bid @ "/teams/B" }cat array_get_propvals foreach temp ! pop
   temp @ loc @ { "@battle/" bid @ "/position/B1" }cat getprop smatch if continue then
   temp @ "status/hp" get if temp @ temp2 ! break then
repeat temp2 @ setprop
temp2 @ "battle/Position" "B2" setto
0 temp2 !
then 
then
 
bid @ battlelooper
;
 
: pvplist
var tempref
 
"^[o^[g------------------------------------------------------------------------------------" tellme
{
 "^[o^[g| ^[cHost         ^[g|"
 " ^[cPartner      ^[g|"
 " ^[cPW? ^[g|"
 " ^[cSize ^[g|"
 " ^[cSetlev ^[g|"
 " ^[cHP? ^[g|"
 " ^[cVS Size ^[g|"
(" ^[cCost ^[g|")
 " ^[cMoveset  ^[g|"
}cat tellme
"^[o^[g------------------------------------------------------------------------------------" tellme
 
loc @ contents_array foreach swap pop tempref !
  tempref @ player? not tempref @ "D" flag? or if continue then
  tempref @ awake? not if continue then
  tempref @ "@pvp" propdir? not if continue then
  tempref @ "@pvp/opponent" getprop if continue then
  tempref @ "@pvp/howmany" getprop not if continue then
  {
   "^[o^[g| ^[w" tempref @ name 1 12 midstr 12 " " padr " ^[g| "
   "^[w" tempref @ "@pvp/partner" getprop dup if name else pop "No Partner" then 1 12 midstr 12 " " padr  " ^[g| "
   "^[w" tempref @ "@pvp/password" getprop if "Yes" else "No" then 3 " " padr " ^[g| "
   "^[w" tempref @ "@pvp/teamsize" getprop stringify 4 " " padr " ^[g| "
   "^[w" tempref @ "@pvp/setlevel" getprop stringify dup not if pop "Normal" then 6 " " padr " ^[g| "
   "^[w" tempref @ "@pvp/hpboost" getprop stringify dup not if pop "No" else "x" then 3 " " padr " ^[g| "
   "^[w  " tempref @ "@pvp/howmany" getprop atoi 1 = if "1v1" else "2v2" then "   ^[g| "
   ("^[w" tempref @ "@pvp/tpcost" getprop if "yes" else "no" then 4 " " padr " ^[g|")
   "^[w" tempref @ "@pvp/4moves" getprop if "Classic" else "Full" then 7 " " padr "   ^[g| "
 
  }cat tellme
 
  repeat
"^[o^[g--------------------------------------------------------------------------------" tellme
;
 
: pvpcreate
var choice
me @ "@huntingTeam/following" getprop if
"^[o^[yYou have to be the leader to make a pvp request." tellme
exit
then
me @ "@pvp" propdir? if
"^[o^[yYou must not be in a pvp to create a pvp." tellme
exit
then
me @ "@battle" propdir? if
"^[o^[yYou must not be in a battle to create a pvp." tellme
exit
then
begin
"^[o^[yPVP battle creation" tellme
"^[o^[yUse ^[r.abort ^[yanytime to cancel." tellme
"^[o^[yPublic or Private battle?" tellme
"^[o^[y1. Public    2. Private" tellme
read choice !
  choice @ ".abort" smatch if "^[rAborted" tellme exit then
  choice @ "1" smatch if break then
  choice @ "2" smatch if break then
    "^[o^[yI didn't quite get that. Try again." tellme
repeat
 
 
choice @ "2" smatch if
 var password
 begin
 "^[o^[yEnter password for battle." tellme
 read password !
 password @ ".abort" smatch if "^[rAborted" tellme exit then
 password @ if
 { "^[o^[yPassword entered as '^[c" password @ "^[y'." }Cat tellme break then
 "^[o^[yInvalid password. try again." tellme
 repeat
then
 
var howmany
begin
"^[o^[yIs this going to be 1v1 or 2v2?" tellme
"^[o^[y1. 1v1    2. 2v2" tellme
read howmany !
  howmany @ ".abort" smatch if "^[rAborted" tellme exit then
  howmany @ "1" smatch if
  me @ "@huntingTeam/leading" getprop if
  "^[o^[yYou can't do a 1v1 while you have a partner." tellme exit
  then
 
  break then
  howmany @ "2" smatch if break then
    "^[o^[yI didn't quite get that. Try again." tellme
 
repeat
 
var teamsize
begin
"^[o^[yHow many pokemon will participate in this battle?" tellme
 
howmany @ "1" smatch if
"^[o^[yBetween 1 and 7 [6 recommended]." tellme
else
"^[o^[yBetween 2 and 14. [even only, 6 recommended]" tellme
then
 
read teamsize !
teamsize @ ".abort" smatch if "^[rAborted" tellme exit then
teamsize @ atoi teamsize !
teamsize @ howmany @ atoi >= if
howmany @ atoi 2 =
teamsize @ 2 % 0 = and
teamsize @ 14 <= and
if
{ "^[o^[yBattle set for ^[c" teamsize @ "^[y teammates." }cat tellme break then
howmany @ atoi 1 = teamsize @ 7 <= and if
{ "^[o^[yBattle set for ^[c" teamsize @ "^[y teammates." }cat tellme break
then
 
then
"^[o^[yI didn't quite get that. Try again." tellme
repeat
 
var battletype
var setlevel
var tpcost
var fourmoves
begin
"^[o^[yWhich type of battle do you want to have?" tellme
"^[o^[y1. Set Level 50 Battle. [no growth]" tellme
"^[o^[y2. Set Level 100 Battle. [no growth]" tellme
{ "^[o^[y3. Training battle [full growth]" ( me @ "@huntingTeam/leading" getprop not if "8" else "6" then " TP cost]") }cat tellme
"^[o^[y4. Spar Battle [no growth]" tellme
"^[o^[y5. Set Level 5 Battle [no growth]" tellme
read battletype !
battletype @ "1" smatch if 50 setlevel ! break then
battletype @ "2" smatch if 100 setlevel ! break then
battletype @ "3" smatch if me @ "@pvp/growth" "yes" setprop me @ "@huntingTeam/leading" getprop not  if 8 else 6 then tpcost ! break then
battletype @ "4" smatch if break then
battletype @ "5" smatch if 5 setlevel ! break then
battletype @ ".abort" smatch if "^[rAborted" tellme exit then
"^[o^[yI didn't quite get that. Try again." tellme
repeat
 (zero cost set here)
 0 tpcost !
0 var! hpboost
(battletype @ "3" smatch not if
 
        "^[o^[yDo you want to use a hp boost?  Enter a number between 2 and 4 if you do." tellme
        read atoi hpboost !
        hpboost @ 2 >=
        hpboost @ 4 <= and if
                { "^[o^[yBoost set to ^[c" hpboost @ "^[y." }cat tellme
        else
                "^[o^[yNo boost set." tellme
                0 hpboost !
        then
        
then
)  (disabled feature, was a mess)
"^[o^[yDo you want to use full movesets for this battle?" tellme
read fourmoves !
 
fourmoves @ "y*" smatch not if "yes" fourmoves ! else 0 fourmoves ! then
 
me @ tpcost @ CheckTP not if
"^[o^[rYou don't have enough TP to battle.  RP more." tellme
exit
then
 
me @ "@huntingteam/leading" getprop if
        me @ "@huntingteam/leading" getprop tpcost @ CheckTP not if
        "^[o^[rYour partner doesn't have enough TP to battle.  RP more." tellme
        exit
        then
then
 
 
me @ "@pvp/password" password @ setprop
me @ "@pvp/howmany" howmany @ setprop
me @ "@pvp/teamsize" teamsize @ setprop
me @ "@pvp/battletype" battletype @ setprop
me @ "@pvp/setlevel" setlevel @ setprop
me @ "@pvp/tpcost" tpcost @ setprop
(me @ "@pvp/hpboost" hpboost @ setprop)
me @ "@pvp/4moves" fourmoves @ setprop
me @ "@pvp/partner" me @ "@huntingTeam/leading" getprop setprop
me @ "@pvp/host" me @ setprop
me @ "@pvp/team" "A" setprop
me @ "@huntingTeam/leading" getprop if
me @ "@huntingteam/leading" getprop "@pvp/host" me @ setprop
me @ "@huntingteam/leading" getprop "@pvp/team" "A" setprop
{ "^[o^[c" me @ name "^[y and ^[c" me @ "@huntingTeam/leading" getprop name "^[y are looking to battle. " }cat "PVP" pretty tellhere
me @ "@huntingteam/leading" getprop "^[y^[oUse +pvp/teamsetup to set up your team" notify
else
{ "^[o^[c" me @ name "^[y is looking to battle. " }cat "PVP" pretty tellhere
then
"^[y^[oUse +pvp/teamsetup to set up your team" tellme
;
 
 
: pvpjoin
var! who
who @ not if me @ name who ! then
who @ part_pmatch #-1 dbcmp not if
   who @ part_pmatch #-2 dbcmp not if
           who @ part_pmatch who !
   else
   who @ pmatch #-1 dbcmp not if
           who @ pmatch who !
 
   else
   { "^[rwhich ^[g" who @ "^[r do you mean!" }cat tellme exit
   then
   then
else
   who @ pname-ok? not if
   { "^[o^[g" who @ 1 strcut pop toupper who @ 1 strcut swap pop tolower "^[y is not on right now." }cat tellme exit
   else
   { "^[rI don' know who ^[y" who @ 1 strcut pop toupper who @ 1 strcut swap pop tolower "^[r is!" }cat tellme exit
   then
then
 
 
me @ "@battle" propdir? if
"^[o^[yYou must not be in a battle to join a pvp." tellme exit then
 
me @ "@huntingteam/following" getprop if
"^[o^[rYou have to be the leader to join a pvp." tellme exit then
 
me @ "@pvp" propdir? if "^[o^[rOne battle at a time, stop being so anxious. Use +pvpabort if you changed your mind" tellme exit then
who @ me @ = if "^[r^[oYou can't join yourself!" tellme exit then
 
loc @ contents_array who @ array_findval array_count not if
"^[r^[oThey aren't in the same room as you!" tellme exit
then
 
 
who @ "@pvp" propdir? not if "^[r^[oThey aren't trying to host right now!" tellme exit then
 
"^[o^[g------------------------------------------------------------------------------" tellme
{ "^[o^[g    Host: ^[w" who @ name  }cat tellme
{ "^[o^[g Partner: ^[w" who @ "@pvp/partner" getprop dup if name else pop "No Partner" then }cat tellme
{ "^[o^[gPassword: ^[w" who @ "@pvp/password" getprop if "Yes" else "No" then   }cat tellme
{ "^[o^[gTeamSize: ^[w" who @ "@pvp/teamsize" getprop  }cat tellme
{ "^[o^[g   Level: ^[w" who @ "@pvp/setlevel" getprop dup not if pop "Normal" then }cat tellme
({ "^[o^[gHP Boost: ^[w" who @ "@pvp/hpboost" getprop dup not if pop "No" else "x" then }cat tellme)
{ "^[o^[g VS Size: ^[w" who @ "@pvp/howmany" getprop atoi 1 = if "1v1" else "2v2" then  }cat tellme
{ "^[o^[g Moveset: ^[w" who @ "@pvp/4moves" getprop if "4moves" else "Full" then }cat tellme
({ "^[o^[g TP Cost: ^[w" who @ "@pvp/tpcost" getprop not if "Free" else me @ "@huntingTeam/leading" getprop not  if 8 else 6 then  then stringify  }cat tellme )
"^[o^[g------------------------------------------------------------------------------" tellme
me @ "@huntingteam/leading" getprop who @ "@pvp/howmany" getprop atoi 1 = and if
"^[o^[rYou can't join a 1v1 battle with a partner, break the team first." tellme exit then
 
"^[o^[gDo you want to join this battle?" tellme
var choice
read choice !
choice @ "y*" smatch not if "^[o^[rEnding." tellme exit then
 
who @ "@pvp/growth" getprop if
me @ "@valid?/email" getprop who @ "@valid?/email" getprop smatch if
"^[o^[rYou can't do that type of battle with your alt.  You can't earn from your alt." "Hunting Party" pretty tellme
exit
then
 
me @ "@huntingTeam/leading" getprop not  if 8 else 6 then var! tpcost 
then
 
me @ tpcost @ CheckTP not if
"^[o^[rYou don't have enough TP to battle.  RP more." tellme
exit
then
 
me @ "@huntingteam/leading" getprop if
       me @ "@huntingteam/leading" getprop tpcost @ CheckTP not if
        "^[o^[rYour partner doesn't have enough TP to battle.  RP more." tellme
        exit
        then
then
3 var! battlemax
 
who @ "@pvp/growth" getprop if
        me @ { "@battled/" who @ }cat getprop battlemax @ > if
        { "^[o^[rYou have battled ^[c" who @ name " ^[rtoo many times today." }cat tellme 
        exit
        then
 
 
        who @ "@huntingTeam/leading" getprop if
        me @ { "@battled/" who @ "@huntingTeam/leading" }cat getprop battlemax @ > if
        { "^[o^[rYou have battled ^[c" who @ "@huntingTeam/leading" getprop name " ^[rtoo many times today." }cat tellme 
        exit
        then then
 
        me @ "@huntingteam/leading" getprop if
 
                me @ "@huntingteam/leading" getprop { "@battled/" who @ }cat getprop battlemax @ > if
                { "^[o^[rYour partner has battled ^[c" who @ name " ^[rtoo many times today." }cat tellme 
                exit
                then
 
 
                who @ "@huntingTeam/leading" getprop if
                me @ "@huntingteam/leading" getprop { "@battled/" who @ "@huntingTeam/leading" }cat getprop battlemax @ > if
                { "^[o^[rYour partner has battled ^[c" who @ "@huntingTeam/leading" getprop name " ^[rtoo many times today." }cat tellme 
                exit
                then then
        then 
 
then
who @ "@pvp/password" getprop if
 var password
 who @ "@pvp/password" getprop password !
 "^[o^[gThis battle is password protected.  Enter password" tellme
 read choice !
 password @ choice @ smatch not if { "^[r^[oinvalid password, '" choice @ "' try again or ask host for password again" }cat tellme exit then
then
 
var opponent
{
 who @ name
 who @ "@huntingTeam/leading" getprop if " and " who @ "@huntingTeam/leading" getprop name then
 
}cat opponent !
 
me @ "@huntingTeam/leading" getprop if
me @ "@huntingteam/leading" getprop "@pvp/host" who @ setprop
me @ "@huntingteam/leading" getprop "@pvp/team" "B" setprop
me @ "@huntingteam/leading" getprop { "^[y^[oGet ready to battle " opponent @ ".  Use +pvp/teamsetup to set up your team" }cat notify then
{ "^[y^[oGet ready to battle " opponent @ ".  Use +pvp/teamsetup to set up your team" }cat tellme
 
var myteam
{
 me @ name
 me @ "@huntingTeam/leading" getprop if " and " me @ "@huntingTeam/leading" getprop name then
}cat myteam !
 
{ "^[o^[c" myteam @ " ^[gaccepts^[c " opponent @ "'s ^[gpvp request!" }cat "PVP" pretty bnotify
 
me @ "@pvp/host" who @ setprop
me @ "@pvp/team" "B" setprop
who @ "@pvp/opponent" me @ setprop
 
;
 
: pvpabort
 
var host
var opponent
me @ "@huntingTeam/following" getprop if
"^[o^[rYou are the follower, you can't abort the pvp request." exit
then
me @ "@pvp" propdir? not if
"^[o^[rYou aren't in a pvp yet." tellme exit then
 
me @ "@pvp/host" getprop host !
host @ me @ = if
 
me @ "@huntingteam/leading" getprop if
me @ "@huntingteam/leading" getprop "@pvp" remove_prop
then
 
me @ "@pvp/opponent" getprop if
me @ "@pvp/opponent" getprop opponent !
opponent @ "@pvp" remove_prop
opponent @ "@huntingteam/leading" getprop if
opponent @ "@huntingteam/leading" getprop "@pvp" remove_prop then
then
 
me @ "@pvp" remove_prop
{ "^[o^[c" me @ name " ^[gremoved their pvp request." }cat "PVP" pretty tellhere
else
me @ "@huntingteam/leading" getprop if
me @ "@huntingteam/leading" getprop "@pvp" remove_prop
then
 
 
host @ "@pvp/opponent" remove_prop
 
me @ "@pvp" remove_prop
{ "^[o^[c" me @ name " ^[gchanged their mind about battling ^[c" host @ name "^[g." }cat "PVP" pretty tellhere
then
 
;
 
: pvpbegin
var! host
var 4moves
 
startprop @ if
me @ "@pvp/host" getprop me @ not = if
"^[o^[rYou aren't hosting a pvp." tellme
exit
then
then
var howmany
 
host @ "@pvp/4moves" getprop 4moves ! 
host @ "@pvp/howmany" getprop stringify howmany !
 
var teamsize
host @ "@pvp/teamsize" getprop teamsize !
(
host @ "@pvp/setup/team/A/" array_get_propvals array_count host @ "@pvp/setup/handicap/A" getprop + teamsize @  =
host @ "@pvp/setup/team/B/" array_get_propvals array_count host @ "@pvp/setup/handicap/B" getprop + teamsize @  = and not if exit then
)
host @ "@pvp/setup/team/A/ready" getprop host @ "@pvp/setup/team/B/ready" getprop + 2.0 >= not if exit then
var bid
new_battle_id bid !
bid @ stringify "full" smatch if
host @ "^[o^[yThere isn't room to battle right now. Use +pvp/start to try again when there is room." notify
exit then
loc @ { "@battle/" BID @ "/AItype" }cat "Player" setprop
host @ "@pvp/growth" getprop if
loc @ { "@battle/" BID @ "/XP" }cat "on" setprop
loc @ { "@battle/" BID @ "/TXP" }cat "on" setprop
then
 
 
 
host @ { "@pvp/setup/multiplayer/A/numplayers" }cat 1 setprop 
host @ { "@pvp/setup/multiplayer/B/numplayers" }cat 1 setprop 
var partner
0 partner !
var opponent
var opartner
0 opartner !
 
host @ "@pvp/opponent" getprop opponent ! 
 
loc @ { "@battle/" BID @ "/battling/" host @ }cat "A" setprop
loc @ { "@battle/" BID @ "/watching/" host @ }cat 1 setprop
host @ "@battle/BattleID" bid @ setprop
host @ host @ "@pvp/tpcost" getprop SpendTP
 
loc @ { "@battle/" BID @ "/battling/" opponent @ }cat "B" setprop
loc @ { "@battle/" BID @ "/watching/" opponent @ }cat 1 setprop
opponent @ "@battle/BattleID" bid @ setprop
opponent @ host @ "@pvp/tpcost" getprop SpendTP
 
 
host @ "@huntingTeam/leading" getprop if
host @ "@huntingTeam/leading" getprop partner !
host @ { "@pvp/setup/multiplayer/A/numplayers" }cat 2 setprop 
 
loc @ { "@battle/" BID @ "/battling/" partner @ }cat "A" setprop
loc @ { "@battle/" BID @ "/watching/" partner @ }cat 1 setprop
partner @ "@battle/BattleID" bid @ setprop
partner @ host @ "@pvp/tpcost" getprop SpendTP
then
 
opponent @ "@huntingTeam/leading" getprop if
opponent @ "@huntingTeam/leading" getprop opartner !
host @ { "@pvp/setup/multiplayer/B/numplayers" }cat 2 setprop  
loc @ { "@battle/" BID @ "/battling/" opartner @ }cat "B" setprop
loc @ { "@battle/" BID @ "/watching/" opartner @ }cat 1 setprop
opartner @ "@battle/BattleID" bid @ setprop
opartner @ host @ "@pvp/tpcost" getprop SpendTP 
then

host @ "@expshare" getprop if
        loc @ { "@battle/" bid @ "/expshare/A" }cat "on" setprop
then 

opponent @ "@expshare" getprop if
        loc @ { "@battle/" bid @ "/expshare/B" }cat "on" setprop
then
 
 
loc @ { "@battle/" BID @ "/howmany" }cat howmany @ setprop
var count1
var id
(set the temp level)
var level
host @ "@pvp/setlevel" getprop level !
 
var hpboost
host @ "@pvp/hpboost" getprop hpboost !
 
var currhp
var newmaxhp
var maxhp
var cont
 
(use this to check if it's a multi team and sort accordingly)
var team
var temp
0 count1 !
{ "A" "B" }list foreach team ! pop
        0 count1 !
        host @ { "@pvp/setup/multiplayer/" team @ }cat propdir? not if continue then
        1 host @ { "@pvp/setup/multiplayer/" team @ "/numplayers" }cat getprop 1 for cont !
                1 teamsize @ host @ { "@pvp/setup/multiplayer/" team @ "/numplayers" }cat getprop / 1 for temp !
                host @ { "@pvp/setup/multiplayer/" team @ "/" cont @ "/" temp @ }cat getprop not if continue then
                count1 @ 1 + count1 !
                host @ { "@pvp/setup/team/" team @ "/" count1 @ }cat
                host @ { "@pvp/setup/multiplayer/" team @ "/" cont @ "/" temp @ }cat getprop setprop
                repeat
        repeat
repeat
 
1 teamsize @ 1 for count1 !
(reminder note. set this up later to have the control setting on it)
{ "A" "B" }list foreach team ! pop
host @ { "@pvp/setup/team/" team @ "/" count1 @ }cat getprop id !
id @ if
        loc @ { "@battle/" BID @ "/control/team" team @ "/" id @ }cat
        host @ { "@pvp/setup/team/" team @ "/control/" id @  }cat getprop cont !
        cont @ setprop
        loc @ { "@battle/" BID @ "/teams/" team @ "/" count1 @ }cat id @ setprop
        loc @ { "@battle/" BID @ "/control/team" team @ "/users/" cont @ "@rp/id" getprop }cat cont @ setprop
 
 
        id @ "status/hp" get atoi currhp !
        id @ "MaxHP" Calculate maxhp !
        id @ "level" level @ setto
        id @ "pvp/hpboost" hpboost @ fsetto
        id @ "MaxHP" Calculate newmaxhp !
        id @ "status/hp" currhp @ newmaxhp @ * maxhp @ / setto
 
then 
repeat
repeat
 
loc @ { "@battle/" bid @ "/position/A1" }cat
loc @ { "@battle/" BID @ "/teams/A/1" }cat getprop setprop
loc @ { "@battle/" bid @ "/position/B1" }cat
loc @ { "@battle/" BID @ "/teams/B/1" }cat getprop setprop
 
howmany @ atoi 1 > if
loc @ { "@battle/" bid @ "/position/A2" }cat
host @ { "@pvp/setup/multiplayer/A/numplayers" }cat getprop 1 = if
loc @ { "@battle/" BID @ "/teams/A/2" }cat 
else
host @ { "@pvp/setup/multiplayer/A/2/1" }cat
then
getprop setprop
 
loc @ { "@battle/" bid @ "/position/B2" }cat
host @ { "@pvp/setup/multiplayer/B/numplayers" }cat getprop 1 = if
loc @ { "@battle/" BID @ "/teams/B/2" }cat 
else
host @ { "@pvp/setup/multiplayer/B/2/1" }cat
then
getprop setprop
then
 
 
var opponent
var opartner
0 opartner !
host @ "@pvp/opponent" getprop opponent !
{
"^[y^[oTrainer Battle! ^[c" host @ name 
host @ "@huntingteam/leading" getprop if
        " ^[y& ^[c" host @ "@huntingteam/leading" getprop name
then
" ^[yVS ^[c" 
opponent @ name 
opponent @ "@huntingteam/leading" getprop if
        " ^[y& ^[c" opponent @ "@huntingteam/leading" getprop name
then
 
"^[y!"
}cat "PVP" pretty tellhere
 
loc @ { "@battle/" BID @ "/trainers/A" }cat 
        { host @ name 
        host @ "@huntingteam/leading" getprop if
        " & " host @ "@huntingteam/leading" getprop name
        then 
        }cat setprop
 
loc @ { "@battle/" BID @ "/trainers/B" }cat {
                opponent @ name 
                opponent @ "@huntingteam/leading" getprop if
                        " & " opponent @ "@huntingteam/leading" getprop name
                then
        }cat setprop
 
(set final battle props)
( redundent 
loc @ { "@battle/" BID @ "/battling/" host @ }cat "A" setprop
loc @ { "@battle/" BID @ "/watching/" host @ }cat 1 setprop
host @ "@battle/BattleID" bid @ setprop
host @ host @ "@pvp/tpcost" getprop SpendTP
 
loc @ { "@battle/" BID @ "/battling/" opponent @ }cat "B" setprop
loc @ { "@battle/" BID @ "/watching/" opponent @ }cat 1 setprop
opponent @ "@battle/BattleID" bid @ setprop
opponent @ host @ "@pvp/tpcost" getprop SpendTP
 
var partner
0 partner !
host @ "@huntingTeam/leading" getprop if
host @ "@huntingTeam/leading" getprop partner !
 
loc @ { "@battle/" BID @ "/battling/" partner @ }cat "A" setprop
loc @ { "@battle/" BID @ "/watching/" partner @ }cat 1 setprop
partner @ "@battle/BattleID" bid @ setprop
partner @ host @ "@pvp/tpcost" getprop SpendTP
then
 
opponent @ "@huntingTeam/leading" getprop if
opponent @ "@huntingTeam/leading" getprop opartner !
 
loc @ { "@battle/" BID @ "/battling/" opartner @ }cat "B" setprop
loc @ { "@battle/" BID @ "/watching/" opartner @ }cat 1 setprop
opartner @ "@battle/BattleID" bid @ setprop
opartner @ host @ "@pvp/tpcost" getprop SpendTP 
then
)
(set the battled props)
 
host @ "@pvp/growth" getprop if
 
        host @ { "@battled/" opponent @ }cat over over getprop 1 + setprop
        opartner @ if
        host @ { "@battled/" opartner @ }cat over over getprop 1 + setprop
        then
 
        partner @ if
                partner @ { "@battled/" opponent @ }cat over over getprop 1 + setprop
                opartner @ if
                partner @ { "@battled/" opartner @ }cat over over getprop 1 + setprop
                then
        then
 
        opponent @ { "@battled/" host @ }cat over over getprop 1 + setprop
 
        partner @ if
        opponent @ { "@battled/" partner @ }cat over over getprop 1 + setprop
        then
 
        opartner @ if
                opartner @ { "@battled/" host @ }cat over over getprop 1 + setprop
                partner @ if
                opartner @ { "@battled/" partner @ }cat over over getprop 1 + setprop
                then
        then
then
(remove pvp props)
 
 
host @ "@huntingteam/leading" getprop if
host @ "@huntingteam/leading" getprop "@pvp" remove_prop
then
 
host @ "@pvp/opponent" getprop if
host @ "@pvp/opponent" getprop opponent !
opponent @ "@pvp" remove_prop
opponent @ "@huntingteam/leading" getprop if
opponent @ "@huntingteam/leading" getprop "@pvp" remove_prop then
then
 
host @ "@pvp" remove_prop
 
(set 4moves)
4moves @ if
loc @ { "@Battle/" BID @ "/4moves" }Cat "enabled" setprop
        bid @ set4moves
then
 
 
bid @ battlelooper
;
 
: pvpteamsetup
var host
var team
var howmany
var teamsize
me @ "@pvp/team/placed/byposition" propdir? if
"^[o^[rYou have already set your team." tellme
exit then
 
me @ "@pvp/host" getprop not if
"^[o^[rYou aren't ready to set your team." tellme
exit then
 
me @ "@pvp/host" getprop host !
me @ "@pvp/team" getprop team !
host @ "@pvp/howmany" getprop howmany !
host @ "@pvp/teamsize" getprop teamsize !
 
var abletofight
 
me @ "fusion" get if me @ "status/hp" get if 1 abletofight @ + abletofight ! then then
me @ "slot/1" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight @ + abletofight ! then
me @ "slot/2" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight @ + abletofight ! then
me @ "slot/3" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight @ + abletofight ! then
me @ "slot/4" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight @ + abletofight ! then
me @ "slot/5" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight @ + abletofight ! then
me @ "slot/6" get temp ! temp @ "status/hp" get temp @ "egg?" get not and if 1 abletofight @ + abletofight ! then
 
abletofight @ not if
"^[r^[oYou don't have any pokemon in fighting condition." tellme
exit
then
 
 
var count1
var count2
1 count1 !
me @ "fusion" get if
me @ "@RP/ID" getprop "status/hp" get if me @ "@pvp/team/A" me @ "@RP/id" getprop setprop
 
then then
 
var idholder
1 6 1 for count2 !
me @ { "slot/" count2 @ }cat get dup if idholder !
idholder @ "Egg?" get not if
me @ { "@pvp/team/" count1 @ }cat idholder @ setprop
1 count1 @ + count1 !
then else pop then
repeat
 
var count3
var amountset
 
me @ "@huntingteam/leading" getprop me @ "@huntingteam/following" getprop or if
teamsize @ 2 / amountset !
else
teamsize @ amountset !
then
 
( amountset @ var! handicap) (this is the number used to make the system think there are more on the team) 
 
1 amountset @ 1 for count3 !
 var id
 var counter
 var notvalid
 var maxhp
 var percent
 var othercont
 var fusionnudge
 
 var trainer1
 
 me @ "@pvp/team/A" getprop trainer1 !
 
 trainer1 @ if 1 fusionnudge ! then
 
 0 counter !
 { "^[y^[o------------------------------------------------------------------------" }cat tellme
 1 me @ "@pvp/team/" array_get_propvals array_count 1 for id !
 
 id @ fusionnudge @ - id !
 
 id @ 1 < if
        trainer1 @ if
                0 trainer1 !
                "A" id !
        then
then
id @ counter !
  me @ { "@pvp/team/" id @ }cat getprop id !
 
  0 notvalid !
  me @ { "@pvp/team/placed/" id @ }cat getprop if 2 notvalid ! then
  id @ "status/hp" get not if 3 notvalid ! then
 
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
 
  id @ "gender" fget "N*" smatch if
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
 
  { "^[y<Position: " me @ { "@pvp/team/placed/" id @ }cat getprop  ">"}cat
  then
 
  notvalid @ 3 = if
  "^[r<Fainted>"
  then
 
 
  }cat tellme
 repeat
 
 { "^[y^[o------------------------------------------------------------------------" }cat tellme
 begin
  { "^[o^[rWhat pokemon do you want in position " count3 @ "? use .end if you are finished use .abort to abort" }cat "TeamSetup" pretty tellme
  read arg !
  
  arg @ ".end" smatch if
  me @ "@pvp/team/placed/byposition/" propdir? if
  break
  else
  "^[r^[oYou need atleast one pokemon selected to be done." "TeamSetup" pretty tellme
  continue
  then
  then
  
  arg @ ".abort" smatch if
  "^[r^[oAborted." "TeamSetup" pretty tellme
  me @ "@pvp/team/placed" remove_prop
  exit
  then
  arg @ strip arg !
 
  arg @ "A" smatch 
  arg @ "B" smatch or not if
  arg @ atoi arg ! then
 
  arg @ not if
  "^[o^[rInvalid pokemon position." "TeamSetup" pretty tellme
  continue
  then
 
  me @ { "@pvp/team/" arg @ }cat getprop not if
  "^[o^[rThere isn't a pokemon there." "TeamSetup" pretty tellme
  continue
  then
 
  me @ { "@pvp/team/" arg @ }cat getprop arg !
 
  0 notvalid !
  me @ { "@pvp/team/placed/" arg @ }cat getprop if 2 notvalid ! then
  arg @ "status/hp" get not if 3 notvalid ! then
 
  notvalid @ if
  "^[o^[rYou can't use that pokemon at this time." "Battle" pretty tellme
  continue
  then
  me @ { "@pvp/team/placed/" arg @ }cat count3 @ setprop
  me @ { "@pvp/team/placed/byposition/" count3 @ }cat arg @ setprop
  break
 repeat
repeat
 
{ "^[y^[o------------------------------------------------------------------------" }cat tellme
0 counter !
 1 me @ "@pvp/team/placed/byposition/" array_get_propvals array_count 1 for id !
  me @ { "@pvp/team/placed/byposition/" id @ }cat getprop id !
  counter @ 1 + counter !
 
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
 
  id @ "gender" fget "N*" smatch if
  "^[o^[m" { id @ "gender" fget 1 1 midstr }cat
  then
  " "
  var hpcolor
 
  id @ "MaxHP" Calculate maxhp !
 
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
 
  }cat tellme
 repeat
{ "^[y^[o------------------------------------------------------------------------" }cat tellme
"^[y^[oAre you sure you want this as your team?" tellme
read arg !
  arg @ "y*" smatch not if
  "^[r^[oAborted." tellme
  me @ "@pvp/team/placed" remove_prop
  exit
  else
  0 count1 !
  (me @ "@huntingteam/following" getprop if
  teamsize @ 2 / count1 !
  then )
  var posnum
  me @ "@huntingteam" propdir? if
        me @ "@huntingteam/following" getprop if 2 posnum ! else 1 posnum ! then
        
  else
  0 posnum !
  then
  1 me @ "@pvp/team/placed/byposition/" array_get_propvals array_count 1 for id !
  count1 @ 1 + count1 !
  posnum @ if
          host @ { "@pvp/setup/multiplayer/" me @ "@pvp/team" getprop "/" posnum @ "/" count1 @ }cat
  else
          host @ { "@pvp/setup/team/" me @ "@pvp/team" getprop "/" count1 @ }cat
  then
            me @ { "@pvp/team/placed/byposition/" id @ }cat getprop setprop
  host @ { "@pvp/setup/team/" me @ "@pvp/team" getprop "/control/" me @ { "@pvp/team/placed/byposition/" id @ }cat getprop }cat me @ setprop
  repeat
  (
  handicap @ count3 @ - handicap !
  host @ { "@pvp/setup/handicap/" me @ "@pvp/team" getprop }cat over over getprop handicap @ + setprop )
  host @ { "@pvp/setup/team/" me @ "@pvp/team" getprop "/ready" }cat over over getprop 
  me @ "@huntingteam/leading" getprop me @ "@huntingteam/following" getprop or if 
  0.5
  else
  1.0 
  then
  + setprop
  "^[g^[oTeam Ready." tellme
  host @ pvpbegin
  then
 
;
 
 
: pvphelp
"+pvp" titlebar
" ^[wPlayer vs Player commands" cleanline tellme
" ^[o^[y+pvp/list       ^[x^[g- ^[wShows all active pvp requests in the room." cleanline tellme
" ^[o^[y+pvp/create     ^[x^[g- ^[wCreates a new PVP request." cleanline tellme
" ^[o^[y+pvp/join       ^[x^[g- ^[wJoin an open PVP request, requires's target name." cleanline tellme
" ^[o^[y+pvp/abort      ^[x^[g- ^[wAborts a PVP request." cleanline tellme
" ^[o^[y+pvp/teamsetup  ^[x^[g- ^[wSetup the team after accepting a PVP request." cleanline tellme
" ^[o^[y+pvp/start      ^[x^[g- ^[wStart a ready PVP." cleanline tellme
hline
 
;
 


: main
idletimer
strip arg !
 
me @ "@version" getprop not if "^[o^[rVersion not set, please type +pversion and choose a version." tellme exit then
 
command @ "+hunt" smatch if huntpokemon exit then
command @ "+pvp" smatch if pvphelp exit then
command @ "+pvp/list" smatch if pvplist exit then
command @ "+pvp/create" smatch if pvpcreate exit then
command @ "+pvp/join" smatch if arg @ pvpjoin exit then
command @ "+pvp/abort" smatch if pvpabort exit then
command @ "+pvp/teamsetup" smatch if pvpteamsetup exit then
command @ "+pvp/start" smatch if 1 startprop ! me @ pvpbegin exit then
command @ "+NPC/battle" smatch if NPCfight exit then
;