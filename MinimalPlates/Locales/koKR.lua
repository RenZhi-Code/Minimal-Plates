---@class MinimalPlates
local MP = MinimalPlates

-- Korean (Korea)
MP.L:RegisterLocale("koKR", {
  -- General
  ["Enable MinimalPlates"] = "MinimalPlates 활성화",
  ["Use Class Colors"] = "직업 색상 사용",
  ["Show Cast Bar"] = "시전 바 표시",
  ["Show Enemy Health Bars (uncheck for name-only)"] = "적 체력 바 표시 (이름만 표시하려면 해제)",
  ["Show Friendly NPCs"] = "우호적 NPC 표시",
  ["Bar Texture:"] = "바 텍스처:",
  ["Font:"] = "글꼴:",
  ["Font Size:"] = "글꼴 크기:",
  ["Health Width:"] = "체력 너비:",
  ["Health Height:"] = "체력 높이:",
  ["Scale:"] = "크기:",
  
  -- Features
  ["Advanced Features"] = "고급 기능",
  ["Show Elite/Rare Indicators"] = "정예/희귀 표시기 표시",
  ["Elite/Rare Style:"] = "정예/희귀 스타일:",
  ["Icon + Text"] = "아이콘 + 텍스트",
  ["Icon Only"] = "아이콘만",
  ["Text Only"] = "텍스트만",
  ["None"] = "없음",
  ["Show Quest Icons"] = "퀘스트 아이콘 표시",
  ["Show Classification (Elite/Rare/Boss)"] = "분류 표시 (정예/희귀/보스)",
  
  -- Classification
  ["Boss"] = "보스",
  ["Rare Elite"] = "희귀 정예",
  ["Rare"] = "희귀",
  ["Elite"] = "정예",
  
  -- Headers
  ["--- Built-in Fonts ---"] = "--- 기본 글꼴 ---",
  ["--- Installed Fonts ---"] = "--- 설치된 글꼴 ---",
  ["--- SharedMedia Fonts ---"] = "--- SharedMedia 글꼴 ---",
  
  -- Settings UI
  ["MinimalPlates Settings"] = "MinimalPlates 설정",
  ["General"] = "일반",
  ["Health & Power"] = "체력 및 자원",
  ["Auras & Icons"] = "오라 및 아이콘",
  ["Advanced"] = "고급",
  
  -- Config UI (General > Display Modes)
  ["Display Modes"] = "표시 모드",
  ["Choose Bar (with health bar), Text (name only), or Hide:"] = "막대(체력바 포함), 텍스트(이름만) 또는 숨기기 선택:",
  ["Enemy Players"] = "적 플레이어",
  ["Enemy players in PvP and opposing faction."] = "반대 진영의 플레이어 및 PvP 적.",
  ["Enemy NPCs"] = "적 NPC",
  ["Friendly Players"] = "아군 플레이어",
  ["Friendly NPCs"] = "아군 NPC",
  ["Additional Unit Info"] = "추가 유닛 정보",
  ["Show Creature Text"] = "생명체 텍스트 표시",
  ["Show NPC titles/subtitles (like 'Innkeeper' or 'Quest Giver')."] = "NPC 직함/부제목 표시(예: ‘여관주인’, ‘퀘스트 제공자’).",
  ["Show Unit Target"] = "유닛 대상 표시",
  ["Show who the unit is currently targeting."] = "유닛이 현재 대상으로 삼는 대상 표시.",
  
  -- Config UI (General > Colors & Effects)
  ["Colors & Effects"] = "색상 및 효과",
  ["Color schemes, target highlighting, and visual effects like glows and mouseover."] = "색상 테마, 대상 강조, 발광 및 마우스오버 등의 시각 효과.",
  ["Colors & Highlighting"] = "색상 및 강조",
  ["Class Colors"] = "직업 색상",
  ["Threat Coloring"] = "위협 색상",
  ["Highlight Current Target"] = "현재 대상 강조",
  ["Target Scale Multiplier"] = "대상 크기 배수",
  ["Extra scaling applied to your current target. Makes it easier to see who you're attacking."] = "현재 대상에 추가 크기 적용. 공격 대상 확인이 쉬워집니다.",
  ["Visual Effects"] = "시각 효과",
  ["Show Threat Glow"] = "위협 발광 표시",
  ["Show Focus Glow"] = "주시 발광 표시",
  ["Show Mouseover Highlight"] = "마우스오버 강조 표시",
  
  -- Config UI (General > Unit Info & Fade)
  ["Unit Info & Fade"] = "유닛 정보 및 페이드",
  ["Unit information display and non-target fading options."] = "유닛 정보 표시 및 비대상 페이드 옵션.",
  ["Unit Information"] = "유닛 정보",
  ["Show Level"] = "레벨 표시",
  ["Show Guild Text"] = "길드 텍스트 표시",
  ["Non-Target Fade"] = "비대상 페이드",
  ["Fade Non-Target Plates"] = "비대상 이름표 페이드",
  ["(More fade options in Advanced tab)"] = "(추가 페이드 옵션은 고급 탭에서)",
  ["Non-Target Alpha"] = "비대상 투명도",
})
