# suzumu
A text-based adventure game engine written in Racket.

This game requires Racket 6.5 or above to be installed.

## Usage

Create a directory named `suzumu` inside your home directory, and inside that a directory named `scenes` and another called `saves`. Copy the contents of the `default-scenes` directory inside this repository to `$HOME/suzumu/scenes`. This will install the data that comes with the game.

Make sure that every file in the `scenes` directory that you want to load in the game ends in `.scene`.

## Playing

Either load up the `game.rkt` file in DrRacket and hit "Run" or start up the game on the command line with `racket game.rkt`. The results should be the same, as suzumu doesn't (yet, anyway) use any graphical features. However, I have noticed that DrRacket is slightly slower in playing the game. YMMV.

Type 'h' and hit enter to see a list of options at any point in the game.

## What doesn't work (yet)

* When you load/save a player, the file is assumed to be in the directory where you're running racket or DrRacket from. It *should* save and load to/from `$HOME/suzumu/saves`.
* When you save a set of scenes, the save location is assumed to be the directory where you're running racket or DrRacket from. It *should* save to `$HOME/suzumu/scenes`. However, all scene loading reads through files ending in .save in `$Home/suzumu/scenes` so loading is fine.

## Making your own scenes

* Modify/delete/add to/remove `scenesL` to your liking.
* Make sure any lambdas you use are quoted, and remember that they are evaluated simply by calling `eval` on what you enter.
* A `choice` `requirement` field **must** return either `#t` or `#f`.
* A `choice` `action` filed **must** return a player struct.
* A `scene` `pre-scene-action` field **must** return a player struct. `choices`
* A `scene` `choices` field **must** be a list of choice structs
* Uncomment the calls to `insert-scenes` and `launch-game` at the bottom of `game.rkt`. You don't want to load the game.
* Call `(save-scenes scenesL "myScenes")` which will create (or **overwrite**) a file called "myScenes" in the current working directory. To load these scenes when you play the game, move or copy myScenes to `$HOME/suzumu/scenes`.

## License

    suzumu - A text adventure game in Racket.
    Copyright (C) 2016, 2017 Iyra Gaura

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.