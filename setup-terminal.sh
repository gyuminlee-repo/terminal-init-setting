#!/usr/bin/env bash
# Windows Terminal + WSL + tmux 자동 설정 스크립트
# 목적: 터미널 열면 자동으로 tmux 세션에 연결
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
    sudo apt-get update -qq && sudo apt-get install -y tmux
    ok "tmux 설치 완료"
fi

# --------------------------------------------------
# 2. zsh + oh-my-zsh 설치
# --------------------------------------------------
if ! command -v zsh &>/dev/null; then
    info "zsh 설치 중..."
    sudo apt-get update -qq && sudo apt-get install -y zsh
    ok "zsh 설치 완료"
else
    ok "zsh $(zsh --version | awk '{print $2}') 설치됨"
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "oh-my-zsh 설치 중..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "oh-my-zsh 설치 완료"
else
    ok "oh-my-zsh 이미 설치됨"
fi

# 기본 셸이 zsh가 아니면 변경
if [ "$(basename "${SHELL:-}")" != "zsh" ]; then
    ZSH_PATH="$(command -v zsh)"
    if grep -q "$ZSH_PATH" /etc/shells; then
        chsh -s "$ZSH_PATH"
        ok "기본 셸을 zsh로 변경 완료 (재로그인 시 적용)"
    else
        warn "zsh가 /etc/shells에 없음 — 수동으로 chsh -s $(command -v zsh) 실행 필요"
    fi
fi

# --------------------------------------------------
# 3. oh-my-zsh 플러그인 설치
# --------------------------------------------------
if [ -d "$HOME/.oh-my-zsh" ]; then
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        ok "zsh-autosuggestions 이미 설치됨"
    else
        info "zsh-autosuggestions 설치 중..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        ok "zsh-autosuggestions 설치 완료"
    fi

    if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        ok "zsh-syntax-highlighting 이미 설치됨"
    else
        info "zsh-syntax-highlighting 설치 중..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        ok "zsh-syntax-highlighting 설치 완료"
    fi

    # plugins 라인에 autosuggestions/highlighting 추가 (아직 없으면)
    if [ -f "$HOME/.zshrc" ]; then
        if grep -q 'plugins=(' "$HOME/.zshrc" && ! grep -q 'zsh-autosuggestions' "$HOME/.zshrc"; then
            sed -i 's/plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
            ok "~/.zshrc plugins 업데이트 완료"
        else
            ok "~/.zshrc plugins 이미 설정됨 — 스킵"
        fi
    fi
fi

# --------------------------------------------------
# 4. ~/.tmux.conf 복사
# --------------------------------------------------
if [ -f "$HOME/.tmux.conf" ]; then
    cp "$HOME/.tmux.conf" "$HOME/.tmux.conf${BACKUP_SUFFIX}"
    info "기존 ~/.tmux.conf 백업 → ~/.tmux.conf${BACKUP_SUFFIX}"
fi
cp "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"
ok "~/.tmux.conf 적용 완료"

# --------------------------------------------------
# 4-1. TPM + tmux 플러그인 설치 (세션 복원용)
# --------------------------------------------------
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM_DIR" ]; then
    ok "TPM 이미 설치됨"
else
    info "TPM(Tmux Plugin Manager) 설치 중..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    ok "TPM 설치 완료"
fi

RESURRECT_DIR="$HOME/.tmux/plugins/tmux-resurrect"
if [ -d "$RESURRECT_DIR" ]; then
    ok "tmux-resurrect 이미 설치됨"
else
    info "tmux-resurrect 설치 중..."
    git clone https://github.com/tmux-plugins/tmux-resurrect "$RESURRECT_DIR"
    ok "tmux-resurrect 설치 완료"
fi

CONTINUUM_DIR="$HOME/.tmux/plugins/tmux-continuum"
if [ -d "$CONTINUUM_DIR" ]; then
    ok "tmux-continuum 이미 설치됨"
else
    info "tmux-continuum 설치 중..."
    git clone https://github.com/tmux-plugins/tmux-continuum "$CONTINUUM_DIR"
    ok "tmux-continuum 설치 완료 (15분마다 세션 자동 저장, 재시작 시 자동 복원)"
fi

# --------------------------------------------------
# 5. 셸 RC 파일에 tmux 자동 연결 블록 추가
# --------------------------------------------------
TMUX_BLOCK='# === tmux 자동 연결 (터미널 열면 바로 tmux 세션으로) ===
# - 이미 tmux 안이면 스킵
# - CLAUDE_CODE 등 비대화형 환경에서는 스킵
# - SSH 세션에서는 스킵 (원격 접속 시 의도치 않은 tmux 방지)
if command -v tmux &>/dev/null \
   && [ -z "${TMUX:-}" ] \
   && [ -z "${CLAUDE_CODE:-}" ] \
   && [ -z "${SSH_CONNECTION:-}" ] \
   && [[ $- == *i* ]]; then
    tmux attach -t main 2>/dev/null || tmux new -s main
fi'

# zsh를 설치했으므로 .zshrc에 추가 (chsh 적용은 재로그인 후)
RC_FILE="$HOME/.zshrc"

if [ -f "$RC_FILE" ] && grep -q "tmux attach -t main" "$RC_FILE"; then
    ok "$RC_FILE tmux 자동 연결 블록 이미 존재 — 스킵"
else
    # RC 파일이 없으면 생성
    touch "$RC_FILE"
    echo "" >> "$RC_FILE"
    echo "$TMUX_BLOCK" >> "$RC_FILE"
    ok "$RC_FILE에 tmux 자동 연결 블록 추가 완료"
fi

# --------------------------------------------------
# 6. .wslconfig 복사 (VM 종료 방지 → tmux 세션 유지)
# --------------------------------------------------
# Windows 사용자 폴더 자동 탐지
WIN_USER_DIR=""
for dir in /mnt/c/Users/*/; do
    base="$(basename "$dir")"
    if [[ "$base" != "Default" && "$base" != "Public" && "$base" != "All Users" && "$base" != "Default User" ]]; then
        WIN_USER_DIR="$dir"
        break
    fi
done

if [ -z "$WIN_USER_DIR" ]; then
    warn "Windows 사용자 폴더를 찾을 수 없음 — .wslconfig 수동 복사 필요"
else
    WSLCONFIG_PATH="${WIN_USER_DIR}.wslconfig"
    if [ -f "$WSLCONFIG_PATH" ]; then
        if grep -q 'vmIdleTimeout' "$WSLCONFIG_PATH"; then
            ok ".wslconfig vmIdleTimeout 이미 설정됨 — 스킵"
        else
            cp "$WSLCONFIG_PATH" "${WSLCONFIG_PATH}${BACKUP_SUFFIX}"
            info "기존 .wslconfig 백업 → .wslconfig${BACKUP_SUFFIX}"
            echo "" >> "$WSLCONFIG_PATH"
            cat "$SCRIPT_DIR/wslconfig" >> "$WSLCONFIG_PATH"
            ok ".wslconfig에 vmIdleTimeout=-1 추가 완료"
        fi
    else
        cp "$SCRIPT_DIR/wslconfig" "$WSLCONFIG_PATH"
        ok ".wslconfig 생성 완료 (vmIdleTimeout=-1)"
    fi
fi

# --------------------------------------------------
# 7. Windows Terminal settings.json 복사
# --------------------------------------------------
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
echo -e "\033[1;36m========================================\033[0m"
echo -e "\033[1;36m  설정 적용 완료!\033[0m"
echo -e "\033[1;36m========================================\033[0m"
echo ""
echo -e "\033[1;33m[다음 단계] 아래 작업을 직접 수행하세요:\033[0m"
echo ""
echo "  1. Windows Terminal을 완전히 종료 (X 버튼)"
echo "  2. Windows Terminal을 다시 실행"
echo "  3. Ubuntu 탭이 열리면 tmux 세션이 자동으로 시작되는지 확인"
echo ""
echo -e "\033[1;33m[확인 방법]\033[0m"
echo ""
echo "  - 좌측 하단에 초록색 상태바가 보이면 성공"
echo "  - 'tmux ls' 명령어로 세션 목록 확인 가능"
echo ""
echo -e "\033[1;33m[tmux 단축키]\033[0m"
echo ""
echo "  Alt+D          수평 분할 (좌우)"
echo "  Alt+Shift+D    수직 분할 (상하)"
echo "  Alt+W          패인 닫기"
echo "  Alt+Z          패인 줌 (전체화면 토글)"
echo "  Alt+방향키     패인 이동"
echo "  Alt+T          새 윈도우"
echo "  Alt+[/]        윈도우 전환"
echo "  Ctrl+B Ctrl+S  세션 저장 (resurrect)"
echo "  Ctrl+B Ctrl+R  세션 복원 (resurrect)"
echo "  Ctrl+Shift+C/V 복사/붙여넣기"
