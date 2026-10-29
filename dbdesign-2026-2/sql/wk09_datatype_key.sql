-- =====================================================================
-- 데이터베이스 설계 · 9주차 목요일 · MySQL로 확인하기 — 데이터 타입과 키 (v2, 10.27 보완)
-- 실행 환경: 내 PC의 MySQL Server 8.4 + Workbench (연결 이름: 학번_이름)
-- 실행 방법: 블록(⓪~⑨)을 하나씩 드래그해 선택한 뒤 번개 아이콘 또는
--           Ctrl+Shift+Enter (macOS: Cmd+Shift+Enter)로 실행한다.
--           전체를 한 번에 실행하지 않는다 — 일부러 오류를 내는 블록이 있다.
--           아무것도 선택하지 않고 Ctrl+Shift+Enter를 누르면 파일 전체가 실행되어 ⑤-1에서 멈춘다.
-- (v2) 블록 규칙 — 8주차 이후 모든 주차 스크립트에 같다
--   · ①을 뺀 모든 블록 첫 줄은 USE wk9_check; — 다른 주차의 연습 DB에 잘못 만들지 않게 하는 안전장치다
--     (①을 건너뛰면 Error 1049가 나서 바로 알 수 있다 → ①부터 실행)
--   · ②·③·④·⑤-1·⑥·⑦은 '다시 시작점'이다. DROP TABLE IF EXISTS로 시작해 그 블록부터 다시 할 수 있다
--     (처음 실행할 때 '1051 Unknown table' 노란 경고는 정상). ⑥을 다시 하면 ⑦도 다시 한다
-- ⓪       : 연결 확인과 실행 설정 — 매번 가장 먼저 실행한다 (v2 추가)
-- A(①~⑤): 데이터 타입을 잘못 고르면 생기는 일 — 전원
-- B(⑥~⑨): 내 파트 연결 엔터티를 테이블로 만들어 보기 — 파트장 (틀을 고쳐 쓴다)
--
-- ※ 연결을 열 때 'Could not acquire management access for administration'
--   (RuntimeError: Unable to execute command chcp) 창이 뜨면 [OK]로 닫고 그대로 진행한다.
--   Workbench '서버 관리' 화면의 오류이며 SQL 실행과는 관계없다. ⓪이 실행되면 연결은 정상이다.
--   ⓪에서 Error 2003·1045 등이 나면 '실습 환경 점검 가이드'의 해결 절차를 따른다.
-- =====================================================================

-- ⓪ 연결 확인과 실행 설정 (v2 추가)
--    기대 결과: version = 8.4.x, current_user_name = root@localhost, port = 3306
--    SET 두 줄은 한글 처리(utf8mb4)와 엄격 모드(잘못된 값을 오류로 막음)를 이 연결 창에 맞춘다.
--    엄격 모드가 꺼져 있으면 ⑤의 300·NULL이 오류 대신 경고로 들어가 버린다.
SET NAMES utf8mb4;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
SELECT VERSION() AS version, CURRENT_USER() AS current_user_name, @@port AS port;

-- ① 연습용 데이터베이스
--    기대 결과: 오류 없음. 왼쪽 'Schemas' 창을 새로고침(↻)하면 wk9_check가 보인다
--    처음 실행할 때 Output 창의 '1 warning(s): 1008 Can't drop database' 노란 표시는 정상이다(지울 DB가 아직 없다는 뜻)
DROP DATABASE IF EXISTS wk9_check;
CREATE DATABASE wk9_check DEFAULT CHARACTER SET utf8mb4;
USE wk9_check;

-- =====================================================================
-- A. 데이터 타입을 잘못 고르면
-- =====================================================================

-- ② 전화번호를 숫자(INT)로 두면 → 앞자리 0이 사라진다  (다시 시작점)
USE wk9_check;
DROP TABLE IF EXISTS type_phone;
CREATE TABLE type_phone (
  phone_int      INT UNSIGNED,   -- 잘못: 계산하지 않는 번호를 숫자로
  phone_varchar  VARCHAR(20)     -- 바름: 번호는 문자
);
INSERT INTO type_phone VALUES ('01012345678', '010-1234-5678');
--    기대 결과: phone_int = 1012345678 (0이 사라짐), phone_varchar = 010-1234-5678
SELECT * FROM type_phone;

-- ③ 날짜를 문자(VARCHAR)로 두면 → 정렬과 비교가 틀린다  (다시 시작점)
USE wk9_check;
DROP TABLE IF EXISTS type_date;
CREATE TABLE type_date (
  date_varchar  VARCHAR(10),     -- 잘못
  date_date     DATE             -- 바름
);
INSERT INTO type_date VALUES ('2026-9-5', '2026-9-5'), ('2026-10-27', '2026-10-27');
--    기대 결과(문자 정렬): 2026-10-27이 2026-9-5보다 앞에 온다 → 10월이 9월보다 먼저
SELECT date_varchar FROM type_date ORDER BY date_varchar;
--    기대 결과(날짜 정렬): 2026-09-05 → 2026-10-27  (날짜 형식도 하나로 맞춰진다)
SELECT date_date FROM type_date ORDER BY date_date;

-- ④ 금액을 FLOAT로 두면 → 합계에 오차가 생긴다  (다시 시작점)
USE wk9_check;
DROP TABLE IF EXISTS type_amount;
CREATE TABLE type_amount (
  amount_float    FLOAT,           -- 잘못: 근삿값 타입
  amount_decimal  DECIMAL(12,2)    -- 바름: 정확한 값
);
INSERT INTO type_amount VALUES (19.99, 19.99), (19.99, 19.99), (19.99, 19.99);
--    기대 결과: 59.97이 아닌 59.969999… 같은 값 ↔ DECIMAL은 정확히 59.97
SELECT SUM(amount_float) AS sum_float, SUM(amount_decimal) AS sum_decimal FROM type_amount;

-- ⑤-1 범위를 정해 주면 → 잘못된 값을 DB가 막는다  (다시 시작점 · v2: 오류가 두 개라 ⑤-1과 ⑤-2로 나누었다)
--    Workbench는 선택한 블록에서 오류가 나면 그 자리에서 멈춘다. 그래서 ⑤-2는 따로 선택해 실행한다.
--    기대 결과: 95는 들어가고, 300에서 Error Code: 1264. Out of range value for column 'score' at row 1
USE wk9_check;
DROP TABLE IF EXISTS type_score;
CREATE TABLE type_score (
  score  TINYINT UNSIGNED NOT NULL   -- 0~255만 들어간다
);
INSERT INTO type_score VALUES (95);
INSERT INTO type_score VALUES (300);

-- ⑤-2 값이 꼭 있어야 하는 칸(NOT NULL)에 빈 값을 넣으면
--    기대 결과: Error Code: 1048. Column 'score' cannot be null
USE wk9_check;
INSERT INTO type_score VALUES (NULL);

-- =====================================================================
-- B. 내 파트 연결 엔터티를 테이블로 — 아래 예(주문–상품 → 주문상세)를
--    우리 조 이름으로 바꿔 쓴다. 이름은 표준 용어사전, 타입은 도메인 표를 따른다.
-- =====================================================================

-- ⑥ 부모 엔터티 두 개 (예: 주문, 상품)  (다시 시작점: B를 다시 할 때 여기부터)
--    (v2) Workbench를 다시 열었거나 새 탭이면 ⓪을 먼저 실행한 뒤 이 블록부터 이어 한다.
USE wk9_check;
DROP TABLE IF EXISTS order_item_wrong, order_item, customer_order, product;
CREATE TABLE customer_order (
  order_id        BIGINT UNSIGNED  NOT NULL,   -- 일련번호형 PK
  order_datetime  DATETIME         NOT NULL,
  PRIMARY KEY (order_id)
);
CREATE TABLE product (
  product_id    CHAR(6)        NOT NULL,       -- 업무 코드형 PK
  product_name  VARCHAR(100)   NOT NULL,
  list_price    DECIMAL(12,2)  NOT NULL,
  PRIMARY KEY (product_id)
);
--    부모 행 넣기 (v2: ⑦에서 옮겨 왔다 — ⑦을 혼자 다시 실행할 수 있게)
INSERT INTO customer_order VALUES (1, '2026-10-29 15:10:00');
INSERT INTO product VALUES ('P00001', '무선 청소기', 289000.00), ('P00002', '공기청정기', 199000.00);

-- ⑦ 연결 엔터티 (예: 주문상세) — FK의 타입은 참조하는 PK와 똑같이  (다시 시작점)
USE wk9_check;
DROP TABLE IF EXISTS order_item;
CREATE TABLE order_item (
  order_id          BIGINT UNSIGNED   NOT NULL,          -- = customer_order.order_id
  product_id        CHAR(6)           NOT NULL,          -- = product.product_id
  order_quantity    SMALLINT UNSIGNED NOT NULL,
  order_unit_price  DECIMAL(12,2)     NOT NULL,          -- 주문 당시 단가 (1건의 사실)
  PRIMARY KEY (order_id, product_id),
  FOREIGN KEY (order_id)   REFERENCES customer_order (order_id),
  FOREIGN KEY (product_id) REFERENCES product (product_id)
);
INSERT INTO order_item VALUES (1, 'P00001', 1, 279000.00), (1, 'P00002', 2, 199000.00);
--    기대 결과: Error Code 1062 (같은 주문에 같은 상품 두 줄) — 업무 규칙을 복합키가 지킨다
INSERT INTO order_item VALUES (1, 'P00001', 3, 279000.00);

-- ⑧ FK 타입이 참조 PK와 다르면 → 테이블이 만들어지지 않는다
--    기대 결과: Error Code 3780. Referencing column 'order_id' and referenced column
--              'order_id' in foreign key constraint ... are incompatible.
--    (BIGINT UNSIGNED를 참조하는데 INT로 선언했다. MySQL이 아닌 DB(MariaDB 등)에서는 오류 번호가 1005 등으로 다르게 나온다)
USE wk9_check;
CREATE TABLE order_item_wrong (
  order_id    INT      NOT NULL,
  product_id  CHAR(6)  NOT NULL,
  PRIMARY KEY (order_id, product_id),
  FOREIGN KEY (order_id) REFERENCES customer_order (order_id)
);

-- ⑨ 확인 — 주문 1건의 상세와 금액 (세 테이블 JOIN)
--    기대 결과: 2행, 합계 677000.00
USE wk9_check;
SELECT o.order_id, p.product_name, i.order_quantity, i.order_unit_price,
       i.order_quantity * i.order_unit_price AS line_amount
FROM order_item AS i
JOIN customer_order AS o ON o.order_id = i.order_id
JOIN product        AS p ON p.product_id = i.product_id;
SELECT SUM(order_quantity * order_unit_price) AS order_total FROM order_item WHERE order_id = 1;

-- 끝. ⓪ 결과와 ⑦의 1062 화면을 캡처해 조 페이지 '🧪 MySQL 실습 기록'의 내 칸에 붙이고, 배운 것을 한 줄 쓴다.
--     파트장은 우리 파트로 고친 연결 엔터티 SQL을 9주차 ③ 코드 블록에도 붙인다.
-- (v2) 막히면 오류 번호를 '실습 환경 점검 가이드'의 오류 카드에서 찾는다. 2003·1045는 연결 문제, 1046·1050·1824는 실행 순서 문제다.
-- 우리 조 이름으로 고친 ⑥~⑦은 .sql로 저장해 두면 10주차 테이블 만들기에 그대로 쓴다.
