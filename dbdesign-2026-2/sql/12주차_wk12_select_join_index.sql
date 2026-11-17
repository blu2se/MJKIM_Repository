-- =====================================================================
-- 데이터베이스 설계 · 12주차(11.19 목) · 조건 조회(WHERE) — 연습 스크립트 (v4)
-- =====================================================================
-- 실습은 3단계로 진행한다. 이 파일은 1단계용이다.
--   1단계 (전원)   ⓪ → ④ 블록을 순서대로 하나씩 실행한다. 연습 DB는 wk12_check다.
--   2단계 (파트장) 실습가이드 4절 '우리 조 틀'을 우리 조 DB에서 실행한다. ★ 표시 줄만 수정한다.
--          (PM)     우리 조 DB 이름을 확정하고 세 파트의 작성 현황을 확인한다.
--   3단계 (전원)   조 페이지 '🧪 MySQL 실습 기록'의 내 '12주차' 행을 작성하고 캡처 2장을 첨부한다.
--
-- ⑤ → ⑧(JOIN · 인덱스)은 이번 실습 범위에서 제외한다(11.17 조정). 12주차 강의자료로 학습한다.
--   강의자료의 결과는 이 블록들을 실제로 실행한 값이다. 확인하고 싶으면 실행해도 된다.
--
-- 실행 방법
--   · 블록 하나를 마우스로 드래그해 선택한다.
--   · Ctrl+Shift+Enter(macOS: Cmd+Shift+Enter)로 실행한다.
--   · 결과를 블록 주석의 '기대 결과'와 비교한다. 일치하면 다음 블록으로 넘어간다.
--
-- 이번 실습의 핵심: WHERE(조건 조회) — 조건에 맞는 행만 조회한다.
--   강의자료로 학습할 내용: INNER JOIN · LEFT JOIN · GROUP BY · 인덱스
--
-- 오류가 날 때
--   · Error 1049(Unknown database) → ①을 건너뛴 경우다. ①부터 다시 실행한다.
--   · ⑦에서 Error 1061(Duplicate key name) → 인덱스가 이미 있다. ②부터 다시 실행하면 초기 상태가 된다.
--   · Error 1052(… is ambiguous) → 두 테이블에 같은 이름의 컬럼이 있다. 컬럼 앞에 e. 또는 d.를 붙인다.
--   · 접속할 때 'chcp' 오류 창이 뜨면 [OK]로 닫는다. SQL 실행과는 관계없다.
--   · ⓪에서 Error 2003 · 1045가 나면 '실습 환경 점검 가이드'를 따른다.
-- =====================================================================

-- ⓪ 연결 확인 — Workbench를 열 때마다 가장 먼저 실행한다
--    기대 결과: version = 8.4.x · current_user_name = root@localhost · port = 3306
--    이 결과 화면이 캡처 1이다.
SET NAMES utf8mb4;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SELECT VERSION() AS version, CURRENT_USER() AS current_user_name, @@port AS port;

-- ① 연습 DB 만들기
--    기대 결과: 오류 없음. 왼쪽 Schemas 창을 새로고침(↻)하면 wk12_check가 보인다.
--    처음 실행하면 노란 경고 '1008 Can't drop database'가 뜬다. 정상이다.
DROP DATABASE IF EXISTS wk12_check;
CREATE DATABASE wk12_check DEFAULT CHARACTER SET utf8mb4;
USE wk12_check;

-- ② 부서 · 사원 테이블 생성과 데이터 입력 (재실행 시작 지점)
--    11주차와 같은 구조의 테이블이다. 이 블록을 다시 실행하면 초기 상태로 돌아간다.
--    부서 4개 중 기획팀(40)에는 소속 사원이 없다. ⑤ · ⑥에서 이 차이를 확인한다.
--    기대 결과: department_rows = 4 · employee_rows = 8
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
  (10, '인사팀'), (20, '영업팀'), (30, '재무팀'), (40, '기획팀');
INSERT INTO employee (employee_id, employee_name, employee_email, employee_phone, hire_date, department_id) VALUES
  (1001, '김시습', 'sisup.kim@kmtech.kr',     '010-1234-5678', '2024-03-02', 10),
  (1002, '이무송', 'musong.lee@kmtech.kr',     NULL,            '2025-01-06', 20),
  (1003, '박미래', 'mirae.park@kmtech.kr',  NULL,            '2026-02-16', 10),
  (1004, '최다솜', 'dasom.choi@kmtech.kr', '010-2222-3333', '2023-07-01', 20),
  (1005, '정강한', 'kanghan.jung@kmtech.kr',   NULL,            '2022-04-11', 30),
  (1006, '서하늘', 'haneul.seo@kmtech.kr',  NULL,            '2026-09-01', 30),
  (1007, '한우리', 'uri.han@kmtech.kr',   '010-4444-5555', '2021-11-15', 20),
  (1008, '윤나래', 'narae.yoon@kmtech.kr',   NULL,            '2025-05-20', 10);
SELECT (SELECT COUNT(*) FROM department) AS department_rows, (SELECT COUNT(*) FROM employee) AS employee_rows;

-- ③ 전체 조회 — 조건 조회 전에 저장된 데이터를 먼저 확인한다
--    기대 결과: 8행 — 1001 김시습 … 1008 윤나래
USE wk12_check;
SELECT employee_id, employee_name, hire_date, department_id
FROM employee
ORDER BY employee_id;

-- ④ SQL ① 조건 조회 (WHERE) — 2026년 입사 사원
--    WHERE는 조회할 행의 조건을 지정한다. ③의 8행 중 조건에 맞는 행만 조회된다.
--    ORDER BY는 정렬 순서를 지정한다.
--    기대 결과: 2행 — 1003 박미래 2026-02-16 · 1006 서하늘 2026-09-01
USE wk12_check;
SELECT employee_id, employee_name, hire_date
FROM employee
WHERE hire_date >= '2026-01-01'
ORDER BY hire_date;

-- ⑤ (선택 · 강의자료 학습) INNER JOIN — 사원명과 부서명을 함께 조회
--    사원 테이블에는 부서 번호만 있고 부서명은 부서 테이블에 있다. 그래서 두 테이블을 조인한다.
--    작성 순서는 네 단계다.
--      FROM employee e                  ← 1. 기준 테이블 (e는 사원 테이블의 별칭)
--      INNER JOIN department d          ← 2. 조인할 테이블 (d는 부서 테이블의 별칭)
--      ON d.department_id = e.department_id   ← 3. 조인 조건 (부모 PK = 자식 FK)
--      SELECT e.employee_name, d.department_name   ← 4. 조회 컬럼
--    INNER JOIN은 조인 조건이 일치하는 행만 조회한다. 사원이 없는 기획팀은 조회되지 않는다.
--    기대 결과: 8행 — 1001 김시습 인사팀 · 1002 이무송 영업팀 … 1008 윤나래 인사팀
USE wk12_check;
SELECT e.employee_id, e.employee_name, d.department_name
FROM employee e
INNER JOIN department d ON d.department_id = e.department_id
ORDER BY e.employee_id;

-- ⑥ (선택 · 강의자료 학습) LEFT JOIN — 전체 부서와 소속 사원
--    LEFT JOIN은 기준 테이블(FROM 뒤, 여기서는 부서)의 행을 모두 조회한다.
--    일치하는 행이 없으면 조인한 테이블의 컬럼은 NULL이 된다.
--    ⑤와 비교한다. ⑤에는 기획팀이 없고, 여기에는 기획팀이 NULL과 함께 조회된다.
--    용도: '사원이 0명인 부서도 조회해야 한다'처럼 누락되는 행이 없어야 할 때.
--    기대 결과: 9행 — 인사팀 3줄 · 영업팀 3줄 · 재무팀 2줄 · 기획팀 1줄(employee_name = NULL)
USE wk12_check;
SELECT d.department_id, d.department_name, e.employee_name
FROM department d
LEFT JOIN employee e ON e.department_id = d.department_id
ORDER BY d.department_id, e.employee_id;

-- ⑦ (선택 · 강의자료 학습) 인덱스 생성과 확인
--    인덱스는 책 뒤의 '찾아보기'와 같다. 조회 조건으로 자주 쓰는 컬럼에 만든다.
--    ④에서 입사일(hire_date)을 조건으로 조회했다. 그래서 hire_date에 만든다. 이것이 인덱스 생성 근거다.
--    명명 규칙: idx_테이블_컬럼
--    확인 방법은 두 가지다.
--      SHOW INDEX → 인덱스가 생성되었는가 (Key_name 컬럼에 idx_employee_hire_date)
--      EXPLAIN    → ④의 SQL이 그 인덱스를 사용하는가 (key 컬럼에 idx_employee_hire_date)
--    기대 결과: SHOW INDEX에 idx_employee_hire_date가 보인다. EXPLAIN의 key 컬럼 = idx_employee_hire_date
--    결과 탭이 2개 생긴다(SHOW INDEX · EXPLAIN).
USE wk12_check;
CREATE INDEX idx_employee_hire_date ON employee (hire_date);
SHOW INDEX FROM employee;
EXPLAIN SELECT employee_id, employee_name, hire_date
FROM employee
WHERE hire_date >= '2026-01-01'
ORDER BY hire_date;

-- ⑧ (선택 · 강의자료 학습) ERP · CRM 테이블 조인 — 사원별 상담 건수
--    상담 / consultation은 CRM 테이블이다. 상담마다 담당 사원번호(employee_id)가 있다.
--    사원 테이블(ERP)의 사원번호와 의미 · 값이 같다. 그래서 두 테이블을 조인할 수 있다.
--    기준 테이블: 사원 · 조인할 테이블: 상담 · 조인 조건: 사원번호
--    COUNT(c.consultation_id)는 사원별 상담 건수다. GROUP BY는 사원별로 한 행씩 집계한다.
--    LEFT JOIN이므로 상담이 없는 사원도 0건으로 조회된다.
--    기대 결과: 결과 탭 2개 — consultation_rows = 6 · 8행(이무송 3 · 최다솜 2 · 한우리 1 · 나머지 5명 0)
--    처음 실행하면 노란 경고 '1051 Unknown table'이 뜬다. 정상이다.
USE wk12_check;
DROP TABLE IF EXISTS consultation;
CREATE TABLE consultation (
  consultation_id            BIGINT UNSIGNED  NOT NULL,
  consultation_date          DATE             NOT NULL,
  customer_name              VARCHAR(50)      NOT NULL,
  employee_id                INT UNSIGNED     NOT NULL,   -- 담당 사원번호 (사원 테이블과 같은 이름 · 같은 타입)
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

-- 끝. 1단계는 여기까지다(⑤ → ⑧은 선택).
-- ---------------------------------------------------------------------
-- 3단계 · 기록 (전원) — 조 페이지 '🧪 MySQL 실습 기록'의 내 '12주차' 행
--   · 캡처 2장을 첨부한다: 캡처 1 ⓪ 결과 · 캡처 2 ④ WHERE 결과.
--   · 발생한 오류 번호를 적는다. 없으면 '없음'. 배운 점을 한 줄로 쓴다.
--   · 기록 마감은 12.11(금)이다. 끝내지 못하면 12.1(화) 보완 실습 때 작성한다.
-- ---------------------------------------------------------------------
-- 2단계 · 우리 파트 조건 조회 SQL 1개 (파트장) — 연습 DB가 아니라 우리 조 DB에서 실행한다
--   실습가이드 4절 '우리 조 틀'을 새 Query 탭에 복사한다. ★ 표시 줄만 우리 파트 이름으로 수정한다.
--   USE KM_TOS_DB;                                   -- ★ 우리 조 DB (통합시스템 영문 약어_DB)
--   SELECT * FROM 자식테이블 ORDER BY 자식테이블_id;    -- 1. 전체 조회 (③과 같은 형식)
--   SELECT … FROM 자식테이블 WHERE 조건컬럼 = 값;       -- 2. SQL ① 조건 조회 (④와 같은 형식)
--   실행에 성공한 SQL은 조 페이지 '12주차' 섹션 내 파트 작성란의 SQL 코드 블록에 붙인다.
-- ---------------------------------------------------------------------
-- 다음 주: 13주차(11.26)에는 요구사항 추적표 1건과 '📣 완료보고 발표' 섹션을 작성한다.
--   완료보고: 12.3(목) 1·2·3·4조 · 12.8(화) 5·6·7조.
-- 연습 DB를 삭제하려면: DROP DATABASE wk12_check;
