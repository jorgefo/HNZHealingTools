local _, ns = ...

-- Locale dispatcher.
-- Las claves son el texto en ingles. Si GetLocale() (o el override del usuario)
-- no tiene entrada para una clave, la metatable devuelve la clave misma, asi
-- que la UI cae a ingles en lugar de quedar en blanco.
ns.L = setmetatable({}, { __index = function(_, key) return key end })

-- Las tablas por-locale se registran aqui desde Locales/<locale>.lua via
-- ns.RegisterLocale. ApplyLocale() consume el registro despues de que todos
-- los archivos de locale hayan corrido (deferido a ADDON_LOADED en Core.lua,
-- ya que SavedVariables.general.language puede sobrescribir GetLocale()).
ns.LocaleTables = {}

-- Mapeo de codigos de cliente a tablas que comparten idioma. Los clientes
-- regionales (esMX, ptPT) no tienen tabla propia pero comparten texto con
-- esES / ptBR respectivamente.
ns.LocaleAliases = {
    esMX = "esES",
    ptPT = "ptBR",
}

function ns.RegisterLocale(localeCode, tbl)
    ns.LocaleTables[localeCode] = tbl
end

-- Lista de idiomas seleccionables manualmente desde el menu General. Se expone
-- publicamente para que Config.lua arme el dropdown sin duplicar la lista.
ns.LOCALE_OPTIONS = {
    { value = "auto",  label = "Auto (client)" },
    { value = "enUS",  label = "English" },
    { value = "esES",  label = "Espanol" },
    { value = "deDE",  label = "Deutsch" },
    { value = "frFR",  label = "Francais" },
    { value = "koKR",  label = "Hangugeo" },
    { value = "ptBR",  label = "Portugues" },
    { value = "ruRU",  label = "Russkiy" },
    { value = "zhCN",  label = "Zhongwen" },
}

-- Determina el locale activo. Prioridad:
--   1) Override del usuario en HNZHealingToolsDB.general.language
--   2) GetLocale() del cliente (con alias para variantes regionales)
--   3) Fallback a enUS
function ns.GetActiveLocale()
    local override = HNZHealingToolsDB and HNZHealingToolsDB.general and HNZHealingToolsDB.general.language
    if override and override ~= "auto" and ns.LocaleTables[override] then
        return override
    end
    local sys = (GetLocale and GetLocale()) or "enUS"
    sys = ns.LocaleAliases[sys] or sys
    if ns.LocaleTables[sys] then return sys end
    return "enUS"
end

-- Reaplica el locale activo. Llamarse:
--   - desde Core.lua en ADDON_LOADED, despues de inicializar SavedVariables.
--   - cuando el usuario cambia el idioma desde el menu General (y luego /reload
--     para refrescar widgets ya construidos).
function ns.ApplyLocale()
    -- Limpia traducciones previas para que cambiar de idioma no deje residuos
    -- de claves que existian en la tabla anterior pero no en la nueva.
    for k in pairs(ns.L) do ns.L[k] = nil end
    local active = ns.GetActiveLocale()
    local tbl = ns.LocaleTables[active]
    if not tbl then return end
    for k, v in pairs(tbl) do
        if type(v) == "string" then ns.L[k] = v end
    end
end
