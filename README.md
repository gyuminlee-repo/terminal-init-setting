# Terminal Init Setting

Windows Terminal + tmux 설정 자동 적용 스크립트.

WSL Ubuntu 환경에서 WezTerm 스타일의 단축키와 세션 보존(tmux)을 Windows Terminal에 적용한다.

## 적용 항목

| 파일 | 설명 |
|------|------|
| `terminal-settings.json` | Windows Terminal 설정 (WezTerm 컬러 스킴, 폰트, Acrylic, 세션 복원) |
| `tmux.conf` | tmux 설정 (WezTerm 스타일 Alt 단축키, 50000줄 스크롤백) |
| `setup-terminal.sh` | 원클릭 셋업 스크립트 |

## 사용법

```bash
git clone https://github.com/gyuminlee-repo/terminal-init-setting.git
cd terminal-init-setting
bash setup-terminal.sh
```

## 단축키

| 기능 | 단축키 |
|------|--------|
| 수평 분할 (좌우) | `Alt+D` |
| 수직 분할 (상하) | `Alt+Shift+D` |
| 패인 닫기 | `Alt+W` |
| 패인 이동 | `Alt+방향키` |
| 패인 크기 조절 | `Alt+Shift+방향키` |
| 새 윈도우 | `Alt+T` |
| 윈도우 전환 | `Alt+[` / `Alt+]` |
| 전체화면 | `Alt+Enter` |
| PowerShell 탭 | `Alt+P` |
| 복사 / 붙여넣기 | `Ctrl+Shift+C` / `Ctrl+Shift+V` |

## 세션 보존

터미널을 닫아도 tmux 서버가 WSL 안에서 유지된다. 다시 터미널을 열면 자동으로 이전 tmux 세션에 연결되어 출력 내용, 분할 레이아웃, 실행 중 프로세스가 그대로 복원된다.

## 요구사항

- Windows Terminal (Microsoft Store)
- WSL Ubuntu
- tmux (스크립트가 자동 설치)
- JetBrainsMono Nerd Font (선택 - 없으면 기본 폰트로 대체)
