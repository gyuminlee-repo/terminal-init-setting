#!/usr/bin/env bash
# Windows Terminal + tmux 설정 자동 적용 스크립트
# 사용법: bash setup-terminal.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

info()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
ok()    { echo -e "\033[1;32m[ OK ]\033[0m $*"; }
fail()  { echo -e "\033[1;31m[FAIL]\033[0m $*"; }

# --------------------------------------------------
# 1. tmux 설치 확인
# --------------------------------------------------
if command -v tmux &>/dev/null; then
    ok "tmux $(tmux -V | awk '{print $2}') 설치됨"
else
    info "tmux 설치 중..."
    sudo apt update -qq && sudo apt install -y tmux
    ok "tmux 설치 완료"
fi

# --------------------------------------------------
# 2. JetBrainsMono Nerd Font 안내
# --------------------------------------------------
if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd"; then
    ok "JetBrainsMono Nerd Font 감지됨"
else
    warn "JetBrainsMono Nerd Font가 감지되지 않음"
    warn "Windows 측에 설치 필요: https://www.nerdfonts.com/font-downloads"
    warn "미설치 시 기본 폰트로 대체되며 동작에는 문제 없음"
fi

# --------------------------------------------------
# 3. ~/.tmux.conf 복사
# --------------------------------------------------
if [ -f "$HOME/.tmux.conf" ]; then
    cp "$HOME/.tmux.conf" "$HOME/.tmux.conf${BACKUP_SUFFIX}"
    info "기존 ~/.tmux.conf 백업 → ~/.tmux.conf${BACKUP_SUFFIX}"
fi
cp "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"
ok "~/.tmux.conf 적용 완료"

# --------------------------------------------------
# 4. ~/.zshrc에 tmux 자동 연결 블록 추가
# --------------------------------------------------
TMUX_BLOCK='# tmux 자동 연결 (터미널 열면 바로 tmux 세션으로)
# - 이미 tmux 안이면 스킵
# - Claude Code 등 비대화형 환경에서는 스킵
if command -v tmux &>/dev/null && [ -z "$TMUX" ] && [ -z "$CLAUDE_CODE" ] && [[ $- == *i* ]]; then
    tmux attach -t main 2>/dev/null || tmux new -s main
fi'

ZSHRC="$HOME/.zshrc"
if [ -f "$ZSHRC" ] && grep -q "tmux attach -t main" "$ZSHRC"; then
    ok "~/.zshrc tmux 자동 연결 블록 이미 존재 — 스킵"
else
    if [ -f "$ZSHRC" ]; then
        echo "" >> "$ZSHRC"
    fi
    echo "$TMUX_BLOCK" >> "$ZSHRC"
    ok "~/.zshrc에 tmux 자동 연결 블록 추가 완료"
fi

# --------------------------------------------------
# 5. Windows Terminal settings.json 복사
# --------------------------------------------------
# Windows 사용자 폴더 자동 탐지
WIN_USER_DIR=""
for dir in /mnt/c/Users/*/; do
    # Default, Public, All Users 제외
    base="$(basename "$dir")"
    if [[ "$base" != "Default" && "$base" != "Public" && "$base" != "All Users" && "$base" != "Default User" ]]; then
        WIN_USER_DIR="$dir"
        break
    fi
done

if [ -z "$WIN_USER_DIR" ]; then
    warn "Windows 사용자 폴더를 찾을 수 없음 — settings.json 수동 복사 필요"
    warn "복사 대상: scripts/dotfiles/terminal-settings.json"
    warn "붙여넣기: %LOCALAPPDATA%\\Packages\\Microsoft.WindowsTerminal_8wekyb3d8bbwe\\LocalState\\settings.json"
else
    WT_DIR="${WIN_USER_DIR}AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState"
    if [ -d "$WT_DIR" ]; then
        if [ -f "$WT_DIR/settings.json" ]; then
            cp "$WT_DIR/settings.json" "$WT_DIR/settings.json${BACKUP_SUFFIX}"
            info "기존 settings.json 백업 → settings.json${BACKUP_SUFFIX}"
        fi
        cp "$SCRIPT_DIR/terminal-settings.json" "$WT_DIR/settings.json"
        ok "Windows Terminal settings.json 적용 완료"
    else
        warn "Windows Terminal이 설치되지 않음 — settings.json 스킵"
        warn "Microsoft Store에서 Windows Terminal 설치 후 다시 실행하세요"
    fi
fi

# --------------------------------------------------
# 완료
# --------------------------------------------------
echo ""
info "=== 설정 적용 완료 ==="
info "Windows Terminal을 재시작하면 적용됩니다."
info ""
info "단축키 요약:"
info "  Alt+D          수평 분할 (좌우)"
info "  Alt+Shift+D    수직 분할 (상하)"
info "  Alt+W          패인 닫기"
info "  Alt+방향키     패인 이동"
info "  Alt+T          새 윈도우"
info "  Alt+[/]        윈도우 전환"
info "  Alt+P          PowerShell 탭"
info "  Ctrl+Shift+C/V 복사/붙여넣기"
