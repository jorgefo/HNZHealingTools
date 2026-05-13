# HNZ Healing Tools — Release 1.3.0

**Fecha:** 2026-05-13
**Interface:** 120005 (Retail 12.0.5)

---

## Resumen

Release con foco en mejorar la experiencia de configuracion: cada modulo trae un **live preview** integrado en su pagina de Config, ahora se puede **reordenar** las listas de Cursor Spells/Auras con flechas, hay un **boton Test** por entry para ver como se ve el icono al lado del cursor real, la **ventana de config es redimensionable**, y al actualizar el addon aparece un popup de **What's New** con las novedades. Tambien incluye un fix importante para el pulse de MRT/NSRT cuando la visibility del modulo Pulse no era `always`.

---

## Nuevas funcionalidades

### Live preview en el config
Cada modulo (Ring / Pulse / Cursor Ring / Cursor Icons) muestra un preview animado al pie de su pagina con datos de muestra renderizados con los settings actuales. Cualquier slider, dropdown o color picker actualiza el preview al instante — no hay que cerrar el menu para ver el resultado.

### Reordenar entries en Cursor Spells / Auras
Flechas arriba/abajo en cada fila de las listas de hechizos y auras del cursor. El orden define como aparecen los iconos junto al cursor en el juego. Las flechas vienen como textura custom incluida en el addon (`Textures/arrow_up.tga`), no dependen de built-ins.

### Boton Test (T) por entry de Cursor
Cada fila de Cursor Spells / Cursor Auras tiene un boton "T" que fuerza al icono a aparecer junto al cursor real durante 5 segundos. Util para previsualizar como se ve un hechizo o aura sin tener que castearlo o esperar a que aplique. Bypass de todos los gates (display disabled / out-of-combat / lista vacia).

### Ventana de config redimensionable
Drag handle en la esquina inferior derecha para cambiar el tamano manualmente. Rango: 720x420 (minimo) a 1600x1080 (maximo). El tamano se persiste por profile en `db.configWindow` y se restaura al abrir el menu.

### Popup What's New
Al actualizar el addon, aparece una vez al login con las notas de la version nueva. Estado persistido account-wide en `HNZHealingToolsDB.lastSeenVersion`, asi los alts no ven el popup repetido. Si pasas mas de una version sin abrir el juego, te muestra todas las versiones intermedias.

---

## Cambios

### Selector de formato MRT/NSRT con botones radio
En el editor de notas, el dropdown que elegia entre formato MRT y NSRT se reemplazo por dos botones tipo radio (NSRT a la izquierda, MRT a la derecha). El boton activo se resalta con el color de acento del addon. **NSRT pasa a ser el default** al crear una nota nueva — alineado con el flujo mas comun: pegar una nota de NSRT con header `EncounterID:` y dejar que el auto-detect llene el ID y el nombre del encuentro.

---

## Bugs corregidos

### Pulse de MRT/NSRT no aparecia con visibility distinto a "always"
El bypass que pasa `MrtTimeline` a `ShowPulse` saltaba solo el toggle `enabled` del modulo Cooldown Pulse, pero no el gate de visibility (`combat` / `ooc`). Si tu `cooldownPulse.visibility` era `"combat"` (default para perfiles migrados desde el viejo `showOnlyInCombat = true`) y probabas la nota fuera de combate con el boton Test, el pulse nunca aparecia aunque la checkbox "Show MRT/NSRT triggers" estuviera marcada.

Ahora `bypassEnabled = true` saltea ambos gates. Justificacion: MRT/NSRT solo dispara durante encounters reales (in-combat por definicion), y la checkbox "Show MRT/NSRT triggers" del modulo Pulse ya es un opt-in explicito del usuario — la visibility del modulo cooldown pulse no deberia pisar esa decision.

---

## Notas tecnicas

- Nuevo campo en `PROFILE_DEFAULTS`: `configWindow = { width = 900, height = 560 }`. No requiere migration; los profiles existentes lo reciben en el merge inicial.
- Nuevo archivo cargado al final del flujo de boot: `WhatsNew.lua`. Registrado en el TOC despues de `Config.lua`.
- Helper `RegisterPreview(slug, fn)` para que cada modulo exponga su preview al config sin acoplar Config.lua a internals de cada modulo.

---

## Compatibilidad

- WoW Retail 12.0.5 (Interface 120005).
- Profiles de versiones anteriores se actualizan en el primer login (merge de defaults). No requiere intervencion manual.
- Backups automaticos pre-migracion (ver pagina Profiles -> Backups en el config).
