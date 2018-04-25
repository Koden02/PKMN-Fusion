$include #3 (ansilib)
$include #6 (useful)
 
: main
var email
strip var! who
 
me @ "W" flag? not me @ "@validator?" getprop not and if "^[rAccess Denied" tellme exit then
 
who @ pmatch
dup not if pop "^[o^[rWho?" tellme exit then
who !
 
who @ "@rp/ID" getprop not if "^[o^[rPlayer not chargen'd!" tellme exit then
who @ "@valid?/AUP" getprop not if "^[o^[rPlayer needs to agree to the AUP first!" tellme exit then
who @ "@valid?/when" getprop if "^[o^[rPlayer is already valid!" tellme exit then
who @ "@prevalid/e-mail" getprop dup if email ! else pop 
"^[o^[yEmail? ^[r(.abort to cancel)" tellme
read dup ".abort" smatch if pop "^[rCanceled" tellme exit then email !
then
who @ "@valid?/email" email @ setprop
who @ "@valid?/wizard" me @ setprop
who @ "@valid?/when" systime setprop
who @ "@battleignorenotify" "off" setprop
 
var ID
who @ "@rp/ID" getprop ID !
 
POKESTORE { "@pokemon/" id @ "/@RP/tp" }cat 1000 setprop
POKESTORE { "@pokemon/" id @ "/@RP/inventory/Poke Ball" }cat 10 setprop
POKESTORE { "@pokemon/" id @ "/@RP/inventory/Potion" }cat 5 setprop
POKESTORE { "@pokemon/" id @ "/@RP/inventory/power anklet" }cat 1 setprop
POKESTORE { "@pokemon/" id @ "/@RP/inventory/power band" }cat 1 setprop
POKESTORE { "@pokemon/" id @ "/@RP/inventory/power belt" }cat 1 setprop
POKESTORE { "@pokemon/" id @ "/@RP/inventory/power bracer" }cat 1 setprop
POKESTORE { "@pokemon/" id @ "/@RP/inventory/power lens" }cat 1 setprop
POKESTORE { "@pokemon/" id @ "/@RP/inventory/power weight" }cat 1 setprop
POKESTORE { "@pokemon/" id @ "/@RP/inventory/Everstone" }cat 1 setprop
POKESTORE { "@pokemon/" id @ "/@RP/inventory/Lucky Egg" }cat 1 setprop
 
  var listener
  { online pop }list foreach listener ! pop
    listener @ "@com/switch/Staff" getprop stringify "on" smatch if
      listener @
      {
        "^[o^[c" me @ name " ^[ghas just validated ^[w" who @ name "^[g."
      }cat "staff" pretty notify
    then
  repeat
 
"^[o^[gDone!" tellme
who @ "^[o^[gYou've been validated!" notify
who @ "^[o^[gHere!  Have some Poke Balls and Potions to start you off! ^[w[^[gReceived 10 poke balls and 5 potions^[w]" notify
who @ "^[o^[gOh! And before you go, take this trainer set.  It includes one of each power item, an everstone, and a lucky egg.  You gotta find more though." notify
who @ "^[o^[w[^[gRecieved a Power Anklet, a Power Band, a Power Belt, a Power Bracer, a Power Lens, a Power Weight, an Everstone, and a Lucky Egg^[w]" notify
(who @ "^[o^[gYou feel inspired! ^[w[^[gYou now have 1000 tp^[w]" notify)
;