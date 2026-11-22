# ThugUI

## 3.0.2

- Changed (Full-screen inventory): off by default. This update turns it off
  once even if you had it on; turn it back on with the new button at the top
  of its page (Settings, Controller, Full-screen inventory).
- New (Full-screen inventory): Window mode. The inventory becomes a window
  you move by dragging and resize from its bottom-right corner, for screens
  where full screen is not all visible. The rest of the screen is covered
  (adjustable), and a Reset window position button puts it back.
- New (Full-screen inventory): Window scale, 30% to 200%, in both modes.
  Icon sizes now go from 25% to 400% and text size from 8 to 48.
- Changed (Full-screen inventory): swapping a bag is left to the game. A
  bag that holds items can be replaced by another; if the game refuses a
  swap, its own message shows in the window. Removing a bag that holds
  items still asks you to empty it first.

## 3.0.1

- Changed (Full-screen window, controller): in combat the bags are
  Blizzard's. Opening the bags mid-fight shows Blizzard's own bag, whose
  controller cursor can use a potion; ThugUI's window is back the next time
  you open the bags out of combat. With "Close when combat starts" off, the
  window says to close it to use items from Blizzard's bag.
- Fixed (Full-screen window): items that open ("Right Click to Open", like a
  barnacle or a satchel) can be opened from the window: they are on the
  Usable tab, and the left face button says Open.
- Changed (Orbs): the resource orb's "Only show when not full" now has the
  same label as the health orb's; the rage note is in the tooltip.

## 3.0.0

- New (WoW Forever, controller): the Pad layout page (Settings, Controller).
  Pictures of your PlayStation or Xbox pad in four tabs: face buttons, L1 /
  R1 + D-pad right, both bumpers held, and the menu buttons. Pick a button
  and choose what it does from short lists: your macros, spells, ThugUI
  actions or Blizzard's own. Every button starts on Blizzard's default, a
  red band warns when a default action no longer has a button, and "Back to
  Blizzard's defaults" puts everything back.
- New (controller): Start and Select (Create / View) open windows that close
  on the same press: the radial, ThugUI menu, map, character, bags,
  spellbook, talents, quest log, professions, group finder, game menu and
  Focus UI.
- New (controller): a double press on Start and on Select, off until you set
  one: ThugUI menu, reload or screenshot.
- New (controller): a hold on the PS / Xbox button, off until you set one:
  ThugUI menu, escape menu or hide the interface. A tap still does the
  button's single action, on release.
- New (controller): the ThugUI menu and Blizzard's radial close each other.
  Start on the ThugUI menu opens Blizzard's radial; your ThugUI menu button
  on Blizzard's radial opens ours.
- New (Full-screen inventory): using an item on another item (Shiny Bauble,
  sharpening stone, enchant) opens the bags with a cyan outline; X applies
  it, Back cancels, items it fits are ticked when the game knows. The
  target's icon fills back in as the cast runs, inside a thick ring.
- New (controller chat): hold D-pad up or down to keep scrolling.
- Changed (controller): the built-in double presses (Start twice for the
  ThugUI menu, Select twice to reload, touchpad twice for a screenshot) are
  gone; set the ones you want on the Pad layout page.
- Fixed: the fishing macro skipped to lures you cannot use yet (Nightcrawlers
  below Fishing 50); it now picks the best usable one.

## 2.6.2

- New (Full-screen inventory): bag space as gauges in the footer. A
  backpack icon and a bar for your normal bags, filled by the slots used,
  with the slots left written on it. Profession bags, quivers, ammo pouches
  and the reagent bag each get their own gauge beside it with the bag's own
  icon, so "Bags" is only the space any loot can go in. A full kind says
  "Full" and turns red.
- New: a notice when another addon does the same job as a ThugUI module
  (Bartender4, Plater, ElvUI and others). "Turn ours off" switches only that
  part of ThugUI off; "Don't show again" stops asking about that addon.
- New (controller): ThugUI's popups answer to the pad. D-pad moves between
  the buttons, Cross presses, Circle closes.
- Changed (controller wheel): a slice that acts closes the wheel; Circle
  steps back one level.
- Fixed (WoW Forever, controller): the pet bar no longer lands on the
  controller's stuck "S" page.

## 2.6.1

- New (WoW Forever, controller): double-tap Select to reload the interface,
  in combat too. One tap shows "Tap again to reload". Switch it off on the
  Controller page.
- New (Full-screen inventory): "Bind to controller button" in an item's Y
  menu. Press the button you want it on; hold L2, R2 or both for the other
  bars. B goes back to the menu. It never opens the game's binding screen,
  so your controller keeps working afterwards.
- New (Full-screen inventory): moving onto gear in your bags shows the stat
  changes against what you wear, under each slot's name.
- New (Full-screen inventory): size sliders for the equipped items, armor
  chest, inventory tabs, reagent strip and bag slots.
- Fixed (Full-screen inventory): the L1/R1 icons at the ends of the tab rows
  showed as text.

## 2.6.0

- New (WoW Forever, controller, experimental): the Full-screen inventory
  tile, off by default. Opening your bags or the character sheet shows one
  full-screen window instead: your character on the left, your bags on the
  right, and a large info panel in the middle in place of tooltips.
  - The character side has Gear, Stats and Upkeep tabs, switched with L1/R1.
    Gear shows your 3D character, the item level on each slot, and a warning
    dot when durability is low.
  - Moving onto gear in your bags shows what you wear in that slot beneath it.
  - X uses or equips, and Y opens a menu: split a stack, link it in chat,
    compare, or destroy, with Cancel picked first. Anything the game would
    refuse is dimmed, with the reason in plain words.
  - Bags: X on a bag puts it in an empty bag slot. A on a bag slot lets you
    pick a bag or remove one.
  - The D-pad moves through a whole side, from the paper doll into the armor
    chest and through the bags, the reagent strip and the bag slots. L2/R2
    switch sides.
  - The game's own popups (such as "this will bind it to you") show in the
    info panel, with the button that answers each option.
  - A framed look is drawn from stand-in art for now. Switch it off on the
    tile's page for plain panels.
- New: choosing a gear quest reward shows what you wear in that slot right
  above its tooltip, or says that nothing is equipped there.
- Changed: profile strings carry a settings version. A string from an older
  ThugUI, including an older major version, imports into a newer one. Any
  setting that no longer fits is skipped and listed after the import. A
  string from a newer ThugUI asks you to update first.

## 2.5.0

- Changed: the controller chat stream shows whichever tab the chat window is
  on. Change tab, close the window, and the stream follows, and it stays on
  that tab after a reload. The stream's own What shows settings are gone.
- Changed: the Chat stream settings are down to three tabs. Size & look and
  Lines stay, and everything else moved onto one Visibility tab.
- New: the controller chat opens in combat. L1/R1 and the D-pad change tabs
  and scroll, and B closes it. Your buttons do not cast until it closes, and a
  chat window left open still closes when combat starts.
- New (WoW Forever): press the Back button twice for a screenshot.

## 2.4.0

- New (WoW Forever, experimental): the Face buttons tile, next to Controller
  and off by default. Set the four face buttons to a spell or macro,
  separately on each of the three controller layouts. A button left on
  Default keeps Blizzard's action, and holding a trigger or bumper still uses
  those bars. A button you set shows your spell or macro's icon, without a
  cooldown sweep for now.
- Changed: the controller wheel opens in combat, as the right-click menu does,
  so you can invite a player mid-fight. Options that need a secure button are
  greyed until combat ends. A wheel that is open when combat starts closes.
- New: the controller buttons hide during NPC dialogue, with a setting on every
  Visibility section, and while any Spoken box is on screen.
- New: when the Spoken addon shows the words (Subtitles, Small Window or Large
  Window), the Dialogue window clears its background and drops its text and
  title. Rewards, XP and choices stay. Voice Only leaves the window as it is.
- Fixed: the target frame's aura row no longer goes blank in combat. It now
  draws through Blizzard's aura container.

## 2.3.0

- Updated for the release of WoW Forever (1.60.1, build 70790). The game
  now lives in `_forever_`, so install ThugUI to
  `World of Warcraft\_forever_\Interface\AddOns`.
- New: the Action Bars page has a Visibility tab. Each bar can show only in
  combat or fade out of combat, on its own. Edit Mode shows every bar in
  full, and controller mode leaves the bars alone.
- New: `/thugseason loot` records the season raid bosses' loot to the debug
  log.
- Fixed: mouseover casts now land on party, target and target-of-target
  frames, and those frames work with click-casting addons.
- Fixed: a target or target of target picked up mid-fight is clickable at
  once.
- Fixed: on Retail, chat could sit in the wrong place after login or
  `/reload` until you cycled its mode.

## 2.2.2

- Updated for Retail 12.1.5 (Interface 120105).

## 2.2.1

- Fixed: party frames could raise a "blocked action" error when combat
  started. Clicking a party frame still targets that member.
- Fixed: on WoW Forever with a controller, trading raised errors when the
  trade window opened, was used or closed. In controller play your bags no
  longer open by themselves with a trade; mouse play and Retail still do.
- Changed: Trade and Inspect left the Start-twice wheel's Utility page.
  They are on the target's own wheel (Triangle).

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
