-- =====================================================================
-- 데이터베이스 설계 · MySQL 기초 따라 하기 — 테이블 · 속성 · 기본키 · 외래키 · 관계 (v1, 10.29)
-- 실행 환경: 내 PC의 MySQL Server 8.4 + Workbench (연결 이름: 학번_이름)
-- 실행 방법: 블록(⓪~⑩)을 하나씩 드래그해 선택한 뒤 번개 아이콘 또는
--           Ctrl+Shift+Enter (macOS: Cmd+Shift+Enter)로 실행한다.
--           전체를 한 번에 실행하지 않는다 — 일부러 오류를 내는 블록(⑤~⑧)이 있다.
-- 이 파일은 연습 DB(basics_check)만 만든다. 우리 조 DB나 다른 주차 DB는 건드리지 않는다.
-- 예제: 인사팀 교육수강대장 — 부서 / department · 사원 / employee · 교육과정 / course · 수강 / enrollment
--   부서 1 : N 사원 (사원은 한 부서에 속한다)
--   사원 N : M 교육과정 → 연결 엔터티 '수강'으로 푼다 (사원 1 : N 수강 N : 1 교육과정)
--
-- 블록 규칙 — 모든 주차 스크립트와 같다
--   · ①을 뺀 모든 블록 첫 줄은 USE basics_check; (①을 건너뛰면 Error 1049 → ①부터 실행)
--   · ②·③은 '다시 시작점'이다. DROP TABLE IF EXISTS로 시작해 그 블록부터 다시 할 수 있다
--     (처음 실행할 때 '1051 Unknown table' 노란 경고는 정상). ②를 다시 하면 ③ · ④도 다시 한다
--
-- ※ 연결을 열 때 'Could not acquire management access for administration'
--   (RuntimeError: Unable to execute command chcp) 창이 뜨면 [OK]로 닫고 그대로 진행한다.
-- =====================================================================

-- ⓪ 연결 확인과 실행 설정 — 매번 가장 먼저 실행한다
--    기대 결과: version = 8.4.x, current_user_name = root@localhost, port = 3306
SET NAMES utf8mb4;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SELECT VERSION() AS version, CURRENT_USER() AS current_user_name, @@port AS port;

-- ① 데이터베이스 만들기와 선택 — CREATE DATABASE · USE
--    기대 결과: 오류 없음. 왼쪽 'Schemas' 창을 새로고침(↻)하면 basics_check가 보인다
--    처음 실행할 때 '1 warning(s): 1008 Can't drop database' 노란 표시는 정상이다
DROP DATABASE IF EXISTS basics_check;
CREATE DATABASE basics_check DEFAULT CHARACTER SET utf8mb4;
USE basics_check;

-- ② 부모 테이블과 자식 테이블 — 속성(컬럼) · 타입 · NOT NULL · 기본키 · 외래키  (다시 시작점)
--    읽는 법: 컬럼마다 '이름  타입  NULL 허용 여부  [DEFAULT 기본값]' 순서로 쓴다
--    부모(department)를 먼저, 자식(employee)을 나중에 만든다 — 순서가 바뀌면 Error 1824
--    기대 결과: SHOW TABLES에 department · employee 2개, DESC employee에 5행(Key 열: PRI · MUL)
USE basics_check;
DROP TABLE IF EXISTS enrollment, employee, course, department;
CREATE TABLE department (
  department_id    INT UNSIGNED  NOT NULL,          -- 기본키(PK): 부서를 하나씩 구별하는 번호
  department_name  VARCHAR(50)   NOT NULL,
  PRIMARY KEY (department_id),
  UNIQUE (department_name)                          -- 대체키: 같은 부서 이름은 두 번 없다
);
CREATE TABLE employee (
  employee_id      INT UNSIGNED  NOT NULL,          -- PK
  employee_name    VARCHAR(50)   NOT NULL,          -- 꼭 있어야 하는 값 → NOT NULL
  employee_phone   VARCHAR(20)   NULL,              -- 없어도 되는 값 → NULL, 번호는 문자
  hire_date        DATE          NOT NULL,
  department_id    INT UNSIGNED  NOT NULL,          -- 외래키(FK): 이름 · 타입이 부모 PK와 똑같다
  PRIMARY KEY (employee_id),
  FOREIGN KEY (department_id) REFERENCES department (department_id)   -- 관계: 부서 1 : N 사원
);
SHOW TABLES;
DESC employee;

-- ③ N:M을 연결 엔터티로 — 복합 기본키 · 외래키 두 개 · DEFAULT · CHECK  (다시 시작점)
--    기대 결과: SHOW CREATE TABLE의 결과 칸에 PRIMARY KEY (employee_id, course_id)와
--              FOREIGN KEY 두 줄, CHECK 두 줄이 보인다 (결과 칸을 오른쪽 클릭 → Open Value in Viewer)
USE basics_check;
DROP TABLE IF EXISTS enrollment, course;
CREATE TABLE course (
  course_id        CHAR(4)            NOT NULL,     -- 업무 코드형 PK (예: DB01)
  course_name      VARCHAR(100)       NOT NULL,
  training_hours   SMALLINT UNSIGNED  NOT NULL,
  course_fee       DECIMAL(12,2)      NOT NULL DEFAULT 0.00,   -- 금액은 DECIMAL, 값이 없으면 0
  PRIMARY KEY (course_id)
);
CREATE TABLE enrollment (
  employee_id      INT UNSIGNED      NOT NULL,      -- FK 1 (= employee.employee_id)
  course_id        CHAR(4)           NOT NULL,      -- FK 2 (= course.course_id)
  enrollment_date  DATE              NOT NULL,
  score            TINYINT UNSIGNED  NULL,          -- 아직 점수가 없을 수 있다
  completion_yn    CHAR(1)           NOT NULL DEFAULT 'N',
  PRIMARY KEY (employee_id, course_id),             -- 복합키: 같은 사원이 같은 과정을 두 번 수강하지 않는다
  FOREIGN KEY (employee_id) REFERENCES employee (employee_id),
  FOREIGN KEY (course_id)   REFERENCES course (course_id),
  CHECK (score <= 100),                             -- 업무 규칙: 점수는 0~100
  CHECK (completion_yn IN ('Y', 'N'))               -- 코드값은 Y / N만
);
SHOW CREATE TABLE enrollment;

-- ④ 데이터 넣기와 확인 — INSERT · SELECT (이 블록은 몇 번 다시 해도 같은 결과)
--    넣는 순서도 부모 → 자식. 지울 때는 자식 → 부모
--    기대 결과: 마지막 SELECT 3행. 이바다(1002)의 completion_yn은 넣지 않았는데 DEFAULT 'N'이 들어간다
USE basics_check;
DELETE FROM enrollment;
DELETE FROM employee;
DELETE FROM course;
DELETE FROM department;
INSERT INTO department VALUES (10, '인사팀'), (20, '영업팀');
INSERT INTO employee VALUES
  (1001, '김하늘', '010-1234-5678', '2024-03-02', 10),
  (1002, '이바다', NULL,            '2025-01-06', 20);
INSERT INTO course (course_id, course_name, training_hours, course_fee) VALUES
  ('DB01', '데이터베이스 기초', 16, 120000.00),
  ('AI03', 'AI 활용',          32, 250000.00);
INSERT INTO enrollment (employee_id, course_id, enrollment_date, score, completion_yn) VALUES
  (1001, 'DB01', '2026-09-01', 92, 'Y'),
  (1001, 'AI03', '2026-10-05', NULL, 'N');
INSERT INTO enrollment (employee_id, course_id, enrollment_date) VALUES (1002, 'DB01', '2026-10-12');
SELECT * FROM enrollment ORDER BY employee_id, course_id;

-- ⑤ 기본키가 막는 것 — 같은 사원 번호를 한 번 더 넣는다
--    기대 결과: Error Code: 1062. Duplicate entry '1001' for key 'employee.PRIMARY'
USE basics_check;
INSERT INTO employee VALUES (1001, '박구름', NULL, '2026-10-29', 10);

-- ⑥ 외래키가 막는 것 — 없는 부서(99)에 사원을 넣는다
--    기대 결과: Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails
USE basics_check;
INSERT INTO employee VALUES (1003, '박구름', NULL, '2026-10-29', 99);

-- ⑦ CHECK가 막는 것 — 점수 120을 넣는다
--    기대 결과: Error Code: 3819. Check constraint 'enrollment_chk_1' is violated.
--    (MySQL 8.0.16 이상에서 동작한다. MariaDB 등 다른 DB에서는 번호가 다르다)
USE basics_check;
INSERT INTO enrollment VALUES (1002, 'AI03', '2026-10-29', 120, 'N');

-- ⑧ NOT NULL이 막는 것 — 사원 이름을 비운다
--    기대 결과: Error Code: 1048. Column 'employee_name' cannot be null
USE basics_check;
INSERT INTO employee VALUES (1004, NULL, NULL, '2026-10-29', 10);

-- ⑨ 만든 테이블 고치기 — ALTER TABLE (컬럼 추가 → 확인 → 되돌리기)
--    테이블을 지우지 않고 속성을 더하거나 뺄 때 쓴다. 이 블록은 다시 해도 같은 결과
--    기대 결과: 첫 DESC에 employee_email 행이 보이고, 두 번째 DESC에서 사라진다
USE basics_check;
ALTER TABLE employee ADD COLUMN employee_email VARCHAR(100) NULL AFTER employee_phone;
DESC employee;
ALTER TABLE employee DROP COLUMN employee_email;
DESC employee;

-- ⑩ Notion에 옮길 결과 만들기 — 관계 따라 조회(JOIN)와 키 목록
--    첫 SELECT: 누가 어느 부서에서 어떤 과정을 들었는가 — 기대 결과 3행
--    두 번째 SELECT: 테이블마다 PK · FK가 무엇이고 어디를 참조하는가 — 키 정의서와 대조한다
--    → Result Grid에서 결과를 캡처하거나, 행을 선택해 오른쪽 클릭 → Copy Row (with names, tab separated)
USE basics_check;
SELECT d.department_name, e.employee_name, c.course_name, en.enrollment_date, en.score, en.completion_yn
FROM enrollment AS en
JOIN employee   AS e ON e.employee_id   = en.employee_id
JOIN department AS d ON d.department_id = e.department_id
JOIN course     AS c ON c.course_id     = en.course_id
ORDER BY e.employee_id, c.course_id;
SELECT TABLE_NAME AS table_name, COLUMN_NAME AS column_name, CONSTRAINT_NAME AS constraint_name,
       REFERENCED_TABLE_NAME AS ref_table, REFERENCED_COLUMN_NAME AS ref_column
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'basics_check'
ORDER BY TABLE_NAME, CONSTRAINT_NAME, ORDINAL_POSITION;

-- 끝. 이 스크립트는 선택이다(기록 의무 · 가중치 없음). 해 봤다면 '🧪 MySQL 실습 기록'의 '실습 환경 점검' 행 '배운 것'에 한 줄 덧붙여도 된다.
--     우리 조 테이블을 만들 때는 ②~③의 틀을 복사해 이름 · 타입만 우리 조 정의서대로 바꾼다.
-- 연습 DB를 지우려면: DROP DATABASE basics_check;
