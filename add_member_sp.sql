DELIMITER //

CREATE PROCEDURE insert_member_with_history1(
    IN p_name VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_phone VARCHAR(20),
    IN p_address VARCHAR(255),
    IN p_username VARCHAR(50)
)
BEGIN
    DECLARE current_member_id INT;
    DECLARE current_version INT;
    DECLARE username_exists INT DEFAULT 0;
    
    -- Check if member already exists based on name, email, phone, and username
    SELECT member_id, COALESCE(MAX(version), 0) AS max_version
    INTO current_member_id, current_version
    FROM members
    WHERE name = p_name
      AND username = username
      AND cur_rec_ind = 1
    GROUP BY member_id
    LIMIT 1;  -- Limit to 1 row to avoid multiple row result
    
    IF current_member_id IS NOT NULL THEN
        -- Member already exists, update existing record and add historical record
        
        -- Step 1: Update existing member's end date and set cur_rec_ind to FALSE
        UPDATE members
        SET effective_end_date = CURRENT_DATE,
            cur_rec_ind = 0,
            action = 'UPDATE'
        WHERE member_id = current_member_id
          AND cur_rec_ind = 1;
        
        -- Step 2: Insert historical record with the same member_id and increment version
        INSERT INTO members (member_id, name, email, phone, address, join_date, effective_start_date, cur_rec_ind, version, username, action)
        VALUES (current_member_id, p_name, p_email, p_phone, p_address, CURRENT_DATE, CURRENT_DATE, TRUE, current_version + 1, p_username, 'INSERT');
        
    ELSE
        -- Member does not exist, insert new member
        
        -- Check if username already exists
        SELECT COUNT(*) INTO username_exists
        FROM members
        WHERE username = p_username;
        
        -- If username exists, raise an error
        IF username_exists > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Username already exists. Please choose a different username.';
        END IF;
        
        -- Insert new member and retrieve the auto-generated member_id
        INSERT INTO members (name, email, phone, address, username, join_date, effective_start_date, cur_rec_ind, version, action)
        VALUES (p_name, p_email, p_phone, p_address, p_username, CURRENT_DATE, CURRENT_DATE, TRUE, 1, 'INSERT');
        
    END IF;
    
    SELECT 'Member insertion successful.' AS message;
END //

DELIMITER ;
