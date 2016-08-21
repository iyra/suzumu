# suzumu
A text-based adventure game engine written in Racket.

This game requires Racket 6.5 or above to be installed.

## Usage

Create a directory named `suzumu` inside your home directory, and inside that a directory named `scenes` and another called `saves`. Copy the contents of the `default-scenes` directory inside this repository to `$HOME/suzumu/scenes`. This will install the data that comes with the game.

Make sure that every file in the `scenes` directory that you want to load in the game ends in `.scene`.

## Playing

Either load up the `game.rkt` file in DrRacket and hit "Run" or start up the game on the command line with `racket game.rkt`. The results should be the same, as suzumu doesn't (yet, anyway) use any graphical features. However, I have noticed that DrRacket is slightly slower in playing the game. YMMV.

Type 'h' and hit enter to see a list of options at any point in the game.

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