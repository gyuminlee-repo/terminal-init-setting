# Terminal Init Setting

Windows Terminal + WSL + tmux 자동 설정 스크립트.

WSL Ubuntu에서 터미널을 열면 자동으로 tmux 세션에 연결된다. WezTerm 스타일 단축키와 세션 보존을 지원한다.

## 적용 항목

| 파일 | 설명 |
|------|------|
| `terminal-settings.json` | Windows Terminal 설정 (WezTerm 컬러 스킴, Acrylic, 세션 복원) |
| `tmux.conf` | tmux 설정 (WezTerm 스타일 Alt 단축키, 50000줄 스크롤백) |
| `setup-terminal.sh` | 원클릭 셋업 스크립트 |

## 설치

```bash
git clone https://github.com/gyuminlee-repo/terminal-init-setting.git
cd terminal-init-setting
bash setup-terminal.sh
```

스크립트가 자동으로 설치하는 항목: tmux, zsh, oh-my-zsh, zsh 플러그인(autosuggestions, syntax-highlighting).

설치 후 Windows Terminal을 완전히 종료하고 다시 열면 적용된다.

## 단축키

### 패인 (화면 분할)

| 기능 | 단축키 |
|------|--------|
| 수평 분할 (좌우) | `Alt+D` |
| 수직 분할 (상하) | `Alt+Shift+D` |
| 패인 닫기 | `Alt+W` |
| 패인 줌 (전체화면 토글) | `Alt+Z` |
| 패인 이동 | `Alt+방향키` |
| 패인 크기 조절 | `Alt+Shift+방향키` |

### 윈도우 (탭)

| 기능 | 단축키 |
|------|--------|
| 새 윈도우 | `Alt+T` |
| 이전 윈도우 | `Alt+[` |
| 다음 윈도우 | `Alt+]` |

### 기타

| 기능 | 단축키 |
|------|--------|
| 전체화면 | `Alt+Enter` |
| PowerShell 탭 | `Alt+P` |
| 복사 | `Ctrl+Shift+C` |
| 붙여넣기 | `Ctrl+Shift+V` |

## tmux 사용 가이드

### 기본 동작

터미널을 열면 자동으로 tmux `main` 세션에 연결된다. 터미널을 닫아도 tmux 서버는 WSL 안에서 계속 살아있으며, 다시 열면 이전 상태(출력 내용, 분할 레이아웃, 실행 중 프로세스)가 그대로 복원된다.

### 세션 관리

```bash
# 새 세션 만들기 (이름 지정)
tmux new -s 작업이름

# 세션 목록 보기
tmux ls

# 특정 세션에 연결
tmux attach -t 작업이름

# 현재 세션에서 빠져나오기 (세션은 유지됨)
Ctrl+B → d

# 세션 종료 (완전 삭제)
tmux kill-session -t 작업이름
```

### 스크롤

마우스 스크롤로 이전 출력을 올려볼 수 있다 (마우스 모드 활성화 상태).

키보드로 스크롤하려면:
1. `Ctrl+B` → `[` 로 스크롤 모드 진입
2. `방향키` 또는 `Page Up/Down`으로 이동
3. `q`로 스크롤 모드 종료

### 복사 (tmux 스크롤 모드에서)

1. `Ctrl+B` → `[` 로 스크롤 모드 진입
2. `Space`로 선택 시작
3. 방향키로 범위 지정
4. `Enter`로 복사
5. `Ctrl+B` → `]` 로 붙여넣기

또는 마우스로 드래그 선택 → `Ctrl+Shift+C`로 클립보드에 복사.

### WSL 재부팅 시

WSL을 재부팅(`wsl --shutdown`)하면 tmux 서버도 종료된다. 이 경우 세션이 사라지므로, 다음 터미널 열 때 새 `main` 세션이 자동 생성된다.

### 알아두면 좋은 점

- **접두키 `Ctrl+B`**: 위 단축키 표의 Alt 조합이 안 되는 상황에서 tmux 기본 접두키로 대체 가능. `Ctrl+B` → `"` (수평분할), `Ctrl+B` → `%` (수직분할) 등.
- **윈도우 번호**: 하단 상태바에 `1:zsh 2:vim` 같은 형태로 표시된다. 번호는 1부터 시작.
- **스크롤백 버퍼**: 최대 50,000줄까지 보존. 오래된 출력은 버퍼를 넘어가면 사라진다.
- **tmux 설정 변경 후 반영**: `tmux source-file ~/.tmux.conf` 또는 tmux를 재시작.

## 요구사항

- Windows Terminal (Microsoft Store)
- WSL Ubuntu
