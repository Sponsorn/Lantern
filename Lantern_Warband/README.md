# Lantern: Warband

Warband management addon for World of Warcraft that helps you organize your characters into groups and automate gold banking.

## Features

### Character Groups
- Create custom groups for organizing your characters (e.g., "Mains", "Alts", "Bankers")
- Assign characters to groups
- Set gold thresholds per group

### Automated Banking
- Automatically balance gold to match your threshold when opening a bank
- Deposit excess gold to warbank if you have more than the threshold
- Withdraw gold from warbank if you have less than the threshold
- Each group has a configurable gold threshold

## How to Use

### Creating a Group
1. Open Lantern options (minimap icon or `/lantern`)
2. Go to **Warband** → **Groups** tab
3. Enter a group name (e.g., "Main Characters")
4. Set gold threshold in gold (e.g., "100" for 100 gold)
5. Click **Create Group**

### Assigning Characters
1. Log in to a character you want to assign
2. Open Lantern options → **Warband** → **Characters** tab
3. Select a group from the dropdown for "Current Character"
4. The character is now assigned!

### Using Auto-Balance
1. Make sure **Auto-balance gold with warbank** is enabled in **General** tab
2. When you open a bank on a character in a group:
   - If you have **more** gold than the threshold: excess will automatically deposit to your warbank
   - If you have **less** gold than the threshold: the difference will automatically withdraw from your warbank
   - You'll see a message: "Deposited X gold to warbank" or "Withdrew X gold from warbank"

## Example Setup

**Group: Main Characters**
- Threshold: 100 gold
- Members: MyWarrior-Area52, MyMage-Area52

**Group: Farming Alts**
- Threshold: 10 gold
- Members: FarmAlt1-Area52, FarmAlt2-Area52

When MyWarrior (with 250 gold) opens a bank:
- Target: 100 gold
- Action: Deposits 150 gold to warbank

When MyWarrior (with 50 gold) opens a bank:
- Target: 100 gold
- Action: Withdraws 50 gold from warbank

When FarmAlt1 (with 45 gold) opens a bank:
- Target: 10 gold
- Action: Deposits 35 gold to warbank

When FarmAlt1 (with 5 gold) opens a bank:
- Target: 10 gold
- Action: Withdraws 5 gold from warbank

## Configuration Options

### General Tab
- **Auto-balance gold with warbank**: Toggle automatic deposits and withdrawals on/off
- **Current character info**: Shows your character's group and threshold

### Groups Tab
- Create new groups with custom thresholds
- Edit existing group thresholds
- Delete groups (characters get unassigned)
- View member counts

### Characters Tab
- Assign current character to a group
- View all assigned characters across your warband

## Requirements

- Lantern core addon
- World of Warcraft patch 11.0.2+ (for warbank support)

## Version

Current version: 0.1.0

## License

Licensed under GPLv3.
