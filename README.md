<img width="200" height="200" src="./img/trokara_tortoise.svg">

# Trokara
A versatile and well documented package for developing terrestrial characters

# IMPORTANT NOTICE
### Trokara is undergoing an api_change. Most of the code will be refactored, and a few old functionalities will be removed,
### while making way for new improvements. If you would like to see these changes, use the api_change branch.
### Do note however, this branch is subject to many changes

## Table of contents
* [General info](#general-info)
* [Screenshots](#screenshots)
* [Technologies](#technologies)
* [Features](#features)
* [Status](#status)
* [Inspiration](#inspiration)
* [Contact](#contact)

## General info
Ever wanted to make a shooter, but end up creating something buggy and not fun to play? \
Or even worse, your code looks practically like an Italian dinner, and your teammates hate you for that? \
Well you're in luck! The brunt of any FPS, TPS, platformers etc has been done for you! \
The set of scripts in TrokaraScripts is available free of any royalty, for anyone from beginners to professionals, to use

Aspects such as physics, user input, and camera rigging have all been implemented already! \
The code also closely follows the GDscript Design Principles, and the SOLID Design Principles \
As such, all the scripts should be easily inheritable for AI, or extra functionality

There is a demo available, with assets courtesy of mstuff \
In the demo, pressing 1 switches to FPS, whilst pressing 2 switches to TPS \
The important thing to note is that both demos use the same script for the KinematicBodies \
The only thing which is different is the cameras, the scripts for which are also available

## Screenshots
![standing screenshot](./img/standing_screenshot.png)
![leaping screenshot](./img/leaping_screenshot.png)

## Technologies
* GDscript - version 3.2.2

## Features
List of features ready and TODOs for future development
* Improved floor snapping
* Near zero deviance on slopes
* Perfectly equal velocities on all slopes
* Multi jumps, off of slopes, ramps and steep walls
* Smarter alternative to SpringArm (KinematicArm)
* Completely set up for inheritance and AI
* Plenty of comments (feel free to contact me with any questions)
* 100% GDscript; Source code fully available!

Features currently being finalised!
* ZERO deviance on complex terrain
* Functioning Wall jumping
* Support for PhysicsMaterials (Bounce, friction)
* Support for moving platforms (Translation, Rotation)
* Support for constant_linear_velocity and constant_angular_velocity

## Status
Project is: _in progress_ \
There are still features which can be added by others, and probably a few bugs which haven't appeared yet \
This project is completely open-source so anyone can contribute

## Inspiration
It all began when my previous project, a third person platformer, went bust. A guy by the name of mstuff asked for someone to help develop a third person controller in discord. I responded, as I was kind of pleased with what I had made before, and wanted to prove it. After many weeks of coding, the final product was very different than from the failed project, yet was much better and cleaner.

## Contact
Created by @manglemix - feel free to contact me!
