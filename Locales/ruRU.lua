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
})
