-- =====================================================================
-- 데이터베이스 설계 · 10주차 목요일 · MySQL로 확인하기 — 제약조건과 CREATE TABLE (v1, 11.5)
-- 실행 환경: 내 PC의 MySQL Server 8.4 + Workbench (연결 이름: 학번_이름)
-- 실행 방법: 블록(⓪~⑨)을 하나씩 드래그해 선택한 뒤 번개 아이콘 또는
--           Ctrl+Shift+Enter (macOS: Cmd+Shift+Enter)로 실행한다.
--           전체를 한 번에 실행하지 않는다 — 일부러 오류를 내는 블록(⑥-1~⑨)이 있다.
--           아무것도 선택하지 않고 Ctrl+Shift+Enter를 누르면 파일 전체가 실행되어 ⑥-1에서 멈춘다.
-- 이 파일은 연습 DB(wk10_check)만 만든다. 우리 조 DB(team1_db 등)나 다른 주차 DB는 건드리지 않는다.
-- 예제: 화요일 강의의 인사팀 교육수강대장 — 부서 / department · 사원 / employee · 교육과정 / course · 수강 / enrollment
--   부서 1 : N 사원 · 사원 1 : N 수강 · 교육과정 1 : N 수강 (사원 N : M 교육과정을 수강으로 해소)
--
-- 블록 규칙 — 8주차 이후 모든 주차 스크립트와 같다
--   · ①을 뺀 모든 블록 첫 줄은 USE wk10_check; (①을 건너뛰면 Error 1049 → ①부터 실행)
--   · ②·③·④는 '다시 시작점'이다. DROP TABLE IF EXISTS로 시작해 그 블록부터 다시 할 수 있다
--     (처음 실행할 때 '1051 Unknown table' 노란 경고는 정상). ②를 다시 하면 ③·④도, ③을 다시 하면 ④도 다시 한다
--   · 제약조건에는 이름을 붙인다: uk_{테이블}_{컬럼} · fk_{자식}_{부모} · ck_{테이블}_{컬럼}
--     → 오류 메시지에 이 이름이 나와서 무엇이 막았는지 바로 읽힌다 (PK의 이름은 MySQL이 늘 PRIMARY로 붙인다)
--
-- ※ 연결을 열 때 'Could not acquire management access for administration'
--   (RuntimeError: Unable to execute command chcp) 창이 뜨면 [OK]로 닫고 그대로 진행한다.
--   ⓪에서 Error 2003·1045 등이 나면 '실습 환경 점검 가이드'의 해결 절차를 따른다.
-- =====================================================================

-- ⓪ 연결 확인과 실행 설정 — 매번 가장 먼저 실행한다
--    기대 결과: version = 8.4.x, current_user_name = root@localhost, port = 3306
--    엄격 모드(STRICT_TRANS_TABLES)가 꺼져 있으면 ⑥-1의 NULL이 오류 대신 경고로 바뀔 수 있다 → ⓪을 꼭 먼저
SET NAMES utf8mb4;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SELECT VERSION() AS version, CURRENT_USER() AS current_user_name, @@port AS port;

-- ① 연습용 데이터베이스
--    기대 결과: 오류 없음. 왼쪽 'Schemas' 창을 새로고침(↻)하면 wk10_check가 보인다
--    처음 실행할 때 '1 warning(s): 1008 Can't drop database' 노란 표시는 정상이다
DROP DATABASE IF EXISTS wk10_check;
CREATE DATABASE wk10_check DEFAULT CHARACTER SET utf8mb4;
USE wk10_check;

-- =====================================================================
-- A. 테이블 정의서를 CREATE TABLE로 — 부모(기준) → 자식(사건·연결) 순서
-- =====================================================================

-- ② 기준 테이블 두 개: 부서, 교육과정 — PK · NOT NULL · UNIQUE · DEFAULT · CHECK  (다시 시작점)
--    지울 때는 자식 → 부모 순서로 한 줄에 적는다(enrollment가 맨 앞)
--    기대 결과: SHOW TABLES에 course · department 2개
USE wk10_check;
DROP TABLE IF EXISTS enrollment, employee, course, department;
CREATE TABLE department (
  department_id    INT UNSIGNED  NOT NULL,                 -- PK 번호형 (기준 엔터티)
  department_name  VARCHAR(50)   NOT NULL,
  PRIMARY KEY (department_id),
  CONSTRAINT uk_department_name UNIQUE (department_name)   -- 대체키: 같은 부서 이름은 하나뿐
);
CREATE TABLE course (
  course_id        CHAR(4)            NOT NULL,            -- PK 코드형 (예: DB01)
  course_name      VARCHAR(100)       NOT NULL,
  training_hours   SMALLINT UNSIGNED  NOT NULL,
  course_fee       DECIMAL(12,2)      NOT NULL DEFAULT 0.00,
  PRIMARY KEY (course_id),
  CONSTRAINT ck_course_hours CHECK (training_hours > 0),   -- 업무 규칙: 교육시간은 1시간 이상
  CONSTRAINT ck_course_fee   CHECK (course_fee >= 0)       -- 업무 규칙: 수강료는 음수가 아니다
);
INSERT INTO department VALUES (10, '인사팀'), (20, '영업팀'), (30, '물류팀');
INSERT INTO course (course_id, course_name, training_hours, course_fee) VALUES
  ('DB01', '데이터베이스 기초', 16, 120000.00),
  ('AI03', 'AI 활용',          32, 250000.00);
INSERT INTO course (course_id, course_name, training_hours) VALUES ('SF02', '안전 교육', 4);   -- 수강료를 안 적으면 DEFAULT 0.00
SHOW TABLES;

-- ③ 자식 테이블: 사원 — FK(ON DELETE RESTRICT) · 대체키 UNIQUE · NULL 허용 칸  (다시 시작점)
--    FK 컬럼 department_id는 부모 PK와 이름·타입(INT UNSIGNED)이 똑같다
--    기대 결과: DESC employee 6행 — Key 열에 PRI(employee_id) · UNI(employee_email) · MUL(department_id)
USE wk10_check;
DROP TABLE IF EXISTS enrollment, employee;
CREATE TABLE employee (
  employee_id      INT UNSIGNED  NOT NULL,                 -- PK
  employee_name    VARCHAR(50)   NOT NULL,
  employee_email   VARCHAR(100)  NOT NULL,                 -- 새 끝말 _email: 도메인 표에 한 줄 더하고 테일러링 기록
  employee_phone   VARCHAR(20)   NULL,                     -- 없어도 되는 값 → NULL
  hire_date        DATE          NOT NULL,
  department_id    INT UNSIGNED  NOT NULL,                 -- FK = department.department_id (사원은 반드시 한 부서)
  PRIMARY KEY (employee_id),
  CONSTRAINT uk_employee_email UNIQUE (employee_email),
  CONSTRAINT fk_employee_department FOREIGN KEY (department_id)
    REFERENCES department (department_id)
    ON DELETE RESTRICT ON UPDATE RESTRICT                  -- 사원이 있는 부서는 지우지 못한다
);
INSERT INTO employee VALUES
  (1001, '김하늘', 'sky.kim@kmtech.kr',  '010-1234-5678', '2024-03-02', 10),
  (1002, '이바다', 'sea.lee@kmtech.kr',  NULL,            '2025-01-06', 20),
  (1003, '박구름', 'cloud.park@kmtech.kr', NULL,          '2026-02-16', 10);
DESC employee;

-- ④ 연결 테이블: 수강 — 복합키 · FK 두 개(옵션이 다르다) · DEFAULT · CHECK 두 개  (다시 시작점)
--    기대 결과: 마지막 SELECT 3행. 1002의 enrollment_status_code는 적지 않았는데 DEFAULT 'APPLIED'가 들어간다
--    SHOW CREATE TABLE의 결과 칸(오른쪽 클릭 → Open Value in Viewer)에 제약조건 이름이 모두 보인다
USE wk10_check;
DROP TABLE IF EXISTS enrollment;
CREATE TABLE enrollment (
  employee_id             INT UNSIGNED      NOT NULL,      -- PK·FK = employee.employee_id
  course_id               CHAR(4)           NOT NULL,      -- PK·FK = course.course_id
  application_date        DATE              NOT NULL,
  score                   TINYINT UNSIGNED  NULL,          -- 교육이 끝나기 전에는 비어 있다
  enrollment_status_code  VARCHAR(20)       NOT NULL DEFAULT 'APPLIED',
  PRIMARY KEY (employee_id, course_id),                    -- 같은 과정은 한 번만 신청한다
  CONSTRAINT fk_enrollment_employee FOREIGN KEY (employee_id)
    REFERENCES employee (employee_id)
    ON DELETE RESTRICT ON UPDATE RESTRICT,                 -- 수강 이력이 있는 사원은 지우지 못한다
  CONSTRAINT fk_enrollment_course FOREIGN KEY (course_id)
    REFERENCES course (course_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,                  -- 과정코드가 바뀌면 수강의 과정코드도 따라 바뀐다
  CONSTRAINT ck_enrollment_score  CHECK (score <= 100),
  CONSTRAINT ck_enrollment_status CHECK (enrollment_status_code IN ('APPLIED', 'ATTENDING', 'COMPLETED', 'CANCELED'))
);
INSERT INTO enrollment VALUES
  (1001, 'DB01', '2026-09-01', 92, 'COMPLETED'),
  (1001, 'AI03', '2026-10-05', NULL, 'ATTENDING');
INSERT INTO enrollment (employee_id, course_id, application_date) VALUES (1002, 'DB01', '2026-11-02');
SHOW CREATE TABLE enrollment;
SELECT * FROM enrollment ORDER BY employee_id, course_id;

-- ⑤ 검증 — 만든 테이블과 제약조건을 목록으로 본다 (Notion에 붙일 결과)
--    첫 SELECT 기대 결과: 13행 — CHECK 4 · FOREIGN KEY 3 · PRIMARY KEY 4 · UNIQUE 2
--    두 번째 SELECT 기대 결과: FK 3행 — fk_enrollment_course만 UPDATE_RULE = CASCADE, 나머지는 RESTRICT
USE wk10_check;
SELECT TABLE_NAME AS table_name, CONSTRAINT_TYPE AS constraint_type, CONSTRAINT_NAME AS constraint_name
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'wk10_check'
ORDER BY TABLE_NAME, CONSTRAINT_TYPE, CONSTRAINT_NAME;
SELECT CONSTRAINT_NAME AS fk_name, TABLE_NAME AS child_table, REFERENCED_TABLE_NAME AS parent_table,
       UPDATE_RULE AS update_rule, DELETE_RULE AS delete_rule
FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'wk10_check'
ORDER BY TABLE_NAME, CONSTRAINT_NAME;

-- =====================================================================
-- B. 제약조건이 막는 것 — 블록마다 오류 하나. 오류가 나야 정상이다
-- =====================================================================

-- ⑥-1 NOT NULL — 꼭 있어야 하는 값(사원명)을 비운다
--    기대 결과: Error Code: 1048. Column 'employee_name' cannot be null
USE wk10_check;
INSERT INTO employee VALUES (1004, NULL, 'new.one@kmtech.kr', NULL, '2026-11-05', 10);

-- ⑥-2 UNIQUE — 이미 있는 이메일로 사원을 넣는다 (대체키)
--    기대 결과: Error Code: 1062. Duplicate entry 'sky.kim@kmtech.kr' for key 'employee.uk_employee_email'
USE wk10_check;
INSERT INTO employee VALUES (1004, '최노을', 'sky.kim@kmtech.kr', NULL, '2026-11-05', 10);

-- ⑥-3 CHECK — 점수 120을 넣는다
--    기대 결과: Error Code: 3819. Check constraint 'ck_enrollment_score' is violated.
--    (CHECK는 MySQL 8.0.16부터 실제로 막는다. MariaDB 등 다른 DB에서는 오류 번호가 다르다)
USE wk10_check;
INSERT INTO enrollment VALUES (1003, 'DB01', '2026-11-05', 120, 'COMPLETED');

-- ⑥-4 FOREIGN KEY — 없는 부서(99)에 사원을 넣는다
--    기대 결과: Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails (… CONSTRAINT `fk_employee_department` …)
USE wk10_check;
INSERT INTO employee VALUES (1004, '최노을', 'sunset.choi@kmtech.kr', NULL, '2026-11-05', 99);

-- =====================================================================
-- C. FK 동작 옵션 — 부모를 지우거나 바꿀 때 자식은 어떻게 되는가
-- =====================================================================

-- ⑦ RESTRICT — 사원이 있는 부서(인사팀 10)를 지운다
--    기대 결과: Error Code: 1451. Cannot delete or update a parent row: a foreign key constraint fails (… `fk_employee_department` …)
--    → 사원이 남아 있는 부서는 지워지지 않는다. 사원이 없는 물류팀(30)은 지울 수 있다(해 보지 않아도 된다)
USE wk10_check;
DELETE FROM department WHERE department_id = 10;

-- ⑧ ON UPDATE CASCADE — 과정코드 DB01을 DB10으로 바꾼다 (이 블록은 다시 해도 같은 결과)
--    기대 결과: 첫 SELECT에서 수강 2행의 course_id가 DB10으로 함께 바뀌어 있다
--    마지막 UPDATE로 DB01로 되돌린다 → 다음 블록과 다시 실행에 영향 없음
USE wk10_check;
UPDATE course SET course_id = 'DB10' WHERE course_id = 'DB01';
SELECT employee_id, course_id, enrollment_status_code FROM enrollment ORDER BY employee_id, course_id;
UPDATE course SET course_id = 'DB01' WHERE course_id = 'DB10';

-- ⑨ ON DELETE SET NULL — NOT NULL인 FK에는 쓸 수 없다 (테이블이 만들어지지 않는다)
--    기대 결과: Error Code: 1830. Column 'department_id' cannot be NOT NULL: needed in a foreign key constraint 'fk_employee_wrong_department' SET NULL
--    → SET NULL은 '선택적' 관계(0..N, FK가 NULL 허용)에서만 쓴다. 관계 정의서의 선택성이 FK 옵션을 정한다
USE wk10_check;
DROP TABLE IF EXISTS employee_wrong;
CREATE TABLE employee_wrong (
  employee_id    INT UNSIGNED  NOT NULL,
  department_id  INT UNSIGNED  NOT NULL,
  PRIMARY KEY (employee_id),
  CONSTRAINT fk_employee_wrong_department FOREIGN KEY (department_id)
    REFERENCES department (department_id) ON DELETE SET NULL
);

-- 끝. ⓪ 결과와 확인 오류 1개(⑥-3의 3819 또는 ⑦의 1451)를 캡처해 조 페이지 '🧪 MySQL 실습 기록'의 내 칸 '10주차' 행에 붙이고,
--     확인한 오류 번호(1048 · 1062 · 3819 · 1452 · 1451 · 1830)와 배운 것을 한 줄 쓴다.
-- 우리 조 테이블은 이 연습 DB가 아니라 우리 조 DB에 만든다 — 아래 틀을 새 Query 탭에 복사해 쓴다.
--   CREATE DATABASE IF NOT EXISTS team1_db DEFAULT CHARACTER SET utf8mb4;   -- 조 번호만 바꾼다 (team1_db ~ team7_db)
--   USE team1_db;
--   DROP TABLE IF EXISTS 자식테이블, 부모테이블;                              -- 지우기는 자식 → 부모
--   CREATE TABLE 부모테이블 ( … PRIMARY KEY (…) );                          -- 만들기는 부모 → 자식
--   CREATE TABLE 자식테이블 ( … CONSTRAINT fk_자식_부모 FOREIGN KEY (…) REFERENCES 부모테이블 (…) );
-- 연습 DB를 지우려면: DROP DATABASE wk10_check;
