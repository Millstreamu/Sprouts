# Sprouts

🌱 SPROUTS — DESIGN DOCUMENT (v4)

A complete rewrite: merged, consistent, and structured around Codex-driven development.

1. HIGH-LEVEL OVERVIEW

Genre: Cozy turn-based hex-grid regrowth strategy
Engine: Godot 4.4+ (2D)
Platform: PC, very low specs
Controls: Keyboard-first (controller later)

Core Fantasy:
Restore a shrouded, dying wilderness by placing life-giving tiles, forming powerful clusters of Nature, Water, and Earth. These clusters spawn Sprouts that do battle with Creeping Decay. Survive long enough to destroy all Decay Totems.

Design Tone:
Lighthearted, calm, “storybook fantasy,” simple input scheme, chill pacing.

2. DEVELOPMENT WORKFLOW (CRITICALLY IMPORTANT)
2.1 How Code Is Written

All code is produced by ChatGPT, generating prompts meant for OpenAI Codex.

Codex writes actual GDScript.

Small errors:
Fed back to ChatGPT for an updated prompt.

Large errors / broken systems:
Fixed directly in Codex without a new prompt.

2.2 UI & Visual Editing Rules

All visuals MUST be editable inside the Godot editor, not locked behind code.

Codex must NOT:

Hardcode pixel positions

Hardcode sizing

Hardcode colors

Build complex UIs only in code

Override textures, fonts, or layout visually via script

Codex SHOULD:

Build scene templates with Nodes, Containers, Panels

Wire signals, logic, data binding

Use exported variables to connect scenes

Leave visual tuning, art placement, and style to the user

2.3 Scene-First Workflow

ChatGPT generates a Codex prompt to create a scene (example: SproutCard.tscn).

Codex creates a functional, clean, unstyled template.

The user opens the scene in Godot and wires in art, textures, border colours, fonts.

Codex integrates the logic backend and connects signals without modifying layout.

2.4 Testing Workflow

No automated testing

All testing done through manual play

Debug logs printed to Godot terminal

Iteration: play → observe issues → Codex fixes → repeat

3. MAIN MENU & META SCREENS
3.1 Main Menu

Visual:

Background art

Logo centered at top

Vertical menu of 5 choices:

Start Run

Collection

Challenges

Settings

Exit

Input:

Arrow keys move a softly animated highlight border

Space selects

Cannot move past top or bottom entry

3.2 Settings Screen

Contains:

Master volume slider

“Clear Data” button → shows confirmation dialog

“Back” button

Only these options for now

3.3 Collection

Tabs at the top (stylized):

Totems

Sprouts

Tiles

Below:

4-wide infinite scroll grid

Cards use a reusable “card scene”

Locked cards show a universal locked version

Unique ID on each card

Unlock Rules:

Sprouts: 3 unlocked at start; others found in runs

Tiles: unlocked the first time you place one

Totems: unlocked via Challenges

All unlocks persist until data is cleared

3.4 Challenges

Listed vertically

All visible from the start

Each challenge shows:

Name

Description

Reward (Totem or unique Sprout/Tile)

Completion indicator

Challenges give permanent unlocks

4. STARTING A RUN
4.1 Totem Selection

Carousel view (left/right scroll)

Center totem enlarged

Shows:

Name

Description

Effects

Locked totems: grayscale art, “Locked” label

Space selects totem

4.2 Difficulty Selection

Appears immediately after totem is selected.

Three circular gem icons:

Easy

Medium

Hard

Arrow keys switch highlight

Space confirms

Press P to continue

Difficulty determines number of Decay Totems:

Easy: 1

Medium: 2

Hard: 3

(+ future modifiers later)

4.3 Sprout Selection

Grid of sprout cards (4 wide)

Arrow keys highlight

Space toggles select/deselect

Must pick exactly 3

A “+” button bottom-right turns green when valid

Press P to begin run

5. SHROUD WORLD (MAIN GAMEPLAY SPACE)
5.1 The World Map

Entire map initially covered in shroud

Placing tiles at the frontier reveals adjacent hexes

Your chosen Totem spawns at center

1–3 Decay Totems spawn depending on difficulty

Goal: Destroy all Decay Totems.

5.2 Tile Placement

Each turn you receive:

A pool of 3 tiles

Choose one to place

Must be placed adjacent to existing Life tiles

Cannot overwrite existing tiles

Tiles are permanent

5.3 Tile Structure

Each tile has:

Category: Nature / Water / Earth / Decay / Special

Sub-type tags (FOREST, RIVER, etc.)

Editor-assigned visuals:

Hex art

Border colour

JSON-assigned gameplay:

Resource output

Adjacency effects

Cluster modifiers

Decay resistance

Special actions or triggers

6. CLUSTER SYSTEM (v4 CORE MECHANIC)
6.1 What is a Cluster?

A cluster is any connected group of tiles of the same core category:

Nature

Water

Earth

Featuring colored outlines:

Green = Nature

Blue = Water

Red = Earth

Overgrowth and Groves count as Nature.

6.2 Cluster Milestones

Trigger immediately on placement:

3 tiles

6 tiles

12 tiles

24 tiles

Milestones only trigger once per cluster (persist even if split up later).

6.3 Cluster Rewards
If the cluster category matches a selected sprout:

Spawn 1 sprout of that type (added to registry)

If not:

Award Soul Seeds, scaling by milestone

Exact values editable in JSON

Example JSON:

{
  "cluster_rewards": {
    "3": 5,
    "6": 10,
    "12": 15,
    "24": 20
  }
}

Multiple clusters can reward in the same turn.

Rare, but allowed.

6.4 Cluster Bonuses

Each cluster applies bonuses to its tiles (values editable):

Resource production % increase

Capacity increase

Decay resistance increases

Bonus scales with cluster size

7. DECAY SYSTEM
7.1 Decay Totems

Key enemy structures

Must be destroyed to win

Spawn Creeping Decay tiles each turn

Visually editable — multiple art variants possible

7.2 Creeping Decay

Identical to previous decay behavior:

Grows outward

Prioritizes path toward player’s Totem

Reduces tile stats

Initiates Sprout Battles when engaging Life tiles

Player can attack Decay tiles adjacent to Life

8. SPROUT SYSTEM
8.1 Sprout Registry

All Sprouts live in this screen

Sprouts are not units on the map

Cluster spawns add new sprouts here

You choose a battle team from the registry

8.2 Leveling

Leveling requires:

Essence resources (Nature, Water, Earth)

Soul Seeds

Soul Seed Level Costs:

L1 → L2 = 1

L2 → L3 = 2

L3 → L4 = 3

...

L5 → L6 = 5

And so on; cost increases by +1 per level

8.3 Sprout Stats

Each sprout features:

HP

Attack

Speed

Unique attack ability

Passives

Permanent death

Persistent damage across all battles

9. TURN SEQUENCE (FINAL)
Turn Steps

1. Player places a tile

Choose 1 of 3

Place it

Reveal shroud

Apply adjacency effects

2. Cluster milestones check immediately

Spawn sprouts OR award soul seeds

3. Player ends turn (press V or click RL-Next)

UI located bottom-right

4. Sprout Battles resolve first

Any triggered battles run here

Sprouts deal/take damage

Tiles cleanse/convert depending on win/loss

5. Decay grows

Creeping Decay expands

May set up battles for next turn

6. New turn begins

Player receives new pool of 3 tiles

10. RESOURCES & UI PANEL
10.1 Resource Types

Nature Essence

Water Essence

Earth Essence

Soul Seeds

Life Essence

10.2 Resource Panel

Located in bottom-right, as a separate scene.
Shows:

All resource counts

Turn number

“RL — Next Turn” button

Press V = end turn shortcut

UI fully editable in Godot. Codex only wires logic.

11. TILE CREATION PIPELINE
User controls (in Godot editor):

Artwork for each tile

Border colour

Card/hex visual structure

Animation or highlight effects

Scene layout

JSON controls (via AI/Codex):

Tile unique ID

Category

Tags

Effects

Clustering behavior

Resource stats

Transformations, conditions, intervals

Battle triggers

Balancing numbers

Tile scenes link to JSON entries via ID at runtime.

12. STATE MACHINES (STRUCTURE)
Main Menu State

Start Run

Collection

Challenges

Settings

Exit

Run Setup State

Totem Selection → Difficulty Selection → Sprout Selection → Load World

Shroud World (Gameplay State)

Tile Placement

Cluster Check

End Turn

Battle

Decay Spread

Next Turn

13. SAVE SYSTEM

Persistent:

Unlocked sprouts

Unlocked tiles

Unlocked totems

Completed challenges

Settings (volume)

Save data cleared only from Settings → “Clear Data”

14. DEBUGGING

Debug done through Godot’s output console

No automated tests

Player manually reports issues

Codex fixes or adjusts logic as needed

END OF DOCUMENT — Sprouts Design Document (v4)
