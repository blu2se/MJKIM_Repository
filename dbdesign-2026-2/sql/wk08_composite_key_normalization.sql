-- =====================================================================
-- 데이터베이스 설계 · 8주차 목요일 · MySQL로 손으로 확인하기 (v2, 10.27 보완)
-- 실행 환경: 내 PC의 MySQL Server 8.4 + Workbench (연결 이름: 학번_이름)
-- 실행 방법: 블록(⓪~⑧)을 하나씩 마우스로 드래그해 선택한 뒤
--           번개 아이콘(Execute the selected portion) 또는
--           Ctrl+Shift+Enter (macOS: Cmd+Shift+Enter)로 실행한다.
--           한 번에 전체를 실행하지 않는다 — 오류가 나야 하는 블록이 있다.
-- 오류가 나는 블록은 '일부러' 오류를 내는 확인 블록이다.
--           아무것도 선택하지 않고 Ctrl+Shift+Enter를 누르면 파일 전체가 실행되어 ④에서 멈춘다.
-- (v2) 블록 규칙 — 8주차 이후 모든 주차 스크립트에 같다
--   · ①을 뺀 모든 블록 첫 줄은 USE wk8_check; — 다른 주차 DB에 잘못 만들지 않게 하는 안전장치다
--     (①을 건너뛰면 Error 1049가 나서 바로 알 수 있다 → ①부터 실행)
--   · '다시 시작점' 블록은 DROP TABLE IF EXISTS로 시작해, 그 블록부터 몇 번이고 다시 할 수 있다
--     (처음 실행할 때 '1051 Unknown table' 노란 경고는 정상)
--
-- ※ 연결을 열 때 'Could not acquire management access for administration'
--   (RuntimeError: Unable to execute command chcp) 창이 뜨면 [OK]로 닫고 그대로 진행한다.
--   Workbench '서버 관리' 화면의 오류이며 SQL 실행과는 관계없다. ⓪이 실행되면 연결은 정상이다.
--   ⓪에서 Error 2003·1045 등이 나면 '실습 환경 점검 가이드'의 해결 절차를 따른다.
-- =====================================================================

-- ⓪ 연결 확인과 실행 설정 (v2 추가) — Workbench를 다시 열었거나 새 탭이면 다시 실행한다
--    기대 결과: version = 8.4.x, current_user_name = root@localhost, port = 3306
SET NAMES utf8mb4;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SELECT VERSION() AS version, CURRENT_USER() AS current_user_name, @@port AS port;

-- ① 연습용 데이터베이스 만들기 (각자 자기 PC에서만 쓴다)
--    처음 실행할 때 Output 창의 '1 warning(s): 1008 Can't drop database' 노란 표시는 정상이다
DROP DATABASE IF EXISTS wk8_check;
CREATE DATABASE wk8_check DEFAULT CHARACTER SET utf8mb4;
USE wk8_check;

-- =====================================================================
-- A. N:M 관계를 연결 엔터티로 — 복합키가 무엇을 막아 주는가
--    업무 규칙: 한 사원은 여러 프로젝트에, 한 프로젝트에는 여러 사원이 투입된다.
--              같은 사원이 같은 프로젝트에 두 번 투입되지 않는다.
-- =====================================================================

-- ② 테이블 세 개 만들기: 사원, 프로젝트, 연결 엔터티(프로젝트투입)  (다시 시작점: A를 다시 할 때 여기부터)
USE wk8_check;
DROP TABLE IF EXISTS project_assignment, project, employee;
CREATE TABLE employee (
  employee_id    INT UNSIGNED  NOT NULL,
  employee_name  VARCHAR(50)   NOT NULL,
  PRIMARY KEY (employee_id)
);

CREATE TABLE project (
  project_id    CHAR(4)       NOT NULL,
  project_name  VARCHAR(100)  NOT NULL,
  PRIMARY KEY (project_id)
);

CREATE TABLE project_assignment (
  employee_id      INT UNSIGNED  NOT NULL,
  project_id       CHAR(4)       NOT NULL,
  assignment_date  DATE          NOT NULL,
  role_code        VARCHAR(20)   NOT NULL,
  PRIMARY KEY (employee_id, project_id),                       -- 복합키
  FOREIGN KEY (employee_id) REFERENCES employee (employee_id),  -- FK 1
  FOREIGN KEY (project_id)  REFERENCES project (project_id)     -- FK 2
);

-- ③ 정상 데이터 넣기
USE wk8_check;
INSERT INTO employee VALUES (1001, '김하늘'), (1002, '이바다'), (1003, '박구름');
INSERT INTO project  VALUES ('P001', '물류 대시보드'), ('P002', '고객 분석');
INSERT INTO project_assignment VALUES
  (1001, 'P001', '2026-09-01', 'DEV'),
  (1001, 'P002', '2026-10-01', 'ANALYST'),   -- 김하늘은 프로젝트 2개 (N)
  (1002, 'P001', '2026-09-15', 'MANAGER');   -- P001에는 사원 2명 (M)

-- ④ 확인 1 — 같은 사원을 같은 프로젝트에 한 번 더 투입해 본다
--    기대 결과: Error Code 1062. Duplicate entry '1001-P001' for key ... PRIMARY
--    → 복합키가 업무 규칙 "두 번 투입되지 않는다"를 DB가 지키게 한다.
USE wk8_check;
INSERT INTO project_assignment VALUES (1001, 'P001', '2026-11-01', 'DEV');

-- ⑤ 확인 2 — 없는 사원(9999)을 투입해 본다
--    기대 결과: Error Code 1452. Cannot add or update a child row: a foreign key constraint fails
--    → 외래키가 '없는 사원'의 투입 기록을 막는다.
USE wk8_check;
INSERT INTO project_assignment VALUES (9999, 'P002', '2026-11-01', 'DEV');

-- ⑥ 확인 3 — 누가 어느 프로젝트에 어떤 역할로 투입되었는가 (세 테이블 JOIN)
--    기대 결과: 3행. 투입일·역할은 사원에도 프로젝트에도 없고 연결 엔터티에만 있다.
USE wk8_check;
SELECT e.employee_name, p.project_name, a.assignment_date, a.role_code
FROM project_assignment AS a
JOIN employee AS e ON e.employee_id = a.employee_id
JOIN project  AS p ON p.project_id  = a.project_id
ORDER BY e.employee_id, p.project_id;

-- =====================================================================
-- B. 이행 종속을 그대로 두면 — 갱신 이상을 직접 일으켜 본다
--    업무 규칙: 과정마다 분야가 하나, 분야마다 분야명이 하나다.
--    과정코드 → 분야코드 → 분야명  (이행 종속, 3NF 위반)
-- =====================================================================

-- ⑦ 정규화 전: 분야명이 과정 행마다 반복된다  (다시 시작점: B를 다시 할 때 여기부터)
USE wk8_check;
DROP TABLE IF EXISTS course_before;
CREATE TABLE course_before (
  course_id          CHAR(4)       NOT NULL,
  course_name        VARCHAR(100)  NOT NULL,
  training_hours     SMALLINT UNSIGNED NOT NULL,
  course_field_id    CHAR(2)       NOT NULL,
  course_field_name  VARCHAR(50)   NOT NULL,
  PRIMARY KEY (course_id)
);
INSERT INTO course_before VALUES
  ('DB01', '데이터베이스 기초', 16, 'DB', '데이터베이스'),
  ('DB02', 'SQL 활용',         24, 'DB', '데이터베이스'),
  ('AI03', 'AI 활용',          32, 'AI', '인공지능');

--    분야명을 '데이터베이스·SQL'로 바꾸라는 지시가 왔다. 담당자가 DB01 한 행만 고쳤다.
UPDATE course_before SET course_field_name = '데이터베이스·SQL' WHERE course_id = 'DB01';

--    기대 결과: DB 분야의 이름이 두 가지('데이터베이스·SQL', '데이터베이스')로 나온다 → 갱신 이상
SELECT course_field_id, course_field_name, COUNT(*) AS course_count
FROM course_before
GROUP BY course_field_id, course_field_name
ORDER BY course_field_id;

-- ⑧ 정규화 후: 결정자(분야코드)를 PK로 떼어 내고, 원래 자리에는 FK로 남긴다  (다시 시작점)
USE wk8_check;
DROP TABLE IF EXISTS course, course_field;
CREATE TABLE course_field (
  course_field_id    CHAR(2)      NOT NULL,
  course_field_name  VARCHAR(50)  NOT NULL,
  PRIMARY KEY (course_field_id)
);
CREATE TABLE course (
  course_id        CHAR(4)          NOT NULL,
  course_name      VARCHAR(100)     NOT NULL,
  training_hours   SMALLINT UNSIGNED NOT NULL,
  course_field_id  CHAR(2)          NOT NULL,
  PRIMARY KEY (course_id),
  FOREIGN KEY (course_field_id) REFERENCES course_field (course_field_id)
);
INSERT INTO course_field VALUES ('DB', '데이터베이스'), ('AI', '인공지능');
INSERT INTO course VALUES
  ('DB01', '데이터베이스 기초', 16, 'DB'),
  ('DB02', 'SQL 활용',         24, 'DB'),
  ('AI03', 'AI 활용',          32, 'AI');

--    같은 지시: 이번에는 한 행만 고치면 된다
UPDATE course_field SET course_field_name = '데이터베이스·SQL' WHERE course_field_id = 'DB';

--    기대 결과: DB01, DB02 모두 '데이터베이스·SQL' — 이름이 하나로 일치한다
SELECT c.course_id, c.course_name, f.course_field_name
FROM course AS c
JOIN course_field AS f ON f.course_field_id = c.course_field_id
ORDER BY c.course_id;

-- 끝. ⓪ 결과와 ④ 오류 화면을 캡처해 조 페이지 '🧪 MySQL 실습 기록'의 내 칸에 붙이고, 배운 것을 한 줄 쓴다.
-- 다 쓴 연습 DB는 지워도 된다:  DROP DATABASE wk8_check;
