OVERVIEW

This game is, at its heart, a puzzle game. The player must try various combinations to determine exactly which one will save one-hundred percent of the hostages. There are myriad variables that seem like they could change the outcome, including dialogue, magma generation, and the order in which you interact with the characters. However, all of those factors are arbitrary. The answer to the puzzle lies in the name of the game: UNDERTONE. The only factor that determines the bad/good/neutral status of the NPC is its color. Bad characters are a cool green/blue, neutral characters are shades of yellow and orange, and the spy is magenta. Even the percentage displayed is completely random until you have used all of your kills.
To organize our code, we had different classes for player, map, character, util and animation. This made it easy for us to categorize our variables and functions so that they only applied to the relevant section of the code. In order to link our files, we put all the variables that reference x-y coordinates in map.lua. The map.lua file references the player and character files, thus, when we can access and change a variable like map.screen in all files. This posed a problem for us at first since we weren’t used to object-oriented coding: if we declared a variable in player, there would be no way to change it in character because the files were not linked. However, we found this to be a better approach in the end because all coordinate-referencing variables are in one centralized file.

MAP.LUA

All of the aesthetic choices in the game were made to foster irony. The pastel color palette and cheerful music are contrasted by the serious stakes set by the exposition paragraph.

We randomly generated clouds, platforms, and mushrooms across the map to give it a more adventure-game feel and to introduce more variables to throw off the player. There are different probabilities for the different blocks to spawn, and are restricted so they don’t overlap or spawn on the title/exposition screens. As you will notice, even though a sizzling sound plays and the player turns red when you touch a magma puddle, there are no negative side-effects to touching a magma puddle. 

We also created the variable “screen” in Map.lua which we use to make it so that once you interact with a character, you can’t go make and interact with them again. The screen variable will update every time the player travels the distance of the virtual screen width. This will update the left boundary so the player can’t backtrack.

CHARACTER.LUA
We used an array to store the non-player characters in map that is linked to character.lua. This made it so we could have the character file have functions that could be executed for each character; otherwise we would need 6 separate files. This made is easy for us to index our sprite sheet array using the ID names we defined at the top of the file. We also made a deadRender() function in order to change the animation of the npc once they were killed. Having this separate function made it possible for some of the characters in the array to be dead and some to be alive.

The dialogue is stored in an array inside of the npc array. The dialogue was taken from conversations we had with our friends in order to confuse the player. They aren’t inherently good, bad or neutral. It adds to the puzzling aspect of the game!

PLAYER.LUA

We introduced various states that the main character can be in. These states are idle, walking, jumping, fire, and dialogue. The idle, walking, and jumping states are associated with animations that represent each state. All the states are linked together so that you can transition from one to the next in a variety of scenarios. For example, if you jump while in a magma puddle, the state transitions from ‘fire’ to ‘jumping.
Along with the animations we also added sound effects and music. We generated the sounds using bxfr.



While we initially wanted a resurrection state at the end of the game for the characters that were killed, we chose not to because the character sprites were too similar and the game was too short for users to distinguish them when they were asked about it again. We liked having the prisoner saved percentage randomly generate until the end of the game so that the player can’t easily figure out the algorithm of calculating the final percentage.
