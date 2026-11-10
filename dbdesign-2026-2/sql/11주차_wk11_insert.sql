-- =====================================================================
-- 데이터베이스 설계 · 11주차 목요일 · MySQL로 확인하기 — 테이블 2개 만들고 데이터 넣기 (v1, 11.12 · 11.10 일정 조정 반영)
-- 실행 환경: 내 PC의 MySQL Server 8.4 + Workbench (연결 이름: 학번_이름)
-- 실행 방법: 블록(⓪~⑥)을 하나씩 드래그해 선택한 뒤 번개 아이콘 또는
--           Ctrl+Shift+Enter (macOS: Cmd+Shift+Enter)로 실행한다.
--           전체를 한 번에 실행하지 않는다 — 일부러 오류를 내는 블록(⑤-1 · ⑤-2)이 있다.
--           아무것도 선택하지 않고 Ctrl+Shift+Enter를 누르면 파일 전체가 실행되어 ⑤-1에서 멈춘다.
-- 이 파일은 연습 DB(wk11_check)만 만든다. 우리 조 DB(team1_db 등)나 다른 주차 DB는 건드리지 않는다.
-- 예제: 부서 / department(부모) 1 : N 사원 / employee(자식) — 오늘 우리 파트에서 하는 것과 같은 '테이블 2개' 모양이다
--   12주차 조회 질의(SELECT · JOIN)도 이 데이터로 한다
--
-- 순서 그림: 만들기 · 넣기는 부모 → 자식 (department → employee), 지우기는 자식 → 부모 (employee → department)
-- 블록 규칙 — 8주차 이후 모든 주차 스크립트와 같다
--   · ①을 뺀 모든 블록 첫 줄은 USE wk11_check; (①을 건너뛰면 Error 1049 → ①부터 실행)
--   · ②는 '다시 시작점'이다. 어디서 막혔든 ②부터 다시 하면 처음과 같아진다
--     (처음 실행할 때 '1051 Unknown table' 노란 경고는 정상)
--   · ③ · ④(행 넣기)를 그냥 다시 실행하면 Error 1062(이미 있는 행)가 난다 → 다시 하려면 ②부터
--
-- ※ 연결을 열 때 'Could not acquire management access for administration'
--   (RuntimeError: Unable to execute command chcp) 창이 뜨면 [OK]로 닫고 그대로 진행한다.
--   ⓪에서 Error 2003·1045 등이 나면 '실습 환경 점검 가이드'의 해결 절차를 따른다.
-- =====================================================================

-- ⓪ 연결 확인과 실행 설정 — 매번 가장 먼저 실행한다
--    기대 결과: version = 8.4.x, current_user_name = root@localhost, port = 3306
SET NAMES utf8mb4;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SELECT VERSION() AS version, CURRENT_USER() AS current_user_name, @@port AS port;

-- ① 연습용 데이터베이스
--    기대 결과: 오류 없음. 왼쪽 'Schemas' 창을 새로고침(↻)하면 wk11_check가 보인다
--    처음 실행할 때 '1 warning(s): 1008 Can't drop database' 노란 표시는 정상이다
DROP DATABASE IF EXISTS wk11_check;
CREATE DATABASE wk11_check DEFAULT CHARACTER SET utf8mb4;
USE wk11_check;

-- ② 테이블 2개 만들기 — 부모(부서) 먼저, 자식(사원) 나중 (다시 시작점)
--    지우기는 자식 → 부모 순서로 한 줄에 적는다 (employee가 앞)
--    기대 결과: SHOW TABLES에 department · employee 2개
USE wk11_check;
DROP TABLE IF EXISTS employee, department;
CREATE TABLE department (
  department_id    INT UNSIGNED  NOT NULL,                 -- PK 번호형
  department_name  VARCHAR(50)   NOT NULL,
  PRIMARY KEY (department_id),
  CONSTRAINT uk_department_name UNIQUE (department_name)
);
CREATE TABLE employee (
  employee_id      INT UNSIGNED  NOT NULL,                 -- PK 번호형
  employee_name    VARCHAR(50)   NOT NULL,
  employee_email   VARCHAR(100)  NOT NULL,
  employee_phone   VARCHAR(20)   NULL,                     -- 없어도 되는 값 → NULL
  hire_date        DATE          NOT NULL,
  department_id    INT UNSIGNED  NOT NULL,                 -- FK = 부모 PK와 같은 이름 · 같은 타입
  PRIMARY KEY (employee_id),
  CONSTRAINT uk_employee_email UNIQUE (employee_email),
  CONSTRAINT fk_employee_department FOREIGN KEY (department_id)
    REFERENCES department (department_id)
    ON DELETE RESTRICT ON UPDATE RESTRICT
);
SHOW TABLES;

-- ③ 부모 행 넣기 — 부서 4행 (다시 하려면 ②부터)
--    INSERT INTO 테이블 (열 이름, …) VALUES (…), (…);  — 열 이름을 적고, 여러 행을 한 번에 넣는다
--    개발팀(40)은 일부러 사원이 없는 부서로 둔다 → 12주차 LEFT JOIN에서 '0명'으로 보인다
--    기대 결과: SELECT 4행 — 10 인사팀 · 20 영업팀 · 30 물류팀 · 40 개발팀
USE wk11_check;
INSERT INTO department (department_id, department_name) VALUES
  (10, '인사팀'), (20, '영업팀'), (30, '물류팀'), (40, '개발팀');
SELECT * FROM department ORDER BY department_id;

-- ④ 자식 행 넣기 — 사원 8행 (부서가 먼저 있어야 한다, 다시 하려면 ②부터)
--    글자 · 날짜는 작은따옴표, 숫자는 따옴표 없이, 없는 값은 따옴표 없는 NULL
--    기대 결과: 첫 SELECT employee_rows = 8 / 두 번째 SELECT 8행 (이 화면을 캡처한다)
USE wk11_check;
INSERT INTO employee (employee_id, employee_name, employee_email, employee_phone, hire_date, department_id) VALUES
  (1001, '김하늘', 'sky.kim@kmtech.kr',     '010-1234-5678', '2024-03-02', 10),
  (1002, '이바다', 'sea.lee@kmtech.kr',     NULL,            '2025-01-06', 20),
  (1003, '박구름', 'cloud.park@kmtech.kr',  NULL,            '2026-02-16', 10),
  (1004, '최노을', 'sunset.choi@kmtech.kr', '010-2222-3333', '2023-07-01', 20),
  (1005, '정새벽', 'dawn.jung@kmtech.kr',   NULL,            '2022-04-11', 30),
  (1006, '한여름', 'summer.han@kmtech.kr',  NULL,            '2026-09-01', 30),
  (1007, '오가을', 'autumn.oh@kmtech.kr',   '010-4444-5555', '2021-11-15', 20),
  (1008, '유겨울', 'winter.yu@kmtech.kr',   NULL,            '2025-05-20', 10);
SELECT COUNT(*) AS employee_rows FROM employee;
SELECT * FROM employee ORDER BY employee_id;

-- ⑤-1 순서를 어긴다 — 없는 부서(99)의 사원을 넣는다
--    기대 결과: Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails (… `fk_employee_department` …)
--    → 자식을 넣기 전에 부모 행이 있어야 한다. 우리 조에서도 부모 테이블 INSERT를 먼저 실행한다
USE wk11_check;
INSERT INTO employee (employee_id, employee_name, employee_email, hire_date, department_id)
VALUES (1009, '강보람', 'bora.kang@kmtech.kr', '2026-11-12', 99);

-- ⑤-2 같은 행을 두 번 넣는다 — 이미 있는 사번 1001
--    기대 결과: Error Code: 1062. Duplicate entry '1001' for key 'employee.PRIMARY'
--    → ③ · ④를 두 번 실행해도 이 오류가 난다. 다시 하려면 ②부터
USE wk11_check;
INSERT INTO employee (employee_id, employee_name, employee_email, hire_date, department_id)
VALUES (1001, '김하늘', 'sky2.kim@kmtech.kr', '2026-11-12', 10);

-- ⑥ 다 들어갔는지 확인 — 부서별 사원 수 (12주차에 배울 조회를 미리 본다. 결과만 확인한다)
--    기대 결과: 4행 — 인사팀 3 · 영업팀 3 · 물류팀 2 · 개발팀 0
USE wk11_check;
SELECT d.department_name, COUNT(e.employee_id) AS employee_count
FROM department d LEFT JOIN employee e ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
ORDER BY d.department_id;

-- 끝. ⓪ 결과와 확인 화면 1개(④의 8행 또는 ⑤-1의 1452)를 캡처해
--     조 페이지 '🧪 MySQL 실습 기록'의 내 칸 '11주차' 행에 붙이고, 본 오류 번호(1452 · 1062)와 배운 것을 한 줄 쓴다.
--     기록 마감은 12.11(금)이다. 오늘 못 끝내면 12.1(화) 보완 실습이나 마감 전까지 채운다(13주차 행은 쓰지 않는다 — 만점 12).
-- 다음: 12주차(11.19)에는 오늘 만든 우리 파트 테이블 2개로 질의 2개(조건 조회 1 · JOIN 1)와 인덱스 1개를 만든다.
--     그 한 줄기를 완료보고(12.3 1·2·3·4조 · 12.8 5·6·7조)에서 그대로 발표한다.
-- 우리 조 테이블은 이 연습 DB가 아니라 우리 조 DB에 만든다 — 실습가이드의 '우리 조 틀'을 새 Query 탭에 복사해 쓴다.
--   CREATE DATABASE IF NOT EXISTS team1_db DEFAULT CHARACTER SET utf8mb4;   -- 조 번호만 바꾼다 (team1_db ~ team7_db)
--   USE team1_db;
--   DROP TABLE IF EXISTS 자식테이블, 부모테이블;                              -- 지우기는 자식 → 부모
--   CREATE TABLE 부모테이블 ( … PRIMARY KEY (…) );                          -- 만들기는 부모 → 자식
--   CREATE TABLE 자식테이블 ( … CONSTRAINT fk_자식_부모 FOREIGN KEY (…) REFERENCES 부모테이블 (…) );
--   INSERT INTO 부모테이블 (…) VALUES (…), (…), (…);                          -- 넣기도 부모 → 자식 (부모 3행 이상)
--   INSERT INTO 자식테이블 (…) VALUES (…), (…), (…), (…), (…);                -- 자식 5행 이상
-- 연습 DB를 지우려면: DROP DATABASE wk11_check;
