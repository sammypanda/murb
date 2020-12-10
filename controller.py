# Table of Contents:
    #1 Variables
        #1a Globals
        #1b Load
        #1c Help
    #2 Dependencies
        #2a Youtube-DL
        #2b JQ
    #3 Functions
        #3a syncActivity()
        #3b song()
        #3c list()
        #3d help()
        #3e load()
        #3f queue()
        #3g syncProcess()
        #3h sync()
        #3i skip()

# Imports) Globals
import os

# Variables) Globals
scriptDir = os.path.dirname(os.path.realpath(__file__))
musicDir = scriptDir + "/assets/music"
