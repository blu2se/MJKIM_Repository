-- =====================================================================
-- 데이터베이스 설계 · 실습 환경 점검 — 내 PC의 MySQL(로컬 DB)에 연결되었는지 확인한다 (v2, 10.27)
-- 실행 환경: 내 PC의 MySQL Server 8.4 + MySQL Workbench (연결 이름: 학번_이름)
-- 실행 방법: 블록(⓪~④)을 하나씩 드래그해 선택한 뒤 번개 아이콘 또는
--           Ctrl+Shift+Enter (macOS: Cmd+Shift+Enter)로 실행한다.
--           결과는 'Result Grid', 성공·오류 메시지는 맨 아래 'Output' 창에서 본다.
-- 이 파일은 내 PC의 연습 DB(conn_check)만 만들고 지운다. 다른 DB는 건드리지 않는다.
-- 구조는 8주차 이후 모든 주차 스크립트와 같다: ⓪ 연결 확인 → ① 연습 DB → … → 마지막 정리
--
-- ※ 연결을 열 때 'Could not acquire management access for administration'
--   (RuntimeError: Unable to execute command chcp) 창이 뜨면 [OK]로 닫고 그대로 진행한다.
--   이 창은 Workbench의 '서버 관리' 화면 오류이며, SQL 실행과는 관계없다.
--   아래 ⓪이 실행되면 DB 연결은 정상이다.
-- =====================================================================

-- ⓪ 연결 확인과 실행 설정 — 모든 주차 스크립트의 첫 블록과 같다
--    기대 결과: version = 8.4.x, current_user_name = root@localhost, port = 3306,
--              character_set_server = utf8mb4, strict_mode = 1
--    → 이 결과 화면을 캡처해 조 페이지 '🧪 MySQL 실습 기록'의 내 칸(연결점검 행)에 붙인다
--    SET 두 줄은 한글 처리(utf8mb4)와 엄격 모드(잘못된 값을 오류로 막음)를 이 연결 창에 맞춘다.
SET NAMES utf8mb4;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SELECT VERSION()                AS version,
       CURRENT_USER()           AS current_user_name,
       @@port                   AS port,
       @@character_set_server   AS character_set_server,
       FIND_IN_SET('STRICT_TRANS_TABLES', @@SESSION.sql_mode) > 0 AS strict_mode;

-- ① 연습 DB 만들기와 선택
--    기대 결과: 오류 없음. 왼쪽 'Schemas' 창에서 새로고침(↻)하면 conn_check가 보인다
--    처음 실행할 때 Output 창의 '1 warning(s): 1008 Can't drop database' 노란 표시는 정상이다(지울 DB가 아직 없다는 뜻)
DROP DATABASE IF EXISTS conn_check;
CREATE DATABASE conn_check DEFAULT CHARACTER SET utf8mb4;
USE conn_check;

-- ② 테이블 만들기 · 한글 넣기 · 읽기  (다시 시작점: 이 블록부터 다시 해도 된다)
--    기대 결과: 1행 — student_name '홍길동', note '한글 저장 확인' 이 깨지지 않고 보인다
USE conn_check;
DROP TABLE IF EXISTS check_log;
CREATE TABLE check_log (
  check_id          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  student_name      VARCHAR(50)   NOT NULL,
  checked_datetime  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  note              VARCHAR(200)  NULL,
  PRIMARY KEY (check_id)
);
INSERT INTO check_log (student_name, note) VALUES ('홍길동', '한글 저장 확인');
SELECT * FROM check_log;

-- ③ 오류는 이렇게 보인다 — 일부러 없는 테이블을 읽는다
--    기대 결과: Output 창에 빨간 X와 Error Code: 1146. Table 'conn_check.no_such_table' doesn't exist
--    오류가 나면 Workbench는 그 자리에서 멈춘다. 다음 블록은 따로 선택해 실행한다
USE conn_check;
SELECT * FROM no_such_table;

-- ④ 정리 — 연습 DB 지우기
--    기대 결과: 오류 없음. 'Schemas' 창 새로고침 후 conn_check가 사라진다
DROP DATABASE IF EXISTS conn_check;

-- 끝. ⓪~②가 기대 결과대로 나오면 이 PC에서 주차별 MySQL 스크립트를 실행할 수 있다.
--     ⓪에서 막히면 '실습 환경 점검 가이드' 4절 B단계(서버 실행 확인)부터 본다.
