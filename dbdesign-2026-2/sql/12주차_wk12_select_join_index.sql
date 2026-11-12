-- =====================================================================
-- 데이터베이스 설계 · 12주차(11.19 목) · 찾아보는 SQL과 인덱스 1개 — 연습 스크립트 (v2)
-- =====================================================================
-- 오늘 할 일은 3단계다. 이 파일은 1단계만 한다.
--   1단계 (전원)   이 파일의 ⓪ → ⑧ 블록을 순서대로 하나씩 실행한다. 연습 DB wk12_check에서 한다.
--   2단계 (파트장) 실습가이드 '우리 조 틀'을 우리 조 DB에서 실행한다. ★ 표시한 곳만 바꾼다.
--                  (PM)   ERP 표와 CRM 표를 같은 번호로 이어 본다. 이을 칸이 있는 조만 한다.
--   3단계 (전원)   조 페이지 '🧪 MySQL 실습 기록'의 내 '12주차' 행을 채운다. 캡처 2장을 붙인다.
--
-- 실행하는 법
--   · 블록 하나를 마우스로 드래그해 선택한다.
--   · Ctrl+Shift+Enter(macOS: Cmd+Shift+Enter)를 누른다.
--   · 결과를 블록 주석의 '나와야 하는 결과'와 비교한다. 같으면 다음 블록으로 간다.
--
-- 오늘 배우는 것은 네 가지다.
--   WHERE (조건으로 찾기) · INNER JOIN (짝이 있는 행만 잇기)
--   LEFT JOIN (기준 표는 모두 남기고 잇기) · 인덱스 (자주 찾는 칸에 찾아보기 만들기)
--
-- 막히면
--   · Error 1049(Unknown database) → ①을 건너뛰었다. ①부터 다시 실행한다.
--   · ⑥에서 Error 1061(Duplicate key name) → 인덱스를 이미 만들었다. ②부터 다시 하면 처음 상태가 된다.
--   · Error 1052(… is ambiguous) → 두 표에 같은 이름의 칸이 있다. 칸 앞에 e. 이나 d. 을 붙인다.
--   · 연결할 때 'chcp' 오류 창이 뜨면 [OK]로 닫는다. SQL 실행과 관계없다.
--   · ⓪에서 Error 2003 · 1045가 나면 '실습 환경 점검 가이드'를 따른다.
-- =====================================================================

-- ⓪ 연결 확인 — Workbench를 열 때마다 가장 먼저 실행한다
--    나와야 하는 결과: version = 8.4.x · current_user_name = root@localhost · port = 3306
--    이 결과 화면이 캡처 1이다.
SET NAMES utf8mb4;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SELECT VERSION() AS version, CURRENT_USER() AS current_user_name, @@port AS port;

-- ① 연습 DB 만들기
--    나와야 하는 결과: 오류 없음. 왼쪽 Schemas 창을 새로고침(↻)하면 wk12_check가 보인다.
--    처음 실행하면 노란 경고 '1008 Can't drop database'가 뜬다. 정상이다.
DROP DATABASE IF EXISTS wk12_check;
CREATE DATABASE wk12_check DEFAULT CHARACTER SET utf8mb4;
USE wk12_check;

-- ② 부서 · 사원 테이블과 데이터 (처음부터 다시 하는 곳)
--    11주차와 같은 테이블 · 같은 데이터다. 이 블록을 다시 실행하면 처음 상태로 돌아간다.
--    부서 4개 중 개발팀(40)에는 사원이 없다. ⑤ · ⑥에서 이 차이를 본다.
--    나와야 하는 결과: department_rows = 4 · employee_rows = 8
--    처음 실행하면 노란 경고 '1051 Unknown table'이 뜬다. 정상이다.
USE wk12_check;
DROP TABLE IF EXISTS employee, department;
CREATE TABLE department (
  department_id    INT UNSIGNED  NOT NULL,
  department_name  VARCHAR(50)   NOT NULL,
  PRIMARY KEY (department_id),
  CONSTRAINT uk_department_name UNIQUE (department_name)
);
CREATE TABLE employee (
  employee_id      INT UNSIGNED  NOT NULL,
  employee_name    VARCHAR(50)   NOT NULL,
  employee_email   VARCHAR(100)  NOT NULL,
  employee_phone   VARCHAR(20)   NULL,
  hire_date        DATE          NOT NULL,
  department_id    INT UNSIGNED  NOT NULL,                 -- FK: 부서 번호
  PRIMARY KEY (employee_id),
  CONSTRAINT uk_employee_email UNIQUE (employee_email),
  CONSTRAINT fk_employee_department FOREIGN KEY (department_id)
    REFERENCES department (department_id)
    ON DELETE RESTRICT ON UPDATE RESTRICT
);
INSERT INTO department (department_id, department_name) VALUES
  (10, '인사팀'), (20, '영업팀'), (30, '물류팀'), (40, '개발팀');
INSERT INTO employee (employee_id, employee_name, employee_email, employee_phone, hire_date, department_id) VALUES
  (1001, '김하늘', 'sky.kim@kmtech.kr',     '010-1234-5678', '2024-03-02', 10),
  (1002, '이바다', 'sea.lee@kmtech.kr',     NULL,            '2025-01-06', 20),
  (1003, '박구름', 'cloud.park@kmtech.kr',  NULL,            '2026-02-16', 10),
  (1004, '최노을', 'sunset.choi@kmtech.kr', '010-2222-3333', '2023-07-01', 20),
  (1005, '정새벽', 'dawn.jung@kmtech.kr',   NULL,            '2022-04-11', 30),
  (1006, '한여름', 'summer.han@kmtech.kr',  NULL,            '2026-09-01', 30),
  (1007, '오가을', 'autumn.oh@kmtech.kr',   '010-4444-5555', '2021-11-15', 20),
  (1008, '유겨울', 'winter.yu@kmtech.kr',   NULL,            '2025-05-20', 10);
SELECT (SELECT COUNT(*) FROM department) AS department_rows, (SELECT COUNT(*) FROM employee) AS employee_rows;

-- ③ 표 전체 보기 — 찾기 전에 먼저 무엇이 들어 있는지 본다
--    나와야 하는 결과: 8행 — 1001 김하늘 … 1008 유겨울
USE wk12_check;
SELECT employee_id, employee_name, hire_date, department_id
FROM employee
ORDER BY employee_id;

-- ④ SQL ① 조건으로 찾기 (WHERE) — 2026년에 입사한 사원
--    WHERE는 '어떤 행만 보여 줄지'를 정한다. ③의 8행 중 조건에 맞는 행만 남는다.
--    ORDER BY는 '어떤 순서로 보여 줄지'를 정한다.
--    나와야 하는 결과: 2행 — 1003 박구름 2026-02-16 · 1006 한여름 2026-09-01
USE wk12_check;
SELECT employee_id, employee_name, hire_date
FROM employee
WHERE hire_date >= '2026-01-01'
ORDER BY hire_date;

-- ⑤ SQL ② 두 표 이어 보기 (INNER JOIN) — 사원 이름 옆에 부서 이름
--    사원 표에는 부서 번호만 있다. 부서 이름은 부서 표에 있다. 그래서 두 표를 잇는다.
--    네 단계로 쓴다.
--      FROM employee e                  ← 1. 기준 표 (e는 사원 표의 짧은 이름)
--      INNER JOIN department d          ← 2. 붙일 표 (d는 부서 표의 짧은 이름)
--      ON d.department_id = e.department_id   ← 3. 맞춰 볼 칸 (부모 PK = 자식 FK)
--      SELECT e.employee_name, d.department_name   ← 4. 보여 줄 칸
--    INNER JOIN은 짝이 있는 행만 보여 준다. 사원이 없는 개발팀은 나오지 않는다.
--    나와야 하는 결과: 8행 — 1001 김하늘 인사팀 · 1002 이바다 영업팀 … 1008 유겨울 인사팀
USE wk12_check;
SELECT e.employee_id, e.employee_name, d.department_name
FROM employee e
INNER JOIN department d ON d.department_id = e.department_id
ORDER BY e.employee_id;

-- ⑥ 두 표 이어 보기 (LEFT JOIN) — 모든 부서와 그 부서의 사원
--    LEFT JOIN은 기준 표(FROM 뒤, 여기서는 부서)의 행을 하나도 빼지 않는다.
--    짝이 없으면 붙일 표의 칸이 NULL로 남는다.
--    ⑤와 비교한다. ⑤에는 개발팀이 없고, 여기에는 개발팀이 NULL과 함께 나온다.
--    언제 쓰나: '사원이 0명인 부서도 보여야 한다'처럼 빠지는 행이 없어야 할 때.
--    나와야 하는 결과: 9행 — 인사팀 3줄 · 영업팀 3줄 · 물류팀 2줄 · 개발팀 1줄(employee_name = NULL)
USE wk12_check;
SELECT d.department_id, d.department_name, e.employee_name
FROM department d
LEFT JOIN employee e ON e.department_id = d.department_id
ORDER BY d.department_id, e.employee_id;

-- ⑦ 인덱스 1개 만들고 확인하기
--    인덱스는 책 뒤의 '찾아보기'와 같다. 자주 찾는 칸에 만든다.
--    ④에서 입사일(hire_date)로 찾았다. 그래서 hire_date에 만든다. 이것이 인덱스를 만든 이유다.
--    이름 규칙: idx_테이블_칸
--    확인은 두 가지다.
--      SHOW INDEX → 인덱스가 만들어졌는가 (Key_name 칸에 idx_employee_hire_date)
--      EXPLAIN    → ④의 SQL이 그 인덱스를 쓰는가 (key 칸에 idx_employee_hire_date)
--    나와야 하는 결과: SHOW INDEX에 idx_employee_hire_date가 보인다. EXPLAIN의 key 칸 = idx_employee_hire_date
--    결과 탭이 2개 생긴다(SHOW INDEX · EXPLAIN). 오른쪽 탭인 EXPLAIN 결과 화면이 캡처 2다.
USE wk12_check;
CREATE INDEX idx_employee_hire_date ON employee (hire_date);
SHOW INDEX FROM employee;
EXPLAIN SELECT employee_id, employee_name, hire_date
FROM employee
WHERE hire_date >= '2026-01-01'
ORDER BY hire_date;

-- ⑧ ERP 표와 CRM 표 이어 보기 — 사원별 상담 건수 (PM이 우리 조에서 쓰는 모양)
--    상담 / consultation은 CRM 쪽 표다. 상담마다 담당 사원번호(employee_id)가 적혀 있다.
--    사원 표(ERP)의 사원번호와 같은 뜻 · 같은 값이다. 그래서 두 표를 이을 수 있다.
--    기준 표: 사원 · 붙일 표: 상담 · 맞춰 볼 칸: 사원번호
--    COUNT(c.consultation_id)는 사원마다 이어진 상담 행의 수다. GROUP BY는 '사원마다 한 줄로'다.
--    LEFT JOIN이라서 상담이 없는 사원도 0건으로 나온다.
--    나와야 하는 결과: 결과 탭 2개 — consultation_rows = 6 · 8행(이바다 3 · 최노을 2 · 오가을 1 · 나머지 5명 0)
--    처음 실행하면 노란 경고 '1051 Unknown table'이 뜬다. 정상이다.
USE wk12_check;
DROP TABLE IF EXISTS consultation;
CREATE TABLE consultation (
  consultation_id            BIGINT UNSIGNED  NOT NULL,
  consultation_date          DATE             NOT NULL,
  customer_name              VARCHAR(50)      NOT NULL,
  employee_id                INT UNSIGNED     NOT NULL,   -- 담당 사원번호 (사원 표와 같은 이름 · 같은 타입)
  PRIMARY KEY (consultation_id)
);
INSERT INTO consultation (consultation_id, consultation_date, customer_name, employee_id) VALUES
  (1, '2026-11-02', '대구상사', 1002),
  (2, '2026-11-03', '경북유통', 1004),
  (3, '2026-11-05', '대구상사', 1002),
  (4, '2026-11-09', '한빛마트', 1007),
  (5, '2026-11-10', '경북유통', 1002),
  (6, '2026-11-11', '한빛마트', 1004);
SELECT COUNT(*) AS consultation_rows FROM consultation;
SELECT e.employee_id, e.employee_name, COUNT(c.consultation_id) AS consultation_count
FROM employee e
LEFT JOIN consultation c ON c.employee_id = e.employee_id
GROUP BY e.employee_id, e.employee_name
ORDER BY e.employee_id;

-- 끝. 여기까지가 1단계다.
-- ---------------------------------------------------------------------
-- 3단계 · 기록 (전원) — 조 페이지 '🧪 MySQL 실습 기록'의 내 '12주차' 행
--   · 캡처 2장을 붙인다: 캡처 1 ⓪ 결과 · 캡처 2 ⑦의 EXPLAIN 결과.
--   · 본 오류 번호가 있으면 적는다. 없으면 '없음'. 배운 것을 한 줄 쓴다.
--   · 기록 마감은 12.11(금)이다. 못 끝내면 12.1(화) 보완 실습 때 채운다.
-- ---------------------------------------------------------------------
-- 2단계 · 우리 파트 SQL 2개와 인덱스 1개 (파트장) — 연습 DB가 아니라 우리 조 DB에서 한다
--   실습가이드의 '우리 조 틀'을 새 Query 탭에 복사한다. ★ 표시한 곳만 우리 파트 이름으로 바꾼다.
--   USE KM_TOS_DB;                                          -- ★ 우리 조 DB (통합시스템 영문 약어_DB)
--   SELECT … FROM 자식테이블 WHERE 찾을칸 = 값;                -- SQL ① 조건으로 찾기 (④와 같은 모양)
--   SELECT … FROM 자식테이블 c INNER JOIN 부모테이블 p ON p.부모_id = c.부모_id;   -- SQL ② (⑤와 같은 모양)
--   CREATE INDEX idx_자식테이블_찾을칸 ON 자식테이블 (찾을칸);   -- 인덱스: SQL ①의 WHERE 칸에 (⑦과 같은 모양)
--   SHOW INDEX · EXPLAIN                                    -- 확인 (⑦과 같은 모양)
--   실행에 성공한 SQL은 조 페이지 '12주차' 섹션 내 파트 칸의 SQL 코드 블록에 붙인다.
-- ---------------------------------------------------------------------
-- 다음 주: 13주차(11.26)에는 요구사항 추적표 1건과 '📣 완료보고 발표' 섹션을 쓴다.
--   완료보고: 12.3(목) 1·2·3·4조 · 12.8(화) 5·6·7조.
-- 연습 DB를 지우려면: DROP DATABASE wk12_check;
