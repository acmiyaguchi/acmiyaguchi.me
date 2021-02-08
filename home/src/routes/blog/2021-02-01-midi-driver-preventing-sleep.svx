---
layout: post
title: MIDI drivers keeping Windows 10 from sleeping?
date: 2021-02-01T22:31:00-08:00
category: Personal
tags:
  - midi
  - keyboard
---

Half an hour after I turned off my computer monitor and laid in bed for the
night, I noted the light, continuous humming of my desktop's fan and the
rattling of the hard-drive platters. It obviously didn't get the memo -- it's
time for sleep, not idle spinning. I couldn't be bothered to leave the warm
embrace of bed, but I was curious enough to see what was keeping it awake later
that morning.

I opened an administrative command prompt on my Windows 10 machine and typed the
following:

```shell
powercfg -requests
```

This command shows processes that might be keeping the computer awake. I had
used this earlier in the week to diagnose my computer's insomnia caused by an
open Spotify window, even when paused. It's a feature, not a bug. 😉

```shell
DISPLAY:
None.

SYSTEM:
[DRIVER] Realtek High Definition Audio (HDAUDIO\FUNC_01&VEN_10EC&DEV_1220&SUBSYS_1458A182&REV_1000\5&5e7edb7&0&0001)
An audio stream is currently in use.

AWAYMODE:
None.

EXECUTION:
[PROCESS] \Device\HarddiskVolume4\Program Files\WindowsApps\SpotifyAB.SpotifyMusic_1.151.382.0_x86__zpdnekdrzrea0\Spotify.exe
Background Audio Playback

PERFBOOST:
None.

ACTIVELOCKSCREEN:
None.
```

So what could it be this time? I quickly noticed something peculiar:

```shell
SYSTEM:
[DRIVER] Realtek High Definition Audio (HDAUDIO\FUNC_01&VEN_10EC&DEV_1220&SUBSYS_1458A182&REV_1000\5&5e7edb7&0&0001)
An audio stream is currently in use.
[DRIVER] CASIO USB MIDI (USB\VID_07CF&PID_6802\7&36e288da&0&2)
An audio stream is currently in use.
[DRIVER] CASIO USB MIDI (USB\VID_07CF&PID_6802\7&36e288da&0&2)
An audio stream is currently in use.
[DRIVER] CASIO USB MIDI (USB\VID_07CF&PID_6802\7&36e288da&0&2)
An audio stream is currently in use.
```

It turns out it was the keyboard I was [recently playing
with](blog/2021-02-01-midi-ssr-sapper) was showing up as multiple active
connections. That couldn't be right; it was certainly powered off with a single
cord plugged into the USB hub. I [played around with LMMS][lmms] and realized
that I could reproduce this issue by doing the following:

- Start LMMS with my keyboard on.
- Attach the keyboard to an instrument.
- Turn off the keyboard while it's being used as a MIDI input.
- Close LMMS and run `powercfg -requests`.

I can create an indefinite number of open audio streams by repeating these
steps. These active streams will keep my computer awake until I restart it. Is
this an issue with LMMS not closing MIDI resources properly? An issue with the
the [Casio audio drivers][drivers] not interfacing with Windows properly? Poor
design decisions in the [Windows Multimedia APIs][winmm]? I can't put my finger
on the exact issue without more investigation. I filed [LMMS/lmms#5900][issue]
on the Github repository; maybe I'll try my hand to see if I can fix the problem
for my use case.

For now, I'll just have to work around the issue and make sure that the keyboard
is always on when I work with my recordings.

[lmms]: https://lmms.io/
[drivers]: https://support.casio.com/en/support/download.php?cid=008&pid=72
[winmm]: https://en.wikipedia.org/wiki/Windows_legacy_audio_components
[issue]: https://github.com/LMMS/lmms/issues/5900
