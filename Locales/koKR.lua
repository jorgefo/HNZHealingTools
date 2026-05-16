local _, ns = ...

-- 한국어 번역 (koKR). 키는 ns.L[...]에서 사용되는 영어 UI 텍스트입니다.
-- 누락된 키는 Locales.lua의 메타테이블을 통해 영어로 대체됩니다.
ns.RegisterLocale("koKR", {
    -- ===== 오류 / 피드백 메시지 =====
    ["Spell not found: "] = "주문을 찾을 수 없음: ",
    [" already monitored."] = " 이미 감시 중입니다.",
    ["Enter a name/ID."] = "이름/ID를 입력하세요.",
    ["Enter a name."] = "이름을 입력하세요.",
    ["Already exists."] = "이미 존재합니다.",
    ["Created: "] = "생성됨: ",
    ["Can't copy to itself."] = "자기 자신에게 복사할 수 없습니다.",
    ["Copied from "] = "복사 출처: ",
    ["Give the profile a name."] = "프로필 이름을 지정하세요.",
    ["Paste the exported string in the box."] = "내보낸 문자열을 상자에 붙여넣으세요.",
    ["Imported as: "] = "가져옴: ",
    ["Import failed."] = "가져오기 실패.",
    ["Ready: Ctrl+C to copy"] = "준비됨: Ctrl+C로 복사",
    ["No active profile to export"] = "내보낼 활성 프로필이 없습니다",

    -- ===== 일반 버튼 =====
    ["Save"] = "저장",
    ["Cancel"] = "취소",
    ["Add"] = "추가",
    ["Update"] = "갱신",
    ["Close"] = "닫기",
    ["Edit"] = "편집",
    ["Test"] = "테스트",
    ["Create"] = "생성",
    ["Load"] = "불러오기",
    ["Export"] = "내보내기",
    ["Import"] = "가져오기",
    ["Copy to current"] = "현재로 복사",

    -- ===== 탭 / 페이지 제목 =====
    ["Cursor Spells"] = "커서 주문",
    ["Cursor Auras"] = "커서 효과",
    ["Ring Auras"] = "링 효과",
    ["Cursor Config"] = "커서 설정",
    ["Ring Config"] = "링 설정",
    ["Profiles"] = "프로필",

    -- ===== 편집기: 제목 및 라벨 =====
    ["Cursor Spell"] = "커서 주문",
    ["Cursor Aura"] = "커서 효과",
    ["Ring Aura"] = "링 효과",
    ["New Cursor Spell"] = "새 커서 주문",
    ["New Cursor Aura"] = "새 커서 효과",
    ["New Ring Aura"] = "새 링 효과",
    ["Editing: "] = "편집 중: ",
    ["Spell name or ID:"] = "주문 이름 또는 ID:",
    ["Aura name or ID:"] = "효과 이름 또는 ID:",
    ["Show only when charges >=  (0=always):"] = "충전 횟수 >= 일 때만 표시 (0=항상):",
    ["Stack text size (0=default):"] = "중첩 텍스트 크기 (0=기본):",
    ["Hide while on cooldown"] = "재사용 대기시간 동안 숨기기",
    ["Hide status overlay"] = "상태 오버레이 숨기기",
    ["Hide cooldown / duration timer"] = "재사용 대기/지속시간 타이머 숨기기",
    ["Hide timer"] = "타이머 숨기기",
    ["Specs:"] = "전문화:",
    ["Required talent:"] = "필요 특성:",
    ["Unit:"] = "대상:",
    ["Type:"] = "유형:",
    ["Show:"] = "표시:",
    ["Min stacks:"] = "최소 중첩:",
    ["Duration (sec, 0=auto):"] = "지속시간 (초, 0=자동):",
    ["Color:"] = "색상:",
    ["Show icon on ring"] = "링에 아이콘 표시",
    ["Play sound on activation"] = "활성화 시 소리 재생",
    ["Pulse icon at screen center on ready"] = "준비되면 화면 중앙에 아이콘 펄스",
    ["Pulse icon at screen center on activation"] = "활성화 시 화면 중앙에 아이콘 펄스",
    ["Play sound on ready"] = "준비되면 소리 재생",
    ["Pulse Display Settings"] = "펄스 표시 설정",
    ["Pulse Config"] = "펄스",
    ["Size & Timing"] = "크기 및 시간",
    ["Hold Duration"] = "유지 시간",
    ["Enable cooldown pulse"] = "쿨다운 펄스 활성화",
    ["Show anchor"] = "고정점 표시",
    ["Hide anchor"] = "고정점 숨기기",
    ["Test pulse"] = "펄스 시험",
    ["Drag to move"] = "끌어서 이동",

    -- ===== TalentPicker =====
    ["[No talent]"] = "[특성 없음]",
    ["Select a talent"] = "특성 선택",
    ["search"] = "검색",
    ["(no talents in this loadout)"] = "(이 로드아웃에 특성 없음)",

    -- ===== SoundPicker =====
    ["Select a sound"] = "소리 선택",

    -- ===== DropZone =====
    ["Drag a spell here"] = "주문을 여기로 끌어다 놓으세요",

    -- ===== 드롭다운: 대상 / 필터 / showWhen =====
    ["Target"] = "대상",
    ["Player"] = "플레이어",
    ["Focus"] = "주시",
    ["Mouseover"] = "마우스 오버",
    ["Pet"] = "소환수",
    ["Buff"] = "이로운 효과",
    ["Debuff"] = "해로운 효과",
    ["Always"] = "항상",
    ["Only missing"] = "없을 때만",
    ["Only active"] = "활성 시에만",
    ["Active only"] = "활성 시에만",
    ["Missing only"] = "없을 때만",
    ["Below stacks"] = "중첩 이하",

    -- ===== 목록 행 (배지) =====
    ["Unknown"] = "알 수 없음",
    ["Min:"] = "최소:",
    ["Hide CD"] = "CD 숨김",
    ["Talent"] = "특성",
    ["[icon]"] = "[아이콘]",

    -- ===== 빈 상태 / 안내 =====
    ["No spells. Use 'Add Cursor Spell...' below."] = "주문이 없습니다. 아래의 '커서 주문 추가...'를 사용하세요.",
    ["No auras. Use 'Add Cursor Aura...' below."] = "효과가 없습니다. 아래의 '커서 효과 추가...'를 사용하세요.",
    ["No ring auras. Use 'Add Ring Aura...' below."] = "링 효과가 없습니다. 아래의 '링 효과 추가...'를 사용하세요.",
    ["Spells shown as icons near the mouse cursor. Click the gear to edit."] = "주문이 마우스 커서 근처에 아이콘으로 표시됩니다. 톱니바퀴를 클릭하여 편집.",
    ["Auras shown as icons near the mouse cursor. Click the gear to edit."] = "효과가 마우스 커서 근처에 아이콘으로 표시됩니다. 톱니바퀴를 클릭하여 편집.",
    ["Auras shown as circular rings around the character. Click the gear to edit, click color to change."] = "효과가 캐릭터 주위에 원형 링으로 표시됩니다. 톱니바퀴를 클릭하여 편집, 색상 클릭으로 변경.",
    ["Add Cursor Spell..."] = "커서 주문 추가...",
    ["Add Cursor Aura..."] = "커서 효과 추가...",
    ["Add Ring Aura..."] = "링 효과 추가...",
    ["or drag a spell here:"] = "또는 여기에 주문을 끌어다 놓으세요:",

    -- ===== 커서 설정 페이지 =====
    ["Cursor Display Settings"] = "커서 표시 설정",
    ["Size & Layout"] = "크기 및 배치",
    ["Icon Size"] = "아이콘 크기",
    ["Icon Spacing"] = "아이콘 간격",
    ["Max Columns"] = "최대 열 수",
    ["Font Size"] = "글자 크기",
    ["Position"] = "위치",
    ["Offset X"] = "X 오프셋",
    ["Offset Y"] = "Y 오프셋",
    ["Opacity"] = "불투명도",
    ["Update Interval"] = "갱신 간격",
    ["Show only in combat"] = "전투 중에만 표시",
    ["Enable cursor display"] = "커서 표시 활성화",

    -- ===== 링 설정 페이지 =====
    ["Ring Display Settings"] = "링 표시 설정",
    ["Size"] = "크기",
    ["Base Radius"] = "기본 반경",
    ["Ring Thickness"] = "링 두께",
    ["Ring Spacing"] = "링 간격",
    ["Appearance"] = "외관",
    ["Segments (smooth)"] = "분할 (부드럽게)",
    ["Enable ring display"] = "링 표시 활성화",

    -- ===== 프로필 페이지 =====
    ["Profile Manager"] = "프로필 관리자",
    ["Active: "] = "활성: ",
    ["(active)"] = "(활성)",
    ["Create New Profile"] = "새 프로필 생성",
    ["Copy From Profile"] = "프로필에서 복사",
    ["Export Current Profile"] = "현재 프로필 내보내기",
    ["(Press Export then Ctrl+C in the box)"] = "(내보내기를 누른 후 상자에서 Ctrl+C)",
    ["Import Profile"] = "프로필 가져오기",
    ["Name:"] = "이름:",
    ["(paste below and press Import)"] = "(아래에 붙여넣고 가져오기 누르기)",

    -- ===== 미니맵 툴팁 =====
    ["Left click:"] = "좌클릭:",
    ["Right click:"] = "우클릭:",
    ["Drag:"] = "드래그:",
    ["open/close config"] = "설정 열기/닫기",
    ["toggle cursor + ring icons"] = "커서 + 링 아이콘 전환",
    ["move icon"] = "아이콘 이동",

    -- ===== 로딩 메시지 =====
    ["loaded"] = "로드됨",
    ["Profile:"] = "프로필:",
    ["Type"] = "입력:",
    ["for options"] = "옵션 보기",

    -- ===== 특성 트리 라벨 =====
    ["Class"] = "직업",
    ["Hero"] = "영웅",
    -- "Spec"은 그대로 유지됩니다.

    -- ===== Changelog / What's New =====
    ["What's New"] = "새로운 기능",
    ["Got it"] = "확인",
    ["Changelog"] = "변경 로그",
    ["View release notes for all versions"] = "모든 버전의 릴리스 노트 보기",

    -- ===== Release notes 1.4.0 =====
    ["Drag trinkets or potions from your bags or equipped slots to the input zone — the addon resolves the use-effect spell ID automatically."] =
        "가방이나 장착 슬롯의 장신구 또는 물약을 입력 영역으로 드래그하세요 — 애드온이 자동으로 사용 효과의 주문 ID를 확인합니다.",
    ["Per-entry visibility for Cursor Spells and Auras: Always / Only in combat / Only out of combat (independent of the global cursor visibility)."] =
        "Cursor 주문 및 효과별 가시성: 항상 / 전투 중에만 / 전투 외에만 (전역 커서 가시성과 독립).",
    ["Per-entry visual overrides for Cursor Spells and Auras: icon size, opacity, and custom position with offset X/Y (the icon detaches from the grid and floats freely)."] =
        "Cursor 주문 및 효과별 시각적 재정의: 아이콘 크기, 불투명도, 오프셋 X/Y로 사용자 지정 위치 (아이콘이 그리드에서 분리되어 자유롭게 배치됨).",
    ["Tabbed editor modals: Cursor Spell and Cursor Aura split into General / Display / Effects; Ring Aura into General / Effects; Pulse Spell and Pulse Aura into General / Sound."] =
        "탭 방식 편집기 창: Cursor Spell과 Cursor Aura는 General / Display / Effects, Ring Aura는 General / Effects, Pulse Spell과 Pulse Aura는 General / Sound로 분할.",
    ["Changelog button (?) in the config window title bar — opens this popup with all release notes on demand."] =
        "구성 창 제목 표시줄의 Changelog (?) 버튼 — 필요할 때 모든 릴리스 노트가 포함된 이 팝업을 엽니다.",
    ["Fix: 'Spell not found' when adding via the autocomplete dropdown for spells/auras the character does not know. The autocomplete-resolved spell ID is now preferred over name lookup."] =
        "수정: 캐릭터가 모르는 주문/효과를 자동 완성 드롭다운으로 추가할 때 '주문을 찾을 수 없음' 발생. 이제 이름 조회보다 자동 완성에서 확인된 주문 ID가 우선 적용됩니다.",
    ["Fix: creating or switching profiles left some menus showing the old profile's values. Config pages are now rebuilt against the active profile on every switch."] =
        "수정: 프로필을 생성하거나 변경할 때 일부 메뉴에 이전 프로필 값이 남아 있었습니다. 이제 변경할 때마다 활성 프로필 기준으로 구성 페이지가 다시 빌드됩니다.",

    -- ===== Release notes 1.5.0 =====
    ["Track items as cooldowns: trinkets, potions and on-use consumables can now be added to the Cursor or Pulse list. New 'Add Item...' button + drag-and-drop dispatches by type (spell vs item) and opens the right editor."] =
        "아이템을 쿨다운으로 추적: 장신구, 물약, 사용형 소모품을 이제 커서 또는 펄스 목록에 추가할 수 있습니다. 새로운 'Add Item...' 버튼 + 드래그 앤 드롭이 타입(주문 vs 아이템)별로 분기하여 알맞은 편집기를 엽니다.",
    ["Item editors with full tabs (mirror of the Spell editor): General + Display + Effects for cursor items; General + Sound for pulse items. Visual overrides, hide flags, pulse on ready, sound — all available."] =
        "전체 탭이 있는 아이템 편집기(주문 편집기의 미러): 커서 아이템은 General + Display + Effects; 펄스 아이템은 General + Sound. 시각적 오버라이드, 숨김 플래그, 준비 시 펄스, 사운드 — 모두 사용 가능.",
    ["Per-entry instance-type filter on every aura/spell/item editor: restrict tracking to Open World, Delves, PvP (Arena/BG), Raid, Mythic+ and/or Dungeon. Reacts instantly when entering/leaving instances."] =
        "모든 효과/주문/아이템 편집기에 인스턴스 타입별 필터: 일반 월드, 어둠땅, PvP (투기장/전장), 공격대, 신화+ 및/또는 던전으로 추적을 제한. 인스턴스 입장/퇴장 시 즉시 반응.",
    ["Aura detection paths 6 + 7: slot iteration (catches semi-restricted auras Midnight hides from name/ID lookups) + manual trigger workaround (for fully-restricted auras like consumable buffs — configure a trigger spell or item ID and the addon synthesizes the ACTIVE state on cast/use)."] =
        "효과 감지 경로 6 + 7: 슬롯 반복(미드나이트가 이름/ID 조회에서 숨기는 반-제한된 효과 포착) + 수동 트리거 우회(소모품 버프와 같은 완전-제한된 효과용 — 트리거 주문 또는 아이템 ID를 설정하면 시전/사용 시 애드온이 ACTIVE 상태를 합성).",
    ["New /hht listauras command: prints every active buff/debuff with name + spellID + source + duration. Useful for finding the real spellID of a buff when the guessed one isn't detected."] =
        "새로운 /hht listauras 명령: 모든 활성 버프/디버프를 이름 + spellID + 출처 + 지속시간과 함께 출력. 추측한 ID가 감지되지 않을 때 버프의 실제 spellID 찾기에 유용.",
    ["Config window no longer closes when opening the Spellbook (PlayerSpellsFrame). ESC still closes it via a custom handler that doesn't break other keybinds."] =
        "마법책(PlayerSpellsFrame)을 열 때 더 이상 구성 창이 닫히지 않습니다. ESC는 다른 키바인드를 깨지 않는 사용자 정의 핸들러를 통해 여전히 창을 닫습니다.",
    ["Fix: comparing SecureNumber spellId in slot iteration tainted the addon ('attempt to compare a secret number value'). Wrapped in ToPublic + pcall — fully restricted auras are skipped safely instead of crashing the whole frame."] =
        "수정: 슬롯 반복에서 SecureNumber spellId 비교가 애드온을 오염시킴('attempt to compare a secret number value'). ToPublic + pcall로 감쌈 — 완전-제한된 효과는 전체 프레임을 충돌시키는 대신 안전하게 건너뜁니다.",
    ["Fix: ApplyRingVisibility nil call when a ring test entry expired (forward declaration bug, latent since 1.3.0)."] =
        "수정: 링 테스트 항목이 만료될 때 ApplyRingVisibility nil 호출(전방 선언 버그, 1.3.0부터 잠복).",

    -- ===== Release notes 1.6.0 =====
    ["Macro trigger system: every aura, pulse, and item editor has a new 'Trigger key' field. Fire any configured display from a macro with /hht trigger <key> or from another addon via HNZHealingTools.Trigger(key). Multiple entries can share a key — one keybind fires them all at once."] =
        "매크로 트리거 시스템: 모든 효과/펄스/아이템 편집기에 'Trigger key' 필드가 추가됨. 매크로에서 /hht trigger <key> 또는 다른 애드온에서 HNZHealingTools.Trigger(key)로 구성된 표시를 발동할 수 있음. 여러 항목이 같은 키를 공유 가능 — 키바인드 하나로 모두 동시에 발동.",
    ["New Macros help page in the config sidebar with copy-pasteable macro examples and Lua snippets."] =
        "설정 사이드바에 새 '매크로' 도움말 페이지 추가 — 복사 가능한 매크로 예시와 Lua 스니펫 포함.",
    ["Floating preview popup: 'Show preview' button at the top of pages with a Live Preview block (Cursor / Ring / Pulse settings + Cursor Ring sub-tabs). Opens to the right of the config window, single-active across pages, inherits position when switching."] =
        "플로팅 미리보기 팝업: 라이브 미리보기 블록이 있던 페이지(Cursor / Ring / Pulse 설정 + Cursor Ring 하위 탭) 상단에 '미리보기 표시' 버튼. 설정 창 오른쪽으로 열림, 페이지 간 단일 활성, 전환 시 위치 상속.",
    ["Stack count now displays correctly for fully-restricted auras tracked by Blizzard's Cooldown Manager (e.g. Mana Tea). The addon now reads the stack count via the same SetText/GetText technique Blizzard's own CDM viewer uses, so SecureNumber values are no longer lost in combat."] =
        "블리자드의 재사용 대기시간 관리자가 추적하는 완전-제한된 효과(예: 마나차)의 중첩 수가 이제 올바르게 표시됨. 애드온이 블리자드 CDM 뷰어와 동일한 SetText/GetText 기법으로 중첩 수를 읽어, 전투 중 SecureNumber 값이 더 이상 손실되지 않음.",
    ["Restricted auras visible in the Cooldown Manager but invisible to addon APIs now synthesize ACTIVE state from the CDM hook (stacks + appliedAt) — icon + count + optional timer render correctly even when all 6 detection paths fail."] =
        "재사용 대기시간 관리자에 보이지만 애드온 API에는 보이지 않는 제한된 효과가 이제 CDM 후크에서 ACTIVE 상태를 합성함(stacks + appliedAt) — 6개 탐지 경로가 모두 실패해도 아이콘 + 카운트 + 선택 타이머가 올바르게 표시됨.",
    ["/hht auradebug now reports inCombat status, CDM-captured stack count, and the full list of FontStrings on the matching CDM frame — useful for diagnosing in-combat detection failures."] =
        "/hht auradebug가 이제 전투 상태(inCombat), CDM에서 캡처한 중첩 수, 일치하는 CDM 프레임의 모든 FontString 목록을 보고함 — 전투 중 탐지 실패 진단에 유용.",
    ["Public API namespace _G.HNZHealingTools exposed for macros and other addons (.version, .Trigger(key))."] =
        "매크로와 다른 애드온을 위한 공개 API 네임스페이스 _G.HNZHealingTools 노출(.version, .Trigger(key)).",

    -- ===== Macros page + trigger UI =====
    ["Macros"] = "매크로",
    ["Trigger key:"] = "트리거 키:",
    ["Show preview"] = "미리보기 표시",
    ["Optional. Fire this aura from a macro: /hht trigger <key>. Requires Duration > 0. Case-insensitive."] =
        "선택. 매크로에서 이 효과 발동: /hht trigger <key>. Duration > 0 필요. 대소문자 구분 없음.",
    ["Optional. Fire this pulse from a macro: /hht trigger <key>. Case-insensitive."] =
        "선택. 매크로에서 이 펄스 발동: /hht trigger <key>. 대소문자 구분 없음.",
    ["Optional. Fire this item from a macro: /hht trigger <key>. Case-insensitive."] =
        "선택. 매크로에서 이 아이템 발동: /hht trigger <key>. 대소문자 구분 없음.",
    ["Usage: /hht trigger <key>"] = "사용법: /hht trigger <key>",
    ["Triggered %d entrie(s) for key '%s'"] = "키 '%s'에 대해 %d개 항목 발동",
    ["No entries match triggerKey '%s'"] = "triggerKey '%s'에 일치하는 항목 없음",
    ["Trigger displays from macros"] = "매크로에서 표시 발동",
    ["You can fire any aura or pulse from a macro, keybind, or another addon — without needing the actual aura/cooldown to trigger. Useful for one-shot visual signals (panic ring, cooldown reminder, callout from a partner addon)."] =
        "실제 효과/재사용 대기시간이 발동되지 않아도 매크로, 키바인드 또는 다른 애드온에서 모든 효과나 펄스를 발동할 수 있음. 일회성 시각 신호(패닉 링, 재사용 대기시간 알림, 파트너 애드온의 콜아웃)에 유용.",
    ["1. Where you can set a Trigger key"] = "1. 트리거 키를 설정할 수 있는 곳",
    ["Open the editor of any of these and fill in the \"Trigger key\" field:"] =
        "아래 항목의 편집기를 열고 \"트리거 키\" 필드를 채우세요:",
    ["  • Cursor Aura — fires the aura's icon at cursor for its Duration."] =
        "  • 커서 효과 — Duration 동안 커서에 효과 아이콘을 발동.",
    ["  • Ring Aura — fires the colored ring around your character for its Duration."] =
        "  • 링 효과 — Duration 동안 캐릭터 주위에 색상 링을 발동.",
    ["  • Cursor Item — fires the central pulse with the item's icon + optional sound."] =
        "  • 커서 아이템 — 아이템 아이콘으로 중앙 펄스 + 선택 사운드 발동.",
    ["  • Pulse Spell / Pulse Aura / Pulse Item — fires the central screen pulse + optional sound."] =
        "  • 펄스 주문 / 펄스 효과 / 펄스 아이템 — 중앙 화면 펄스 + 선택 사운드 발동.",
    ["2. Fire it"] = "2. 발동",
    ["From a chat message or macro line:"] = "대화 메시지 또는 매크로 줄에서:",
    ["From Lua (other addons, /run, WeakAuras custom code):"] =
        "Lua에서 (다른 애드온, /run, WeakAuras 사용자 코드):",
    ["Example: cast + trigger together"] = "예시: 시전 + 트리거 함께",
    ["Combine a real cast with a visual trigger in one macro:"] =
        "실제 시전과 시각 트리거를 하나의 매크로에 결합:",
    ["Tips"] = "팁",
    ["  • Multiple entries can share the same trigger key — they all fire at once (e.g. one key can show a Ring Aura + play a Pulse simultaneously)."] =
        "  • 여러 항목이 같은 트리거 키를 공유 가능 — 동시에 모두 발동(예: 키 하나로 링 효과 표시 + 펄스 재생 동시).",
    ["  • Trigger keys are case-insensitive. \"Panic\" and \"panic\" match the same entries."] =
        "  • 트리거 키는 대소문자 구분 없음. \"Panic\"과 \"panic\"은 같은 항목에 일치.",
    ["  • Aura entries (Cursor / Ring) require Duration > 0 — without a duration there's no way to know when the visual should disappear."] =
        "  • 효과 항목(커서/링)은 Duration > 0 필요 — 지속시간 없이는 시각이 사라질 때를 알 수 없음.",
    ["  • Pulse entries fire immediately and the animation has its own length (configured globally in Pulse → Config)."] =
        "  • 펄스 항목은 즉시 발동하며 애니메이션은 자체 길이가 있음(Pulse → Config에서 전역 설정).",
    ["  • HNZHealingTools.Trigger(key) returns the number of entries that matched (0 = no entries have that key)."] =
        "  • HNZHealingTools.Trigger(key)는 일치한 항목 수를 반환(0 = 해당 키를 가진 항목 없음).",
    ["  • Combat-safe: trigger keys work during combat lockdown."] =
        "  • 전투 안전: 전투 잠금 중에도 트리거 키 작동.",
})
