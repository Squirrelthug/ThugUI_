# ThugUI

## 2.2.0

- New: Chat stream replaces Acorns. Chat runs as a see-through stream of
  text, by default on the left edge of the screen. A chat button on the
  minimap cycles Blizzard's chat, the stream, or hidden; right-click opens
  its settings. Your acorn chat settings carry over. `/thugchat` controls it.
- New: the Copy window. "Copy from..." on any page with scope buttons opens
  a window that shows where a copy comes from and where it goes.
- New: on WoW Forever, the orbs, target and party frames, nameplates,
  dialogue, camera, frame hider and cooldown viewer keep separate settings
  for mouse and keyboard play and for controller play. Your current setup
  is kept for both.
- New: party frames show shields and incoming heals on the bar, or on a
  square or circle whose background shows health. The second ring and
  line and the "heals & absorbs" layer are gone; an old profile that used
  them shows health there.
- New: Frame hider > Objective tracker, a page of its own: hide the
  tracker, or set when it shows (combat, targets, moving, flying, and
  "hide in combat in dungeons and raids").
- New: every visibility page has every rule, including "fade while
  moving", in mouse play and on Retail too. "Show on gamepad input"
  appears only with the Controller tile on.
- New installs start with: action bars 1 to 4 managed (12 buttons of 42 px
  per row), nameplates, dialogue, the minimap (top left), world map,
  fishing, orbs, target and party frames (circles), Chat stream, frame
  hider and automation on; camera (no situation ticked), cooldown viewer
  and the buff window off. Existing setups keep every tile as it was.
- Changed: Cursor rings are retired. Their features live in the orb rings
  and the orbs.
- Changed: party frame icon position moves in tenths, and the circle's
  target ring can be a hairline. In test mode the first frame is you,
  live.
- Fixed: Blizzard's action bars you hid came back after logging out. ThugUI
  remembers bars you hide on its page or in Options and hides them again.
- Fixed: profile strings made in controller play lost the mouse setup.
- Fixed: switched-off modules no longer run anything in the background.

## 2.1.1

- Fixed: the right-click unit menu's protected options (Set focus, raid
  marks and the rest) did nothing when clicked.
- Fixed: raid marks from the unit menu and the controller wheel were
  refused by the game; they now use Blizzard's /tm. The wheel gets a Clear
  mark page and a Remove mark slice beside the marks.
- Fixed: on WoW Forever the global cooldown never swept the cursor GCD
  ring or an orb ring set to Global cooldown, in or out of combat.
- Back: the map on the controller shortcuts' bottom face button (hold the
  shortcut modifiers, press the bottom face button), out of combat.
- New: "Fade while flying" on every visibility page (a flight path, or a
  flying mount in the air). On by default for the orbs, which already hid on
  flight paths; off for everything else.
- Changed: the controller wheel always opens on Utility.

## 2.1.0

- New: party frames in place of Blizzard's, as bars, squares or circles.
  Each part of a square or circle shows health, the resource, or incoming
  heals and absorbs, in its own colour; an optional second ring; a grid of
  rows or columns; and a different look per role (tanks, healers, damage).
- New: right-click the target, target-of-target and party frames for a unit
  menu (whisper, inspect, trade, invite, raid marks, set focus and more).
  With a controller, Triangle opens the same options on a wheel.
- New: a Party page on the controller wheel, in place of Blizzard's raid
  manager panel while you are in a party.
- New: Themes. Twenty presets (item quality, every class over its talent
  background, places over loading screens, Alliance and Horde), your own
  saved themes, pictures from the game's art, text size, and a resizable
  settings window.
- New: profile strings to share a profile and import one as a new profile.
- New: fishing by double-click or a double-pressed key.
- New: the same visibility rules on more frames: show on gamepad input,
  fade while moving, and "always show in combat" for party frames and both
  chat streams.
- New: our own confirmation dialog everywhere, and controller hints beside
  Blizzard's on-screen button legend.
- Changed: long settings pages are split into nested tabs.
- Changed: the controller wheel lets you walk while it is open, slows the
  camera, and stays closed during combat; the buff window leaves the sticks
  to you and navigates with the D-pad.
- Fixed: the cast and GCD sweeps in combat, cursor rings showing while off,
  and the settings window failing to build.
- Known: the controller map shortcut (L1 + R1 + Cross) is switched off for
  now, and the camera still creeps slightly while the wheel is open.

## 2.0.0

- One addon for retail and WoW Forever, from one folder.
- Every part is a module with its own tile on the Modules page, grouped
  into General, Combat HUD, UI and Interface (and Controller on WoW Forever).
- New: health and resource orbs, target and target-of-target frames,
  dialogue and camera settings, profiles.
