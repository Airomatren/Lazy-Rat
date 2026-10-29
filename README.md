# Lazy Rat

A World of Warcraft (Retail) addon that clicks the annoying popups for you: resurrections, battle resurrections, summons, dungeon queue pops and premade group sign-ups. Every feature can be turned on or off.

Type `/lr` or click the minimap button to open the settings.

## Features

### General
- **Auto-accept resurrections:** takes a normal res as soon as it's offered.
- **Auto-accept battle resurrections:** a separate toggle for combat resses. A res counts as a battle res if it comes during a boss encounter or while the caster is in combat.
- **Auto-accept summons:** takes summons automatically. If you're in combat, it waits and accepts as soon as combat ends.
- **Remove profession gear transforms:** automatically takes off the profession outfit buff (Chef's Hat, smithing gear, etc.) after you craft or gather, and the fishing outfit when you stop fishing. Anything applied during combat is removed when combat ends.
- **Minimap button:** click to open settings, drag to move it around the minimap, or hide it.

### Auto Queue
- **Auto-accept queue pops & role checks (LFG/LFR):** accepts the "Enter Dungeon" popup and completes role checks with your preferred roles.
- **Auto Sign-Up (Premade Groups):** skips the role dialog when you sign up for a group in the Premade Groups finder and signs you up with your preferred roles. Hold **Shift** when signing up to get the normal dialog instead.
- **Preferred Roles:** Tank, Healer and Damage. **Saved per character**, so your tank and your mage can each keep their own picks. Roles your class or spec can't play are ignored, and if nothing valid is selected you're signed up as Damage.

### Notifications
- **Chat message:** prints a line in chat whenever Lazy Rat accepts something.
- **Raid warning message:** shows the big message in the middle of your screen as well.

All settings except Preferred Roles are shared across your account.

## Installation

You need the **Retail** version of World of Warcraft.

### 1. Download

On this page, click the green **Code** button, then **Download ZIP**.

### 2. Find your AddOns folder

The easiest way: open the **Battle.net app**, select World of Warcraft, click the **gear icon** next to the Play button and choose **Show in Explorer** (Windows) or **Show in Finder** (Mac). Then open `_retail_` → `Interface` → `AddOns`.

The usual locations are:

| System  | Folder |
|---------|--------|
| Windows | `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns` |
| Mac     | `/Applications/World of Warcraft/_retail_/Interface/AddOns` |

If `Interface` or `AddOns` doesn't exist yet, create it. Spelling and capitals must match.

### 3. Unzip and rename

1. Extract the ZIP. You'll get a folder called **`Lazy-Rat-main`**.
2. **Rename it to `LazyRat`.** WoW won't load it under the GitHub name.
3. Move the `LazyRat` folder into `AddOns`.

When you're done, this file should exist:

```
...\_retail_\Interface\AddOns\LazyRat\LazyRat.toc
```

A common mistake is a folder nested inside another one, like `AddOns\LazyRat\Lazy-Rat-main\LazyRat.toc`. If that happens, move the inner folder up a level.

### 4. Enable it in game

1. Fully restart WoW if it was open (a `/reload` isn't enough for a newly installed addon).
2. On the character select screen, click **AddOns** (bottom left) and make sure **Lazy Rat** is ticked.
3. If it's listed as **Out of date**, tick **Load out of date AddOns** at the top of that window.
4. Log in and type `/lr`.

### Updating

Download the ZIP again and replace the old `LazyRat` folder. Your settings are kept: WoW stores them in the `WTF` folder, not inside the addon.

### Installing with git (optional)

If you use git, clone straight into the right folder name and run `git pull` to update:

```
cd "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns"
git clone https://github.com/Airomatren/Lazy-Rat.git LazyRat
```

## Shoutout

Big thanks to **Noobheartx** and [MythicPlusCount](https://github.com/noobheartx/MythicPlusCount) (MIT licensed). Lazy Rat's queue-pop accept, premade auto sign-up and role-check handling are based on its Auto Queue feature, and the settings window copies its look. Go check it out.

Thanks also to **EllesmereUI**: the profession gear removal is based on its *Hide Item Transforms* option, including its list of profession transform spell IDs.

If you use both, turn off MythicPlusCount's *Auto Queue* so the two don't both try to handle the sign-up dialog.
