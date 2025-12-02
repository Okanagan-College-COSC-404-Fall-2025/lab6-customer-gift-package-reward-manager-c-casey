-- part A
CREATE OR REPLACE TYPE gift_table_type IS TABLE OF VARCHAR2(20);
/

CREATE TABLE gift_catalog (
    gift_id NUMBER PRIMARY KEY,
    min_purchase NUMBER,
    gifts gift_table_type
) NESTED TABLE gifts STORE AS gift_table;

INSERT INTO gift_catalog VALUES (1, 100, gift_table_type('Stickers', 'Pen Set'));
INSERT INTO gift_catalog VALUES (2, 1000, gift_table_type('Teddy Bear', 'Mug', 'Perfume Sample'));
INSERT INTO gift_catalog VALUES (3, 10000, gift_table_type('Backpack', 'Thermos Bottle', 'Chocolate Collection'));

-- part B
CREATE TABLE customer_rewards (
    reward_id NUMBER GENERATED ALWAYS AS IDENTITY,
    customer_email VARCHAR2(250),
    gift_id NUMBER REFERENCES gift_catalog(gift_id),
    reward_date DATE DEFAULT SYSDATE
);

-- part C
CREATE OR REPLACE PACKAGE customer_manager AS
    FUNCTION get_total_purchase(c_id NUMBER) RETURN NUMBER;
    PROCEDURE assign_gifts_to_all;
END customer_manager;
/

CREATE OR REPLACE PACKAGE BODY customer_manager AS
    FUNCTION get_total_purchase(c_id NUMBER) RETURN NUMBER AS
        v_total NUMBER := 0;
    BEGIN
        SELECT SUM(unit_price * quantity)
          INTO v_total
          FROM Order_Items
          JOIN Orders USING (order_id)
          JOIN Customers USING (customer_id)
         WHERE customer_id = c_id; 

        RETURN v_total;
    END get_total_purchase;

    FUNCTION choose_gift_package(p_total_purchase NUMBER) RETURN NUMBER AS
       v_gift_id NUMBER;
    BEGIN
        v_gift_id := CASE WHEN (p_total_purchase >= 10000) THEN 1
                          WHEN (p_total_purchase >= 1000) THEN 2
                          WHEN (p_total_purchase >= 100) THEN 3
                          ELSE NULL 
                     END;

        RETURN v_gift_id;
    END choose_gift_package;

    PROCEDURE assign_gifts_to_all AS
        CURSOR cust_cursor IS
            SELECT customer_id, email_address
              FROM customers;
        v_gift_package NUMBER;
    BEGIN
        FOR cust IN cust_cursor LOOP
            v_gift_package := choose_gift_package(get_total_purchase(cust.customer_id));
            INSERT INTO customer_rewards(customer_email, gift_id) VALUES (
                cust.email_address,
                v_gift_package
            );
        END LOOP;
    END assign_gifts_to_all;
END customer_manager;
/

BEGIN
    customer_manager.assign_gifts_to_all();
END;
/

-- part D
CREATE OR REPLACE PROCEDURE test_package AS
    CURSOR cool_cursor IS
        SELECT *
          FROM customer_rewards
          JOIN gift_catalog USING (gift_id)
         ORDER BY reward_id;
    v_count NUMBER := 0;
BEGIN
    FOR rec IN cool_cursor LOOP
        EXIT WHEN v_count >= 5;
        dbms_output.put_line('Customer: ' || rec.customer_email);
        FOR i IN 1 .. rec.gifts.COUNT LOOP
            dbms_output.put_line('       Gift ' || i || ' - ' || rec.gifts(i));
        END LOOP;
        v_count := v_count + 1;
    END LOOP;
END test_package;
/

BEGIN
    test_package();
END;
/