# Super Bombinhas

Super Bombinhas is a retro platformer game inspired by classics like Super Mario World, but with a unique change characters mechanic. It is built with Ruby and the Gosu and MiniGL libraries.
You can download the installers from releases here in GitHub or in [itch.io](https://victords.itch.io/super-bombinhas), where you can also find a more detailed description and a gameplay video.

## Version 1.2.3

* Small level design changes
* Show bombs' maximum HP
* Automatically change to item that the current bomb can use when switching bombs
* Fix bug in world 5 boss

## Screenshots

![Super Bombinhas 1](https://raw.githubusercontent.com/victords/super-bombinhas/master/screenshot/game-menu.png)

![Super Bombinhas 2](https://raw.githubusercontent.com/victords/super-bombinhas/master/screenshot/map.png)

![Super Bombinhas 3](https://raw.githubusercontent.com/victords/super-bombinhas/master/screenshot/main1.png)

![Super Bombinhas 4](https://raw.githubusercontent.com/victords/super-bombinhas/master/screenshot/main2.png)

## Running the game

1. Install Ruby.
    * For Windows: [RubyInstaller](https://rubyinstaller.org/)
    * For Linux: [RVM](https://rvm.io/)
2. Install Gosu and MiniGL (see "Installing" [here](https://github.com/victords/minigl)).
3. Clone this repository.
4. Open a command prompt/terminal in the repository folder and run `ruby game.rb`.

## Remarks

* The source code is distributed under the GNU GPLv3 license and the image and sound assets (contents of the folders data/img, data/song and data/tileset) under the Creative Commons Attribution-ShareAlike 4.0 license.
* The game was only tested thoroughly by me. You can expect to find some bugs - if you find them, please let me know.
* Regarding the soundtrack, credits go to [Zergananda](https://soundcloud.com/zergananda) and [Francesco Corrado](https://soundcloud.com/franzcorradomusic).
* The "bundle.rb" is not part of the source code of the game, it's a utility script I use to create a bundled file with all the source code.
* The level editor I have used to create all the stages is also available [here](https://github.com/victords/super-bombinhas-editor).

## Contributing

The first goal of this repository is for people to play the game and give feedback on the gameplay, graphics, soundtrack, etc. However, improvements to the source code and new ideas will also be welcome.

If you're interested in contributing with the source code, contact me on [victordavidsantos@gmail.com](mailto:victordavidsantos@gmail.com) so I can give you an overview of the project's structure. If there are many people interested, I will then include such overview in this README.

Also, if you want to support my work, you can donate bitcoins to this wallet: bc1qq2x69etga4a2zk9ca99dpc5xpc4q48hn5jg065
