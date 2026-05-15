local _, ns = ...

-- 简体中文翻译 (zhCN)。键为 ns.L[...] 中使用的英文 UI 文本。
-- 缺失的键会通过 Locales.lua 中的 metatable 回退到英文。
ns.RegisterLocale("zhCN", {
    -- ===== 错误 / 反馈消息 =====
    ["Spell not found: "] = "未找到法术：",
    [" already monitored."] = " 已被监控。",
    ["Enter a name/ID."] = "请输入名称/ID。",
    ["Enter a name."] = "请输入名称。",
    ["Already exists."] = "已存在。",
    ["Created: "] = "已创建：",
    ["Can't copy to itself."] = "无法复制到自身。",
    ["Copied from "] = "复制自 ",
    ["Give the profile a name."] = "请为配置文件命名。",
    ["Paste the exported string in the box."] = "请将导出字符串粘贴到框中。",
    ["Imported as: "] = "已导入为：",
    ["Import failed."] = "导入失败。",
    ["Ready: Ctrl+C to copy"] = "就绪：Ctrl+C 复制",
    ["No active profile to export"] = "没有可导出的活动配置文件",

    -- ===== 通用按钮 =====
    ["Save"] = "保存",
    ["Cancel"] = "取消",
    ["Add"] = "添加",
    ["Update"] = "更新",
    ["Close"] = "关闭",
    ["Edit"] = "编辑",
    ["Test"] = "测试",
    ["Create"] = "创建",
    ["Load"] = "加载",
    ["Export"] = "导出",
    ["Import"] = "导入",
    ["Copy to current"] = "复制到当前",

    -- ===== 标签页 / 页面标题 =====
    ["Cursor Spells"] = "光标法术",
    ["Cursor Auras"] = "光标光环",
    ["Ring Auras"] = "环形光环",
    ["Cursor Config"] = "光标配置",
    ["Ring Config"] = "环形配置",
    ["Profiles"] = "配置文件",

    -- ===== 编辑器：标题与标签 =====
    ["Cursor Spell"] = "光标法术",
    ["Cursor Aura"] = "光标光环",
    ["Ring Aura"] = "环形光环",
    ["New Cursor Spell"] = "新建光标法术",
    ["New Cursor Aura"] = "新建光标光环",
    ["New Ring Aura"] = "新建环形光环",
    ["Editing: "] = "编辑中：",
    ["Spell name or ID:"] = "法术名称或 ID：",
    ["Aura name or ID:"] = "光环名称或 ID：",
    ["Show only when charges >=  (0=always):"] = "仅当充能 >=  时显示（0=始终）：",
    ["Stack text size (0=default):"] = "层数文字大小（0=默认）：",
    ["Hide while on cooldown"] = "冷却中时隐藏",
    ["Hide status overlay"] = "隐藏状态覆盖",
    ["Hide cooldown / duration timer"] = "隐藏冷却/持续时间计时器",
    ["Hide timer"] = "隐藏计时器",
    ["Specs:"] = "专精：",
    ["Required talent:"] = "所需天赋：",
    ["Unit:"] = "单位：",
    ["Type:"] = "类型：",
    ["Show:"] = "显示：",
    ["Min stacks:"] = "最小层数：",
    ["Duration (sec, 0=auto):"] = "持续时间（秒，0=自动）：",
    ["Color:"] = "颜色：",
    ["Show icon on ring"] = "在环上显示图标",
    ["Play sound on activation"] = "激活时播放声音",
    ["Pulse icon at screen center on ready"] = "就绪时在屏幕中央脉冲显示图标",
    ["Pulse icon at screen center on activation"] = "激活时在屏幕中央脉冲显示图标",
    ["Play sound on ready"] = "就绪时播放声音",
    ["Pulse Display Settings"] = "脉冲显示设置",
    ["Pulse Config"] = "脉冲",
    ["Size & Timing"] = "大小和时长",
    ["Hold Duration"] = "持续时间",
    ["Enable cooldown pulse"] = "启用冷却脉冲",
    ["Show anchor"] = "显示锚点",
    ["Hide anchor"] = "隐藏锚点",
    ["Test pulse"] = "测试脉冲",
    ["Drag to move"] = "拖动以移动",

    -- ===== TalentPicker =====
    ["[No talent]"] = "[无天赋]",
    ["Select a talent"] = "选择天赋",
    ["search"] = "搜索",
    ["(no talents in this loadout)"] = "（此配置中没有天赋）",

    -- ===== SoundPicker =====
    ["Select a sound"] = "选择声音",

    -- ===== DropZone =====
    ["Drag a spell here"] = "将法术拖到此处",

    -- ===== 下拉菜单：单位 / 过滤 / showWhen =====
    ["Target"] = "目标",
    ["Player"] = "玩家",
    ["Focus"] = "焦点",
    ["Mouseover"] = "鼠标悬停",
    ["Pet"] = "宠物",
    ["Buff"] = "增益",
    ["Debuff"] = "减益",
    ["Always"] = "始终",
    ["Only missing"] = "仅当缺失",
    ["Only active"] = "仅当激活",
    ["Active only"] = "仅当激活",
    ["Missing only"] = "仅当缺失",
    ["Below stacks"] = "低于层数",

    -- ===== 列表行（标签）=====
    ["Unknown"] = "未知",
    ["Min:"] = "最小：",
    ["Hide CD"] = "隐藏CD",
    ["Talent"] = "天赋",
    ["[icon]"] = "[图标]",

    -- ===== 空状态 / 提示 =====
    ["No spells. Use 'Add Cursor Spell...' below."] = "没有法术。请使用下方的“添加光标法术…”。",
    ["No auras. Use 'Add Cursor Aura...' below."] = "没有光环。请使用下方的“添加光标光环…”。",
    ["No ring auras. Use 'Add Ring Aura...' below."] = "没有环形光环。请使用下方的“添加环形光环…”。",
    ["Spells shown as icons near the mouse cursor. Click the gear to edit."] = "法术以图标形式显示在鼠标光标附近。点击齿轮编辑。",
    ["Auras shown as icons near the mouse cursor. Click the gear to edit."] = "光环以图标形式显示在鼠标光标附近。点击齿轮编辑。",
    ["Auras shown as circular rings around the character. Click the gear to edit, click color to change."] = "光环以环形显示在角色周围。点击齿轮编辑，点击颜色可更改。",
    ["Add Cursor Spell..."] = "添加光标法术…",
    ["Add Cursor Aura..."] = "添加光标光环…",
    ["Add Ring Aura..."] = "添加环形光环…",
    ["or drag a spell here:"] = "或将法术拖到此处：",

    -- ===== 光标设置页 =====
    ["Cursor Display Settings"] = "光标显示设置",
    ["Size & Layout"] = "大小与布局",
    ["Icon Size"] = "图标大小",
    ["Icon Spacing"] = "图标间距",
    ["Max Columns"] = "最大列数",
    ["Font Size"] = "字体大小",
    ["Position"] = "位置",
    ["Offset X"] = "X 偏移",
    ["Offset Y"] = "Y 偏移",
    ["Opacity"] = "不透明度",
    ["Update Interval"] = "更新间隔",
    ["Show only in combat"] = "仅在战斗中显示",
    ["Enable cursor display"] = "启用光标显示",

    -- ===== 环形设置页 =====
    ["Ring Display Settings"] = "环形显示设置",
    ["Size"] = "大小",
    ["Base Radius"] = "基础半径",
    ["Ring Thickness"] = "环的粗细",
    ["Ring Spacing"] = "环的间距",
    ["Appearance"] = "外观",
    ["Segments (smooth)"] = "分段（平滑）",
    ["Enable ring display"] = "启用环形显示",

    -- ===== 配置文件页 =====
    ["Profile Manager"] = "配置文件管理器",
    ["Active: "] = "当前：",
    ["(active)"] = "（当前）",
    ["Create New Profile"] = "新建配置文件",
    ["Copy From Profile"] = "从配置文件复制",
    ["Export Current Profile"] = "导出当前配置文件",
    ["(Press Export then Ctrl+C in the box)"] = "（按导出，然后在框中按 Ctrl+C）",
    ["Import Profile"] = "导入配置文件",
    ["Name:"] = "名称：",
    ["(paste below and press Import)"] = "（粘贴到下方并按导入）",

    -- ===== 小地图提示 =====
    ["Left click:"] = "左键：",
    ["Right click:"] = "右键：",
    ["Drag:"] = "拖动：",
    ["open/close config"] = "打开/关闭配置",
    ["toggle cursor + ring icons"] = "切换光标+环形图标",
    ["move icon"] = "移动图标",

    -- ===== 加载消息 =====
    ["loaded"] = "已加载",
    ["Profile:"] = "配置文件：",
    ["Type"] = "输入",
    ["for options"] = "查看选项",

    -- ===== 天赋树标签 =====
    ["Class"] = "职业",
    ["Hero"] = "英雄",
    -- "Spec" 保持原样。

    -- ===== Changelog / What's New =====
    ["What's New"] = "更新内容",
    ["Got it"] = "知道了",
    ["Changelog"] = "更新日志",
    ["View release notes for all versions"] = "查看所有版本的发布说明",

    -- ===== Release notes 1.4.0 =====
    ["Drag trinkets or potions from your bags or equipped slots to the input zone — the addon resolves the use-effect spell ID automatically."] =
        "将饰品或药水从背包或装备槽拖到输入区域 — 插件会自动解析使用效果的法术 ID。",
    ["Per-entry visibility for Cursor Spells and Auras: Always / Only in combat / Only out of combat (independent of the global cursor visibility)."] =
        "Cursor 法术和光环的逐条可见性：始终 / 仅战斗中 / 仅战斗外（独立于全局光标可见性）。",
    ["Per-entry visual overrides for Cursor Spells and Auras: icon size, opacity, and custom position with offset X/Y (the icon detaches from the grid and floats freely)."] =
        "Cursor 法术和光环的逐条视觉覆盖：图标大小、不透明度、以及带偏移 X/Y 的自定义位置（图标会从网格中分离并自由浮动）。",
    ["Tabbed editor modals: Cursor Spell and Cursor Aura split into General / Display / Effects; Ring Aura into General / Effects; Pulse Spell and Pulse Aura into General / Sound."] =
        "选项卡式编辑器弹窗：Cursor Spell 和 Cursor Aura 分为 General / Display / Effects；Ring Aura 分为 General / Effects；Pulse Spell 和 Pulse Aura 分为 General / Sound。",
    ["Changelog button (?) in the config window title bar — opens this popup with all release notes on demand."] =
        "配置窗口标题栏中的 Changelog (?) 按钮 — 随时打开此弹窗查看所有发布说明。",
    ["Fix: 'Spell not found' when adding via the autocomplete dropdown for spells/auras the character does not know. The autocomplete-resolved spell ID is now preferred over name lookup."] =
        "修复：从角色未知的法术/光环的自动完成下拉中添加时显示「未找到法术」。现在优先使用自动完成解析出的法术 ID，而非按名称查找。",
    ["Fix: creating or switching profiles left some menus showing the old profile's values. Config pages are now rebuilt against the active profile on every switch."] =
        "修复：创建或切换配置文件时，部分菜单仍显示旧配置文件的值。配置页面现在会在每次切换时根据活动配置文件重新构建。",

    -- ===== Release notes 1.5.0 =====
    ["Track items as cooldowns: trinkets, potions and on-use consumables can now be added to the Cursor or Pulse list. New 'Add Item...' button + drag-and-drop dispatches by type (spell vs item) and opens the right editor."] =
        "将物品作为冷却追踪：饰品、药水和触发型消耗品现在可以添加到光标或脉冲列表。新增「Add Item...」按钮 + 拖放按类型（法术 vs 物品）分发并打开正确的编辑器。",
    ["Item editors with full tabs (mirror of the Spell editor): General + Display + Effects for cursor items; General + Sound for pulse items. Visual overrides, hide flags, pulse on ready, sound — all available."] =
        "完整选项卡的物品编辑器（法术编辑器的镜像）：光标物品的 General + Display + Effects；脉冲物品的 General + Sound。视觉覆盖、隐藏标志、就绪时脉冲、声音 — 全部可用。",
    ["Per-entry instance-type filter on every aura/spell/item editor: restrict tracking to Open World, Delves, PvP (Arena/BG), Raid, Mythic+ and/or Dungeon. Reacts instantly when entering/leaving instances."] =
        "每个光环/法术/物品编辑器都有按条目的副本类型过滤器：将追踪限制为开放世界、地穴、PvP（竞技场/战场）、团队、史诗钥石+和/或地下城。进入/离开副本时立即响应。",
    ["Aura detection paths 6 + 7: slot iteration (catches semi-restricted auras Midnight hides from name/ID lookups) + manual trigger workaround (for fully-restricted auras like consumable buffs — configure a trigger spell or item ID and the addon synthesizes the ACTIVE state on cast/use)."] =
        "光环检测路径 6 + 7：slot 迭代（捕获 Midnight 在按名称/ID 查找时隐藏的半受限光环）+ 手动触发器变通方案（用于像消耗品增益这样的完全受限光环 — 配置触发法术或物品 ID，插件在施放/使用时合成 ACTIVE 状态）。",
    ["New /hht listauras command: prints every active buff/debuff with name + spellID + source + duration. Useful for finding the real spellID of a buff when the guessed one isn't detected."] =
        "新增 /hht listauras 命令：打印每个活动增益/减益及其名称 + spellID + 来源 + 持续时间。当猜测的 ID 未被检测到时，可用于查找增益的真实 spellID。",
    ["Config window no longer closes when opening the Spellbook (PlayerSpellsFrame). ESC still closes it via a custom handler that doesn't break other keybinds."] =
        "配置窗口在打开法术书（PlayerSpellsFrame）时不再关闭。ESC 仍然通过自定义处理程序关闭它，不会破坏其他按键绑定。",
    ["Fix: comparing SecureNumber spellId in slot iteration tainted the addon ('attempt to compare a secret number value'). Wrapped in ToPublic + pcall — fully restricted auras are skipped safely instead of crashing the whole frame."] =
        "修复：在 slot 迭代中比较 SecureNumber spellId 污染了插件（'attempt to compare a secret number value'）。包装在 ToPublic + pcall 中 — 完全受限光环被安全跳过，而不是导致整个 frame 崩溃。",
    ["Fix: ApplyRingVisibility nil call when a ring test entry expired (forward declaration bug, latent since 1.3.0)."] =
        "修复：环测试条目过期时 ApplyRingVisibility 的 nil 调用（前向声明 bug，自 1.3.0 起潜伏）。",
})
