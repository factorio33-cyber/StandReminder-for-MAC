# StandUpReminder

A very small macOS menu bar app that alternates between:

- a `work` timer
- a `stand up` timer

If the screen locks or the session becomes inactive, the app resets back to the start of a work session.


## What it does

- lives in the menu bar
- lets the user set the work duration
- lets the user set the stand-up duration
- sends local notifications when it is time to stand up and when it is time to work again
- lets the user turn reminder sound on or off
- resets the timer if the screen locks


## Notes

- The first launch will ask for notification permission.
- The default cycle is `55 minutes work / 5 minutes standing`.
