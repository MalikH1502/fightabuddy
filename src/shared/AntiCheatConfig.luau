local AntiCheatConfig = {}

-- Rate limiting settings
AntiCheatConfig.PUNCH_COOLDOWN = 0.6 -- Minimum time between punches
AntiCheatConfig.MAX_PUNCHES_PER_SECOND = 2
AntiCheatConfig.BURST_WINDOW = 5 -- Time window to check for bursts

-- Distance and validation settings
AntiCheatConfig.MAX_PUNCH_DISTANCE = 15 -- Maximum distance for a valid punch
AntiCheatConfig.MAX_HIT_DISTANCE = 4 -- Maximum distance for hit detection
AntiCheatConfig.MIN_DAMAGE = 1
AntiCheatConfig.MAX_DAMAGE = 200

-- Punishment settings
AntiCheatConfig.WARNING_THRESHOLD = 3 -- Warnings before kick
AntiCheatConfig.KICK_THRESHOLD = 5 -- Violations before kick
AntiCheatConfig.BAN_THRESHOLD = 10 -- Total violations before ban consideration

-- Logging
AntiCheatConfig.LOG_VIOLATIONS = true
AntiCheatConfig.NOTIFY_ADMINS = true

return AntiCheatConfig