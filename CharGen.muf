$include $lib/ansi (ANSI)
$include $lib/useful (useful)
 
: helper
var! subject
" " tellme
subject @ "version" smatch if

        var speciesnum
        0 var! count
        "^[o^[g----- ^[cVersion List  ^[g--------------------------------------------------------" tellme
        { "^[o^[c Version " #0 "@pokemon versions/1/name" getprop }cat tellme
        #0 "@pokemon versions/1/pokemon" getprop ", " explode_array var! v1poke
        1 700 1 for intostr 3 "0" padl speciesnum !
         v1poke @ POKEDEX { "pokemon/" speciesnum @ "/name" }cat getprop not if speciesnum @ "a" strcat speciesnum ! then
           POKEDEX { "pokemon/" speciesnum @ "/name" }cat getprop array_findval not if continue then
          count @ not if { "^[o^[g| "  else " ^[g| " then "^[y"
          POKEDEX { "pokemon/" speciesnum @ "/name" }cat getprop 11 " " padr
          count @ 1 + 5 % count !
          count @ not if " ^[g|" }cat tellme then
          repeat
          count @ if " ^[g|" }cat tellme then
          " " tellme
          0 count !
        { "^[o^[c Version " #0 "@pokemon versions/2/name" getprop }cat tellme
        #0 "@pokemon versions/2/pokemon" getprop ", " explode_array var! v2poke
        1 700 1 for intostr 3 "0" padl speciesnum !
          POKEDEX { "pokemon/" speciesnum @ "/name" }cat getprop not if speciesnum @ "a" strcat speciesnum ! then
          v2poke @ POKEDEX { "pokemon/" speciesnum @ "/name" }cat getprop array_findval not if continue then
          count @ not if { "^[o^[g| "  else " ^[g| " then "^[y"
          POKEDEX { "pokemon/" speciesnum @ "/name" }cat getprop 11 " " padr
          count @ 1 + 5 % count !
          count @ not if " ^[g|" }cat tellme then
          repeat
          count @ if " ^[g|" }cat tellme then          
          "^[o^[g----------------------------------------------------------------------------" tellme
          " " tellme
exit
then

subject @ "pokemon" smatch if
        var speciesnum
        var breedmove?
        0 var! count
        "^[o^[g----- ^[cChargen List  ^[g--------------------------------------------------------" tellme
        1 700 1 for intostr 3 "0" padl speciesnum !
          POKEDEX { "pokemon/" speciesnum @ "/name" }cat getprop not if speciesnum @ "a" strcat speciesnum ! then
          
            POKEDEX { "pokemon/" speciesnum @ "/chargen?" }cat getprop not
          me @ "@rp/permission" getprop not and if continue then
          POKEDEX { "pokemon/" speciesnum @ "/breedmoves"  }cat propdir? if "Y" breedmove? ! else 0 breedmove? ! then
          count @ not if { "^[o^[g| "  else " ^[g| " then breedmove? @ if "^[c" else "^[y" then
          POKEDEX { "pokemon/" speciesnum @ "/name" }cat getprop 11 " " padr
          breedmove? @ if "^[wB" else " " then
          count @ 1 + 5 % count !
          count @ not if " ^[g|" }cat tellme then
          repeat
          count @ if " ^[g|" }cat tellme then
          "^[o^[g----------------------------------------------------------------------------" tellme
          "^[o^[gPokemon with a ^[wB^[g near their name have breedmoves." tellme
          " " tellme
exit
then
 
 
subject @ "exp" smatch if
        "^[o^[gIn Pokemon Fusion there are two types of experience points: fighting experience [xp] and trainer experience [txp]." tellme
        " " tellme
        "^[o^[gXP is the same XP you are used to from the game, and is used to decide the level of your pokemon or fusion." tellme
        " " tellme
        "^[o^[gTXP is used as a representation for how skilled of a trainer you are. The higher your trainer level:" tellme
        "^[o^[g--The more experience you earn by using the +train system." tellme
        "^[o^[g--The stronger the pokemon you can face in the wild by having access to more +Tiers" tellme
        "^[o^[g--The more TP you earn per tick, so you can have more battles. " tellme
        "^[o^[g----Tiers are how we separate weaker pokemon from stronger instead of by location." tellme
        " " tellme
        "^[o^[gIt is worth noting that your TXP will grow a lot slower than your XP, so it is worth considering when choosing how much to start with." tellme
        " " tellme
exit
then
 
;
 
: MakeHuman
"^[o^[gYou have chosen to make a Human character." tellme
 
"^[o^[y Please select your gender: ^[c(^[yM^[c)^[yale or ^[c(^[yF^[c)^[yemale?" tellme
var gender
begin
  read gender !
  gender @ ".abort" smatch if "^[rAborted" tellme exit then
  gender @ "M*" smatch if "Male" break then
  gender @ "F*" smatch if "Female" break then
  "^[o^[y I didn't quite get that. Please select your gender." tellme
repeat
gender !
{ "^[o^[gYou have chosen to be " gender @ "." }cat tellme
 
"^[o^[y As a human character, you may select a type to be your favored pokemon type." tellme
"^[o^[y Pokemon of this type trust you more, like you more, and are easier for you to train." tellme
"^[o^[y System wise, pokemon of this time will gain bond and xp faster." tellme
{
"Bug"
"Dark"
"Dragon"
"Electric"
"Fighting"
"Fire"
"Flying"
"Ghost"
"Grass"
"Ground"
"Ice"
"Normal"
"Poison"
"Psychic"
"Rock"
"Steel"
"Water"
}list var! types
var type
types @ foreach type ! pop
  { "^[o^[c  " type @ }cat tellme
repeat
begin
  read cap type !
  type @ ".abort" smatch if "^[rAborted" tellme exit then
  types @ type @ array_findval array_count not if
    "^[o^[rInvalid choice. Try again." tellme
    continue
  then
  break
repeat
{ "^[o^[gYou chose to favor the " type @ " type." }cat tellme


var species
var speciesnum
var pversion
begin

        "^[o^[y Pokemon Fusion has two versions, which version are you from? 1 or 2" tellme
        "^[o^[y If you would like a list of version exclusive pokemon, type 'help' ^[r***Warning, large list***" tellme 
        { "^[o^[y1. " #0 "@pokemon versions/1/name" getprop }cat tellme
        { "^[o^[y2. " #0 "@pokemon versions/2/name" getprop }cat tellme
        read pversion !
        pversion @ "help" smatch if "version" helper continue then
        pversion @ ".abort" smatch if "^[rAborted" tellme exit then
        pversion @ "1" smatch
        pversion @ "2" smatch or if 
                                   { "^[o^[gYou've chosen Version " #0 { "@pokemon verisons/" pversion @ "/name" }cat getprop "." }cat tellme break then
        "^[o^[y Please enter either 1 or 2." tellme
        
repeat

begin
"^[o^[y Please choose a species for your starting pokemon." tellme
"^[o^[y If you would like a list of all valid starting pokemon, type 'help' ^[r***Warning, large list***" tellme
  read species !
  species @ "help" smatch if "pokemon" helper continue then
  species @ ".abort" smatch if "^[rAborted" tellme exit then
  POKEDEX { "pokemon/byname/" species @ }cat getprop speciesnum !
  speciesnum @ not if "^[o^[y I don't know that species. Try again." tellme continue then
  POKEDEX { "pokemon/" speciesnum @ "/chargen?" }cat getprop not
  me @ "@rp/permission" getprop not and if
    "^[o^[y You can't begin with a starter of that species. Try again." tellme
    continue
  then
  POKEDEX { "pokemon/" speciesnum @ "/name" }cat getprop break
repeat
species !
{ "^[o^[gYou have chosen a " species @ " as your starter." }cat tellme
 
var pokegender
POKEDEX { "pokemon/" speciesnum @ "/genderratio" }cat getprop var! ratio
"Neuter" pokegender !
ratio @ "Male" smatch if
  "Male" pokegender !
  "^[o^[gYou have chosen a Male pokemon." tellme
then
ratio @ "Female" smatch if
  "Female" pokegender !
  "^[o^[gYou have chosen a Female pokemon." tellme
then
ratio @ "*:*" smatch if
  "^[o^[y Please choose a gender for your starting pokemon: ^[c(^[yM^[c)^[yale or ^[c(^[yF^[c)^[yemale?" tellme
  begin
    read pokegender !
    pokegender @ ".abort" smatch if "^[rAborted" tellme exit then
    pokegender @ "M*" smatch if
      "Male" pokegender !
      "^[o^[gYou have chosen a Male pokemon." tellme
      break
    then
    pokegender @ "F*" smatch if
      "Female" pokegender !
      "^[o^[gYou have chosen a Female pokemon." tellme
      break
    then
    "^[o^[y I didn't quite get that. Please select a gender." tellme
  repeat
then
pokegender @ "Neuter" smatch if
  "^[o^[gYou have chosen a Genderless pokemon." tellme
then
 
 (allow player to name pokemon)
 { "^[y^[oWould you like to name your ^[c" pokegender @ " " species @ " ^[g?  (y/n)" }cat tellme
 var choice
 var pname
 read choice !
 
 
 choice @ "Y*" smatch if
 begin
 "^[y^[oPick a name." tellme
 read pname !
 pname @ strip pname !
 { "^[o^[yAre you sure you want to name it ^[c" pname @ "^[g? (y/n)" }cat tellme
 read choice !
 choice @ "Y*" smatch if
 break
 then
 repeat
 then
 
var ability
var temp
POKEDEX { "pokemon/" speciesnum @ "/abilities" }cat get ability !
ability @ ":" split not if
  ability !
  { "^[o^[gYour pokemon has the " ability @ " ability." }cat tellme
else
  pop "^[o^[y Please choose the ability your pokemon has from the following:" tellme
  ability @ ":" explode_array ability !
  ability @ foreach
    "^[o^[c  " swap strcat tellme
  repeat
  begin
    read temp !
    temp @ ".abort" smatch if "^[rAborted" tellme exit then
    ability @ temp @ array_matchval array_count not if
      "^[o^[y That ability wasn't listed. Try again." tellme
      continue
    then
    temp @ cap ability ! break
  repeat
  { "^[o^[gYou chose the " ability @ " ability for your pokemon." }cat tellme
then
 
begin
"^[o^[y Select your pokemon's nature from the following." tellme
"^[o          ^[cDecrease" tellme
"^[o^[g         |---------|---------|---------|---------|---------|" tellme
"^[o^[cIncrease ^[g| ^[cPhysAtk ^[g| ^[cPhysDef ^[g|  ^[cSpeed  ^[g| ^[cSpecAtk ^[g| ^[cSpecDef ^[g|" tellme
"^[o^[g---------|---------|---------|---------|---------|---------|" tellme
"^[o^[c PhysAtk ^[g| ^[wHardy   ^[g| ^[wLonely  ^[g| ^[wBrave   ^[g| ^[wAdamant ^[g| ^[wNaughty ^[g|" tellme
"^[o^[g---------|---------|---------|---------|---------|---------|" tellme
"^[o^[c PhysDef ^[g| ^[wBold    ^[g| ^[wDocile  ^[g| ^[wRelaxed ^[g| ^[wImpish  ^[g| ^[wLax     ^[g|" tellme
"^[o^[g---------|---------|---------|---------|---------|---------|" tellme
"^[o^[c  Speed  ^[g| ^[wTimid   ^[g| ^[wHasty   ^[g| ^[wSerious ^[g| ^[wJolly   ^[g| ^[wNaive   ^[g|" tellme
"^[o^[g---------|---------|---------|---------|---------|---------|" tellme
"^[o^[c SpecAtk ^[g| ^[wModest  ^[g| ^[wMild    ^[g| ^[wQuiet   ^[g| ^[wBashful ^[g| ^[wRash    ^[g|" tellme
"^[o^[g---------|---------|---------|---------|---------|---------|" tellme
"^[o^[c SpecDef ^[g| ^[wCalm    ^[g| ^[wGentle  ^[g| ^[wSassy   ^[g| ^[wCareful ^[g| ^[wQuirky  ^[g|" tellme
"^[o^[g---------|---------|---------|---------|---------|---------|" tellme
"^[o^[yNatures that increase and decrease the same stat are neutral." tellme
var nature
read cap nature !
nature @ ".abort" smatch if "^[rAborted" tellme exit then
{ "Hardy" "Lonely" "Brave" "Adamant" "Naughty"
  "Bold" "Docile" "Relaxed" "Impish" "Lax"
  "Timid" "Hasty" "Serious" "Jolly" "Naive"
  "Modest" "Mild" "Quiet" "Bashful" "Rash"
  "Calm" "Gentle" "Sassy" "Careful" "Quirky" }list
{ nature @ toupper }list array_intersect array_count if
break
else
"^[o^[rNot a valid nature, pick one from the list." tellme
then
repeat
 
{ "^[o^[g You chose the " nature @ " nature for your pokemon." }cat tellme
 
POKEDEX { "pokemon/" speciesnum @ "/breedmoves" }cat array_get_propvals var! breedmoves
var pre
breedmoves @ array_count not POKEDEX { "pokemon/" speciesnum @ "/EvolveFrom" }cat propdir? and if
POKEDEX { "pokemon/" speciesnum @ "/EvolveFrom" }cat array_get_propvals foreach pop pre ! repeat
 
POKEDEX { "pokemon/" POKEDEX { "pokemon/byname/" pre @ }cat getprop "/breedmoves" }cat array_get_propvals breedmoves !
then
 
"" var! breedmove1
"" var! breedmove2
breedmoves @ array_count if
  "^[o^[y You may select two breed moves for your pokemon from the following:" tellme
  breedmoves @ foreach pop "^[c  " swap strcat tellme repeat
  "^[o^[y You may select 'Nothing' if you do not want a breedmove." tellme
  "^[o^[y Select your pokemon's first breed move." tellme
  begin
    read cap breedmove1 !
    breedmove1 @ ".abort" smatch if "^[rAborted" tellme exit then
    breedmove1 @ "Nothing" smatch if "" breedmove1 ! break then
    breedmoves @ breedmove1 @ array_getitem not if
      "^[o^[yThat move isn't on the list. Try again." tellme
      continue
    then
    { "^[o^[gYou have chosen the move " breedmove1 @ }cat tellme
    break
  repeat
  breedmove1 @ if
    "^[o^[y Select your pokemon's second breed move." tellme
    begin
      read cap breedmove2 !
      breedmove2 @ ".abort" smatch if "^[rAborted" tellme exit then
      breedmove2 @ "Nothing" smatch if "" breedmove2 ! break then
      breedmoves @ breedmove2 @ array_getitem not if
        "^[o^[yThat move isn't on the list. Try again." tellme
        continue
      then
      { "^[o^[gYou have chosen the move " breedmove2 @ }cat tellme
      break
    repeat
  then
then
 
 
var xp
var txp
begin
"^[o^[y You have 2500 XP to divide between your Trainer Experience and your pokemon's Fighting Experience" tellme
"^[o^[y How much XP will you devote to your pokemon's Fighting Experience?" tellme
"^[o^[y If you need help understanding the difference in experience, type 'help'." tellme
  read xp !
  xp @ "h*" smatch if "exp" helper continue then
  xp @ ".abort" smatch if "^[rAborted" tellme exit then
  xp @ atoi xp !
  xp @ 0 < xp @ 2500 > or if
    "^[o^[y Invalid amount. Try again." tellme
    continue
  then
  break
repeat
2500 xp @ - txp !
{ "^[o^[gYou have " txp @ intostr " Training XP. Your pokemon has " xp @ intostr " Fighting XP." }cat tellme
 
"^[o^[y Are you content with your selections? (y/n)" tellme
read "y*" smatch not if "^[rAborted." tellme exit then
 
var myID
var pokeID
 
( POKESTORE { "@pokemon/" me @ "@rp/ID" getprop }cat over over propdir? if remove_prop else pop pop then )
me @ "@rp/ID" newID setprop
me @ "@rp/ID" getprop myID !
 
myID @ "species" "000" setto
myID @ "gender" gender @ setto
myID @ "IVs"
  ""
  1 30 1 for pop
    frand 0.5 < if "1" else "0" then strcat
  repeat
setto
myID @ "player?" me @ setto
myID @ "holding" "Nothing" setto
myID @ "txp" txp @ setto
myID @ "Favored Type" type @ setto
myID @ "credits" 10000 setto
 
NewID pokeID !
pokeID @ "happiness" POKEDEX { "/pokemon/" speciesnum @ "/basehappiness" }cat getprop setto 
pokeID @ "species" speciesnum @ setto
pokeID @ "gender" pokegender @ setto
pokeID @ "name" pname @ setto
pokeID @ "IVs"
  ""
  1 30 1 for pop
    frand 0.5 < if "1" else "0" then strcat
  repeat
setto
pokeID @ "nature" nature @ setto
pokeID @ "ability" ability @ setto
pokeID @ "holding" "Nothing" setto
pokeID @ "Original Trainer" myID @ setto
pokeID @ "Current Trainer" myID @ setto
breedmove1 @ if pokeID @ { "movesknown/" breedmove1 @ }cat 1 setto pokeID @ { "movesets/1/A" }cat breedmove1 @ setto then
breedmove2 @ if pokeID @ { "movesknown/" breedmove2 @ }cat 1 setto pokeID @ { "movesets/1/B" }cat breedmove2 @ setto then
pokeID @ "xp" xp @ setto
pokeID @ "Bond" 140 setto
 
myID @ "Slot/1" pokeID @ setto
me @ "@achieve" remove_prop
me @ "@Version" pversion @ atoi setprop
me @ { "@achieve/poke-owned/" speciesnum @  }cat 1 setprop 
"^[o^[gDone! Please make sure you have a description and +info before asking a wizard for validation." tellme
;
 
 
: MakeFusion
"^[o^[gYou have chosen to make a Fusion character." tellme
 
"^[o^[y Please select your human gender: ^[c(^[yM^[c)^[yale or ^[c(^[yF^[c)^[yemale?" tellme
var gender
begin
  read gender !
  gender @ ".abort" smatch if "^[rAborted" tellme exit then
  gender @ "M*" smatch if "Male" break then
  gender @ "F*" smatch if "Female" break then
  "^[o^[y I didn't quite get that. Please select your gender." tellme
repeat
gender !
{ "^[o^[gYou have chosen to be " gender @ "." }cat tellme
 
 
var species
var speciesnum
var pversion
begin

        "^[o^[y Pokemon Fusion has two versions, which version are you from? 1 or 2" tellme
        "^[o^[y If you would like a list of version exclusive pokemon, type 'help' ^[r***Warning, large list***" tellme 
        { "^[o^[y1. " #0 "@pokemon versions/1/name" getprop }cat tellme
        { "^[o^[y2. " #0 "@pokemon versions/2/name" getprop }cat tellme
        read pversion !
        pversion @ "help" smatch if "version" helper continue then
        pversion @ ".abort" smatch if "^[rAborted" tellme exit then
        pversion @ "1" smatch
        pversion @ "2" smatch or if 
                                   { "^[o^[gYou've chosen Version " #0 { "@pokemon verisons/" pversion @ "/name" }cat getprop "." }cat tellme break then
        "^[o^[y Please enter either 1 or 2." tellme
        
repeat

begin
"^[o^[y Please choose a species for your fusion." tellme
"^[o^[y If you would like a list of all valid pokemon fusion choices, type 'help' ^[r***Warning, large list***" tellme
  read species !
  species @ "help" smatch if "pokemon" helper continue then
  species @ ".abort" smatch if "^[rAborted" tellme exit then
  POKEDEX { "pokemon/byname/" species @ }cat getprop speciesnum !
  speciesnum @ not if "^[o^[y I don't know that species. Try again." tellme continue then
  POKEDEX { "pokemon/" speciesnum @ "/chargen?" }cat getprop not
  me @ "@rp/permission" getprop not and if
    "^[o^[y You can't begin with a starter of that species. Try again." tellme
    continue
  then
  POKEDEX { "pokemon/" speciesnum @ "/name" }cat getprop break
repeat
species !
{ "^[o^[gYou have chosen a " species @ " as your fusion." }cat tellme
 
var types
var type
POKEDEX { "pokemon/" speciesnum @ "/type" }cat getprop ":" explode_array types !
types @ array_count 1 = if
  types @ 0 array_getitem type !
else
  "^[o^[y Chose one of the following types to be your favored type." tellme
  types @ foreach type ! pop
    { "^[o^[c  " type @ }cat tellme
  repeat
  begin
    read cap type !
    type @ ".abort" smatch if "^[rAborted" tellme exit then
    types @ type @ array_findval array_count not if
      "^[o^[rInvalid choice. Try again." tellme
      continue
    then
    break
  repeat
then
 
var pokegender
POKEDEX { "pokemon/" speciesnum @ "/genderratio" }cat getprop var! ratio
"Neuter" pokegender !
ratio @ "Male" smatch if
  "Male" pokegender !
  "^[o^[gYou have chosen a Male fusion." tellme
then
ratio @ "Female" smatch if
  "Female" pokegender !
  "^[o^[gYou have chosen a Female fusion." tellme
then
ratio @ "*:*" smatch if
  "^[o^[y Please choose a gender for your fusion: ^[c(^[yM^[c)^[yale or ^[c(^[yF^[c)^[yemale?" tellme
  begin
    read pokegender !
    pokegender @ ".abort" smatch if "^[rAborted" tellme exit then
    pokegender @ "M*" smatch if
      "Male" pokegender !
      "^[o^[gYou have chosen a Male fusion." tellme
      break
    then
    pokegender @ "F*" smatch if
      "Female" pokegender !
      "^[o^[gYou have chosen a Female fusion." tellme
      break
    then
    "^[o^[y I didn't quite get that. Please select a gender." tellme
  repeat
then
pokegender @ "Neuter" smatch if
  "^[o^[gYou have chosen a Genderless pokemon for your fusion." tellme
  "^[o^[y Select a gender for your fusion: ^[c(^[yM^[c)^[yale, ^[c(^[yF^[c)^[yemale, or ^[c(^[yN^[c)^[yeuter" tellme
  begin
    read pokegender !
    pokegender @ ".abort" smatch if "^[rAborted" tellme exit then
    pokegender @ "M*" smatch if
      "Male" pokegender !
      "^[o^[gYou have chosen a Male fusion." tellme
      break
    then
    pokegender @ "F*" smatch if
      "Female" pokegender !
      "^[o^[gYou have chosen a Female fusion." tellme
      break
    then
    pokegender @ "N*" smatch if
      "Neuter" pokegender !
      "^[o^[gYou have chosen a Neuter fusion." tellme
      break
    then
    "^[o^[y I didn't quite get that. Please select a gender." tellme
  repeat
then
 
var ability
var temp
POKEDEX { "pokemon/" speciesnum @ "/abilities" }cat get ability !
ability @ ":" split not if
  ability !
  { "^[o^[gYour fusion has the " ability @ " ability." }cat tellme
else
  pop "^[o^[y Please choose the ability your fusion has from the following:" tellme
  ability @ ":" explode_array ability !
  ability @ foreach
    "^[o^[c  " swap strcat tellme
  repeat
  begin
    read temp !
    temp @ ".abort" smatch if "^[rAborted" tellme exit then
    ability @ temp @ array_matchval array_count not if
      "^[o^[y That ability wasn't listed. Try again." tellme
      continue
    then
    temp @ cap ability ! break
  repeat
  { "^[o^[gYou chose the " ability @ " ability for your fusion." }cat tellme
then
begin 
"^[o^[y Select your fusion's nature from the following." tellme
"^[o          ^[cDecrease" tellme
"^[o^[g         |---------|---------|---------|---------|---------|" tellme
"^[o^[cIncrease ^[g| ^[cPhysAtk ^[g| ^[cPhysDef ^[g|  ^[cSpeed  ^[g| ^[cSpecAtk ^[g| ^[cSpecDef ^[g|" tellme
"^[o^[g---------|---------|---------|---------|---------|---------|" tellme
"^[o^[c PhysAtk ^[g| ^[wHardy   ^[g| ^[wLonely  ^[g| ^[wBrave   ^[g| ^[wAdamant ^[g| ^[wNaughty ^[g|" tellme
"^[o^[g---------|---------|---------|---------|---------|---------|" tellme
"^[o^[c PhysDef ^[g| ^[wBold    ^[g| ^[wDocile  ^[g| ^[wRelaxed ^[g| ^[wImpish  ^[g| ^[wLax     ^[g|" tellme
"^[o^[g---------|---------|---------|---------|---------|---------|" tellme
"^[o^[c  Speed  ^[g| ^[wTimid   ^[g| ^[wHasty   ^[g| ^[wSerious ^[g| ^[wJolly   ^[g| ^[wNaive   ^[g|" tellme
"^[o^[g---------|---------|---------|---------|---------|---------|" tellme
"^[o^[c SpecAtk ^[g| ^[wModest  ^[g| ^[wMild    ^[g| ^[wQuiet   ^[g| ^[wBashful ^[g| ^[wRash    ^[g|" tellme
"^[o^[g---------|---------|---------|---------|---------|---------|" tellme
"^[o^[c SpecDef ^[g| ^[wCalm    ^[g| ^[wGentle  ^[g| ^[wSassy   ^[g| ^[wCareful ^[g| ^[wQuirky  ^[g|" tellme
"^[o^[g---------|---------|---------|---------|---------|---------|" tellme
"^[o^[yNatures that increase and decrease the same stat are neutral." tellme
var nature
read cap nature !
nature @ ".abort" smatch if "^[rAborted" tellme exit then
{ "Hardy" "Lonely" "Brave" "Adamant" "Naughty"
  "Bold" "Docile" "Relaxed" "Impish" "Lax"
  "Timid" "Hasty" "Serious" "Jolly" "Naive"
  "Modest" "Mild" "Quiet" "Bashful" "Rash"
  "Calm" "Gentle" "Sassy" "Careful" "Quirky" }list
{ nature @ toupper }list array_intersect array_count if
break
else
"^[o^[rNot a valid nature, pick one from the list." tellme
then
repeat
 
{ "^[o^[g You chose the " nature @ " nature for your fusion." }cat tellme
 
POKEDEX { "pokemon/" speciesnum @ "/breedmoves" }cat array_get_propvals var! breedmoves
var pre
breedmoves @ array_count not POKEDEX { "pokemon/" speciesnum @ "/EvolveFrom" }cat propdir? and if
POKEDEX { "pokemon/" speciesnum @ "/EvolveFrom" }cat array_get_propvals foreach pop pre ! repeat
 
POKEDEX { "pokemon/" POKEDEX { "pokemon/byname/" pre @ }cat getprop "/breedmoves" }cat array_get_propvals breedmoves !
then
 
"" var! breedmove1
"" var! breedmove2
breedmoves @ array_count if
  "^[o^[y You may select two breed moves for your fusion from the following:" tellme
  breedmoves @ foreach pop "^[c  " swap strcat tellme repeat
  "^[o^[y You may select 'Nothing' if you do not want a breedmove." tellme
  "^[o^[y Select your fusion's first breed move." tellme
  begin
    read cap breedmove1 !
    breedmove1 @ ".abort" smatch if "^[rAborted" tellme exit then
    breedmove1 @ "Nothing" smatch if "" breedmove1 ! break then
    breedmoves @ breedmove1 @ array_getitem not if
      "^[o^[yThat move isn't on the list. Try again." tellme
      continue
    then
    { "^[o^[gYou have chosen the move " breedmove1 @ }cat tellme
    break
  repeat
  breedmove1 @ if
    "^[o^[y Select your fusion's second breed move." tellme
    begin
      read cap breedmove2 !
      breedmove2 @ ".abort" smatch if "^[rAborted" tellme exit then
      breedmove2 @ "Nothing" smatch if "" breedmove2 ! break then
      breedmoves @ breedmove2 @ array_getitem not if
        "^[o^[yThat move isn't on the list. Try again." tellme
        continue
      then
      { "^[o^[gYou have chosen the move " breedmove2 @ }cat tellme
      break
    repeat
  then
then
 
 
var xp
var txp
begin
"^[o^[y You have 2500 XP to divide between your Trainer Experience and your Fighting Experience" tellme
"^[o^[y How much XP will you devote to your Fighting Experience?" tellme
"^[o^[y If you need help understanding the difference in experience, type 'help'." tellme
  read xp !
  xp @ "h*" smatch if "exp" helper continue then
  xp @ ".abort" smatch if "^[rAborted" tellme exit then
  xp @ atoi xp !
  xp @ 0 < xp @ 2500 > or if
    "^[o^[y Invalid amount. Try again." tellme
    continue
  then
  break
repeat
2500 xp @ - txp !
{ "^[o^[gYou have " txp @ intostr " Training XP. You have " xp @ intostr " Fighting XP." }cat tellme
 
"^[o^[y Are you content with your selections? (y/n)" tellme
read "y*" smatch not if "^[rAborted." tellme exit then
 
var myID
var pokeID
 
( POKESTORE { "@pokemon/" me @ "@rp/ID" getprop }cat over over propdir? if remove_prop else pop pop then )
me @ "@rp/ID" newID setprop
me @ "@rp/ID" getprop myID !
 
myID @ "species" "000" setto
myID @ "gender" gender @ setto
myID @ "IVs"
  ""
  1 30 1 for pop
    frand 0.5 < if "1" else "0" then strcat
  repeat
setto
myID @ "player?" me @ setto
myID @ "holding" "Nothing" setto
myID @ "txp" txp @ setto
myID @ "xp" xp @ setto
myID @ "Favored Type" type @ setto
myID @ "credits" 10000 setto
 
NewID pokeID !
pokeID @ "species" speciesnum @ setto
pokeID @ "happiness" POKEDEX { "/pokemon/" speciesnum @ "/basehappiness" }cat getprop setto
pokeID @ "gender" pokegender @ setto
pokeID @ "nature" nature @ setto
pokeID @ "ability" ability @ setto
pokeID @ "holding" "Nothing" setto
pokeID @ "Original Trainer" myID @ setto
pokeID @ "Current Trainer" myID @ setto
breedmove1 @ if pokeID @ { "movesknown/" breedmove1 @ }cat 1 setto pokeID @ { "movesets/1/A" }cat breedmove1 @ setto then
breedmove2 @ if pokeID @ { "movesknown/" breedmove2 @ }cat 1 setto pokeID @ { "movesets/1/B" }cat breedmove2 @ setto then
 
myID @ { "fusionlist/" pokeID @ }cat 1 setto
myID @ "fusion" pokeID @ setto
me @ "@Version" pversion @ atoi setprop
me @ "@achieve" remove_prop
me @ { "@achieve/poke-owned/" speciesnum @  }cat 1 setprop
"^[o^[gDone! Please make sure you have a description and +info before asking a wizard for validation." tellme
;
 
 
: main
me @ "@valid?" propdir? if
  "You're already valid." tellme
  exit
then
 
"^[o^[gWelcome to Pokemon Fusion!" tellme
"^[o^[y You have two options for creation of your character:" tellme
"^[o^[c A: Play a human trainer, start with a basic or baby pokemon of your choice" tellme
"^[o^[c B: Play a Fusion from the start, but receive no starter" tellme
"^[o^[y Which will you choose? (^[r.abort^[y at any time to quit)" tellme
 
var character
begin
  read character !
  character @ ".abort" smatch if "^[rAborted" tellme exit then
  character @ "{A|B}" smatch if break then
  "^[o^[y I didn't quite get that. Which will you choose?" tellme
repeat
 
character @ "A" smatch if MakeHuman   then
character @ "B" smatch if MakeFusion  then
 
;