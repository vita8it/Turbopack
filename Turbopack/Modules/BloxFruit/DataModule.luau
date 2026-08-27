local Sea = ...
local DataModule = {} do
    DataModule.Shops = {
        ["Ability"] = {
            ["Buy Geppo"] = { "BuyHaki", "Geppo" },
            ["Buy Buso"] = { "BuyHaki", "Buso" },
            ["Buy Soru"] = { "BuyHaki", "Soru" },
            ["Buy Ken"] = { "KenTalk", "Buy" },
        },
        ["Sword"] = {
            ["Buy Katana"] = { "BuyItem", "Katana" },
            ["Buy Cutlass"] = { "BuyItem", "Cutlass" },
            ["Buy Dual Katana"] = { "BuyItem", "Dual Katana" },
            ["Buy Iron Mace"] = { "BuyItem", "Iron Mace" },
            ["Buy Triple Katana"] = { "BuyItem", "Triple Katana" },
            ["Buy Pipe"] = { "BuyItem", "Pipe" },
            ["Buy Dual-Headed Blade"] = { "BuyItem", "Dual-Headed Blade" },
            ["Buy Soul Cane"] = { "BuyItem", "Soul Cane" },
            ["Buy Bisento"] = { "BuyItem", "Bisento" },
        },
        ["Gun"] = {
            ["Buy Musket"] = { "BuyItem", "Musket" },
            ["Buy Slingshot"] = { "BuyItem", "Slingshot" },
            ["Buy Flintlock"] = { "BuyItem", "Flintlock" },
            ["Buy Refined Slingshot"] = { "BuyItem", "Refined Slingshot" },
            ["Buy Dual Flintlock"] = { "BuyItem", "Dual Flintlock" },
            ["Buy Cannon"] = { "BuyItem", "Cannon" },
            ["Buy Kabucha"] = { "BlackbeardReward", "Slingshot", "2" },
        },
        ["Accessories"] = {
            ["Buy Black Cape"] = { "BuyItem", "Black Cape" },
            ["Buy Swordsman Hat"] = { "BuyItem", "Swordsman Hat" },
            ["Buy Tomoe Ring"] = { "BuyItem", "Tomoe Ring" },
        },
        ["Race"] = {
            ["Ghoul Race"] = { "Ectoplasm", "Change", 4 },
            ["Cyborg Race"] = { "CyborgTrainer", "Buy" },
        },
    }
    
    DataModule.FruitIds = {
        ["rbxassetid://15124425041"] = "Rocket",
        ["rbxassetid://15123685330"] = "Spin",
        ["rbxassetid://15123613404"] = "Blade",
        ["rbxassetid://15123689268"] = "Spring",
        ["rbxassetid://15123595806"] = "Bomb",
        ["rbxassetid://15123677932"] = "Smoke",
        ["rbxassetid://15124220207"] = "Spike",
        ["rbxassetid://121545956771325"] = "Flame",
        ["rbxassetid://15123673019"] = "Sand",
        ["rbxassetid://15123618591"] = "Dark",
        ["rbxassetid://77885466312115"] = "Eagle",
        ["rbxassetid://15112600534"] = "Diamond",
        ["rbxassetid://15123640714"] = "Light",
        ["rbxassetid://15123668008"] = "Rubber",
        ["rbxassetid://15123662036"] = "Ghost",
        ["rbxassetid://15123645682"] = "Magma",
        ["rbxassetid://15123606541"] = "Quake",
        ["rbxassetid://15123643097"] = "Love",
        ["rbxassetid://15123681598"] = "Spider",
        ["rbxassetid://116828771482820"] = "Creation",
        ["rbxassetid://15123679712"] = "Sound",
        ["rbxassetid://15123654553"] = "Phoenix",
        ["rbxassetid://15123656798"] = "Portal",
        ["rbxassetid://15123670514"] = "Rumble",
        ["rbxassetid://15123652069"] = "Pain",
        ["rbxassetid://15123587371"] = "Blizzard",
        ["rbxassetid://15123633312"] = "Gravity",
        ["rbxassetid://15123648309"] = "Mammoth",
        ["rbxassetid://15694681122"] = "T-Rex",
        ["rbxassetid://15123624401"] = "Dough",
        ["rbxassetid://15123675904"] = "Shadow",
        ["rbxassetid://10773719142"] = "Venom",
        ["rbxassetid://15123616275"] = "Control",
        ["rbxassetid://11911905519"] = "Spirit",
        ["rbxassetid://15123638064"] = "Leopard",
        ["rbxassetid://15487764876"] = "Kitsune",
        ["rbxassetid://115276580506154"] = "Yeti",
        ["rbxassetid://118054805452821"] = "Gas",
        ["rbxassetid://95749033139458"] = "Dragon East"
    }
    
    DataModule.Islands = {
        {
            ['Pirate Starter'] = CFrame.new(1077, 16, 1439),
            ['Marine Starter'] = CFrame.new(-2922, 41, 2111),
            ['Jungle'] = CFrame.new(-1439, 62, 8),
            ['Colosseum'] = CFrame.new(-1664, 151, -3245),
            ['Frozen Village'] = CFrame.new(1221, 138, -1487),
            ['Desert'] = CFrame.new(1058, 52, 4491),
            ['Fountain City'] = CFrame.new(5269, 56, 4061),
            ['Marine Fortress'] = CFrame.new(-5094, 263, 4414),
            ['Middle Town'] = CFrame.new(-849, 74, 1625),
            ['Pirate Village'] = CFrame.new(-1151, 65, 4160),
            ['Underwater City'] = CFrame.new(61318, 19, 1525),
            ['Whirlpool'] = CFrame.new(4344, 21, -1883),
            ['Prison'] = CFrame.new(5316, 89, 699),
            ['Lower Skyland'] = CFrame.new(-5050, 278, -2732),
            ['Middle Skyland'] = CFrame.new(-4654, 873, -1762),
            ['Upper Skyland'] = CFrame.new(-7654, 5623, -1071)
        },
        {
            ['Kingdom of Rose'] = CFrame.new(-385, 319, 463),
            ['Green Zone'] = CFrame.new(-2435, 73, -3250),
            ['Hot and Cold'] = CFrame.new(-5507, 82, -5165),
            ['Cursed Ship'] = CFrame.new(916, 126, 33073),
            ['Snow Mountain'] = CFrame.new(1008, 446, -4906),
            ['Ice Castle'] = CFrame.new(6146, 484, -6729),
            ['Dark Arena'] = CFrame.new(3892, 14, -3616),
            ['Graveyard Island'] = CFrame.new(-5722, 9, -963),
            ['Forgotten Island'] = CFrame.new(-3026, 319, -10083),
            ['North Pole'] = CFrame.new(-5397, 12, 1454),
        },
        {
            ['Submerged Island'] = CFrame.new(9952, -1887, 9678),
            ['Tiki Outpost'] = CFrame.new(-16928, 9, 437),
            ['Castle on the Sea'] = CFrame.new(-5086, 315, -2974),
            ['Hydra Island'] = CFrame.new(5164, 1174, 222),
            ['Peanut Island'] = CFrame.new(-2111, 193, -10243),
            ['Ice Cream Island'] = CFrame.new(-801, 210, -10999),
            ['Cake Loaf'] = CFrame.new(-1748, 489, -12360),
            ['Chocolate Island'] = CFrame.new(256, 124, -12549),
            ['North Pole'] = CFrame.new(-906, 89, -14666),
            ['Port Town'] = CFrame.new(-390, 11, 5244),
            ['Great Tree'] = CFrame.new(3295, 776, -6281),
            ['Haunted Castle'] = CFrame.new(-9499, 500, 6009),
            ['Floating Turtle'] = CFrame.new(-12310, 1163, -9968)
        },
    }

    DataModule.Places = {
        {
            ["Cyborg's Domain"] = CFrame.new(6271, 71, 4000),
            ["Thunder God's Domain"] = CFrame.new(-7989, 5814, -2030),
            ["Saber Expert's Domain"] = CFrame.new(-1425, 30, -14)
        },
        {
            ['Cafe'] = CFrame.new(-377, 73, 290),
            ['Basement Cafe'] = CFrame.new(-350, 16, 242),
            ['Mansion'] = CFrame.new(-392, 374, 720),
            ["Swan's Room"] = CFrame.new(2462, 15, 695),
            ['Raid'] = CFrame.new(-6535, 310, -4745),
            ['Labs'] = CFrame.new(-5548, 224, -5899),
            ['Colosseum'] = CFrame.new(-1822, 46, 1411),
        },
        {
            ["Beautiful Pirate's Domain"] = CFrame.new(5339, 22, -328),
            ['Head Castle on the Sea'] = CFrame.new(-5421, 1090, -2666),
            ['Mansion'] = CFrame.new(-12552, 337, -7504),
            ['Dragon Dojo'] = CFrame.new(5701, 1207, 924),
            ['Friendly Arena'] = CFrame.new(5012, 59, -1571),
            ['Waterfall'] = CFrame.new(5174, 8, 1191),
            ['Head of Great Tree'] = CFrame.new(3070, 2281, -7335)
        },
    }

    DataModule.Materials = {
        {
            ["Fish Tail"] = { "Fishman Warrior", "Fishman Commando" },
            ["Magma Ore"] = { "Military Soldier", "Military Spy" },
            ["GunPowder"] = { "Brute", "Pirate" },
            ["Angel Wings"] = { "God's Guard" },
            ["Scrap Metal"] = { "Brute" },
            ["Leather"] = { "Brute" }
        },
        {
            ["Ectoplasm"] = { 'Ship Steward', 'Ship Officer', 'Ship Engineer', 'Ship Deckhand' },
            ["Mystic Droplet"] = { "Water Fighter", "Sea Soldier" },
            ["Radioactive Material"] = { "Factory Staff" },
            ["Scrap Metal"] = { "Swan Pirate" },
            ["Magma Ore"] = { "Magma Ninja" },
            ["Vampire Fang"] = { "Vampire" }
        },
        {
            ["Conjured Cocoa"] = { "Cocoa Warrior", "Chocolate Bar Battler", "Sweet Thief", "Candy Rebel" },
            ["Dragon Scale"] = { "Dragon Crew Archer", "Dragon Crew Warrior" },
            ["Fish Tail"] = { "Fishman Raider", "Fishman Captain" },
            ["Mini Tusk"] = { "Mythological Pirate" },
            ["Gunpowder"] = { "Pistol Billionaire" },
            ["Scrap Metal"] = { "Jungle Pirate" },
            ["Demonic Wisp"] = { "Demonic Soul" }
        }
    }
    
    DataModule.Bosses = {
        {
            ["The Gorilla King"] = {
                Position = Vector3.new(-1128, 6, -451),
                Quest = { "JungleQuest", CFrame.new(-1598, 37, 153) },
                Level = 20,
            },
            ["Chef"] = {
                Position = Vector3.new(-1131, 14, 4080),
                Quest = { "BuggyQuest1", CFrame.new(-1140, 4, 3829) },
                Level = 55,
            },
            ["Yeti"] = {
                Position = Vector3.new(1185, 106, -1518),
                Quest = { "SnowQuest", CFrame.new(1385, 87, -1298) },
                Level = 105,
            },
            ["Vice Admiral"] = {
                Position = Vector3.new(-4807, 21, 4360),
                Quest = { "MarineQuest2", CFrame.new(-5035, 29, 4326), 2 },
                Level = 130,
            },
            ["Warden"] = {
                Position = Vector3.new(5230, 4, 749),
                Quest = { "ImpelQuest", CFrame.new(5191, 4, 692), 1 },
                Level = 220,
            },
            ["Chief Warden"] = {
                Position = Vector3.new(5230, 4, 749),
                Quest = { "ImpelQuest", CFrame.new(5191, 4, 692), 2 },
                Level = 230,
            },
            ["Swan"] = {
                Position = Vector3.new(5230, 4, 749),
                Quest = { "ImpelQuest", CFrame.new(5191, 4, 692) },
                Level = 240,
            },
            ["Magma Admiral"] = {
                Position = Vector3.new(-5694, 18, 8735),
                Quest = { "MagmaQuest", CFrame.new(-5319, 12, 8515) },
                Level = 350,
            },
            ["Fishman Lord"] = {
                Position = Vector3.new(61350, 31, 1095),
                Quest = { "FishmanQuest", CFrame.new(61122, 18, 1567) },
                Level = 425,
            },
            ["Wysper"] = {
                Position = Vector3.new(-7927, 5551, -637),
                Quest = { "SkyExp1Quest", CFrame.new(-7861, 5545, -381) },
                Level = 500,
            },
            ["Thunder God"] = {
                Position = Vector3.new(-7751, 5607, -2315),
                Quest = { "SkyExp2Quest", CFrame.new(-7903, 5636, -1412) },
                Level = 575,
            },
            ["Cyborg"] = {
                Position = Vector3.new(6138, 10, 3939),
                Quest = { "FountainQuest", CFrame.new(5258, 39, 4052) },
                Level = 675,
            },
        },

        {
            ["Diamond"] = {
                Position = Vector3.new(-1569, 199, -31),
                Quest = { "Area1Quest", CFrame.new(-427, 73, 1835) },
                Level = 750,
            },
            ["Jeremy"] = {
                Position = Vector3.new(2316, 449, 787),
                Quest = { "Area2Quest", CFrame.new(635, 73, 919) },
                Level = 850,
            },
            ["Orbitus"] = {
                Position = Vector3.new(-2086, 73, -4208),
                Quest = { "MarineQuest3", CFrame.new(-2441, 73, -3219) },
                Level = 925,
            },
            ["Smoke Admiral"] = {
                Position = Vector3.new(-5078, 24, -5352),
                Quest = { "IceSideQuest", CFrame.new(-6061, 16, -4904) },
                Level = 1150,
            },
            ["Awakened Ice Admiral"] = {
                Position = Vector3.new(6473, 297, -6944),
                Quest = { "FrostQuest", CFrame.new(5668, 28, -6484) },
                Level = 1400,
            },
            ["Tide Keeper"] = {
                Position = Vector3.new(-3711, 77, -11469),
                Quest = { "ForgottenQuest", CFrame.new(-3056, 240, -10145) },
                Level = 1475,
            },
        },

        {
            ["Stone"] = {
                Position = Vector3.new(-1049, 40, 6791),
                Quest = { "PiratePortQuest", CFrame.new(-449, 109, 5950) },
                Level = 1550,
            },
            ["Hydra Leader"] = {
                Position = Vector3.new(5836, 1019, -83),
                Quest = { "VenomCrewQuest", CFrame.new(5214, 1004, 761) },
                Level = 1675,
            },
            ["Kilo Admiral"] = {
                Position = Vector3.new(2904, 509, -7349),
                Quest = { "MarineTreeIsland", CFrame.new(2485, 74, -6788) },
                Level = 1750,
            },
            ["Captain Elephant"] = {
                Position = Vector3.new(-13393, 319, -8423),
                Quest = { "DeepForestIsland", CFrame.new(-13233, 332, -7626) },
                Level = 1875,
            },
            ["Beautiful Pirate"] = {
                Position = Vector3.new(5370, 22, -89),
                Quest = { "DeepForestIsland2", CFrame.new(-12682, 391, -9901) },
                Level = 1950,
            },
            ["Cake Queen"] = {
                Position = Vector3.new(-710, 382, -11150),
                Quest = { "IceCreamIslandQuest", CFrame.new(-818, 66, -10964) },
                Level = 2175,
            },
        },
    }
    
    DataModule.Gates = {
        {
            ["Under Water"] = Vector3.new(61163, 5, 1819),
            ["Sky 1"] = Vector3.new(-4607, 872, -1667),
            ["Sky 2"] = Vector3.new(-7894, 5545, -380),
            ["Gate"] = Vector3.new(3860, 26, -1780)
        },
        {
            ["Out Ghost Ship"] = Vector3.new(-6505, 125, -130),
            ["Ghost Ship"] = Vector3.new(923, 125, 32852),
            ["Mansion"] = Vector3.new(-288, 200, 611),
            ["Swan"] = Vector3.new(2283, 60, 905)
        },
        {
            ["Castle on the Sea"] = Vector3.new(-5100, 450, -3250),
            ["Mansion"] = Vector3.new(-12540, 333, -7600),
            ["Hydra"] = Vector3.new(5750, 1120, -338)
        },
    }
end

DataModule.Currently = {
    Materials = DataModule.Materials[Sea],
    Islands = DataModule.Islands[Sea],
    Places = DataModule.Places[Sea],
    Bosses = DataModule.Bosses[Sea],
    Gates = DataModule.Gates[Sea]
}

function DataModule:GetNames(Name)
    local List = {}

    for Key in self.Currently[Name] do
        List[#List + 1] = Key
    end

    return List
end

do
    DataModule.MaterialNames = DataModule:GetNames("Materials")
    DataModule.IslandNames = DataModule:GetNames("Islands")
    DataModule.PlaceNames = DataModule:GetNames("Places")
    DataModule.BosseNames = DataModule:GetNames("Bosses")
    DataModule.GateNames = DataModule:GetNames("Gates")
end

return DataModule