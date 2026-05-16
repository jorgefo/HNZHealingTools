local _, ns = ...

-- Русский перевод (ruRU). Ключами служат английские UI-строки из ns.L[...].
-- Если ключ отсутствует, metatable из Locales.lua вернёт английский текст.
ns.RegisterLocale("ruRU", {
    -- ===== Сообщения об ошибках / уведомления =====
    ["Spell not found: "] = "Заклинание не найдено: ",
    [" already monitored."] = " уже отслеживается.",
    ["Enter a name/ID."] = "Введите имя/ID.",
    ["Enter a name."] = "Введите имя.",
    ["Already exists."] = "Уже существует.",
    ["Created: "] = "Создано: ",
    ["Can't copy to itself."] = "Нельзя копировать в самого себя.",
    ["Copied from "] = "Скопировано из ",
    ["Give the profile a name."] = "Задайте имя профилю.",
    ["Paste the exported string in the box."] = "Вставьте экспортированную строку в поле.",
    ["Imported as: "] = "Импортировано как: ",
    ["Import failed."] = "Ошибка импорта.",
    ["Ready: Ctrl+C to copy"] = "Готово: Ctrl+C для копирования",
    ["No active profile to export"] = "Нет активного профиля для экспорта",

    -- ===== Стандартные кнопки =====
    ["Save"] = "Сохранить",
    ["Cancel"] = "Отмена",
    ["Add"] = "Добавить",
    ["Update"] = "Обновить",
    ["Close"] = "Закрыть",
    ["Edit"] = "Изменить",
    ["Test"] = "Тест",
    ["Create"] = "Создать",
    ["Load"] = "Загрузить",
    ["Export"] = "Экспорт",
    ["Import"] = "Импорт",
    ["Copy to current"] = "Скопировать в текущий",

    -- ===== Вкладки / заголовки страниц =====
    ["Cursor Spells"] = "Заклинания у курсора",
    ["Cursor Auras"] = "Ауры у курсора",
    ["Ring Auras"] = "Ауры на кольце",
    ["Cursor Config"] = "Настр. курсора",
    ["Ring Config"] = "Настр. кольца",
    ["Profiles"] = "Профили",

    -- ===== Редакторы: заголовки и метки =====
    ["Cursor Spell"] = "Заклинание у курсора",
    ["Cursor Aura"] = "Аура у курсора",
    ["Ring Aura"] = "Аура на кольце",
    ["New Cursor Spell"] = "Новое заклинание у курсора",
    ["New Cursor Aura"] = "Новая аура у курсора",
    ["New Ring Aura"] = "Новая аура на кольце",
    ["Editing: "] = "Редактирование: ",
    ["Spell name or ID:"] = "Имя заклинания или ID:",
    ["Aura name or ID:"] = "Имя ауры или ID:",
    ["Show only when charges >=  (0=always):"] = "Показывать только когда зарядов >=  (0=всегда):",
    ["Stack text size (0=default):"] = "Размер текста стаков (0=по умолчанию):",
    ["Hide while on cooldown"] = "Скрывать во время восстановления",
    ["Hide status overlay"] = "Скрывать индикатор состояния",
    ["Hide cooldown / duration timer"] = "Скрывать таймер восст./длительности",
    ["Hide timer"] = "Скрывать таймер",
    ["Specs:"] = "Специализации:",
    ["Required talent:"] = "Требуемый талант:",
    ["Unit:"] = "Цель:",
    ["Type:"] = "Тип:",
    ["Show:"] = "Показывать:",
    ["Min stacks:"] = "Мин. стаков:",
    ["Duration (sec, 0=auto):"] = "Длительность (сек, 0=авто):",
    ["Color:"] = "Цвет:",
    ["Show icon on ring"] = "Показывать значок на кольце",
    ["Play sound on activation"] = "Звук при активации",
    ["Pulse icon at screen center on ready"] = "Пульс значка в центре экрана при готовности",
    ["Pulse icon at screen center on activation"] = "Пульс значка в центре экрана при активации",
    ["Play sound on ready"] = "Воспроизводить звук при готовности",
    ["Pulse Display Settings"] = "Настройки пульса",
    ["Pulse Config"] = "Пульс",
    ["Size & Timing"] = "Размер и время",
    ["Hold Duration"] = "Длительность показа",
    ["Enable cooldown pulse"] = "Включить пульс перезарядки",
    ["Show anchor"] = "Показать якорь",
    ["Hide anchor"] = "Скрыть якорь",
    ["Test pulse"] = "Проверить пульс",
    ["Drag to move"] = "Перетащите для перемещения",

    -- ===== TalentPicker =====
    ["[No talent]"] = "[Нет таланта]",
    ["Select a talent"] = "Выберите талант",
    ["search"] = "поиск",
    ["(no talents in this loadout)"] = "(нет талантов в этой раскладке)",

    -- ===== SoundPicker =====
    ["Select a sound"] = "Выберите звук",

    -- ===== DropZone =====
    ["Drag a spell here"] = "Перетащите заклинание сюда",

    -- ===== Выпадающие списки: цели / фильтры / showWhen =====
    ["Target"] = "Цель",
    ["Player"] = "Игрок",
    ["Focus"] = "Фокус",
    ["Mouseover"] = "Под курсором",
    ["Pet"] = "Питомец",
    ["Buff"] = "Бафф",
    ["Debuff"] = "Дебафф",
    ["Always"] = "Всегда",
    ["Only missing"] = "Только если отсутствует",
    ["Only active"] = "Только если активно",
    ["Active only"] = "Только если активно",
    ["Missing only"] = "Только если отсутствует",
    ["Below stacks"] = "Меньше стаков",

    -- ===== Строки списка (значки) =====
    ["Unknown"] = "Неизвестно",
    ["Min:"] = "Мин:",
    ["Hide CD"] = "Без КД",
    ["Talent"] = "Талант",
    ["[icon]"] = "[значок]",

    -- ===== Пустые состояния / подсказки =====
    ["No spells. Use 'Add Cursor Spell...' below."] = "Нет заклинаний. Используйте 'Добавить заклинание у курсора...' ниже.",
    ["No auras. Use 'Add Cursor Aura...' below."] = "Нет аур. Используйте 'Добавить ауру у курсора...' ниже.",
    ["No ring auras. Use 'Add Ring Aura...' below."] = "Нет аур на кольце. Используйте 'Добавить ауру на кольце...' ниже.",
    ["Spells shown as icons near the mouse cursor. Click the gear to edit."] = "Заклинания показываются значками рядом с курсором. Нажмите на шестерёнку для редактирования.",
    ["Auras shown as icons near the mouse cursor. Click the gear to edit."] = "Ауры показываются значками рядом с курсором. Нажмите на шестерёнку для редактирования.",
    ["Auras shown as circular rings around the character. Click the gear to edit, click color to change."] = "Ауры показываются кольцами вокруг персонажа. Нажмите на шестерёнку для редактирования, нажмите на цвет для смены.",
    ["Add Cursor Spell..."] = "Добавить заклинание у курсора...",
    ["Add Cursor Aura..."] = "Добавить ауру у курсора...",
    ["Add Ring Aura..."] = "Добавить ауру на кольце...",
    ["or drag a spell here:"] = "или перетащите заклинание сюда:",

    -- ===== Настройки курсора =====
    ["Cursor Display Settings"] = "Настройки отображения у курсора",
    ["Size & Layout"] = "Размер и расположение",
    ["Icon Size"] = "Размер значка",
    ["Icon Spacing"] = "Интервал значков",
    ["Max Columns"] = "Макс. колонок",
    ["Font Size"] = "Размер шрифта",
    ["Position"] = "Позиция",
    ["Offset X"] = "Смещение X",
    ["Offset Y"] = "Смещение Y",
    ["Opacity"] = "Прозрачность",
    ["Update Interval"] = "Интервал обновления",
    ["Show only in combat"] = "Показывать только в бою",
    ["Enable cursor display"] = "Включить отображение у курсора",

    -- ===== Настройки кольца =====
    ["Ring Display Settings"] = "Настройки отображения кольца",
    ["Size"] = "Размер",
    ["Base Radius"] = "Базовый радиус",
    ["Ring Thickness"] = "Толщина кольца",
    ["Ring Spacing"] = "Интервал между кольцами",
    ["Appearance"] = "Внешний вид",
    ["Segments (smooth)"] = "Сегменты (сглаживание)",
    ["Enable ring display"] = "Включить отображение кольца",

    -- ===== Профили =====
    ["Profile Manager"] = "Менеджер профилей",
    ["Active: "] = "Активный: ",
    ["(active)"] = "(активный)",
    ["Create New Profile"] = "Создать новый профиль",
    ["Copy From Profile"] = "Копировать из профиля",
    ["Export Current Profile"] = "Экспортировать текущий профиль",
    ["(Press Export then Ctrl+C in the box)"] = "(Нажмите Export, затем Ctrl+C в поле)",
    ["Import Profile"] = "Импортировать профиль",
    ["Name:"] = "Имя:",
    ["(paste below and press Import)"] = "(вставьте ниже и нажмите Import)",

    -- ===== Подсказка миникарты =====
    ["Left click:"] = "Левая кнопка:",
    ["Right click:"] = "Правая кнопка:",
    ["Drag:"] = "Перетаскивание:",
    ["open/close config"] = "открыть/закрыть настройки",
    ["toggle cursor + ring icons"] = "переключить значки курсора + кольца",
    ["move icon"] = "переместить значок",

    -- ===== Сообщение о загрузке =====
    ["loaded"] = "загружен",
    ["Profile:"] = "Профиль:",
    ["Type"] = "Введите",
    ["for options"] = "для опций",

    -- ===== Метки дерева талантов =====
    ["Class"] = "Класс",
    ["Hero"] = "Герой",
    -- "Spec" остаётся как есть.

    -- ===== Changelog / What's New =====
    ["What's New"] = "Что нового",
    ["Got it"] = "Понятно",
    ["Changelog"] = "Журнал изменений",
    ["View release notes for all versions"] = "Показать заметки о выпуске всех версий",

    -- ===== Release notes 1.4.0 =====
    ["Drag trinkets or potions from your bags or equipped slots to the input zone — the addon resolves the use-effect spell ID automatically."] =
        "Перетащите тринкеты или зелья из сумки или экипированных слотов в зону ввода — аддон автоматически определит ID заклинания эффекта использования.",
    ["Per-entry visibility for Cursor Spells and Auras: Always / Only in combat / Only out of combat (independent of the global cursor visibility)."] =
        "Видимость для каждой записи Cursor Spells и Auras: Всегда / Только в бою / Только вне боя (независимо от глобальной видимости курсора).",
    ["Per-entry visual overrides for Cursor Spells and Auras: icon size, opacity, and custom position with offset X/Y (the icon detaches from the grid and floats freely)."] =
        "Визуальные переопределения для каждой записи Cursor Spells и Auras: размер иконки, прозрачность и пользовательская позиция со смещением X/Y (иконка открепляется от сетки и располагается свободно).",
    ["Tabbed editor modals: Cursor Spell and Cursor Aura split into General / Display / Effects; Ring Aura into General / Effects; Pulse Spell and Pulse Aura into General / Sound."] =
        "Модальные редакторы с вкладками: Cursor Spell и Cursor Aura разделены на General / Display / Effects; Ring Aura на General / Effects; Pulse Spell и Pulse Aura на General / Sound.",
    ["Changelog button (?) in the config window title bar — opens this popup with all release notes on demand."] =
        "Кнопка Changelog (?) в заголовке окна настроек — открывает этот попап со всеми заметками о выпуске по требованию.",
    ["Fix: 'Spell not found' when adding via the autocomplete dropdown for spells/auras the character does not know. The autocomplete-resolved spell ID is now preferred over name lookup."] =
        "Исправление: 'Заклинание не найдено' при добавлении через автодополнение для заклинаний/аур, которых персонаж не знает. Теперь ID заклинания из автодополнения имеет приоритет над поиском по имени.",
    ["Fix: creating or switching profiles left some menus showing the old profile's values. Config pages are now rebuilt against the active profile on every switch."] =
        "Исправление: при создании или смене профиля некоторые меню показывали значения старого профиля. Страницы настроек теперь перестраиваются под активный профиль при каждой смене.",

    -- ===== Release notes 1.5.0 =====
    ["Track items as cooldowns: trinkets, potions and on-use consumables can now be added to the Cursor or Pulse list. New 'Add Item...' button + drag-and-drop dispatches by type (spell vs item) and opens the right editor."] =
        "Отслеживание предметов как кулдаунов: безделушки, зелья и расходники с активацией теперь можно добавлять в список Cursor или Pulse. Новая кнопка 'Add Item...' + перетаскивание распределяет по типу (заклинание vs предмет) и открывает нужный редактор.",
    ["Item editors with full tabs (mirror of the Spell editor): General + Display + Effects for cursor items; General + Sound for pulse items. Visual overrides, hide flags, pulse on ready, sound — all available."] =
        "Редакторы предметов с полными вкладками (зеркало редактора Заклинаний): General + Display + Effects для предметов курсора; General + Sound для предметов пульса. Визуальные переопределения, флаги скрытия, пульс при готовности, звук — всё доступно.",
    ["Per-entry instance-type filter on every aura/spell/item editor: restrict tracking to Open World, Delves, PvP (Arena/BG), Raid, Mythic+ and/or Dungeon. Reacts instantly when entering/leaving instances."] =
        "Фильтр по типу инстанса для каждой записи в любом редакторе ауры/заклинания/предмета: ограничить отслеживание Открытым миром, Делвами, PvP (Арена/Поле боя), Рейдом, Мифик+ и/или Подземельем. Реагирует мгновенно при входе/выходе из инстансов.",
    ["Aura detection paths 6 + 7: slot iteration (catches semi-restricted auras Midnight hides from name/ID lookups) + manual trigger workaround (for fully-restricted auras like consumable buffs — configure a trigger spell or item ID and the addon synthesizes the ACTIVE state on cast/use)."] =
        "Пути обнаружения аур 6 + 7: итерация слотов (ловит полу-ограниченные ауры, которые Midnight скрывает от поиска по имени/ID) + ручной триггер обходной (для полностью-ограниченных аур типа баффов расходников — настройте ID заклинания или предмета триггера и аддон синтезирует состояние ACTIVE при касте/использовании).",
    ["New /hht listauras command: prints every active buff/debuff with name + spellID + source + duration. Useful for finding the real spellID of a buff when the guessed one isn't detected."] =
        "Новая команда /hht listauras: выводит каждый активный бафф/дебафф с именем + spellID + источником + длительностью. Полезно для нахождения реального spellID баффа, когда угаданный не обнаруживается.",
    ["Config window no longer closes when opening the Spellbook (PlayerSpellsFrame). ESC still closes it via a custom handler that doesn't break other keybinds."] =
        "Окно настроек больше не закрывается при открытии Книги заклинаний (PlayerSpellsFrame). ESC по-прежнему закрывает его через собственный обработчик, который не ломает другие назначения клавиш.",
    ["Fix: comparing SecureNumber spellId in slot iteration tainted the addon ('attempt to compare a secret number value'). Wrapped in ToPublic + pcall — fully restricted auras are skipped safely instead of crashing the whole frame."] =
        "Исправление: сравнение SecureNumber spellId в итерации слотов заражало аддон ('attempt to compare a secret number value'). Обёрнуто в ToPublic + pcall — полностью-ограниченные ауры безопасно пропускаются вместо краха всего фрейма.",
    ["Fix: ApplyRingVisibility nil call when a ring test entry expired (forward declaration bug, latent since 1.3.0)."] =
        "Исправление: nil вызов ApplyRingVisibility при истечении тестовой записи кольца (баг forward declaration, латентный с 1.3.0).",

    -- ===== Release notes 1.6.0 =====
    ["Macro trigger system: every aura, pulse, and item editor has a new 'Trigger key' field. Fire any configured display from a macro with /hht trigger <key> or from another addon via HNZHealingTools.Trigger(key). Multiple entries can share a key — one keybind fires them all at once."] =
        "Система триггера через макрос: каждый редактор ауры, пульса и предмета имеет новое поле 'Trigger key'. Запускайте любой настроенный дисплей из макроса через /hht trigger <key> или из другого аддона через HNZHealingTools.Trigger(key). Несколько записей могут разделять один ключ — один кейбинд запускает их все сразу.",
    ["New Macros help page in the config sidebar with copy-pasteable macro examples and Lua snippets."] =
        "Новая страница 'Макросы' в боковой панели конфига с копируемыми примерами макросов и Lua-сниппетами.",
    ["Floating preview popup: 'Show preview' button at the top of pages with a Live Preview block (Cursor / Ring / Pulse settings + Cursor Ring sub-tabs). Opens to the right of the config window, single-active across pages, inherits position when switching."] =
        "Плавающее всплывающее окно превью: кнопка 'Показать превью' вверху страниц с блоком Live Preview (настройки Cursor / Ring / Pulse + подвкладки Cursor Ring). Открывается справа от окна конфига, единственное активное между страницами, наследует позицию при переключении.",
    ["Stack count now displays correctly for fully-restricted auras tracked by Blizzard's Cooldown Manager (e.g. Mana Tea). The addon now reads the stack count via the same SetText/GetText technique Blizzard's own CDM viewer uses, so SecureNumber values are no longer lost in combat."] =
        "Счётчик стаков теперь корректно отображается для полностью-ограниченных аур, отслеживаемых Cooldown Manager Blizzard (напр. Чай маны). Аддон читает стаки тем же методом SetText/GetText, что и нативный CDM-просмотрщик Blizzard, поэтому SecureNumber значения больше не теряются в бою.",
    ["Restricted auras visible in the Cooldown Manager but invisible to addon APIs now synthesize ACTIVE state from the CDM hook (stacks + appliedAt) — icon + count + optional timer render correctly even when all 6 detection paths fail."] =
        "Ограниченные ауры, видимые в Cooldown Manager, но невидимые для API аддона, теперь синтезируют состояние ACTIVE из CDM-хука (stacks + appliedAt) — иконка + счётчик + опциональный таймер рендерятся корректно, даже когда все 6 путей детекции отказывают.",
    ["/hht auradebug now reports inCombat status, CDM-captured stack count, and the full list of FontStrings on the matching CDM frame — useful for diagnosing in-combat detection failures."] =
        "/hht auradebug теперь сообщает статус боя (inCombat), счётчик стаков из CDM и полный список FontString соответствующего CDM-фрейма — полезно для диагностики сбоев детекции в бою.",
    ["Public API namespace _G.HNZHealingTools exposed for macros and other addons (.version, .Trigger(key))."] =
        "Публичное пространство имён API _G.HNZHealingTools открыто для макросов и других аддонов (.version, .Trigger(key)).",

    -- ===== Macros page + trigger UI =====
    ["Macros"] = "Макросы",
    ["Trigger key:"] = "Ключ триггера:",
    ["Show preview"] = "Показать превью",
    ["Optional. Fire this aura from a macro: /hht trigger <key>. Requires Duration > 0. Case-insensitive."] =
        "Необязательно. Запуск этой ауры из макроса: /hht trigger <key>. Требуется Duration > 0. Без учёта регистра.",
    ["Optional. Fire this pulse from a macro: /hht trigger <key>. Case-insensitive."] =
        "Необязательно. Запуск этого пульса из макроса: /hht trigger <key>. Без учёта регистра.",
    ["Optional. Fire this item from a macro: /hht trigger <key>. Case-insensitive."] =
        "Необязательно. Запуск этого предмета из макроса: /hht trigger <key>. Без учёта регистра.",
    ["Usage: /hht trigger <key>"] = "Использование: /hht trigger <key>",
    ["Triggered %d entrie(s) for key '%s'"] = "Запущено %d запись/записей для ключа '%s'",
    ["No entries match triggerKey '%s'"] = "Нет записей, совпадающих с triggerKey '%s'",
    ["Trigger displays from macros"] = "Запуск дисплеев из макросов",
    ["You can fire any aura or pulse from a macro, keybind, or another addon — without needing the actual aura/cooldown to trigger. Useful for one-shot visual signals (panic ring, cooldown reminder, callout from a partner addon)."] =
        "Вы можете запустить любую ауру или пульс из макроса, кейбинда или другого аддона — без необходимости фактического срабатывания ауры/кулдауна. Полезно для разовых визуальных сигналов (паник-ring, напоминание о кулдауне, сигнал от партнёрского аддона).",
    ["1. Where you can set a Trigger key"] = "1. Где задать ключ триггера",
    ["Open the editor of any of these and fill in the \"Trigger key\" field:"] =
        "Откройте редактор любого из этих элементов и заполните поле \"Ключ триггера\":",
    ["  • Cursor Aura — fires the aura's icon at cursor for its Duration."] =
        "  • Cursor Aura — запускает иконку ауры у курсора на её Duration.",
    ["  • Ring Aura — fires the colored ring around your character for its Duration."] =
        "  • Ring Aura — запускает цветное кольцо вокруг персонажа на её Duration.",
    ["  • Cursor Item — fires the central pulse with the item's icon + optional sound."] =
        "  • Cursor Item — запускает центральный пульс с иконкой предмета + опциональным звуком.",
    ["  • Pulse Spell / Pulse Aura / Pulse Item — fires the central screen pulse + optional sound."] =
        "  • Pulse Spell / Pulse Aura / Pulse Item — запускает центральный экранный пульс + опциональный звук.",
    ["2. Fire it"] = "2. Запуск",
    ["From a chat message or macro line:"] = "Из сообщения чата или строки макроса:",
    ["From Lua (other addons, /run, WeakAuras custom code):"] =
        "Из Lua (другие аддоны, /run, custom-код WeakAuras):",
    ["Example: cast + trigger together"] = "Пример: каст + триггер вместе",
    ["Combine a real cast with a visual trigger in one macro:"] =
        "Комбинируйте реальный каст с визуальным триггером в одном макросе:",
    ["Tips"] = "Подсказки",
    ["  • Multiple entries can share the same trigger key — they all fire at once (e.g. one key can show a Ring Aura + play a Pulse simultaneously)."] =
        "  • Несколько записей могут разделять один ключ триггера — все запускаются одновременно (напр. один ключ показывает Ring Aura + воспроизводит Pulse).",
    ["  • Trigger keys are case-insensitive. \"Panic\" and \"panic\" match the same entries."] =
        "  • Ключи триггера нечувствительны к регистру. \"Panic\" и \"panic\" совпадают с одними записями.",
    ["  • Aura entries (Cursor / Ring) require Duration > 0 — without a duration there's no way to know when the visual should disappear."] =
        "  • Записи ауры (Cursor / Ring) требуют Duration > 0 — без длительности невозможно знать, когда визуал должен исчезнуть.",
    ["  • Pulse entries fire immediately and the animation has its own length (configured globally in Pulse → Config)."] =
        "  • Записи пульса запускаются мгновенно, анимация имеет собственную длительность (настраивается глобально в Pulse → Config).",
    ["  • HNZHealingTools.Trigger(key) returns the number of entries that matched (0 = no entries have that key)."] =
        "  • HNZHealingTools.Trigger(key) возвращает количество совпавших записей (0 = ни одна запись не имеет такого ключа).",
    ["  • Combat-safe: trigger keys work during combat lockdown."] =
        "  • Безопасно в бою: ключи триггера работают во время combat lockdown.",
})
