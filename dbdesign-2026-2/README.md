# 데이터베이스 설계 (2026-2) · MySQL 실습 스크립트

경영정보학과 데이터베이스 설계(122264-01) 수업의 주차별 MySQL 실습 스크립트 원본이다.
**학생은 GitHub 계정이 없어도 된다.** 평소에는 Notion 허브의 'MySQL 실습 스크립트' 페이지에서 복사해 쓰고, 이 저장소는 Notion이 열리지 않을 때의 예비 경로다.

## 스크립트

| 파일 | 내용 | 판 |
|---|---|---|
| [`sql/00_conn_check.sql`](sql/00_conn_check.sql) | 실습 환경 점검 — 내 PC의 MySQL에 연결되었는지 확인 (처음 한 번, 새 PC에서 한 번) | v2 · 2026-10-27 |
| [`sql/wk08_composite_key_normalization.sql`](sql/wk08_composite_key_normalization.sql) | 8주차 — 복합키·외래키가 막는 것, 이행 종속과 갱신 이상 | v2 · 2026-10-27 |
| [`sql/wk09_datatype_key.sql`](sql/wk09_datatype_key.sql) | 9주차 — 데이터 타입을 잘못 고르면 생기는 일, 연결 엔터티 CREATE TABLE | v2 · 2026-10-27 |

## 쓰는 방법 (4단계, 매주 같다)

1. **연결** — MySQL Workbench에서 내 연결 타일(학번_이름)을 연다. `Could not acquire management access … chcp` 창이 뜨면 **[OK]**로 닫는다 (SQL 실행과 관계없는 서버 관리 화면 오류).
2. **복사** — 위 표에서 파일을 누르고, 파일 화면 오른쪽 위 **복사 아이콘(Copy raw file)** 을 누른다.
3. **붙여넣기** — Workbench의 Query 탭을 누르고 **Ctrl+V**.
4. **실행** — ⓪ 블록부터 하나씩 드래그해 선택하고 **Ctrl+Shift+Enter** (macOS: Cmd+Shift+Enter). 전체를 한 번에 실행하지 않는다.

명령줄(MySQL Command Line Client)로 실행할 때만 파일 화면의 **내려받기 아이콘(Download raw file)** 으로 `C:\dblab`에 저장하고 `source C:/dblab/wk09_datatype_key.sql` 처럼 실행한다.

## 모든 주차 스크립트의 공통 규칙

- **⓪ 연결 확인** — 첫 블록. Workbench를 다시 열면 ⓪만 다시 실행하고 하던 블록부터 이어 한다.
- **① 주차별 연습 DB** — `wk8_check`, `wk9_check` … 주차마다 따로라서 같은 탭에서 이어 해도 서로 건드리지 않는다. 막히면 ①부터 다시 하면 처음 상태가 된다.
- **블록 첫 줄 USE** — ①을 건너뛰면 다른 주차 DB에 몰래 만들어지는 대신 Error 1049로 바로 알려 준다.
- **(다시 시작점)** — 이 표시가 있는 블록은 몇 번이고 그 블록부터 다시 할 수 있다.
- **확인 오류는 블록당 하나** — 일부러 내는 오류는 블록 마지막 줄에 있다. 오류가 나면 Workbench가 멈추는 것이 정상이다.
- 처음 실행할 때 Output 창의 노란 경고 `1008 Can't drop database`, `1051 Unknown table`은 정상이다.

## 실습 기록

각자 조 Notion 페이지의 **'🧪 MySQL 실습 기록'** 내 칸에 ⓪ 결과 캡처, 확인 오류 캡처, 배운 것 한 줄을 남긴다. 본인 계정으로 직접 작성한 기록이 평가 근거다.

## 검증

모든 스크립트는 배포 전에 MySQL 서버에서 Workbench와 같은 방식(블록 단위 실행, 오류에서 멈춤)으로 실행해 기대 결과를 확인했다. 같은 연결에서 주차를 정순·역순으로 이어 실행해도 결과가 같다.

---
김민중 · blu2se@kmu.ac.kr · 이 저장소의 스크립트는 수업 실습용이다.
