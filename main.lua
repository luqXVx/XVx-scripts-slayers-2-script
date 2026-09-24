# XVx Scripts – Admin-/Debug-System für dein eigenes Roblox-Spiel

Komplettes Luau-System mit Key-System, 6 Tabs und serverseitiger Validierung.
Alles ist nur für **dein eigenes Spiel** gedacht: Auto-Farm, Auto-Boss und Combat funktionieren ausschließlich mit NPCs/Bossen, die du selbst registrierst.

---

## 0. Grundidee (Architektur)

| Seite | Aufgabe |
|---|---|
| **Client** (LocalScript) | Nur UI + die reine Bewegung (Fly, NoClip, Infinite Jump). Sendet nur *Wünsche* („Toggle X an“, „Ziel Y“, „Wert 50“). |
| **Server** (Script + ModuleScripts) | Prüft den Key, prüft jede Anfrage, begrenzt Werte (Clamp), führt Auto-Farm/Boss/Combat aus, vergibt XP/Coins/Items/Drops/Quest-Rewards. |

Der Client bestimmt **nie**, wie viel XP, Coins oder Items er bekommt. Die Beträge kommen aus Attributen deiner NPCs/Bosse bzw. aus `ServerConfig`.
Der Key steht **nur** in `ServerScriptService` (Clients können diesen Ordner nicht lesen).

---

## 1. Ordner, die du erstellen musst

```
ReplicatedStorage
└─ XVx                      (Folder)
   ├─ Config                (ModuleScript)
   └─ Remotes               (Folder – wird vom Server automatisch erstellt)

ServerScriptService
└─ XVx                      (Folder)
   ├─ XVxServer             (Script)
   ├─ ServerConfig          (ModuleScript)   <- hier steht der Key
   ├─ Sessions              (ModuleScript)
   ├─ Auth                  (ModuleScript)
   ├─ Rewards               (ModuleScript)
   ├─ Quests                (ModuleScript)
   ├─ Targets               (ModuleScript)
   ├─ PlayerTools           (ModuleScript)
   └─ Automation            (ModuleScript)

ServerStorage
└─ XVxItems                 (Folder)  <- Tools für "Testitems" (z. B. ein Tool "Sword")

StarterGui
└─ XVxScripts               (deine vorhandene ScreenGui, ResetOnSpawn = false)
   └─ XVxClient             (LocalScript)
      ├─ UIKit              (ModuleScript)
      └─ Movement           (ModuleScript)

Workspace
├─ XVxTeleports             (Folder)
│  ├─ Spawn                 (Part)
│  ├─ TestPositions         (Folder mit Parts, Name = Anzeigename)
│  └─ BossArenas            (Folder mit Parts, Name = Anzeigename)
└─ deine NPCs / Bosse       (mit Tags, siehe Abschnitt 8)
```

Wichtig: Die Ordner heißen in ReplicatedStorage **und** ServerScriptService jeweils `XVx` – das ist gewollt.

---

## 2. Benötigte ModuleScripts

| Modul | Ort | Zweck |
|---|---|---|
| `Config` | ReplicatedStorage/XVx | Geteilte, **nicht geheime** Einstellungen: Discord-Link, Limits, Tags, Theme |
| `ServerConfig` | ServerScriptService/XVx | **Key**, Versuche-Limit, Kampfschaden, Reward-Beträge, Quests, optionale Hooks |
| `Sessions` | ServerScriptService/XVx | Zustand pro Spieler (Toggles, Werte, Ziele) |
| `Auth` | ServerScriptService/XVx | Key-Prüfung, Rate-Limit, Freischaltung |
| `Rewards` | ServerScriptService/XVx | XP/Coins/Items vergeben (validiert, Test-Rewards mit Limits) |
| `Quests` | ServerScriptService/XVx | Mini-Questsystem (Annehmen, Fortschritt, Abschließen) |
| `Targets` | ServerScriptService/XVx | Registrierte NPCs/Bosse, Schaden, Tod-Erkennung, Drops, Einsammeln |
| `PlayerTools` | ServerScriptService/XVx | Speed, JumpPower, Heal, God Mode, Teleports |
| `Automation` | ServerScriptService/XVx | Ein einziger Scheduler für Auto-Farm/Boss/Combat/Loot/Quest |
| `UIKit` | unter XVxClient | UI-Bausteine (Toggle, Slider, Dropdown, Button, Tabs) |
| `Movement` | unter XVxClient | Fly, NoClip, Infinite Jump (nur nach Server-Freigabe) |

---

## 3. Benötigte Remotes

Alle liegen in `ReplicatedStorage/XVx/Remotes` und werden von `XVxServer` **automatisch erstellt** – du musst nichts von Hand anlegen.

| Name | Typ | Richtung | Zweck |
|---|---|---|---|
| `KeySubmit` | RemoteFunction | Client → Server | Key prüfen (`nil` = nur Status abfragen) |
| `GetState` | RemoteFunction | Client → Server | Toggles, Werte, Listen (Teleports, Bosse, Items) laden |
| `SetToggle` | RemoteFunction | Client → Server | Funktion an/aus |
| `SetValue` | RemoteFunction | Client → Server | Speed, JumpPower, Attack Range, Loot-Radius |
| `DoAction` | RemoteFunction | Client → Server | Heal, Teleport, Boss wählen, Quest, Test-Rewards |
| `StateSync` | RemoteEvent | Server → Client | Status-Infos (Ziel, Boss, Quest), Meldungen |

Jede Anfrage wird serverseitig geprüft: Freischaltung, Datentypen, erlaubte Namen, Wertebereich, Rate-Limit.

---

## 4. Was kommt nach `ReplicatedStorage`?

Nur `XVx/Config` (ModuleScript, Code 1). Sonst nichts. Der Ordner `Remotes` entsteht automatisch beim Serverstart.

## 5. Was kommt nach `ServerScriptService`?

Der Ordner `XVx` mit `XVxServer` (Script) und den 8 ModuleScripts (Code 2 bis 10).

## 6. Was kommt in deine vorhandene UI?

`XVxClient` (LocalScript) mit `UIKit` und `Movement` als Kinder. Der Code bindet sich **per Namen** an deine UI. Vorhandene Elemente werden übernommen und in ihrem Design **nicht verändert**. Fehlende Elemente werden im Standardstil erzeugt (Farben in `Config.Theme` anpassbar).

| Name (direkt in der ScreenGui) | Klasse | Hinweis |
|---|---|---|
| `KeyFrame` | Frame | Key-Fenster |
| ↳ `Title` | TextLabel | Text wird auf „XVx Scripts“ gesetzt |
| ↳ `KeyInput` | TextBox | Eingabe, nur Buchstaben/Zahlen |
| ↳ `SubmitButton` | TextButton | Key bestätigen |
| ↳ `ErrorLabel` | TextLabel | Fehlermeldung |
| ↳ `LinkBox` | TextBox | zeigt den Discord-Link zum Kopieren |
| ↳ `GetKeyButton` | TextButton | „Get Key“, unten im Key-Fenster |
| `MainFrame` | Frame | Haupt-UI (bis zur Freischaltung unsichtbar) |
| ↳ `Title` | TextLabel | Text wird „XVx Scripts“ |
| ↳ `TabBar` | Frame | Tab-Buttons `Tab_Player`, `Tab_Teleport`, `Tab_AutoFarm`, `Tab_Boss`, `Tab_Combat`, `Tab_Rewards` (TextButton, optional) |
| ↳ `Pages` | Frame | Seiten `Page_Player` … `Page_Rewards` (ScrollingFrame, optional) |
| ↳ `Toast` | TextLabel | Kurzmeldungen |

Heißt bei dir etwas anders, benenne es um oder lass es vom Script erzeugen. Die Zeilen/Toggles/Slider innerhalb der Tabs erzeugt `UIKit` immer selbst.

## 7. Wo jeder Code eingefügt wird

| Code | Typ | Ort |
|---|---|---|
| 1 `Config` | ModuleScript | ReplicatedStorage/XVx |
| 2 `ServerConfig` | ModuleScript | ServerScriptService/XVx |
| 3 `Sessions` | ModuleScript | ServerScriptService/XVx |
| 4 `Auth` | ModuleScript | ServerScriptService/XVx |
| 5 `Rewards` | ModuleScript | ServerScriptService/XVx |
| 6 `Quests` | ModuleScript | ServerScriptService/XVx |
| 7 `Targets` | ModuleScript | ServerScriptService/XVx |
| 8 `PlayerTools` | ModuleScript | ServerScriptService/XVx |
| 9 `Automation` | ModuleScript | ServerScriptService/XVx |
| 10 `XVxServer` | **Script** | ServerScriptService/XVx |
| 11 `UIKit` | ModuleScript | StarterGui/XVxScripts/XVxClient |
| 12 `Movement` | ModuleScript | StarterGui/XVxScripts/XVxClient |
| 13 `XVxClient` | **LocalScript** | StarterGui/XVxScripts |

## 8. Eigene NPCs und Bosse registrieren

Registrierung läuft über **CollectionService-Tags + Attribute**. Tags und Attribute werden mit dem Place gespeichert.

**NPC** (Model mit `Humanoid` und `HumanoidRootPart`): Tag `XVxNpc`

| Attribut | Typ | Bedeutung |
|---|---|---|
| `XP` | number | XP beim Kill (Standard: `ServerConfig.Rewards.DefaultXP`) |
| `Coins` | number | Coins beim Kill |
| `NpcType` | string | Gruppenname für „Teleport zu NPC“ (Standard: Modellname) |
| `DisplayName` | string | Anzeigename |
| `DropCoins` | number | optional: Coin-Drop (Loot), der eingesammelt werden muss |
| `DropItem` / `DropChance` | string / 0–1 | optional: Item-Drop (Name muss in `ServerStorage/XVxItems` existieren) |

**Boss**: Tag `XVxBoss` plus `BossId` (string, eindeutig), `DisplayName` und dieselben Reward-Attribute. Rewards werden mit `BossMultiplier` multipliziert.

**Einsammelbare Welt-Objekte** (für „Auto Collect“): BasePart mit Tag `XVxCollectible` und den Attributen `Kind` (`"Coins"`, `"XP"` oder `"Item"`), `Amount`, bei Items `ItemName`.

Schnell registrieren, in der **Command Bar** in Studio (einmalig ausführen):

```lua
local CS = game:GetService("CollectionService")

for _, npc in workspace.MeineNPCs:GetChildren() do
	CS:AddTag(npc, "XVxNpc")
	npc:SetAttribute("XP", 15)
	npc:SetAttribute("Coins", 8)
	npc:SetAttribute("NpcType", "Goblin")
end

local boss = workspace.MeinBoss
CS:AddTag(boss, "XVxBoss")
boss:SetAttribute("BossId", "Golem")
boss:SetAttribute("DisplayName", "Golem")
boss:SetAttribute("XP", 200)
boss:SetAttribute("Coins", 100)
boss:SetAttribute("DropItem", "Sword")
boss:SetAttribute("DropChance", 0.5)
```

Werden NPCs/Bosse per Script gespawnt (Klon einer Vorlage), reicht es, die Vorlage zu taggen – Tags werden mit `Clone()` kopiert. Ansonsten nach dem Parenten `CollectionService:AddTag(klon, "XVxNpc")` aufrufen.
Bosse, die du respawnen lässt, müssen dieselbe `BossId` behalten. Dann findet der Auto-Boss den neuen Boss automatisch.

## 9. Teleport-Ziele und Testitems

- `Workspace/XVxTeleports/TestPositions/<Name>`: beliebig viele Parts, der Partname erscheint im Dropdown.
- `Workspace/XVxTeleports/BossArenas/<Name>`: dasselbe für Boss-Arenen.
- `Workspace/XVxTeleports/Spawn`: Part für „Zurück zum Spawn“. Fehlt er, wird die erste `SpawnLocation` benutzt.
- NPC-Teleport: Dropdown mit allen `NpcType`-Gruppen, es geht zum nächsten lebenden NPC dieser Gruppe.
- Testitems: `Tool`-Objekte in `ServerStorage/XVxItems`; erlaubte Namen in `ServerConfig.Rewards.TestItems` eintragen.

## 10. Wichtige Hinweise

- **Key ändern:** `ServerConfig.Key` (nur Buchstaben/Zahlen). **Discord-Link ändern:** `Config.DiscordLink`.
- **„Get Key“:** Roblox erlaubt Spielen nicht, externe Links zu öffnen oder in die Zwischenablage zu schreiben. Der Button zeigt deshalb den Link markiert in `LinkBox` an (Strg+C bzw. auf Mobile lange drücken). Prüfe außerdem, ob Discord-Links in deinem Spiel mit den Roblox-Richtlinien vereinbar sind; Social-Links auf der Spielseite sind der sichere Weg.
- **Live-Spiel:** Wer den Key kennt, bekommt Admin-Funktionen. Trage für ein veröffentlichtes Spiel in `ServerConfig.AllowedUserIds` deine UserIds ein oder setze `StudioOnly = true`.
- **Datenspeicherung:** XP/Coins liegen standardmäßig in `leaderstats` (nicht persistent). Für dein eigenes Datensystem überschreibst du die Hooks in `ServerConfig.Hooks` (`GiveXP`, `GiveCoins`, `GiveItem`, `DealDamage`).
- **Eigener Anti-Cheat:** Fly/NoClip sind Client-Bewegungen. Lies serverseitig `require(ServerScriptService.XVx.Sessions).Get(player).Toggles.Fly` (bzw. `.NoClip`), um autorisierte Admins auszunehmen.
- **Performance:** Es gibt genau **eine** `Heartbeat`-Verbindung auf dem Server, die nur existiert, solange mindestens eine Auto-Funktion aktiv ist, und sie tickt alle 0,2 s. Auf dem Client laufen Fly/NoClip/Infinite Jump nur, solange sie eingeschaltet sind.
- **Ausschalten = beenden:** Beim Ausschalten werden Ziele, Verbindungen, ForceField, BodyMover/Constraints und Loot-Fenster vollständig zurückgesetzt.

---

## Code 1 – `Config` (ModuleScript in ReplicatedStorage/XVx)

```lua
--[[
	XVx Scripts – Config (geteilt, KEINE Geheimnisse!)
	Pfad: ReplicatedStorage > XVx > Config (ModuleScript)
]]

local Config = {}

Config.Name = "XVx Scripts"
Config.DiscordLink = "https://discord.gg/JvHTZvDPkT" -- hier änderbar
Config.ToggleUiKey = Enum.KeyCode.RightControl -- UI nach Freischaltung ein-/ausblenden

Config.Tags = {
	Npc = "XVxNpc",
	Boss = "XVxBoss",
	Drop = "XVxDrop",
	Collectible = "XVxCollectible",
}

Config.Folders = {
	Teleports = "XVxTeleports", -- in Workspace
	Drops = "XVxDrops", -- wird in Workspace automatisch erstellt
	Items = "XVxItems", -- in ServerStorage
}

-- Der Server begrenzt jeden Wert auf diese Bereiche
Config.Limits = {
	WalkSpeed = { Min = 16, Max = 120, Default = 16 },
	JumpPower = { Min = 50, Max = 200, Default = 50 },
	AttackRange = { Min = 3, Max = 30, Default = 8 },
	LootRadius = { Min = 5, Max = 80, Default = 25 },
}

Config.FlySpeed = 60
Config.TargetSearchRadius = 80 -- Suchradius für "Auto Target"

-- Alle erlaubten Toggles. "Auto" = Status Running/Stopped wird angezeigt.
Config.Features = {
	Fly = "Movement",
	NoClip = "Movement",
	InfiniteJump = "Movement",
	GodMode = "Player",

	AutoFarmXP = "Auto",
	AutoFarmCoins = "Auto",
	AutoFarmNpcs = "Auto",
	AutoCollect = "Auto",
	AutoLoot = "Auto",
	AutoQuest = "Auto",
	AutoQuestComplete = "Auto",

	AutoBoss = "Auto", -- Boss-Farm ON/OFF (Hauptschalter)
	BossSearch = "Option",
	BossFight = "Option",
	BossNext = "Option",
	BossLoot = "Option",

	AutoAttack = "Auto",
	AutoTarget = "Auto",
}

Config.Remotes = {
	Folder = "Remotes",
	KeySubmit = "KeySubmit",
	GetState = "GetState",
	SetToggle = "SetToggle",
	SetValue = "SetValue",
	DoAction = "DoAction",
	StateSync = "StateSync",
}

-- Farben für Elemente, die UIKit selbst erzeugt (an dein Design anpassen)
Config.Theme = {
	Background = Color3.fromRGB(22, 22, 30),
	Row = Color3.fromRGB(34, 34, 46),
	Accent = Color3.fromRGB(120, 90, 255),
	Text = Color3.fromRGB(235, 235, 245),
	SubText = Color3.fromRGB(150, 150, 170),
	On = Color3.fromRGB(70, 200, 120),
	Off = Color3.fromRGB(200, 70, 80),
	Font = Enum.Font.GothamMedium,
}

return Config
```

---

## Code 2 – `ServerConfig` (ModuleScript in ServerScriptService/XVx)

```lua
--[[
	XVx Scripts – ServerConfig (NUR SERVER!)
	Pfad: ServerScriptService > XVx > ServerConfig (ModuleScript)
	Clients können diesen Ordner nicht lesen. Der Key darf niemals in ReplicatedStorage
	oder in einem LocalScript stehen.
]]

local ServerConfig = {}

-- ===== Key-System =====
ServerConfig.Key = "Q7M2X9K4L8R5T6V1" -- hier änderbar (nur Buchstaben/Zahlen)
ServerConfig.MaxAttempts = 5 -- Fehlversuche bis zur Sperre
ServerConfig.LockSeconds = 60 -- Dauer der Sperre
ServerConfig.AllowedUserIds = {} -- leer = jeder mit Key; sonst z. B. { 123456789 }
ServerConfig.StudioOnly = false -- true = System nur in Roblox Studio nutzbar

-- ===== Kampf (nur eigene NPCs/Bosse) =====
ServerConfig.Combat = {
	Damage = 25, -- Schaden pro Treffer (bestimmt der Server, nie der Client)
	Cooldown = 0.4, -- Sekunden zwischen Treffern (Minimum effektiv 0.2)
}

-- ===== Rewards =====
ServerConfig.Rewards = {
	DefaultXP = 10, -- falls NPC kein Attribut "XP" hat
	DefaultCoins = 5, -- falls NPC kein Attribut "Coins" hat
	BossMultiplier = 5, -- Boss-Rewards = Attribut * BossMultiplier
	DropLifetime = 60, -- Sekunden, bis ein Drop verschwindet
	StatXP = "XP", -- Name des leaderstats-Werts
	StatCoins = "Coins",

	-- Test-Rewards (Tab "Rewards"), serverseitig begrenzt
	TestMaxXP = 10000,
	TestMaxCoins = 10000,
	TestMaxItems = 5,
	TestCooldown = 0.5,
	TestItems = { "Sword" }, -- erlaubte Tools aus ServerStorage/XVxItems
}

-- ===== Quests =====
-- Type: "Kill" (NPCs), "Boss" (Bosse), "Loot" (eingesammelte Drops/Collectibles)
-- AllowAutoComplete = true: "Auto Quest abschließen" darf diese Quest automatisch abgeben
ServerConfig.Quests = {
	{ Id = "kill10", Name = "Besiege 10 NPCs", Type = "Kill", Amount = 10, XP = 100, Coins = 50, AllowAutoComplete = true },
	{ Id = "loot15", Name = "Sammle 15 Drops", Type = "Loot", Amount = 15, XP = 75, Coins = 0, AllowAutoComplete = false },
	{ Id = "boss1", Name = "Besiege einen Boss", Type = "Boss", Amount = 1, XP = 500, Coins = 250, AllowAutoComplete = true },
}

-- ===== Optionale Hooks für dein eigenes Datensystem =====
-- Ohne Hook nutzt XVx leaderstats bzw. Humanoid:TakeDamage.
ServerConfig.Hooks = {
	-- GiveXP = function(player, amount) MeinSystem.AddXP(player, amount) end,
	-- GiveCoins = function(player, amount) MeinSystem.AddCoins(player, amount) end,
	-- GiveItem = function(player, itemName, amount) return MeinSystem.AddItem(player, itemName, amount) end, -- true/false
	-- DealDamage = function(player, npcModel, damage) MeinKampfSystem.Hit(player, npcModel, damage) end,
}

return ServerConfig
```

---

## Code 3 – `Sessions` (ModuleScript in ServerScriptService/XVx)

```lua
--[[
	XVx Scripts – Sessions
	Zustand pro freigeschaltetem Spieler (nur im Server-Speicher).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("XVx"):WaitForChild("Config"))

local Sessions = {}
local map = {}

function Sessions.Get(player)
	local s = map[player.UserId]
	if not s then
		local L = Config.Limits
		s = {
			Player = player,
			Toggles = {},
			Values = {
				WalkSpeed = L.WalkSpeed.Default,
				JumpPower = L.JumpPower.Default,
				AttackRange = L.AttackRange.Default,
				LootRadius = L.LootRadius.Default,
			},
			Touched = {}, -- Werte, die der Spieler wirklich verstellt hat
			SelectedBossId = "", -- "" = automatisch
			Target = nil, -- Auto Target
			FarmTarget = nil,
			BossTarget = nil,
			NextAttack = 0,
			LootUntil = 0,
			BossMsgUntil = 0,
			GodConn = nil,
			Info = { Target = "-", Boss = "-", Quest = "-" },
			LastInfo = "",
			NextInfoSend = 0,
		}
		map[player.UserId] = s
	end
	return s
end

function Sessions.Remove(player)
	map[player.UserId] = nil
end

function Sessions.All()
	return map
end

return Sessions
```

---

## Code 4 – `Auth` (ModuleScript in ServerScriptService/XVx)

```lua
--[[
	XVx Scripts – Auth
	Serverseitige Key-Prüfung mit Fehlversuch-Limit und Sperre.
]]

local RunService = game:GetService("RunService")
local ServerConfig = require(script.Parent.ServerConfig)

local Auth = {}
local records = {}

local function record(player)
	local r = records[player.UserId]
	if not r then
		r = { Authorized = false, Attempts = 0, LockedUntil = 0 }
		records[player.UserId] = r
	end
	return r
end

-- Vergleich ohne frühen Abbruch
local function safeEquals(a, b)
	if #a ~= #b then
		return false
	end
	local diff = 0
	for i = 1, #a do
		diff = bit32.bor(diff, bit32.bxor(string.byte(a, i), string.byte(b, i)))
	end
	return diff == 0
end

local function isAllowedUser(player)
	local list = ServerConfig.AllowedUserIds
	if #list == 0 then
		return true
	end
	return table.find(list, player.UserId) ~= nil
end

local function fail(r)
	r.Attempts += 1
	if r.Attempts >= ServerConfig.MaxAttempts then
		r.Attempts = 0
		r.LockedUntil = os.clock() + ServerConfig.LockSeconds
		return false, ("Zu viele Fehlversuche. Bitte %d Sekunden warten."):format(ServerConfig.LockSeconds)
	end
	return false, ("Falscher Key. Noch %d Versuche."):format(ServerConfig.MaxAttempts - r.Attempts)
end

function Auth.IsAuthorized(player)
	local r = records[player.UserId]
	return r ~= nil and r.Authorized == true
end

function Auth.Submit(player, input)
	if ServerConfig.StudioOnly and not RunService:IsStudio() then
		return false, "Nicht verfügbar."
	end
	if not isAllowedUser(player) then
		return false, "Kein Zugriff."
	end

	local r = record(player)
	if r.Authorized then
		return true, "Bereits freigeschaltet."
	end

	local now = os.clock()
	if now < r.LockedUntil then
		return false, ("Gesperrt. Bitte %d Sekunden warten."):format(math.ceil(r.LockedUntil - now))
	end

	-- Nur Buchstaben und Zahlen, begrenzte Länge
	if type(input) ~= "string" or #input == 0 or #input > 64 or input:find("[^%w]") then
		return fail(r)
	end

	if safeEquals(input, ServerConfig.Key) then
		r.Authorized = true
		r.Attempts = 0
		return true, "Key akzeptiert."
	end
	return fail(r)
end

function Auth.Remove(player)
	records[player.UserId] = nil
end

return Auth
```

---

## Code 5 – `Rewards` (ModuleScript in ServerScriptService/XVx)

```lua
--[[
	XVx Scripts – Rewards
	Alle XP/Coins/Items werden hier vergeben. Beträge kommen vom Server,
	der Client sendet höchstens eine (begrenzte) Test-Menge.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("XVx"):WaitForChild("Config"))
local ServerConfig = require(script.Parent.ServerConfig)

local R = ServerConfig.Rewards
local Hooks = ServerConfig.Hooks

local Rewards = {}
local lastTest = {}

local function getStat(player, name)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
	end
	local v = ls:FindFirstChild(name)
	if not v then
		v = Instance.new("IntValue")
		v.Name = name
		v.Parent = ls
	end
	return v
end

-- Gibt eine ganze Zahl >= 1 (maximal `max`) zurück oder nil bei ungültiger Eingabe
local function sanitize(amount, max)
	if type(amount) ~= "number" or amount ~= amount or amount == math.huge or amount == -math.huge then
		return nil
	end
	amount = math.floor(amount)
	if amount < 1 then
		return nil
	end
	return math.min(amount, max)
end

function Rewards.GiveXP(player, amount)
	amount = sanitize(amount, 1e9)
	if not amount then
		return false
	end
	if Hooks.GiveXP then
		Hooks.GiveXP(player, amount)
	else
		local stat = getStat(player, R.StatXP)
		stat.Value += amount
	end
	return true
end

function Rewards.GiveCoins(player, amount)
	amount = sanitize(amount, 1e9)
	if not amount then
		return false
	end
	if Hooks.GiveCoins then
		Hooks.GiveCoins(player, amount)
	else
		local stat = getStat(player, R.StatCoins)
		stat.Value += amount
	end
	return true
end

function Rewards.GiveItem(player, itemName, amount)
	amount = sanitize(amount, 100)
	if not amount or type(itemName) ~= "string" then
		return false
	end
	if Hooks.GiveItem then
		return Hooks.GiveItem(player, itemName, amount) == true
	end
	local folder = ServerStorage:FindFirstChild(Config.Folders.Items)
	local template = folder and folder:FindFirstChild(itemName)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not (template and template:IsA("Tool") and backpack) then
		return false
	end
	for _ = 1, amount do
		template:Clone().Parent = backpack
	end
	return true
end

-- Für Drops/Collectibles (Werte stammen aus Attributen im Workspace, gesetzt vom Server/Entwickler)
function Rewards.GrantPickup(player, kind, amount, itemName)
	if kind == "Coins" then
		return Rewards.GiveCoins(player, amount)
	elseif kind == "XP" then
		return Rewards.GiveXP(player, amount)
	elseif kind == "Item" then
		return Rewards.GiveItem(player, itemName, amount or 1)
	end
	return false
end

-- Test-Rewards aus dem Rewards-Tab: erlaubte Items, Höchstmengen, Cooldown
function Rewards.GiveTest(player, kind, amount, itemName)
	local now = os.clock()
	if now - (lastTest[player.UserId] or 0) < R.TestCooldown then
		return false, "Bitte kurz warten."
	end
	lastTest[player.UserId] = now

	if kind == "XP" then
		local a = sanitize(amount, R.TestMaxXP)
		if not a then
			return false, "Ungültige Menge."
		end
		Rewards.GiveXP(player, a)
		return true, ("+%d Test-XP"):format(a)
	elseif kind == "Coins" then
		local a = sanitize(amount, R.TestMaxCoins)
		if not a then
			return false, "Ungültige Menge."
		end
		Rewards.GiveCoins(player, a)
		return true, ("+%d Test-Coins"):format(a)
	elseif kind == "Item" then
		if type(itemName) ~= "string" or not table.find(R.TestItems, itemName) then
			return false, "Item nicht erlaubt."
		end
		local a = sanitize(amount, R.TestMaxItems)
		if not a then
			return false, "Ungültige Menge."
		end
		if Rewards.GiveItem(player, itemName, a) then
			return true, ("%dx %s erhalten"):format(a, itemName)
		end
		return false, "Item nicht gefunden (ServerStorage/XVxItems)."
	end
	return false, "Unbekannte Art."
end

function Rewards.Remove(player)
	lastTest[player.UserId] = nil
end

return Rewards
```

---

## Code 6 – `Quests` (ModuleScript in ServerScriptService/XVx)

```lua
--[[
	XVx Scripts – Quests
	Mini-Questsystem. Fortschritt wird ausschließlich vom Server gezählt
	(Kills, Boss-Kills, eingesammelte Drops). Ersetze es bei Bedarf durch dein eigenes System.
]]

local ServerConfig = require(script.Parent.ServerConfig)
local Rewards = require(script.Parent.Rewards)

local Quests = {}
local state = {}

local function get(player)
	local s = state[player.UserId]
	if not s then
		s = { Active = nil, Progress = 0, Done = {} }
		state[player.UserId] = s
	end
	return s
end

local function def(id)
	for _, q in ServerConfig.Quests do
		if q.Id == id then
			return q
		end
	end
	return nil
end

function Quests.NextAvailable(player)
	local s = get(player)
	for _, q in ServerConfig.Quests do
		if not s.Done[q.Id] then
			return q
		end
	end
	return nil
end

-- Nimmt die nächste offene Quest an
function Quests.Accept(player)
	local s = get(player)
	if s.Active then
		return false, "Es läuft bereits eine Quest."
	end
	local q = Quests.NextAvailable(player)
	if not q then
		return false, "Keine Quests mehr offen."
	end
	s.Active = q.Id
	s.Progress = 0
	return true, "Quest angenommen: " .. q.Name
end

-- Nur vom Server aufrufen (Targets/Automation)
function Quests.Report(player, questType, amount)
	local s = get(player)
	local q = s.Active and def(s.Active)
	if q and q.Type == questType then
		s.Progress = math.min(q.Amount, s.Progress + (amount or 1))
	end
end

function Quests.IsReady(player)
	local s = get(player)
	local q = s.Active and def(s.Active)
	return q ~= nil and s.Progress >= q.Amount
end

-- auto = true: nur Quests mit AllowAutoComplete
function Quests.Complete(player, auto)
	local s = get(player)
	local q = s.Active and def(s.Active)
	if not q then
		return false, "Keine aktive Quest."
	end
	if s.Progress < q.Amount then
		return false, "Quest noch nicht erfüllt."
	end
	if auto and not q.AllowAutoComplete then
		return false, "Diese Quest muss manuell abgeschlossen werden."
	end
	if q.XP and q.XP > 0 then
		Rewards.GiveXP(player, q.XP)
	end
	if q.Coins and q.Coins > 0 then
		Rewards.GiveCoins(player, q.Coins)
	end
	s.Done[q.Id] = true
	s.Active = nil
	s.Progress = 0
	return true, "Quest abgeschlossen: " .. q.Name
end

function Quests.Describe(player)
	local s = get(player)
	local q = s.Active and def(s.Active)
	if not q then
		return Quests.NextAvailable(player) and "Keine aktive Quest" or "Alle Quests erledigt"
	end
	if s.Progress >= q.Amount then
		return q.Name .. " – bereit zum Abschluss"
	end
	return ("%s (%d/%d)"):format(q.Name, s.Progress, q.Amount)
end

function Quests.Remove(player)
	state[player.UserId] = nil
end

return Quests
```

---

## Code 7 – `Targets` (ModuleScript in ServerScriptService/XVx)

```lua
--[[
	XVx Scripts – Targets
	Verwaltet NUR registrierte NPCs/Bosse (CollectionService-Tags), Schaden, Tod-Erkennung,
	Rewards, Drops und das Einsammeln. Fremde Modelle/Spieler sind nie gültige Ziele.
]]

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("XVx"):WaitForChild("Config"))
local ServerConfig = require(script.Parent.ServerConfig)
local Rewards = require(script.Parent.Rewards)
local Quests = require(script.Parent.Quests)

local R = ServerConfig.Rewards
local Hooks = ServerConfig.Hooks

local Targets = {}

local weak = { __mode = "k" }
local hooked = setmetatable({}, weak) -- Modelle, deren Tod bereits überwacht wird
local rewarded = setmetatable({}, weak) -- Modelle, deren Rewards schon vergeben wurden
local lastAttacker = setmetatable({}, weak) -- [Modell] = UserId
local defeatedCallbacks = {}

local function num(value, default)
	if type(value) == "number" then
		return value
	end
	return default
end

-- ===== Grundfunktionen =====

function Targets.RootOf(model)
	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

function Targets.IsBoss(model)
	return CollectionService:HasTag(model, Config.Tags.Boss)
end

function Targets.NpcTypeOf(model)
	return tostring(model:GetAttribute("NpcType") or model.Name)
end

function Targets.BossIdOf(model)
	return tostring(model:GetAttribute("BossId") or model.Name)
end

function Targets.DisplayName(model)
	return tostring(model:GetAttribute("DisplayName") or model.Name)
end

-- Gültig = registriert, im Workspace, Humanoid lebt, Root vorhanden
function Targets.IsValid(model)
	if typeof(model) ~= "Instance" or not model:IsA("Model") or not model:IsDescendantOf(workspace) then
		return false
	end
	if not (CollectionService:HasTag(model, Config.Tags.Npc) or CollectionService:HasTag(model, Config.Tags.Boss)) then
		return false
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0 and Targets.RootOf(model) ~= nil
end

-- Halbe Modellbreite, damit große Bosse fair in Reichweite kommen
function Targets.Extent(model)
	local _, size = model:GetBoundingBox()
	return math.max(size.X, size.Z) / 2
end

function Targets.List(tag)
	local out = {}
	for _, inst in CollectionService:GetTagged(tag) do
		if Targets.IsValid(inst) then
			table.insert(out, inst)
		end
	end
	return out
end

function Targets.Nearest(tags, position, maxDist)
	local best, bestDist = nil, maxDist or math.huge
	for _, tag in tags do
		for _, model in CollectionService:GetTagged(tag) do
			if Targets.IsValid(model) then
				local d = (Targets.RootOf(model).Position - position).Magnitude
				if d < bestDist then
					best, bestDist = model, d
				end
			end
		end
	end
	return best
end

function Targets.NearestNpcOfType(typeName, position)
	local best, bestDist = nil, math.huge
	for _, model in Targets.List(Config.Tags.Npc) do
		if Targets.NpcTypeOf(model) == typeName then
			local d = (Targets.RootOf(model).Position - position).Magnitude
			if d < bestDist then
				best, bestDist = model, d
			end
		end
	end
	return best
end

-- ===== Listen für die UI =====

function Targets.NpcTypes()
	local seen, out = {}, {}
	for _, m in CollectionService:GetTagged(Config.Tags.Npc) do
		if m:IsA("Model") and m:IsDescendantOf(workspace) then
			local t = Targets.NpcTypeOf(m)
			if not seen[t] then
				seen[t] = true
				table.insert(out, t)
			end
		end
	end
	table.sort(out)
	return out
end

function Targets.BossEntries()
	local seen, out = {}, {}
	for _, m in CollectionService:GetTagged(Config.Tags.Boss) do
		if m:IsA("Model") and m:IsDescendantOf(workspace) then
			local id = Targets.BossIdOf(m)
			if not seen[id] then
				seen[id] = true
				table.insert(out, { Id = id, Name = Targets.DisplayName(m) })
			end
		end
	end
	table.sort(out, function(a, b)
		return a.Id < b.Id
	end)
	return out
end

function Targets.HasBossId(id)
	for _, m in CollectionService:GetTagged(Config.Tags.Boss) do
		if m:IsA("Model") and m:IsDescendantOf(workspace) and Targets.BossIdOf(m) == id then
			return true
		end
	end
	return false
end

-- Lebenden Boss mit dieser BossId finden
function Targets.FindBoss(id)
	for _, m in Targets.List(Config.Tags.Boss) do
		if Targets.BossIdOf(m) == id then
			return m
		end
	end
	return nil
end

-- Nächster verfügbarer (lebender) Boss nach currentId; nil, wenn kein anderer lebt
function Targets.NextBossId(currentId)
	local seen, ids = {}, {}
	for _, m in Targets.List(Config.Tags.Boss) do
		local id = Targets.BossIdOf(m)
		if id ~= currentId and not seen[id] then
			seen[id] = true
			table.insert(ids, id)
		end
	end
	if #ids == 0 then
		return nil
	end
	table.sort(ids)
	for _, id in ids do
		if id > currentId then
			return id
		end
	end
	return ids[1]
end

-- ===== Schaden =====

function Targets.Damage(player, model, amount)
	if not Targets.IsValid(model) then
		return
	end
	lastAttacker[model] = player.UserId
	if Hooks.DealDamage then
		Hooks.DealDamage(player, model, amount)
		return
	end
	model:FindFirstChildOfClass("Humanoid"):TakeDamage(amount)
end

-- ===== Drops =====

local function dropFolder()
	local f = workspace:FindFirstChild(Config.Folders.Drops)
	if not f then
		f = Instance.new("Folder")
		f.Name = Config.Folders.Drops
		f.Parent = workspace
	end
	return f
end

local function makeDrop(position, kind, amount, itemName, ownerId)
	local part = Instance.new("Part")
	part.Name = "XVxDrop_" .. kind
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * 1.5
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = kind == "Coins" and Color3.fromRGB(255, 205, 50) or Color3.fromRGB(90, 200, 255)
	part.Position = position + Vector3.new(math.random(-3, 3), 1.5, math.random(-3, 3))
	part:SetAttribute("Kind", kind)
	part:SetAttribute("Amount", amount)
	part:SetAttribute("ItemName", itemName or "")
	part:SetAttribute("OwnerUserId", ownerId or 0)
	CollectionService:AddTag(part, Config.Tags.Drop)
	part.Parent = dropFolder()
	Debris:AddItem(part, R.DropLifetime)
end

local function spawnDrops(model, position, killer)
	local coins = num(model:GetAttribute("DropCoins"), 0)
	if coins > 0 then
		makeDrop(position, "Coins", coins, nil, killer.UserId)
	end
	local item = model:GetAttribute("DropItem")
	if type(item) == "string" and item ~= "" and math.random() <= num(model:GetAttribute("DropChance"), 1) then
		makeDrop(position, "Item", 1, item, killer.UserId)
	end
end

-- Sammelt Drops/Collectibles im Radius (serverseitige Distanzprüfung, Besitzer-Prüfung, max. 10 pro Aufruf)
function Targets.Collect(player, tag, center, radius)
	local count = 0
	for _, part in CollectionService:GetTagged(tag) do
		if count >= 10 then
			break
		end
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			local owner = num(part:GetAttribute("OwnerUserId"), 0)
			if (owner == 0 or owner == player.UserId) and (part.Position - center).Magnitude <= radius then
				local ok = Rewards.GrantPickup(
					player,
					part:GetAttribute("Kind"),
					part:GetAttribute("Amount"),
					part:GetAttribute("ItemName")
				)
				if ok then
					part:Destroy()
					count += 1
					Quests.Report(player, "Loot", 1)
				end
			end
		end
	end
	return count
end

-- ===== Tod / Rewards =====

function Targets.OnDefeated(callback)
	table.insert(defeatedCallbacks, callback)
end

local function onDied(model)
	if rewarded[model] then
		return
	end
	rewarded[model] = true

	local isBoss = Targets.IsBoss(model)
	local root = Targets.RootOf(model)
	local position = root and root.Position or Vector3.zero
	local killer = Players:GetPlayerByUserId(lastAttacker[model] or 0)

	-- Rewards nur, wenn ein XVx-Angriff den letzten Schaden gemacht hat
	if killer then
		local mult = isBoss and R.BossMultiplier or 1
		Rewards.GiveXP(killer, num(model:GetAttribute("XP"), R.DefaultXP) * mult)
		Rewards.GiveCoins(killer, num(model:GetAttribute("Coins"), R.DefaultCoins) * mult)
		Quests.Report(killer, "Kill", 1)
		if isBoss then
			Quests.Report(killer, "Boss", 1)
		end
		spawnDrops(model, position, killer)
	end

	for _, callback in defeatedCallbacks do
		task.spawn(callback, model, killer, isBoss, position)
	end
end

local function setup(model)
	if not model:IsA("Model") or hooked[model] then
		return
	end
	hooked[model] = true
	task.spawn(function()
		local hum = model:WaitForChild("Humanoid", 10)
		if not hum then
			warn("[XVx Scripts] Kein Humanoid in registriertem Modell: " .. model:GetFullName())
			return
		end
		hum.Died:Once(function()
			onDied(model)
		end)
	end)
end

function Targets.Init()
	for _, tag in { Config.Tags.Npc, Config.Tags.Boss } do
		CollectionService:GetInstanceAddedSignal(tag):Connect(setup)
		for _, inst in CollectionService:GetTagged(tag) do
			setup(inst)
		end
	end
end

return Targets
```

---

## Code 8 – `PlayerTools` (ModuleScript in ServerScriptService/XVx)

```lua
--[[
	XVx Scripts – PlayerTools
	Serverseitig: Speed, JumpPower, Heal, God Mode, Teleports.
	Alle Werte werden auf Config.Limits begrenzt, Teleport-Ziele nur aus deinen Ordnern.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("XVx"):WaitForChild("Config"))
local Sessions = require(script.Parent.Sessions)
local Targets = require(script.Parent.Targets)

local PlayerTools = {}

local function humanoidOf(player)
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

function PlayerTools.RootPosition(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position
end

-- ===== God Mode =====

function PlayerTools.ApplyGod(player)
	local s = Sessions.Get(player)
	if s.GodConn then
		s.GodConn:Disconnect()
		s.GodConn = nil
	end
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local ff = char:FindFirstChild("XVxGod")

	if s.Toggles.GodMode then
		if not ff then
			ff = Instance.new("ForceField")
			ff.Name = "XVxGod"
			ff.Visible = false
			ff.Parent = char
		end
		if hum then
			hum.Health = hum.MaxHealth
			s.GodConn = hum.HealthChanged:Connect(function(health)
				if s.Toggles.GodMode and health > 0 and health < hum.MaxHealth then
					hum.Health = hum.MaxHealth
				end
			end)
		end
	elseif ff then
		ff:Destroy()
	end
end

-- Nach Freischaltung / Respawn: geänderte Werte und God Mode erneut anwenden
function PlayerTools.ApplyAll(player)
	local s = Sessions.Get(player)
	local hum = humanoidOf(player)
	if not hum then
		return
	end
	if s.Touched.WalkSpeed then
		hum.WalkSpeed = s.Values.WalkSpeed
	end
	if s.Touched.JumpPower then
		hum.UseJumpPower = true
		hum.JumpPower = s.Values.JumpPower
	end
	PlayerTools.ApplyGod(player)
end

-- ===== Werte =====

function PlayerTools.SetValue(player, name, value)
	local limit = Config.Limits[name]
	if type(name) ~= "string" or not limit or type(value) ~= "number" or value ~= value then
		return false, "Ungültiger Wert."
	end
	value = math.clamp(math.floor(value + 0.5), limit.Min, limit.Max)
	local s = Sessions.Get(player)
	s.Values[name] = value
	s.Touched[name] = true
	if name == "WalkSpeed" or name == "JumpPower" then
		PlayerTools.ApplyAll(player)
	end
	return true, value
end

function PlayerTools.Heal(player)
	local hum = humanoidOf(player)
	if not hum or hum.Health <= 0 then
		return false, "Kein lebender Charakter."
	end
	hum.Health = hum.MaxHealth
	return true, "Geheilt."
end

-- ===== Teleports =====

local function teleportChild(name)
	local root = workspace:FindFirstChild(Config.Folders.Teleports)
	return root and root:FindFirstChild(name)
end

function PlayerTools.ListTeleports(folderName)
	local folder = teleportChild(folderName)
	local names = {}
	if folder then
		for _, part in folder:GetChildren() do
			if part:IsA("BasePart") then
				table.insert(names, part.Name)
			end
		end
	end
	table.sort(names)
	return names
end

function PlayerTools.TeleportToCFrame(player, cf)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end
	char:PivotTo(cf + Vector3.new(0, 4, 0))
	hrp.AssemblyLinearVelocity = Vector3.zero
	return true
end

-- folderName: "TestPositions" oder "BossArenas"
function PlayerTools.TeleportPreset(player, folderName, name)
	if type(name) ~= "string" then
		return false, "Ungültiges Ziel."
	end
	local folder = teleportChild(folderName)
	local part = folder and folder:FindFirstChild(name)
	if not (part and part:IsA("BasePart")) then
		return false, "Position nicht gefunden."
	end
	if PlayerTools.TeleportToCFrame(player, part.CFrame) then
		return true, "Teleportiert: " .. name
	end
	return false, "Kein Charakter."
end

function PlayerTools.TeleportSpawn(player)
	local part = teleportChild("Spawn")
	if not (part and part:IsA("BasePart")) then
		part = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	end
	if not part then
		return false, "Kein Spawn gefunden."
	end
	if PlayerTools.TeleportToCFrame(player, part.CFrame) then
		return true, "Zurück am Spawn."
	end
	return false, "Kein Charakter."
end

function PlayerTools.TeleportToModel(player, model)
	if not Targets.IsValid(model) then
		return false, "Ziel nicht verfügbar."
	end
	local root = Targets.RootOf(model)
	if PlayerTools.TeleportToCFrame(player, root.CFrame * CFrame.new(0, 0, 8)) then
		return true, "Teleportiert zu " .. Targets.DisplayName(model)
	end
	return false, "Kein Charakter."
end

function PlayerTools.TeleportToNpcType(player, typeName)
	if type(typeName) ~= "string" then
		return false, "Ungültiges Ziel."
	end
	local pos = PlayerTools.RootPosition(player)
	if not pos then
		return false, "Kein Charakter."
	end
	return PlayerTools.TeleportToModel(player, Targets.NearestNpcOfType(typeName, pos))
end

return PlayerTools
```

---

## Code 9 – `Automation` (ModuleScript in ServerScriptService/XVx)

```lua
--[[
	XVx Scripts – Automation
	Auto Farm, Auto Boss, Auto Attack, Auto Target, Auto Loot/Collect, Auto Quest.
	Es gibt EINE Heartbeat-Verbindung für alle Spieler. Sie existiert nur, solange
	mindestens eine Auto-Funktion aktiv ist, und tickt alle 0,2 s.
	Ziele sind ausschließlich registrierte NPCs/Bosse (siehe Targets).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local XVx = script.Parent
local Config = require(ReplicatedStorage:WaitForChild("XVx"):WaitForChild("Config"))
local ServerConfig = require(XVx.ServerConfig)
local Sessions = require(XVx.Sessions)
local Targets = require(XVx.Targets)
local Quests = require(XVx.Quests)
local PlayerTools = require(XVx.PlayerTools)

local Automation = {}

-- Toggles, die den Scheduler wirklich brauchen
local DRIVERS = {
	"AutoFarmXP", "AutoFarmCoins", "AutoFarmNpcs", "AutoCollect", "AutoLoot",
	"AutoQuest", "AutoQuestComplete", "AutoBoss", "AutoAttack", "AutoTarget",
}

local TICK = 0.2
local ALL_TAGS = { Config.Tags.Npc, Config.Tags.Boss }

local connection = nil
local accumulator = 0
local send = function() end -- wird von XVxServer gesetzt (RemoteEvent zum Client)

local function num(value, default)
	if type(value) == "number" then
		return value
	end
	return default
end

local function hasDriver(s)
	for _, name in DRIVERS do
		if s.Toggles[name] then
			return true
		end
	end
	return false
end

local function anyDriverEnabled()
	for _, s in Sessions.All() do
		if hasDriver(s) then
			return true
		end
	end
	return false
end

-- ===== Status-Infos an den Client (gedrosselt, nur bei Änderung) =====

local function pushInfo(player, s, now, force)
	local info = s.Info
	local text = info.Target .. "|" .. info.Boss .. "|" .. info.Quest
	if text == s.LastInfo then
		return
	end
	if not force and now < s.NextInfoSend then
		return
	end
	s.LastInfo = text
	s.NextInfoSend = now + 0.5
	send(player, { Type = "Info", Info = table.clone(info) })
end

function Automation.PushInfo(player)
	local s = Sessions.Get(player)
	s.Info.Quest = Quests.Describe(player)
	pushInfo(player, s, os.clock(), true)
end

function Automation.Bind(sendFunction)
	send = sendFunction
end

-- ===== Zielwahl =====

local function pickBoss(s, hrp, T)
	if Targets.IsValid(s.BossTarget) then
		return s.BossTarget
	end
	local boss = nil
	if s.SelectedBossId ~= "" then
		boss = Targets.FindBoss(s.SelectedBossId)
	end
	-- "Boss automatisch suchen" (oder Auswahl = Automatisch): nächster lebender Boss
	if not boss and (T.BossSearch or s.SelectedBossId == "") then
		boss = Targets.Nearest({ Config.Tags.Boss }, hrp.Position, math.huge)
	end
	s.BossTarget = boss
	return boss
end

local function pickFarmTarget(s, hrp, T)
	if Targets.IsValid(s.FarmTarget) then
		return s.FarmTarget
	end
	local R = ServerConfig.Rewards
	local best, bestValue, bestDist = nil, -math.huge, math.huge
	for _, npc in Targets.List(Config.Tags.Npc) do
		local value = 0
		if T.AutoFarmXP then
			value = num(npc:GetAttribute("XP"), R.DefaultXP)
		elseif T.AutoFarmCoins then
			value = num(npc:GetAttribute("Coins"), R.DefaultCoins)
		end
		local dist = (Targets.RootOf(npc).Position - hrp.Position).Magnitude
		if value > bestValue or (value == bestValue and dist < bestDist) then
			best, bestValue, bestDist = npc, value, dist
		end
	end
	s.FarmTarget = best
	return best
end

-- Stellt den Spieler in sinnvoller Distanz vor das Ziel
local function approach(char, hrp, troot, reach)
	local offset = hrp.Position - troot.Position
	local flat = Vector3.new(offset.X, 0, offset.Z)
	local dir = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0, 0, 1)
	local standOff = math.clamp(reach * 0.6, 2, 12)
	local pos = troot.Position + dir * standOff
	char:PivotTo(CFrame.lookAt(pos, Vector3.new(troot.Position.X, pos.Y, troot.Position.Z)))
	hrp.AssemblyLinearVelocity = Vector3.zero
end

-- ===== Ein Tick pro Spieler =====

local function tickPlayer(player, s, now)
	local T = s.Toggles
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp and hum.Health > 0) then
		return
	end

	local info = s.Info
	local range = s.Values.AttackRange -- bereits serverseitig begrenzt

	-- Quests
	if T.AutoQuest then
		Quests.Accept(player)
	end
	if T.AutoQuestComplete and Quests.IsReady(player) then
		Quests.Complete(player, true) -- nur Quests mit AllowAutoComplete
	end
	info.Quest = Quests.Describe(player)

	-- Ziel bestimmen: Boss > Farm > Auto Target > nächstes Ziel in Reichweite
	local target, moving, attack = nil, false, T.AutoAttack == true

	if T.AutoBoss then
		local boss = pickBoss(s, hrp, T)
		if boss then
			target, moving = boss, true
			attack = attack or T.BossFight == true
			if now >= s.BossMsgUntil then
				info.Boss = (T.BossFight and "Kampf: " or "Ziel: ") .. Targets.DisplayName(boss)
			end
		elseif now >= s.BossMsgUntil then
			info.Boss = "Suche Boss ..."
		end
	end

	if not target and (T.AutoFarmXP or T.AutoFarmCoins or T.AutoFarmNpcs) then
		target = pickFarmTarget(s, hrp, T)
		if target then
			moving, attack = true, true
		end
	end

	if not target then
		if T.AutoTarget then
			-- nach dem Besiegen wird automatisch das nächste gültige Ziel gewählt
			if not Targets.IsValid(s.Target) then
				s.Target = Targets.Nearest(ALL_TAGS, hrp.Position, Config.TargetSearchRadius)
			end
			target = s.Target
		elseif T.AutoAttack then
			target = Targets.Nearest(ALL_TAGS, hrp.Position, range + 15)
		end
	end

	info.Target = target and Targets.DisplayName(target) or "-"

	-- Hinlaufen + Angreifen (Reichweite und Cooldown prüft der Server)
	if target then
		local troot = Targets.RootOf(target)
		local reach = range + Targets.Extent(target)
		local dist = (hrp.Position - troot.Position).Magnitude
		if moving and dist > reach * 0.9 then
			approach(char, hrp, troot, reach)
			dist = (hrp.Position - troot.Position).Magnitude
		end
		if attack and dist <= reach + 1 and now >= s.NextAttack then
			s.NextAttack = now + ServerConfig.Combat.Cooldown
			Targets.Damage(player, target, ServerConfig.Combat.Damage)
		end
	end

	-- Loot / Collect (Loot-Fenster bleibt nach einem Boss-Kill kurz offen)
	local radius = s.Values.LootRadius
	if T.AutoLoot or now < s.LootUntil then
		Targets.Collect(player, Config.Tags.Drop, hrp.Position, radius)
	end
	if T.AutoCollect then
		Targets.Collect(player, Config.Tags.Collectible, hrp.Position, radius)
	end

	pushInfo(player, s, now, false)
end

-- ===== Scheduler =====

local function step(dt)
	accumulator += dt
	if accumulator < TICK then
		return
	end
	accumulator = 0
	local now = os.clock()
	for _, s in Sessions.All() do
		if s.Player.Parent and hasDriver(s) then
			local ok, err = pcall(tickPlayer, s.Player, s, now)
			if not ok then
				warn("[XVx Scripts] Automation-Fehler: " .. tostring(err))
			end
		end
	end
end

-- Startet/stoppt die Heartbeat-Verbindung je nach Bedarf
function Automation.Refresh()
	local needed = anyDriverEnabled()
	if needed and not connection then
		accumulator = 0
		connection = RunService.Heartbeat:Connect(step)
	elseif not needed and connection then
		connection:Disconnect()
		connection = nil
	end
end

-- Wird nach jedem Toggle aufgerufen: beim Ausschalten wird alles zurückgesetzt
function Automation.OnToggle(player, feature, state)
	local s = Sessions.Get(player)
	local T = s.Toggles
	if not state then
		if feature == "AutoBoss" then
			s.BossTarget = nil
			s.LootUntil = 0
			s.Info.Boss = "-"
		elseif feature == "AutoTarget" then
			s.Target = nil
		elseif feature == "AutoFarmXP" or feature == "AutoFarmCoins" or feature == "AutoFarmNpcs" then
			s.FarmTarget = nil
		end
		if not (T.AutoBoss or T.AutoFarmXP or T.AutoFarmCoins or T.AutoFarmNpcs or T.AutoTarget or T.AutoAttack) then
			s.Info.Target = "-"
		end
	end
	Automation.Refresh()
	Automation.PushInfo(player)
end

-- ===== Boss besiegt: automatisch erkennen, looten, nächsten Boss wählen =====

function Automation.Init()
	Targets.OnDefeated(function(model, _killer, isBoss, position)
		if not isBoss then
			return -- normale NPCs: ungültige Ziele werden beim nächsten Tick automatisch ersetzt
		end
		local name = Targets.DisplayName(model)
		for _, s in Sessions.All() do
			if s.BossTarget == model then
				s.BossTarget = nil
				s.Info.Boss = "Besiegt: " .. name
				s.BossMsgUntil = os.clock() + 4
				send(s.Player, { Type = "Toast", Text = "Boss besiegt: " .. name })

				if s.Toggles.AutoBoss then
					if s.Toggles.BossLoot then
						PlayerTools.TeleportToCFrame(s.Player, CFrame.new(position))
						s.LootUntil = os.clock() + 4
					end
					if s.Toggles.BossNext then
						local nextId = Targets.NextBossId(Targets.BossIdOf(model))
						if nextId then
							s.SelectedBossId = nextId
							send(s.Player, { Type = "SelectedBoss", Id = nextId })
						end
					end
				end
			end
		end
	end)
end

return Automation
```

---

## Code 10 – `XVxServer` (**Script** in ServerScriptService/XVx)

```lua
--[[
	XVx Scripts – XVxServer (Script, kein ModuleScript!)
	Pfad: ServerScriptService > XVx > XVxServer
	Erstellt die Remotes, prüft JEDE Client-Anfrage und verteilt sie an die Module.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local XVx = script.Parent
local SharedFolder = ReplicatedStorage:WaitForChild("XVx")
local Config = require(SharedFolder:WaitForChild("Config"))
local ServerConfig = require(XVx.ServerConfig)
local Sessions = require(XVx.Sessions)
local Auth = require(XVx.Auth)
local Rewards = require(XVx.Rewards)
local Quests = require(XVx.Quests)
local Targets = require(XVx.Targets)
local PlayerTools = require(XVx.PlayerTools)
local Automation = require(XVx.Automation)

-- ===== Remotes anlegen =====

local remotesFolder = SharedFolder:FindFirstChild(Config.Remotes.Folder)
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = Config.Remotes.Folder
	remotesFolder.Parent = SharedFolder
end

local function remote(className, name)
	local r = remotesFolder:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = remotesFolder
	end
	return r
end

local KeySubmit = remote("RemoteFunction", Config.Remotes.KeySubmit)
local GetState = remote("RemoteFunction", Config.Remotes.GetState)
local SetToggle = remote("RemoteFunction", Config.Remotes.SetToggle)
local SetValue = remote("RemoteFunction", Config.Remotes.SetValue)
local DoAction = remote("RemoteFunction", Config.Remotes.DoAction)
local StateSync = remote("RemoteEvent", Config.Remotes.StateSync)

-- ===== Rate-Limit (Token-Bucket: 20 Anfragen Burst, 15/s) =====

local buckets = {}

local function allow(player)
	local now = os.clock()
	local b = buckets[player.UserId]
	if not b then
		b = { tokens = 20, last = now }
		buckets[player.UserId] = b
	end
	b.tokens = math.min(20, b.tokens + (now - b.last) * 15)
	b.last = now
	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end

-- Jede Anfrage: Rate-Limit + pcall (ein Fehler darf den Server nie stören)
local function guarded(fn)
	return function(player, ...)
		if not allow(player) then
			return false, "Zu viele Anfragen."
		end
		local ok, a, b = pcall(fn, player, ...)
		if not ok then
			warn("[XVx Scripts] Fehler in Remote-Handler: " .. tostring(a))
			return false, "Serverfehler."
		end
		return a, b
	end
end

-- Zusätzlich: nur freigeschaltete Spieler
local function requireAuth(fn)
	return guarded(function(player, ...)
		if not Auth.IsAuthorized(player) then
			return false, "Nicht freigeschaltet."
		end
		return fn(player, ...)
	end)
end

Automation.Bind(function(player, payload)
	StateSync:FireClient(player, payload)
end)

-- ===== Key =====

KeySubmit.OnServerInvoke = guarded(function(player, input)
	if input == nil then
		return Auth.IsAuthorized(player), "" -- nur Statusabfrage (zählt nicht als Versuch)
	end
	local ok, message = Auth.Submit(player, input)
	if ok then
		Sessions.Get(player)
		PlayerTools.ApplyAll(player)
	end
	return ok, message
end)

-- ===== Zustand + Listen für die UI =====

GetState.OnServerInvoke = requireAuth(function(player)
	local s = Sessions.Get(player)
	Automation.PushInfo(player)
	return {
		Toggles = table.clone(s.Toggles),
		Values = table.clone(s.Values),
		SelectedBoss = s.SelectedBossId,
		Lists = {
			TestPositions = PlayerTools.ListTeleports("TestPositions"),
			BossArenas = PlayerTools.ListTeleports("BossArenas"),
			NpcTypes = Targets.NpcTypes(),
			Bosses = Targets.BossEntries(),
			Items = table.clone(ServerConfig.Rewards.TestItems),
		},
	}
end)

-- ===== Toggles =====

SetToggle.OnServerInvoke = requireAuth(function(player, feature, state)
	if type(feature) ~= "string" or type(state) ~= "boolean" or Config.Features[feature] == nil then
		return false, "Ungültige Anfrage."
	end
	local s = Sessions.Get(player)
	s.Toggles[feature] = state

	if feature == "GodMode" then
		PlayerTools.ApplyGod(player)
	end
	-- Fly/NoClip/InfiniteJump: Server gibt frei, der Client führt die Bewegung aus
	Automation.OnToggle(player, feature, state)
	return true, state
end)

-- ===== Werte (Speed, JumpPower, Attack Range, Loot-Radius) =====

SetValue.OnServerInvoke = requireAuth(function(player, name, value)
	return PlayerTools.SetValue(player, name, value)
end)

-- ===== Aktionen =====

local Actions = {}

Actions.Heal = function(player)
	return PlayerTools.Heal(player)
end

Actions.Teleport = function(player, payload)
	if type(payload) ~= "table" then
		return false, "Ungültige Anfrage."
	end
	local kind, id = payload.Kind, payload.Id
	if kind == "Test" then
		return PlayerTools.TeleportPreset(player, "TestPositions", id)
	elseif kind == "BossArena" then
		return PlayerTools.TeleportPreset(player, "BossArenas", id)
	elseif kind == "Npc" then
		return PlayerTools.TeleportToNpcType(player, id)
	elseif kind == "Spawn" then
		return PlayerTools.TeleportSpawn(player)
	end
	return false, "Unbekanntes Teleport-Ziel."
end

Actions.TeleportBoss = function(player, bossId)
	if type(bossId) ~= "string" then
		return false, "Ungültige Anfrage."
	end
	local boss
	if bossId == "" then
		local pos = PlayerTools.RootPosition(player)
		boss = pos and Targets.Nearest({ Config.Tags.Boss }, pos, math.huge)
	else
		boss = Targets.FindBoss(bossId)
	end
	return PlayerTools.TeleportToModel(player, boss)
end

Actions.SelectBoss = function(player, id)
	if type(id) ~= "string" then
		return false, "Ungültige Anfrage."
	end
	if id ~= "" and not Targets.HasBossId(id) then
		return false, "Boss nicht registriert."
	end
	local s = Sessions.Get(player)
	s.SelectedBossId = id
	s.BossTarget = nil
	return true, id == "" and "Automatische Boss-Wahl" or ("Boss gewählt: " .. id)
end

Actions.QuestAccept = function(player)
	local ok, message = Quests.Accept(player)
	Automation.PushInfo(player)
	return ok, message
end

Actions.QuestComplete = function(player)
	local ok, message = Quests.Complete(player, false)
	Automation.PushInfo(player)
	return ok, message
end

Actions.GiveTest = function(player, payload)
	if type(payload) ~= "table" then
		return false, "Ungültige Anfrage."
	end
	return Rewards.GiveTest(player, payload.Kind, payload.Amount, payload.Item)
end

DoAction.OnServerInvoke = requireAuth(function(player, action, payload)
	local handler = type(action) == "string" and Actions[action]
	if not handler then
		return false, "Unbekannte Aktion."
	end
	return handler(player, payload)
end)

-- ===== Spieler kommen / gehen =====

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(char)
		if Auth.IsAuthorized(player) and char:WaitForChild("Humanoid", 5) then
			PlayerTools.ApplyAll(player)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	Auth.Remove(player)
	Sessions.Remove(player)
	Rewards.Remove(player)
	Quests.Remove(player)
	buckets[player.UserId] = nil
	Automation.Refresh() -- Scheduler stoppt, wenn niemand mehr etwas aktiv hat
end)

Targets.Init()
Automation.Init()
print("[XVx Scripts] Server bereit.")
```

---

## Code 11 – `UIKit` (ModuleScript unter StarterGui/XVxScripts/XVxClient)

```lua
--[[
	XVx Scripts – UIKit
	Bausteine für die Tabs: Toggle (ON/OFF + Running/Stopped), Slider mit Eingabefeld,
	Dropdown, Button, Info-Zeile, Tabs. Bestehende Elemente deiner UI werden nie überschrieben.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("XVx"):WaitForChild("Config"))
local Theme = Config.Theme

local UIKit = {}
local orders = setmetatable({}, { __mode = "k" })

local function nextOrder(page)
	orders[page] = (orders[page] or 0) + 1
	return orders[page]
end

local function round(inst, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = inst
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Theme.Font
	l.TextSize = 14
	l.TextColor3 = Theme.Text
	l.TextXAlignment = Enum.TextXAlignment.Left
	for key, value in props do
		l[key] = value
	end
	l.Parent = parent
	return l
end

local function newRow(page, height)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, height)
	row.BackgroundColor3 = Theme.Row
	row.BorderSizePixel = 0
	row.LayoutOrder = nextOrder(page)
	row.Parent = page
	round(row)
	return row
end

-- Nimmt ein vorhandenes Element (gleicher Name + Klasse) oder erzeugt es mit den Standard-Props.
-- Props/Rundung werden NUR bei neu erzeugten Elementen gesetzt -> dein Design bleibt unverändert.
function UIKit.Ensure(parent, className, name, props, rounded)
	local found = parent:FindFirstChild(name)
	if found and found:IsA(className) then
		return found, false
	end
	local inst = Instance.new(className)
	inst.Name = name
	for key, value in props or {} do
		inst[key] = value
	end
	if rounded then
		round(inst, 8)
	end
	inst.Parent = parent
	return inst, true
end

function UIKit.Header(page, caption)
	label(page, {
		Size = UDim2.new(1, -8, 0, 22),
		Text = caption,
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme.Accent,
		LayoutOrder = nextOrder(page),
	})
end

-- Toggle mit sichtbarem ON/OFF; isAuto = zusätzlich "Running"/"Stopped"
function UIKit.Toggle(page, caption, isAuto, onClick)
	local row = newRow(page, 34)
	label(row, {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -170, 1, 0),
		Text = caption,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local status = nil
	if isAuto then
		status = label(row, {
			Position = UDim2.new(1, -170, 0, 0),
			Size = UDim2.new(0, 100, 1, 0),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
	end

	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(54, 22)
	button.Position = UDim2.new(1, -62, 0.5, -11)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BorderSizePixel = 0
	button.Parent = row
	round(button)

	local widget = { State = false }
	function widget.Set(state)
		widget.State = state == true
		button.Text = widget.State and "ON" or "OFF"
		button.BackgroundColor3 = widget.State and Theme.On or Theme.Off
		if status then
			status.Text = widget.State and "Running" or "Stopped"
			status.TextColor3 = widget.State and Theme.On or Theme.SubText
		end
	end

	button.Activated:Connect(function()
		onClick(not widget.State)
	end)
	widget.Set(false)
	return widget
end

-- Slider + Eingabefeld. onCommit(value) wird beim Loslassen bzw. nach der Eingabe aufgerufen.
function UIKit.Slider(page, caption, min, max, default, onCommit)
	local row = newRow(page, 54)
	label(row, {
		Position = UDim2.fromOffset(10, 4),
		Size = UDim2.new(1, -100, 0, 22),
		Text = caption,
	})

	local box = Instance.new("TextBox")
	box.Size = UDim2.fromOffset(64, 22)
	box.Position = UDim2.new(1, -74, 0, 4)
	box.BackgroundColor3 = Theme.Background
	box.TextColor3 = Theme.Text
	box.Font = Theme.Font
	box.TextSize = 14
	box.ClearTextOnFocus = false
	box.BorderSizePixel = 0
	box.Parent = row
	round(box, 5)

	local hit = Instance.new("Frame") -- große Trefferfläche (Touch)
	hit.BackgroundTransparency = 1
	hit.Position = UDim2.new(0, 10, 0, 28)
	hit.Size = UDim2.new(1, -20, 0, 22)
	hit.Parent = row

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Position = UDim2.fromScale(0, 0.5)
	bar.Size = UDim2.new(1, 0, 0, 6)
	bar.BackgroundColor3 = Theme.Background
	bar.BorderSizePixel = 0
	bar.Parent = hit
	round(bar, 3)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Theme.Accent
	fill.BorderSizePixel = 0
	fill.Parent = bar
	round(fill, 3)

	local widget = { Value = default }

	local function render(v)
		widget.Value = v
		fill.Size = UDim2.fromScale(math.clamp((v - min) / (max - min), 0, 1), 1)
		box.Text = tostring(v)
	end

	local function fromX(x)
		local a = math.clamp((x - hit.AbsolutePosition.X) / math.max(hit.AbsoluteSize.X, 1), 0, 1)
		return math.floor(min + a * (max - min) + 0.5)
	end

	function widget.Set(v)
		render(math.clamp(math.floor(v + 0.5), min, max))
	end

	local function isPointer(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
	end

	hit.InputBegan:Connect(function(input)
		if not isPointer(input) then
			return
		end
		render(fromX(input.Position.X))
		-- Globale Events nur WÄHREND des Ziehens verbinden
		local moveConn, endConn
		moveConn = UserInputService.InputChanged:Connect(function(changed)
			if changed.UserInputType == Enum.UserInputType.MouseMovement
				or changed.UserInputType == Enum.UserInputType.Touch then
				render(fromX(changed.Position.X))
			end
		end)
		endConn = UserInputService.InputEnded:Connect(function(ended)
			if isPointer(ended) then
				moveConn:Disconnect()
				endConn:Disconnect()
				onCommit(widget.Value)
			end
		end)
	end)

	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then
			render(math.clamp(math.floor(n + 0.5), min, max))
			onCommit(widget.Value)
		else
			render(widget.Value)
		end
	end)

	render(default)
	return widget
end

function UIKit.Button(page, caption, onClick)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -8, 0, 34)
	b.BackgroundColor3 = Theme.Accent
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Theme.Font
	b.TextSize = 14
	b.Text = caption
	b.BorderSizePixel = 0
	b.LayoutOrder = nextOrder(page)
	b.Parent = page
	round(b)
	b.Activated:Connect(onClick)
	return b
end

-- Zahlen-/Textfeld; GetNumber() liefert die Zahl oder nil
function UIKit.Input(page, caption, default)
	local row = newRow(page, 34)
	label(row, {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -140, 1, 0),
		Text = caption,
	})
	local box = Instance.new("TextBox")
	box.Size = UDim2.fromOffset(110, 22)
	box.Position = UDim2.new(1, -120, 0.5, -11)
	box.BackgroundColor3 = Theme.Background
	box.TextColor3 = Theme.Text
	box.Font = Theme.Font
	box.TextSize = 14
	box.Text = tostring(default or "")
	box.ClearTextOnFocus = false
	box.BorderSizePixel = 0
	box.Parent = row
	round(box, 5)
	return {
		GetNumber = function()
			return tonumber(box.Text)
		end,
	}
end

-- Nur-Lese-Zeile für Statusinfos ("Ziel: Goblin")
function UIKit.Info(page, caption)
	local row = newRow(page, 28)
	local l = label(row, {
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		TextSize = 13,
		TextColor3 = Theme.SubText,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local widget = {}
	function widget.Set(value)
		l.Text = caption .. ": " .. tostring(value)
	end
	widget.Set("-")
	return widget
end

-- Dropdown. Optionen: Strings oder { Label = "...", Value = ... }
function UIKit.Dropdown(page, caption, onSelect)
	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, -8, 0, 34)
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.LayoutOrder = nextOrder(page)
	container.Parent = page

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	local head = Instance.new("TextButton")
	head.Size = UDim2.new(1, 0, 0, 34)
	head.LayoutOrder = 1
	head.BackgroundColor3 = Theme.Row
	head.TextColor3 = Theme.Text
	head.Font = Theme.Font
	head.TextSize = 14
	head.BorderSizePixel = 0
	head.TextXAlignment = Enum.TextXAlignment.Left
	head.Parent = container
	round(head)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.Parent = head

	local list = Instance.new("ScrollingFrame")
	list.LayoutOrder = 2
	list.Visible = false
	list.BackgroundColor3 = Theme.Background
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Size = UDim2.new(1, 0, 0, 0)
	list.Parent = container
	round(list)
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 2)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list

	local widget = { Value = nil, Options = {} }

	local function labelFor(value)
		for _, option in widget.Options do
			if option.Value == value then
				return option.Label
			end
		end
		return nil
	end

	local function refreshHead()
		local text = widget.Value ~= nil and labelFor(widget.Value) or "-"
		head.Text = caption .. ": " .. tostring(text)
	end

	function widget.SetOptions(options)
		for _, child in list:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		widget.Options = {}
		for i, option in options do
			local opt = type(option) == "table" and option or { Label = tostring(option), Value = option }
			table.insert(widget.Options, opt)

			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, -6, 0, 28)
			b.LayoutOrder = i
			b.BackgroundColor3 = Theme.Row
			b.TextColor3 = Theme.Text
			b.Font = Theme.Font
			b.TextSize = 13
			b.Text = tostring(opt.Label)
			b.BorderSizePixel = 0
			b.Parent = list
			round(b, 5)
			b.Activated:Connect(function()
				widget.Value = opt.Value
				refreshHead()
				list.Visible = false
				if onSelect then
					onSelect(opt.Value)
				end
			end)
		end
		list.Size = UDim2.new(1, 0, 0, math.min(#options, 5) * 30 + 4)
		if widget.Value ~= nil and labelFor(widget.Value) == nil then
			widget.Value = nil
		end
		refreshHead()
	end

	function widget.SetValue(value)
		widget.Value = value
		refreshHead()
	end

	head.Activated:Connect(function()
		list.Visible = not list.Visible
	end)
	refreshHead()
	return widget
end

-- Tabs: nutzt vorhandene "Tab_<Key>"-Buttons und "Page_<Key>"-Seiten, erzeugt fehlende
function UIKit.BuildTabs(tabBar, pageHolder, definitions)
	if not tabBar:FindFirstChildOfClass("UIListLayout") then
		local l = Instance.new("UIListLayout")
		l.FillDirection = Enum.FillDirection.Horizontal
		l.Padding = UDim.new(0, 4)
		l.SortOrder = Enum.SortOrder.LayoutOrder
		l.Parent = tabBar
	end

	local pages, buttons = {}, {}

	local function select(key)
		for k, page in pages do
			page.Visible = (k == key)
			buttons[k].BackgroundColor3 = (k == key) and Theme.Accent or Theme.Row
		end
	end

	for i, def in definitions do
		local button = UIKit.Ensure(tabBar, "TextButton", "Tab_" .. def.Key, {
			Size = UDim2.fromOffset(86, 30),
			BackgroundColor3 = Theme.Row,
			Text = def.Title,
			TextColor3 = Theme.Text,
			Font = Theme.Font,
			TextSize = 13,
			BorderSizePixel = 0,
			LayoutOrder = i,
		}, true)

		local page = UIKit.Ensure(pageHolder, "ScrollingFrame", "Page_" .. def.Key, {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
		})

		local layout = page:FindFirstChildOfClass("UIListLayout")
		if not layout then
			layout = Instance.new("UIListLayout")
			layout.Padding = UDim.new(0, 6)
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			layout.Parent = page
		end
		layout.SortOrder = Enum.SortOrder.LayoutOrder -- nötig für die Reihenfolge der Zeilen

		buttons[def.Key] = button
		pages[def.Key] = page
		button.Activated:Connect(function()
			select(def.Key)
		end)
	end

	select(definitions[1].Key)
	return pages
end

return UIKit
```

---

## Code 12 – `Movement` (ModuleScript unter StarterGui/XVxScripts/XVxClient)

```lua
--[[
	XVx Scripts – Movement (Client)
	Fly, NoClip, Infinite Jump. Werden NUR aktiviert, nachdem der Server den Toggle bestätigt hat.
	Jede Funktion läuft nur, solange sie eingeschaltet ist, und räumt beim Ausschalten alles auf.
	Fly-Steuerung: WASD/Stick = bewegen (Kamerarichtung), Space = hoch, Shift = runter.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("XVx"):WaitForChild("Config"))

local player = Players.LocalPlayer
local Movement = {}

local wanted = { Fly = false, NoClip = false, InfiniteJump = false }
local conns = {}
local flyInstances = {}
local noclipSaved = nil

local function humanoid()
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function disconnect(key)
	if conns[key] then
		conns[key]:Disconnect()
		conns[key] = nil
	end
end

-- ===== Fly =====

local function stopFly()
	disconnect("Fly")
	for _, inst in flyInstances do
		inst:Destroy()
	end
	table.clear(flyInstances)
	local hum = humanoid()
	if hum then
		hum.PlatformStand = false
	end
end

local function startFly()
	stopFly()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = humanoid()
	if not (hrp and hum) then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "XVxFlyAttachment"
	attachment.Parent = hrp

	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = hrp

	local align = Instance.new("AlignOrientation")
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.MaxTorque = math.huge
	align.Responsiveness = 30
	align.Parent = hrp

	flyInstances = { attachment, velocity, align }
	hum.PlatformStand = true

	conns.Fly = RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local look = cam.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)

		local move = hum.MoveDirection
		local forward = move:Dot(flat)
		local vertical = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			vertical += 1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			vertical -= 1
		end

		local speed = Config.FlySpeed
		velocity.VectorVelocity = move * speed + Vector3.new(0, (vertical + forward * look.Y) * speed, 0)
		align.CFrame = CFrame.lookAt(Vector3.zero, flat)
	end)
end

-- ===== NoClip =====

local function stopNoClip()
	disconnect("NoClip")
	disconnect("NoClipAdded")
	if noclipSaved then
		for part in noclipSaved do
			if part.Parent then
				part.CanCollide = true -- gespeichert wurden nur Teile, die vorher kollidierten
			end
		end
		noclipSaved = nil
	end
end

local function startNoClip()
	stopNoClip()
	local char = player.Character
	if not char then
		return
	end

	local parts = {}
	local function track(inst)
		if inst:IsA("BasePart") then
			parts[inst] = true
		end
	end
	for _, d in char:GetDescendants() do
		track(d)
	end
	conns.NoClipAdded = char.DescendantAdded:Connect(track)

	noclipSaved = {}
	conns.NoClip = RunService.Stepped:Connect(function()
		for part in parts do
			if not part.Parent then
				parts[part] = nil
			elseif part.CanCollide then
				noclipSaved[part] = true
				part.CanCollide = false
			end
		end
	end)
end

-- ===== Infinite Jump =====

local function stopInfiniteJump()
	disconnect("InfiniteJump")
end

local function startInfiniteJump()
	stopInfiniteJump()
	conns.InfiniteJump = UserInputService.JumpRequest:Connect(function()
		local hum = humanoid()
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
end

-- ===== Öffentliche API =====

local starters = { Fly = startFly, NoClip = startNoClip, InfiniteJump = startInfiniteJump }
local stoppers = { Fly = stopFly, NoClip = stopNoClip, InfiniteJump = stopInfiniteJump }

function Movement.SetEnabled(feature, enabled)
	if wanted[feature] == nil then
		return
	end
	wanted[feature] = enabled
	if enabled then
		starters[feature]()
	else
		stoppers[feature]()
	end
end

function Movement.Init()
	-- Beim Sterben/Respawn alles sauber beenden und danach (falls aktiv) neu starten
	player.CharacterRemoving:Connect(function()
		for _, stop in stoppers do
			stop()
		end
	end)
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart")
		char:WaitForChild("Humanoid")
		for feature, on in wanted do
			if on then
				starters[feature]()
			end
		end
	end)
end

return Movement
```

---

## Code 13 – `XVxClient` (**LocalScript** direkt in StarterGui/XVxScripts)

```lua
--[[
	XVx Scripts – XVxClient (LocalScript)
	Pfad: StarterGui > XVxScripts > XVxClient   (UIKit + Movement als Kinder dieses Scripts)
	Bindet sich per Namen an deine vorhandene UI. Fehlende Elemente werden im Standardstil erzeugt.
	Der Client fragt nur an - alle Entscheidungen trifft der Server.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local gui = script.Parent
assert(gui:IsA("ScreenGui"), "XVxClient muss direkt in der ScreenGui 'XVxScripts' liegen.")
gui.ResetOnSpawn = false

local Shared = ReplicatedStorage:WaitForChild("XVx")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = Shared:WaitForChild(Config.Remotes.Folder)
local R = {
	KeySubmit = Remotes:WaitForChild(Config.Remotes.KeySubmit),
	GetState = Remotes:WaitForChild(Config.Remotes.GetState),
	SetToggle = Remotes:WaitForChild(Config.Remotes.SetToggle),
	SetValue = Remotes:WaitForChild(Config.Remotes.SetValue),
	DoAction = Remotes:WaitForChild(Config.Remotes.DoAction),
	StateSync = Remotes:WaitForChild(Config.Remotes.StateSync),
}

local UIKit = require(script:WaitForChild("UIKit"))
local Movement = require(script:WaitForChild("Movement"))
local Theme = Config.Theme

-- Server-Aufruf, der nie einen Fehler wirft
local function call(remote, ...)
	local ok, a, b = pcall(remote.InvokeServer, remote, ...)
	if not ok then
		return false, "Verbindungsfehler."
	end
	return a, b
end

-- =====================================================================
-- 1) Key-UI
-- =====================================================================

local keyFrame = UIKit.Ensure(gui, "Frame", "KeyFrame", {
	Size = UDim2.fromOffset(360, 250),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0,
}, true)

local keyTitle = UIKit.Ensure(keyFrame, "TextLabel", "Title", {
	Position = UDim2.fromOffset(10, 8),
	Size = UDim2.new(1, -20, 0, 40),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 22,
	TextColor3 = Theme.Text,
})
keyTitle.Text = Config.Name

local keyInput = UIKit.Ensure(keyFrame, "TextBox", "KeyInput", {
	Position = UDim2.fromOffset(20, 56),
	Size = UDim2.new(1, -40, 0, 38),
	BackgroundColor3 = Theme.Row,
	TextColor3 = Theme.Text,
	PlaceholderText = "Key eingeben",
	Font = Theme.Font,
	TextSize = 16,
	Text = "",
	ClearTextOnFocus = false,
	BorderSizePixel = 0,
}, true)

local submitButton = UIKit.Ensure(keyFrame, "TextButton", "SubmitButton", {
	Position = UDim2.fromOffset(20, 102),
	Size = UDim2.new(1, -40, 0, 38),
	BackgroundColor3 = Theme.Accent,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "Bestätigen",
	Font = Theme.Font,
	TextSize = 16,
	BorderSizePixel = 0,
}, true)

local errorLabel = UIKit.Ensure(keyFrame, "TextLabel", "ErrorLabel", {
	Position = UDim2.fromOffset(20, 146),
	Size = UDim2.new(1, -40, 0, 22),
	BackgroundTransparency = 1,
	Font = Theme.Font,
	TextSize = 13,
	TextColor3 = Theme.Off,
	Text = "",
})

local linkBox = UIKit.Ensure(keyFrame, "TextBox", "LinkBox", {
	Position = UDim2.fromOffset(20, 172),
	Size = UDim2.new(1, -40, 0, 26),
	BackgroundColor3 = Theme.Row,
	TextColor3 = Theme.SubText,
	Font = Theme.Font,
	TextSize = 13,
	Text = "",
	BorderSizePixel = 0,
	Visible = false,
}, true)
linkBox.TextEditable = false -- markier- und kopierbar, aber nicht änderbar
linkBox.ClearTextOnFocus = false

local getKeyButton = UIKit.Ensure(keyFrame, "TextButton", "GetKeyButton", {
	Position = UDim2.new(0, 20, 1, -46),
	Size = UDim2.new(1, -40, 0, 34),
	BackgroundColor3 = Theme.Row,
	TextColor3 = Theme.Text,
	Text = "Get Key",
	Font = Theme.Font,
	TextSize = 15,
	BorderSizePixel = 0,
}, true)

-- =====================================================================
-- 2) Haupt-UI (bis zur Freischaltung unsichtbar)
-- =====================================================================

local mainFrame = UIKit.Ensure(gui, "Frame", "MainFrame", {
	Size = UDim2.fromOffset(580, 430),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Theme.Background,
	BorderSizePixel = 0,
}, true)

local mainTitle = UIKit.Ensure(mainFrame, "TextLabel", "Title", {
	Position = UDim2.fromOffset(12, 4),
	Size = UDim2.new(1, -24, 0, 34),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = Theme.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
})
mainTitle.Text = Config.Name

local tabBar = UIKit.Ensure(mainFrame, "Frame", "TabBar", {
	Position = UDim2.fromOffset(8, 42),
	Size = UDim2.new(1, -16, 0, 34),
	BackgroundTransparency = 1,
})

local pagesHolder = UIKit.Ensure(mainFrame, "Frame", "Pages", {
	Position = UDim2.fromOffset(8, 82),
	Size = UDim2.new(1, -16, 1, -120),
	BackgroundTransparency = 1,
})

local toastLabel = UIKit.Ensure(mainFrame, "TextLabel", "Toast", {
	Position = UDim2.new(0, 8, 1, -34),
	Size = UDim2.new(1, -16, 0, 28),
	BackgroundColor3 = Theme.Row,
	Font = Theme.Font,
	TextSize = 14,
	TextColor3 = Theme.Text,
	Text = "",
	Visible = false,
	BorderSizePixel = 0,
}, true)

keyFrame.Visible = true
mainFrame.Visible = false

local toastId = 0
local function toast(text, isError)
	toastLabel.Text = text
	toastLabel.TextColor3 = isError and Theme.Off or Theme.Text
	toastLabel.Visible = true
	toastId += 1
	local id = toastId
	task.delay(3, function()
		if toastId == id then
			toastLabel.Visible = false
		end
	end)
end

-- =====================================================================
-- 3) Bausteine + Server-Anbindung
-- =====================================================================

local toggleWidgets = {} -- [feature] = { widget, ... }
local sliderWidgets = {} -- [wertname] = widget
local infoWidgets = { Target = {}, Boss = {}, Quest = {} }
local dropdowns = {}

local function setFeature(feature, state)
	for _, w in toggleWidgets[feature] or {} do
		w.Set(state)
	end
	if Config.Features[feature] == "Movement" then
		Movement.SetEnabled(feature, state)
	end
end

local function onToggle(feature, wanted)
	local ok, result = call(R.SetToggle, feature, wanted)
	if ok then
		setFeature(feature, result == true)
	else
		toast(tostring(result or "Fehler"), true)
	end
end

local function action(name, payload)
	local ok, message = call(R.DoAction, name, payload)
	if type(message) == "string" and message ~= "" then
		toast(message, not ok)
	end
	return ok
end

local function addToggle(page, caption, feature)
	local w = UIKit.Toggle(page, caption, Config.Features[feature] == "Auto", function(wanted)
		onToggle(feature, wanted)
	end)
	toggleWidgets[feature] = toggleWidgets[feature] or {}
	table.insert(toggleWidgets[feature], w)
end

local function addSlider(page, caption, name)
	local limit = Config.Limits[name]
	local w
	w = UIKit.Slider(page, caption, limit.Min, limit.Max, limit.Default, function(value)
		local ok, applied = call(R.SetValue, name, value)
		if ok and type(applied) == "number" then
			w.Set(applied) -- der Server hat den Wert ggf. begrenzt
		else
			toast(tostring(applied or "Fehler"), true)
		end
	end)
	sliderWidgets[name] = w
end

local function addInfo(page, caption, key)
	table.insert(infoWidgets[key], UIKit.Info(page, caption))
end

local function applyState(state)
	if type(state) ~= "table" then
		return
	end
	for feature in Config.Features do
		setFeature(feature, state.Toggles[feature] == true)
	end
	for name, w in sliderWidgets do
		if type(state.Values[name]) == "number" then
			w.Set(state.Values[name])
		end
	end

	local lists = state.Lists
	dropdowns.Test.SetOptions(lists.TestPositions)
	dropdowns.Arena.SetOptions(lists.BossArenas)
	dropdowns.Npc.SetOptions(lists.NpcTypes)
	dropdowns.Item.SetOptions(lists.Items)

	local bossOptions = { { Label = "Automatisch (nächster Boss)", Value = "" } }
	for _, boss in lists.Bosses do
		table.insert(bossOptions, { Label = boss.Name, Value = boss.Id })
	end
	dropdowns.Boss.SetOptions(bossOptions)
	dropdowns.Boss.SetValue(state.SelectedBoss or "")
end

local function refreshState()
	local ok, state = pcall(R.GetState.InvokeServer, R.GetState)
	if ok then
		applyState(state)
	end
end

-- =====================================================================
-- 4) Tabs und Inhalte
-- =====================================================================

local pages = UIKit.BuildTabs(tabBar, pagesHolder, {
	{ Key = "Player", Title = "Player" },
	{ Key = "Teleport", Title = "Teleport" },
	{ Key = "AutoFarm", Title = "Auto Farm" },
	{ Key = "Boss", Title = "Boss" },
	{ Key = "Combat", Title = "Combat" },
	{ Key = "Rewards", Title = "Rewards" },
})

-- ---- Player ----
do
	local p = pages.Player
	UIKit.Header(p, "Bewegung")
	addToggle(p, "Fly (Space hoch / Shift runter)", "Fly")
	addSlider(p, "Speed", "WalkSpeed")
	addSlider(p, "JumpPower", "JumpPower")
	addToggle(p, "Infinite Jump", "InfiniteJump")
	addToggle(p, "NoClip", "NoClip")
	UIKit.Header(p, "Testhilfen")
	UIKit.Button(p, "Heal", function()
		action("Heal")
	end)
	addToggle(p, "God Mode (Test)", "GodMode")
end

-- ---- Teleport ----
do
	local p = pages.Teleport
	UIKit.Header(p, "Eigene Ziele")

	dropdowns.Test = UIKit.Dropdown(p, "Test-Position")
	UIKit.Button(p, "Zur Test-Position teleportieren", function()
		if dropdowns.Test.Value then
			action("Teleport", { Kind = "Test", Id = dropdowns.Test.Value })
		else
			toast("Bitte eine Position wählen.", true)
		end
	end)

	dropdowns.Npc = UIKit.Dropdown(p, "NPC-Typ")
	UIKit.Button(p, "Zum nächsten NPC dieses Typs", function()
		if dropdowns.Npc.Value then
			action("Teleport", { Kind = "Npc", Id = dropdowns.Npc.Value })
		else
			toast("Bitte einen NPC-Typ wählen.", true)
		end
	end)

	dropdowns.Arena = UIKit.Dropdown(p, "Boss-Arena")
	UIKit.Button(p, "Zur Boss-Arena teleportieren", function()
		if dropdowns.Arena.Value then
			action("Teleport", { Kind = "BossArena", Id = dropdowns.Arena.Value })
		else
			toast("Bitte eine Arena wählen.", true)
		end
	end)

	UIKit.Button(p, "Zurück zum Spawn", function()
		action("Teleport", { Kind = "Spawn" })
	end)
	UIKit.Button(p, "Listen aktualisieren", function()
		refreshState()
		toast("Listen aktualisiert.")
	end)
end

-- ---- Auto Farm ----
do
	local p = pages.AutoFarm
	UIKit.Header(p, "Farmen (nur eigene NPCs)")
	addToggle(p, "Auto Farm XP", "AutoFarmXP")
	addToggle(p, "Auto Farm Coins", "AutoFarmCoins")
	addToggle(p, "Auto Farm eigene NPCs", "AutoFarmNpcs")
	addInfo(p, "Ziel", "Target")
	UIKit.Header(p, "Einsammeln")
	addToggle(p, "Auto Collect", "AutoCollect")
	addToggle(p, "Auto Loot", "AutoLoot")
	addSlider(p, "Loot-Radius", "LootRadius")
	UIKit.Header(p, "Quests")
	addToggle(p, "Auto Quest", "AutoQuest")
	addToggle(p, "Auto Quest abschließen", "AutoQuestComplete")
	addInfo(p, "Quest", "Quest")
	UIKit.Button(p, "Quest annehmen", function()
		action("QuestAccept")
	end)
	UIKit.Button(p, "Quest abschließen", function()
		action("QuestComplete")
	end)
end

-- ---- Boss ----
do
	local p = pages.Boss
	UIKit.Header(p, "Auswahl")
	dropdowns.Boss = UIKit.Dropdown(p, "Boss", function(value)
		action("SelectBoss", value)
	end)
	UIKit.Button(p, "Zu meinem Boss teleportieren", function()
		action("TeleportBoss", dropdowns.Boss.Value or "")
	end)
	UIKit.Button(p, "Listen aktualisieren", function()
		refreshState()
		toast("Listen aktualisiert.")
	end)
	UIKit.Header(p, "Boss-Farm")
	addToggle(p, "Boss-Farm (Auto Boss)", "AutoBoss")
	addToggle(p, "Boss automatisch suchen", "BossSearch")
	addToggle(p, "Boss automatisch bekämpfen", "BossFight")
	addToggle(p, "Danach nächsten Boss wählen", "BossNext")
	addToggle(p, "Auto Loot nach Boss-Kill", "BossLoot")
	addInfo(p, "Boss", "Boss")
end

-- ---- Combat ----
do
	local p = pages.Combat
	UIKit.Header(p, "Kampf (nur eigene NPCs/Bosse)")
	addToggle(p, "Auto Attack", "AutoAttack")
	addToggle(p, "Auto Target", "AutoTarget")
	addSlider(p, "Attack Range", "AttackRange")
	addInfo(p, "Ziel", "Target")
end

-- ---- Rewards ----
do
	local p = pages.Rewards
	UIKit.Header(p, "Test-Rewards (serverseitig begrenzt)")
	local xpInput = UIKit.Input(p, "XP-Menge", 100)
	UIKit.Button(p, "Test-XP vergeben", function()
		action("GiveTest", { Kind = "XP", Amount = xpInput.GetNumber() })
	end)
	local coinInput = UIKit.Input(p, "Coin-Menge", 100)
	UIKit.Button(p, "Test-Coins vergeben", function()
		action("GiveTest", { Kind = "Coins", Amount = coinInput.GetNumber() })
	end)
	dropdowns.Item = UIKit.Dropdown(p, "Testitem")
	local itemAmount = UIKit.Input(p, "Item-Anzahl", 1)
	UIKit.Button(p, "Testitem vergeben", function()
		if dropdowns.Item.Value then
			action("GiveTest", { Kind = "Item", Item = dropdowns.Item.Value, Amount = itemAmount.GetNumber() })
		else
			toast("Bitte ein Item wählen.", true)
		end
	end)
	UIKit.Header(p, "Drops")
	addToggle(p, "Drops automatisch einsammeln", "AutoLoot")
end

-- =====================================================================
-- 5) Key-Ablauf
-- =====================================================================

local unlocked = false

local function unlock()
	unlocked = true
	keyFrame.Visible = false
	mainFrame.Visible = true
	refreshState()
end

-- Nur Buchstaben/Zahlen im Key-Feld
keyInput:GetPropertyChangedSignal("Text"):Connect(function()
	local clean = keyInput.Text:gsub("[^%w]", "")
	clean = clean:sub(1, 32)
	if clean ~= keyInput.Text then
		keyInput.Text = clean
	end
end)

local busy = false
local function submitKey()
	if busy then
		return
	end
	if keyInput.Text == "" then
		errorLabel.Text = "Bitte einen Key eingeben."
		errorLabel.TextColor3 = Theme.Off
		return
	end
	busy = true
	local ok, message = call(R.KeySubmit, keyInput.Text)
	busy = false

	if ok then
		errorLabel.Text = ""
		unlock()
	else
		errorLabel.Text = tostring(message or "Falscher Key.")
		errorLabel.TextColor3 = Theme.Off
	end
end

submitButton.Activated:Connect(submitKey)
keyInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		submitKey()
	end
end)

-- "Get Key": Roblox erlaubt kein Öffnen externer Links -> Link anzeigen und markieren
getKeyButton.Activated:Connect(function()
	linkBox.Text = Config.DiscordLink
	linkBox.Visible = true
	errorLabel.Text = "Link markiert: kopieren mit Strg+C (Mobile: lange drücken)."
	errorLabel.TextColor3 = Theme.SubText
	linkBox:CaptureFocus()
end)

linkBox.Focused:Connect(function()
	task.defer(function()
		linkBox.SelectionStart = 1
		linkBox.CursorPosition = #linkBox.Text + 1
	end)
end)

-- =====================================================================
-- 6) Meldungen vom Server + UI ein-/ausblenden
-- =====================================================================

R.StateSync.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.Type == "Info" and type(payload.Info) == "table" then
		for key, widgets in infoWidgets do
			for _, w in widgets do
				w.Set(payload.Info[key] or "-")
			end
		end
	elseif payload.Type == "SelectedBoss" then
		dropdowns.Boss.SetValue(tostring(payload.Id or ""))
	elseif payload.Type == "Toast" then
		toast(tostring(payload.Text or ""))
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and unlocked and input.KeyCode == Config.ToggleUiKey then
		mainFrame.Visible = not mainFrame.Visible
	end
end)

Movement.Init()

-- Falls der Server dich schon freigeschaltet hat (z. B. nach UI-Reset), direkt entsperren
task.spawn(function()
	local authorized = call(R.KeySubmit, nil)
	if authorized == true then
		unlock()
	end
end)
```

---

## Schnelltest (in Roblox Studio)

1. Alle Scripts einfügen (Abschnitt 7), `XVxTeleports` und mindestens einen NPC registrieren (Abschnitt 8).
2. **Play** drücken → nur die Key-UI ist sichtbar. Falscher Key → Fehlermeldung mit Restversuchen. `Get Key` → Link erscheint markiert.
3. Key `ServerConfig.Key` eingeben → Haupt-UI „XVx Scripts“ erscheint. Mit `Config.ToggleUiKey` (RightControl) blendest du sie ein/aus.
4. Toggle „Auto Farm eigene NPCs“ einschalten: Status wechselt auf **Running**, der Charakter läuft zum NPC und greift an. Ausschalten → **Stopped**, alles endet sofort.
5. Output-Fenster: `[XVx Scripts] Server bereit.` muss erscheinen. Warnungen mit `[XVx Scripts]` nennen fehlende Humanoids o. Ä.

