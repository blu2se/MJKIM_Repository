-- =====================================================================
-- 데이터베이스 설계 · 11주차(11.12 목) · 테이블 2개 만들고 데이터 넣기 — 연습 스크립트 (v1)
-- =====================================================================
-- 오늘 할 일은 3단계다. 이 파일은 1단계만 한다.
--   1단계 (전원)   이 파일의 ⓪ → ⑥ 블록을 순서대로 하나씩 실행한다. 연습 DB wk11_check에서 한다.
--   2단계 (파트장) 실습가이드 '우리 조 틀'로 우리 파트 테이블 2개를 만든다. 우리 조 DB(메인시스템 영문 약어 + _DB, PM이 확정)에서 한다.
--   3단계 (전원)   조 페이지 '🧪 MySQL 실습 기록'의 내 '11주차' 행을 채운다. 캡처 2장을 붙인다.
--
-- 실행하는 법
--   · 블록 하나를 마우스로 드래그해 선택한다.
--   · Ctrl+Shift+Enter(macOS: Cmd+Shift+Enter)를 누른다.
--   · 결과를 블록 주석의 '기대 결과'와 비교한다. 같으면 다음 블록으로 간다.
--   · 전체를 한 번에 실행하지 않는다. ⑤-1 · ⑤-2는 일부러 오류를 낸다. 전체 실행은 ⑤-1에서 멈춘다.
--
-- 예제 모양: 부서 / department(부모) 1 : N 사원 / employee(자식)
--   우리 파트에서 만들 '부모 1 · 자식 1' 테이블과 모양이 같다.
--   만들기 · 넣기 순서: 부모 → 자식. 지우기 순서: 자식 → 부모.
--
-- 막히면
--   · Error 1049(Unknown database) → ①을 건너뛰었다. ①부터 다시 실행한다.
--   · ③ · ④에서 Error 1062 → 이미 넣은 행이다. ②부터 다시 실행한다. ②가 '다시 시작점'이다.
--   · 연결할 때 'chcp' 오류 창이 뜨면 [OK]로 닫는다. SQL 실행과 관계없다.
--   · ⓪에서 Error 2003 · 1045가 나면 '실습 환경 점검 가이드'를 따른다.
-- =====================================================================

-- ⓪ 연결 확인 — Workbench를 열 때마다 가장 먼저 실행한다
--    기대 결과: version = 8.4.x · current_user_name = root@localhost · port = 3306
--    이 결과 화면이 캡처 1이다.
SET NAMES utf8mb4;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SELECT VERSION() AS version, CURRENT_USER() AS current_user_name, @@port AS port;

-- ① 연습 DB 만들기
--    기대 결과: 오류 없음. 왼쪽 Schemas 창을 새로고침(↻)하면 wk11_check가 보인다.
--    처음 실행하면 노란 경고 '1008 Can't drop database'가 뜬다. 정상이다.
DROP DATABASE IF EXISTS wk11_check;
CREATE DATABASE wk11_check DEFAULT CHARACTER SET utf8mb4;
USE wk11_check;

-- ② 테이블 2개 만들기 (다시 시작점) — 부모 department 먼저, 자식 employee 나중
--    DROP 줄은 자식 → 부모 순서다. 그래서 employee가 앞에 있다.
--    자식의 FK(department_id)는 부모 PK와 이름 · 타입이 같다.
--    기대 결과: SHOW TABLES에 department · employee 2개가 나온다.
--    처음 실행하면 노란 경고 '1051 Unknown table'이 뜬다. 정상이다.
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

-- ③ 부모 행 넣기 — 부서 4행
--    쓰는 법: INSERT INTO 테이블 (열 이름, …) VALUES (…), (…);
--    열 이름을 먼저 적는다. 여러 행을 쉼표로 이어 한 번에 넣는다.
--    개발팀(40)에는 사원을 넣지 않는다. ⑥에서 '0명'으로 보인다.
--    기대 결과: 4행 — 10 인사팀 · 20 영업팀 · 30 물류팀 · 40 개발팀
USE wk11_check;
INSERT INTO department (department_id, department_name) VALUES
  (10, '인사팀'), (20, '영업팀'), (30, '물류팀'), (40, '개발팀');
SELECT * FROM department ORDER BY department_id;

-- ④ 자식 행 넣기 — 사원 8행 (③을 먼저 실행해야 한다)
--    글자 · 날짜는 작은따옴표로 감싼다. 숫자는 따옴표 없이 쓴다.
--    값이 없으면 따옴표 없이 NULL이라고 쓴다.
--    기대 결과: 첫 결과 employee_rows = 8. 두 번째 결과 사원 8행.
--    두 번째 결과 화면이 캡처 2다. (⑤-1의 1452 오류 화면으로 대신해도 된다.)
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

-- ⑤-1 일부러 오류 내기 ① — 없는 부서(99)의 사원을 넣는다
--    기대 결과: Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails (… `fk_employee_department` …)
--    배울 것: 부모 행이 없으면 자식 행을 넣을 수 없다. FK가 막는다.
--    우리 조 테이블도 부모 INSERT를 먼저 실행한다.
USE wk11_check;
INSERT INTO employee (employee_id, employee_name, employee_email, hire_date, department_id)
VALUES (1009, '강보람', 'bora.kang@kmtech.kr', '2026-11-12', 99);

-- ⑤-2 일부러 오류 내기 ② — 이미 있는 사번 1001을 또 넣는다
--    기대 결과: Error Code: 1062. Duplicate entry '1001' for key 'employee.PRIMARY'
--    배울 것: PK 값은 두 번 들어갈 수 없다.
--    ③ · ④를 두 번 실행해도 같은 오류가 난다. 그때는 ②부터 다시 한다.
USE wk11_check;
INSERT INTO employee (employee_id, employee_name, employee_email, hire_date, department_id)
VALUES (1001, '김하늘', 'sky2.kim@kmtech.kr', '2026-11-12', 10);

-- ⑥ 다 들어갔는지 확인 — 부서별 사원 수
--    12주차에 배울 조회다. 오늘은 실행해서 결과만 확인한다.
--    기대 결과: 4행 — 인사팀 3 · 영업팀 3 · 물류팀 2 · 개발팀 0
USE wk11_check;
SELECT d.department_name, COUNT(e.employee_id) AS employee_count
FROM department d LEFT JOIN employee e ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
ORDER BY d.department_id;

-- 끝. 여기까지가 1단계다.
-- ---------------------------------------------------------------------
-- 3단계 · 기록 (전원) — 조 페이지 '🧪 MySQL 실습 기록'의 내 '11주차' 행
--   · 캡처 2장을 붙인다: 캡처 1 ⓪ 결과 · 캡처 2 ④의 사원 8행(또는 ⑤-1의 1452).
--   · 본 오류 번호(1452 · 1062)를 적는다. 배운 것을 한 줄 쓴다.
--   · 기록 마감은 12.11(금)이다. 못 끝내면 12.1(화) 보완 실습 때 채운다.
--   · 13주차 행은 쓰지 않는다. 만점은 12다.
-- ---------------------------------------------------------------------
-- 2단계 · 우리 파트 테이블 2개 (파트장) — 이 연습 DB가 아니라 우리 조 DB에 만든다
--   실습가이드의 '우리 조 틀'을 새 Query 탭에 복사해 쓴다. 뼈대는 아래와 같다.
--   CREATE DATABASE IF NOT EXISTS KM_TOS_DB DEFAULT CHARACTER SET utf8mb4;  -- 우리 조 DB 이름으로 바꾼다 (메인시스템 영문 약어 + _DB, PM이 확정)
--   USE KM_TOS_DB;
--   DROP TABLE IF EXISTS 자식테이블, 부모테이블;                              -- 지우기는 자식 → 부모
--   CREATE TABLE 부모테이블 ( … PRIMARY KEY (…) );                          -- 만들기는 부모 → 자식
--   CREATE TABLE 자식테이블 ( … CONSTRAINT fk_자식_부모 FOREIGN KEY (…) REFERENCES 부모테이블 (…) );
--   INSERT INTO 부모테이블 (…) VALUES (…), (…), (…);                          -- 넣기도 부모 → 자식 (부모 3행 이상)
--   INSERT INTO 자식테이블 (…) VALUES (…), (…), (…), (…), (…);                -- 자식 5행 이상
--   SHOW TABLES;                                                             -- 캡처 1
--   SELECT (SELECT COUNT(*) FROM 부모테이블) AS parent_rows, (SELECT COUNT(*) FROM 자식테이블) AS child_rows;   -- 캡처 2
--   실행에 성공한 SQL은 조 페이지 '11주차' 섹션 내 파트 칸의 SQL 코드 블록에 붙인다.
-- ---------------------------------------------------------------------
-- 다음 주: 12주차(11.19)에는 오늘 만든 테이블 2개로 질의 2개와 인덱스 1개를 만든다.
--   질의는 조건 조회 1개 · JOIN 1개다. 그 결과를 완료보고에서 발표한다.
--   완료보고: 12.3(목) 1·2·3·4조 · 12.8(화) 5·6·7조.
-- 연습 DB를 지우려면: DROP DATABASE wk11_check;
