local _, ns = ...

-- enUS is the canonical key set. Strings are keyed by their English text, so this
-- file just needs to exist (the metatable in Locales.lua falls back to the key
-- when no override is present). We still register an empty table so Locales.lua
-- can pick enUS as the active locale on English clients without warnings.
ns.RegisterLocale("enUS", {})
