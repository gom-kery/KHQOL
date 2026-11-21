-- Forever item-distance data from LibRangeCheck-3.0, bundled in RangeDisplay 6.3.7.
-- Copyright (c) 2023 The WoWUIDev Community. MIT license in LibRangeCheck-LICENSE.txt.
local K=_G.KHQOL
local FriendItems,HarmItems
FriendItems = {
    [5] = {
      1970,   -- Restoring Balm
      8149,   -- Voodoo Charm
      15826,  -- Curative Animal Salve
      16308,  -- Northridge Crowbar
      16991,  -- Triage Bandage
      17117,  -- Rat Catcher's Flute
      20403,  -- Proxy of Nozdormu
      22259,  -- Unbestowed Friendship Bracelet
      208855, -- Rainbow Fin Albacore Chum
      209027, -- Crab Treats
      209057, -- Prototype Engine
      213036, -- Water of Elune'ara
      221199, -- Satyrweed Tincture
      225943, -- Rancid Hunk of Flesh
    },
    [10] = {
      17626,  -- Frostwolf Muzzle
      17689,  -- Stormpike Training Collar
      21267,  -- Toasting Goblet
      23164,  -- Bubbly Beverage
      226207, -- Echo of Anastari
      226208, -- Echo of Barthilas
      226209, -- Echo of Dathrohan
      226210, -- Echo of Maleki
      226211, -- Echo of Nerub'enkan
      226212, -- Echo of Ramstein
      226213, -- Echo of Rivendare
      226214, -- Echo of Willey
    },
    [15] = {
      1251,   -- Linen Bandage
      2581,   -- Heavy Linen Bandage
      3530,   -- Wool Bandage
      3531,   -- Heavy Wool Bandage
      6450,   -- Silk Bandage
      6451,   -- Heavy Silk Bandage
      8544,   -- Mageweave Bandage
      8545,   -- Heavy Mageweave Bandage
      14529,  -- Runecloth Bandage
      14530,  -- Heavy Runecloth Bandage
      19066,  -- Warsong Gulch Runecloth Bandage
      19067,  -- Warsong Gulch Mageweave Bandage
      19068,  -- Warsong Gulch Silk Bandage
      19307,  -- Alterac Heavy Runecloth Bandage
      20065,  -- Arathi Basin Mageweave Bandage
      20066,  -- Arathi Basin Runecloth Bandage
      20067,  -- Arathi Basin Silk Bandage
      20232,  -- Defiler's Mageweave Bandage
      20234,  -- Defiler's Runecloth Bandage
      20235,  -- Defiler's Silk Bandage
      20237,  -- Highlander's Mageweave Bandage
      20243,  -- Highlander's Runecloth Bandage
      20244,  -- Highlander's Silk Bandage
      23684,  -- Crystal Infused Bandage
      232433, -- Dense Runecloth Bandage
    },
    [20] = {
      12450,  -- Juju Flurry
      12451,  -- Juju Power
      12455,  -- Juju Ember
      12457,  -- Juju Chill
      12458,  -- Juju Guile
      12460,  -- Juju Might
      17757,  -- Amulet of Spirits
      21519,  -- Mistletoe
      219963, -- Deputization Authorization: Duskwood Mission I
      219965, -- Deputization Authorization: Duskwood Mission II
      219983, -- Deputization Authorization: Duskwood Mission III
      219984, -- Deputization Authorization: Duskwood Mission IV
      219985, -- Deputization Authorization: Duskwood Mission V
      219986, -- Deputization Authorization: Duskwood Mission VI
      219987, -- Deputization Authorization: Duskwood Mission VII
      219988, -- Deputization Authorization: Duskwood Mission VIII
      219989, -- Deputization Authorization: Duskwood Mission IX
      219990, -- Deputization Authorization: Duskwood Mission X
      219991, -- Deputization Authorization: Duskwood Mission XI
      219992, -- Deputization Authorization: Duskwood Mission XII
      219993, -- Deputization Authorization: Duskwood Mission XIII
      219994, -- Deputization Authorization: Duskwood Mission XIV
      219995, -- Deputization Authorization: Duskwood Mission XV
      219996, -- Deputization Authorization: Duskwood Mission XVI
      219997, -- Deputization Authorization: Duskwood Mission XVII
      219998, -- Deputization Authorization: Duskwood Mission XVIII
      220053, -- Deputization Authorization: Ashenvale Mission I
      220054, -- Deputization Authorization: Ashenvale Mission II
      220055, -- Deputization Authorization: Ashenvale Mission III
      220056, -- Deputization Authorization: Ashenvale Mission IV
      220057, -- Deputization Authorization: Ashenvale Mission V
      220058, -- Deputization Authorization: Ashenvale Mission VI
      220059, -- Deputization Authorization: Ashenvale Mission VII
      220060, -- Deputization Authorization: Ashenvale Mission VIII
      220061, -- Deputization Authorization: Ashenvale Mission IX
      220062, -- Deputization Authorization: Ashenvale Mission X
      220063, -- Deputization Authorization: Ashenvale Mission XI
      220064, -- Deputization Authorization: Ashenvale Mission XII
      220065, -- Deputization Authorization: Ashenvale Mission XIII
      220066, -- Deputization Authorization: Ashenvale Mission XIV
      220067, -- Deputization Authorization: Ashenvale Mission XV
      220068, -- Deputization Authorization: Ashenvale Mission XVI
      220069, -- Deputization Authorization: Ashenvale Mission XVII
      220070, -- Deputization Authorization: Ashenvale Mission XVIII
      220071, -- Deputization Authorization: Hinterlands Mission I
      220072, -- Deputization Authorization: Hinterlands Mission II
      220073, -- Deputization Authorization: Hinterlands Mission III
      220074, -- Deputization Authorization: Hinterlands Mission IV
      220075, -- Deputization Authorization: Hinterlands Mission V
      220076, -- Deputization Authorization: Hinterlands Mission VI
      220077, -- Deputization Authorization: Hinterlands Mission VII
      220078, -- Deputization Authorization: Hinterlands Mission VIII
      220079, -- Deputization Authorization: Hinterlands Mission IX
      220080, -- Deputization Authorization: Hinterlands Mission X
      220081, -- Deputization Authorization: Hinterlands Mission XI
      220082, -- Deputization Authorization: Hinterlands Mission XII
      220083, -- Deputization Authorization: Hinterlands Mission XIII
      220084, -- Deputization Authorization: Hinterlands Mission XIV
      220085, -- Deputization Authorization: Hinterlands Mission XV
      220086, -- Deputization Authorization: Hinterlands Mission XVI
      220087, -- Deputization Authorization: Hinterlands Mission XVII
      220088, -- Deputization Authorization: Hinterlands Mission XVIII
      220089, -- Deputization Authorization: Feralas Mission I
      220090, -- Deputization Authorization: Feralas Mission II
      220091, -- Deputization Authorization: Feralas Mission III
      220092, -- Deputization Authorization: Feralas Mission IV
      220093, -- Deputization Authorization: Feralas Mission V
      220094, -- Deputization Authorization: Feralas Mission VI
      220095, -- Deputization Authorization: Feralas Mission VII
      220096, -- Deputization Authorization: Feralas Mission VIII
      220097, -- Deputization Authorization: Feralas Mission IX
      220098, -- Deputization Authorization: Feralas Mission X
      220099, -- Deputization Authorization: Feralas Mission XI
      220100, -- Deputization Authorization: Feralas Mission XII
      220101, -- Deputization Authorization: Feralas Mission XIII
      220102, -- Deputization Authorization: Feralas Mission XIV
      220103, -- Deputization Authorization: Feralas Mission XV
      220104, -- Deputization Authorization: Feralas Mission XVI
      220105, -- Deputization Authorization: Feralas Mission XVII
      220106, -- Deputization Authorization: Feralas Mission XVIII
      220792, -- Scroll of Spatial Mending
      223168, -- Worldcore Fragment
      223171, -- Scroll of Geomancy
      224806, -- Legion Portal Tuner
      224893, -- Overcharged Portal Tuner
      231298, -- Scroll of Lesser Spatial Mending
      231836, -- Glowing Scroll of Spatial Mending
      232344, -- Vick's VIP Pass
    },
    [25] = {
      13289,  -- Egan's Blaster
    },
    [30] = {
      954,    -- Scroll of Strength
      955,    -- Scroll of Intellect
      1180,   -- Scroll of Stamina
      1181,   -- Scroll of Spirit
      1477,   -- Scroll of Agility II
      1478,   -- Scroll of Protection II
      1711,   -- Scroll of Stamina II
      1712,   -- Scroll of Spirit II
      1851,   -- Cleansing Water
      1912,   -- Deprecated Reed Pipe
      2289,   -- Scroll of Strength II
      2290,   -- Scroll of Intellect II
      2948,   -- Deprecated Talisman of Cleansing
      3012,   -- Scroll of Agility
      3013,   -- Scroll of Protection
      4381,   -- Minor Recombobulator
      4419,   -- Scroll of Intellect III
      4421,   -- Scroll of Protection III
      4422,   -- Scroll of Stamina III
      4424,   -- Scroll of Spirit III
      4425,   -- Scroll of Agility III
      4426,   -- Scroll of Strength III
      4444,   -- Black Husk Shield
      5232,   -- Minor Soulstone
      5613,   -- Staff of the Purifier
      6452,   -- Anti-Venom
      6453,   -- Strong Anti-Venom
      10305,  -- Scroll of Protection IV
      10306,  -- Scroll of Spirit IV
      10307,  -- Scroll of Stamina IV
      10308,  -- Scroll of Intellect IV
      10309,  -- Scroll of Agility IV
      10310,  -- Scroll of Strength IV
      11563,  -- Crystal Force
      11564,  -- Crystal Ward
      11567,  -- Crystal Spire
      16892,  -- Lesser Soulstone
      16893,  -- Soulstone
      16895,  -- Greater Soulstone
      16896,  -- Major Soulstone
      17202,  -- Snowball
      17310,  -- Aspect of Neptulon
      18637,  -- Major Recombobulator
      19440,  -- Powerful Anti-Venom
      20908,  -- Festival of Nian Firework
      21038,  -- Hardpacked Snowball
      21713,  -- Elune's Candle
      22200,  -- Silver Shafted Arrow
      22206,  -- Bouquet of Red Roses
      22218,  -- Handful of Rose Petals
    },
    [35] = {
      18904,  -- Zorbin's Ultra-Shrinker
    },
    [40] = {
      1713,   -- Ankh of Life
      5205,   -- Sprouted Frond
      5323,   -- Everglow Lantern
      8346,   -- Gauntlets of the Sea
      11562,  -- Crystal Restore
      18640,  -- Happy Fun Rock
      18662,  -- Heavy Leather Ball
      213349, -- Gniodine Pill Bottle
      216500, -- Bloodbonded Grove Talisman
      216503, -- Bloodstorm Jewel
      216517, -- Sanguine Sanctuary
      216607, -- Bloodlight Offering
      230280, -- Aegis of Preservation
    },
    [45] = {
      221316, -- Premo's Poise-Demanding Uniform
    },
    [50] = {
      221315, -- Rainbow Generator
    },
    [100] = {
      5418,   -- Weapon of Mass Destruction (test)
      17162,  -- Eric Test Item A
      23715,  -- Permanent Lung Juice Cocktail
      23718,  -- Permanent Ground Scorpok Assay
      23719,  -- Permanent Cerebral Cortex Compound
      23721,  -- Permanent Gizzard Gum
      23722,  -- Permanent R.O.I.D.S.
      227685, -- Modified Shadow Scalpel
    },
    -- [50000] = {
    --   228227, -- Scroll of Overwhelming Power
    -- },
  }
HarmItems = {
    [5] = {
      8149,   -- Voodoo Charm
      15826,  -- Curative Animal Salve
      16308,  -- Northridge Crowbar
      17117,  -- Rat Catcher's Flute
      22259,  -- Unbestowed Friendship Bracelet
      22432,  -- Devilsaur Barb
      206466, -- Prairie Crown
      208760, -- Glade Crown
      208855, -- Rainbow Fin Albacore Chum
      209027, -- Crab Treats
      209057, -- Prototype Engine
      213036, -- Water of Elune'ara
      221199, -- Satyrweed Tincture
      225943, -- Rancid Hunk of Flesh
    },
    [10] = {
      9606,   -- Treant Muisek Vessel
      9618,   -- Wildkin Muisek Vessel
      9619,   -- Hippogryph Muisek Vessel
      9620,   -- Faerie Dragon Muisek Vessel
      9621,   -- Mountain Giant Muisek Vessel
      10699,  -- Yeh'kinya's Bramble
      17626,  -- Frostwolf Muzzle
      17689,  -- Stormpike Training Collar
      226472, -- Stratholme Shadow Jar
    },
    [15] = {
      4559,   -- CHU's QUEST ITEM
    },
    [20] = {
      1191,   -- Bag of Marbles
      2012,   -- Deprecated Phylactery of Rot
      4388,   -- Discombobulator Ray
      10645,  -- Gnomish Death Ray
      13892,  -- Kodo Kombobulator
      17757,  -- Amulet of Spirits
      18209,  -- Energized Sparkplug
      22048,  -- Lord Valthalak's Amulet
      202251, -- Bag of Pet Treats
      227936, -- Diplomat Ring
      232344, -- Vick's VIP Pass
    },
    [25] = {
      13289,  -- Egan's Blaster
    },
    [30] = {
      835,    -- Large Rope Net
      1404,   -- Tidal Charm
      1434,   -- Glowing Wax Stick
      1444,   -- Deprecated Inferno Stone
      1472,   -- Deprecated Polished Lakestone Charm
      1704,   -- Deprecated Cold Basilisk Eye
      1854,   -- Deprecated Brooch of the Night Watch
      1914,   -- Deprecated Miniature Silver Hammer
      1995,   -- Deprecated Cat's Paw
      2091,   -- Magic Dust
      3434,   -- Slumber Sand
      3441,   -- Deprecated Crippling Agent
      4479,   -- Burning Charm
      4480,   -- Thundering Charm
      4481,   -- Cresting Charm
      4941,   -- Really Sticky Glue
      5079,   -- Cold Basilisk Eye
      5457,   -- Severed Voodoo Claw
      6436,   -- Burning Gem
      7344,   -- Torch of Holy Flame
      7734,   -- Six Demon Bag
      9328,   -- Super Snapper FX
      9394,   -- Horned Viking Helmet
      10588,  -- Goblin Rocket Helmet
      10716,  -- Gnomish Shrink Ray
      10720,  -- Gnomish Net-o-Matic Projector
      11170,  -- Deprecated Silver Totem of Aquementas
      11522,  -- Silver Totem of Aquementas
      11565,  -- Crystal Yield
      12288,  -- Encased Corrupt Ooze
      12646,  -- Infus Emerald
      12647,  -- Felhas Ruby
      13213,  -- Smolderweb's Eye
      13509,  -- Clutch of Foresight
      13514,  -- Wail of the Banshee
      17202,  -- Snowball
      17310,  -- Aspect of Neptulon
      20084,  -- Hunting Net
      20908,  -- Festival of Nian Firework
      21038,  -- Hardpacked Snowball
      21713,  -- Elune's Candle
      22200,  -- Silver Shafted Arrow
      22206,  -- Bouquet of Red Roses
      22218,  -- Handful of Rose Petals
      220649, -- Merithra's Inheritence
      228576, -- Smolderweb's Eye
      233226, -- Ancient Zandalarian Rope
    },
    [35] = {
      1258,   -- Bind On Use Test Item
      1399,   -- Magic Candle
      1402,   -- Brimstone
      8688,   -- Bind On Acquire Test Item
      18904,  -- Zorbin's Ultra-Shrinker
      220568, -- Temple Explorer's Gun Axe
      233216, -- Freez-O-Matic Ray
    },
    [40] = {
      4945,   -- Faintly Glowing Skull
      8348,   -- Helm of Fire
      191414, -- Skeletal Artifact
      208773, -- Fishing Harpoon
      208843, -- Battle Totem
      209047, -- Gnarled Harpoon
    },
    [45] = {
      221316, -- Premo's Poise-Demanding Uniform
    },
    [100] = {
      5418,   -- Weapon of Mass Destruction (test)
      17162,  -- Eric Test Item A
      23715,  -- Permanent Lung Juice Cocktail
      23718,  -- Permanent Ground Scorpok Assay
      23719,  -- Permanent Cerebral Cortex Compound
      23721,  -- Permanent Gizzard Gum
      23722,  -- Permanent R.O.I.D.S.
      227685, -- Modified Shadow Scalpel
    },
    -- [50000] = {
    --   228227, -- Scroll of Overwhelming Power
    -- },
  }
K.modules.range.distanceItems={friend=FriendItems,harm=HarmItems}
