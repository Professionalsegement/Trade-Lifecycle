create database ca_practice;
USE ca_practice;

CREATE TABLE exchanges (
    exchange_code VARCHAR(10) PRIMARY KEY,
    exchange_name VARCHAR(100) NOT NULL,
    country VARCHAR(50) DEFAULT 'India',
    timezone VARCHAR(20) DEFAULT 'IST'
);

CREATE TABLE instruments (
    isin VARCHAR(12) PRIMARY KEY,
    ticker VARCHAR(20) NOT NULL UNIQUE,
    company_name VARCHAR(100) NOT NULL,
    sector VARCHAR(50) NOT NULL,
    face_value DECIMAL(10, 2) NOT NULL CHECK (face_value > 0),
    primary_exchange VARCHAR(10),
    FOREIGN KEY (primary_exchange) REFERENCES exchanges(exchange_code)
);

CREATE TABLE investors (
    investor_id VARCHAR(15) PRIMARY KEY,
    investor_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(20) CHECK (account_type IN ('Retail', 'Institutional', 'HNI', 'FII', 'DII')),
    pan_number VARCHAR(10) NOT NULL UNIQUE CHECK (LENGTH(pan_number) = 10),
    kyc_status VARCHAR(20) DEFAULT 'Pending' CHECK (kyc_status IN ('Verified', 'Pending', 'Suspended')),
    residential_status VARCHAR(20) DEFAULT 'Resident' CHECK (residential_status IN ('Resident', 'NRI', 'Foreign Portfolio'))
);

CREATE TABLE holdings (
    holding_id INT AUTO_INCREMENT PRIMARY KEY,
    investor_id VARCHAR(15),
    isin VARCHAR(12),
    quantity_held INT NOT NULL CHECK (quantity_held >= 0),
    avg_cost_price DECIMAL(18, 4) NOT NULL CHECK (avg_cost_price >= 0),
    last_updated_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (investor_id) REFERENCES investors(investor_id),
    FOREIGN KEY (isin) REFERENCES instruments(isin),
    UNIQUE KEY uq_investor_isin (investor_id, isin)
);


CREATE TABLE corporate_actions (
    ca_id VARCHAR(15) PRIMARY KEY,
    ca_type VARCHAR(20) CHECK (ca_type IN ('Cash Dividend', 'Stock Split', 'Bonus Issue')),
    isin VARCHAR(12),
    ex_date DATE NOT NULL,
    record_date DATE NOT NULL,
    ratio_or_amount DECIMAL(18, 4) NOT NULL,
    CHECK (record_date >= ex_date),
    FOREIGN KEY (isin) REFERENCES instruments(isin)
);

CREATE TABLE ca_announcements (
    announcement_id VARCHAR(20) PRIMARY KEY,
    ca_id VARCHAR(15),
    exchange_code VARCHAR(10),
    circular_reference VARCHAR(50) NOT NULL UNIQUE,
    announcement_date DATE NOT NULL,
    pdf_attachment_url VARCHAR(255),
    FOREIGN KEY (ca_id) REFERENCES corporate_actions(ca_id) ON DELETE CASCADE,
    FOREIGN KEY (exchange_code) REFERENCES exchanges(exchange_code)
);


CREATE TABLE ca_entitlements (
    entitlement_id INT AUTO_INCREMENT PRIMARY KEY,
    ca_id VARCHAR(15),
    investor_id VARCHAR(15),
    eligible_quantity INT NOT NULL CHECK (eligible_quantity >= 0),
    gross_entitlement_amt DECIMAL(18, 4) DEFAULT 0.0000,
    shares_to_receive INT DEFAULT 0,
    FOREIGN KEY (ca_id) REFERENCES corporate_actions(ca_id),
    FOREIGN KEY (investor_id) REFERENCES investors(investor_id),
    UNIQUE KEY uq_ca_investor (ca_id, investor_id)
);


    CREATE TABLE tax_withholding(
    tax_id INT AUTO_INCREMENT PRIMARY KEY,
    entitlement_id INT,
    tax_rate_pct DECIMAL(5, 2) NOT NULL CHECK (tax_rate_pct >= 0.00),
    tds_deducted_amt DECIMAL(18, 4) NOT NULL CHECK (tds_deducted_amt >= 0.00),
    net_payout_amt DECIMAL(18, 4) NOT NULL CHECK (net_payout_amt >= 0.00),
    pan_verified_status VARCHAR(20) CHECK (pan_verified_status IN ('Matched', 'Mismatched', 'Not Provided')),
    FOREIGN KEY (entitlement_id) REFERENCES ca_entitlements(entitlement_id) ON DELETE CASCADE
);

CREATE TABLE ca_processing_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    ca_id VARCHAR(15),
    processing_status VARCHAR(20) DEFAULT 'Pending' CHECK (processing_status IN ('Pending', 'Processed', 'Failed')),
    execution_date TIMESTAMP NULL,
    error_message VARCHAR(255),
    FOREIGN KEY (ca_id) REFERENCES corporate_actions(ca_id)
);

CREATE TABLE audit_trail (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id VARCHAR(50) NOT NULL,
    action_type VARCHAR(20) CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE', 'APPROVE')),
    performed_by VARCHAR(50) NOT NULL,
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    previous_value TEXT,
    new_value TEXT
);


INSERT INTO exchanges VALUES 
('NSE', 'National Stock Exchange of India', 'India', 'IST'),
('BSE', 'Bombay Stock Exchange', 'India', 'IST'),
('MCX', 'Multi Commodity Exchange of India', 'India', 'IST');

INSERT INTO instruments VALUES 
('INE002A01018', 'RELIANCE', 'Reliance Industries Limited', 'Energy', 10.00, 'NSE'),
('INE238A01034', 'MARUTI', 'Maruti Suzuki India Limited', 'Automobile', 5.00, 'NSE'),
('INE040A01034', 'HDFCBANK', 'HDFC Bank Limited', 'Financial Services', 1.00, 'NSE'),
('INE009A01021', 'INFY', 'Infosys Limited', 'IT', 5.00, 'NSE'),
('INE467B01029', 'TCS', 'Tata Consultancy Services Limited', 'IT', 1.00, 'BSE'),
('INE062A01020', 'SBIN', 'State Bank of India', 'Financial Services', 1.00, 'NSE'),
('INE154A01025', 'ITC', 'ITC Limited', 'FMCG', 1.00, 'NSE');

INSERT INTO investors VALUES 
('INV-INST-001', 'BlackRock Global Funds', 'FII', 'BLKRK1234F', 'Verified', 'Foreign Portfolio'),
('INV-INST-002', 'SBI Mutual Fund - Bluechip', 'DII', 'SBIMF5678M', 'Verified', 'Resident'),
('INV-HNI-001', 'Radhakishan Damani Trust', 'HNI', 'RKDMN9911A', 'Verified', 'Resident'),
('INV-HNI-002', 'Ananya Birla Family Office', 'HNI', 'ABFAM4422K', 'Verified', 'Resident'),
('INV-RET-001', 'Amit Sharma', 'Retail', 'AMTSH8833P', 'Verified', 'Resident'),
('INV-RET-002', 'Priya Nair', 'Retail', 'PRYNR2277L', 'Pending', 'Resident'),
('INV-RET-003', 'Rajesh Patel', 'Retail', 'RJPTL5511Q', 'Verified', 'NRI'),
('INV-RET-004', 'Vikram Malhotra', 'Retail', 'VKMLH6644N', 'Suspended', 'Resident');


INSERT INTO holdings (investor_id, isin, quantity_held, avg_cost_price) VALUES 
('INV-INST-001', 'INE002A01018', 120000, 2450.00),
('INV-INST-002', 'INE002A01018', 350000, 2410.00),
('INV-HNI-001', 'INE002A01018', 15000, 2500.00),
('INV-INST-001', 'INE238A01034', 8000, 8100.00),
('INV-INST-002', 'INE238A01034', 15000, 8250.00),
('INV-RET-001', 'INE238A01034', 50, 8400.00),
('INV-RET-002', 'INE238A01034', 120, 8350.00),
('INV-INST-002', 'INE040A01034', 500000, 1600.00),
('INV-HNI-002', 'INE040A01034', 25000, 1620.00),
('INV-RET-003', 'INE009A01021', 400, 1420.00),
('INV-RET-001', 'INE154A01025', 2500, 410.00),
('INV-RET-004', 'INE154A01025', 1000, 425.00);


INSERT INTO corporate_actions VALUES 
('CA-2026-DIV01', 'Cash Dividend', 'INE238A01034', '2026-05-15', '2026-05-17', 90.0000), 
('CA-2026-SPL01', 'Stock Split', 'INE040A01034', '2026-05-20', '2026-05-22', 2.0000),    
('CA-2026-BON01', 'Bonus Issue', 'INE154A01025', '2026-06-05', '2026-06-07', 0.5000),    
('CA-2026-DIV02', 'Cash Dividend', 'INE002A01018', '2026-05-01', '2026-05-03', 15.0000); 


INSERT INTO ca_announcements VALUES 
('ANN-001', 'CA-2026-DIV01', 'NSE', 'NSE/LIST/C/2026/0041', '2026-04-15', 'http://nseindia.com'),
('ANN-002', 'CA-2026-SPL01', 'NSE', 'NSE/LIST/C/2026/0088', '2026-04-20', 'http://nseindia.com'),
('ANN-003', 'CA-2026-BON01', 'BSE', 'BSE/LIST/COMP/3321', '2026-05-10', 'http://bseindia.com'),
('ANN-004', 'CA-2026-DIV02', 'NSE', 'NSE/LIST/C/2026/0012', '2026-04-01', 'http://nseindia.com');

INSERT INTO ca_entitlements (ca_id, investor_id, eligible_quantity, gross_entitlement_amt, shares_to_receive) VALUES
('CA-2026-DIV01', 'INV-INST-001', 8000, 720000.00, 0),
('CA-2026-DIV01', 'INV-INST-002', 15000, 1350000.00, 0),
('CA-2026-DIV01', 'INV-RET-001', 50, 4500.00, 0),
('CA-2026-DIV01', 'INV-RET-002', 120, 10800.00, 0),
('CA-2026-SPL01', 'INV-INST-002', 500000, 0.00, 500000),
('CA-2026-SPL01', 'INV-HNI-002', 25000, 0.00, 25000),
('CA-2026-DIV02', 'INV-INST-001', 120000, 1800000.00, 0), 
('CA-2026-DIV02', 'INV-INST-002', 350000, 5250000.00, 0),
('CA-2026-DIV02', 'INV-HNI-001', 15000, 225000.00, 0);

INSERT INTO tax_withholding (entitlement_id, tax_rate_pct, tds_deducted_amt, net_payout_amt, pan_verified_status) VALUES
(1, 20.00, 144000.00, 576000.00, 'Matched'),
(2, 10.00, 135000.00, 1215000.00, 'Matched'),
(3, 0.00, 0.00, 4500.00, 'Matched'),
(4, 20.00, 2160.00, 8640.00, 'Mismatched');

INSERT INTO ca_processing_log (ca_id, processing_status, execution_date, error_message) VALUES
('CA-2026-DIV01', 'Processed', '2026-05-18 11:00:00', NULL),
('CA-2026-SPL01', 'Processed', '2026-05-23 09:15:00', NULL),
('CA-2026-BON01', 'Pending', NULL, NULL),
('CA-2026-DIV02', 'Failed', '2026-05-04 15:30:00', 'RBI Liquidity Sweep Settlement Reject code E-09');

INSERT INTO audit_trail (table_name, record_id, action_type, performed_by, previous_value, new_value) VALUES
('corporate_actions', 'CA-2026-DIV01', 'INSERT', 'OPS_MGR_01', NULL, 'Type: Cash Div, ISIN: INE238A01034, Amt: 90.00') ,
('ca_processing_log', 'CA-2026-DIV01', 'APPROVE', 'CUSTODY_DIR_02', 'Status: Pending', 'Status: Processed'),
('investors', 'INV-RET-004', 'UPDATE', 'KYC_TEAM_04', 'Status: Verified', 'Status: Suspended') ;

USE ca_practice;

DROP TABLE IF EXISTS audit_trail;
DROP TABLE IF EXISTS ca_processing_log;
DROP TABLE IF EXISTS tax_withholding;
DROP TABLE IF EXISTS ca_entitlements;
DROP TABLE IF EXISTS ca_announcements;
DROP TABLE IF EXISTS corporate_actions;
DROP TABLE IF EXISTS holdings;
DROP TABLE IF EXISTS investors;
DROP TABLE IF EXISTS instruments;
DROP TABLE IF EXISTS exchanges;
USE ca_practice;
CREATE TABLE exchanges (
    exchange_code VARCHAR(10) PRIMARY KEY,
    exchange_name VARCHAR(100) NOT NULL,
    country VARCHAR(50) DEFAULT 'India',
    timezone VARCHAR(20) DEFAULT 'IST'
);

CREATE TABLE instruments (
    isin VARCHAR(12) PRIMARY KEY,
    ticker VARCHAR(20) NOT NULL UNIQUE,
    company_name VARCHAR(100) NOT NULL,
    sector VARCHAR(50) NOT NULL,
    face_value DECIMAL(10, 2) NOT NULL CHECK (face_value > 0),
    primary_exchange VARCHAR(10),
    FOREIGN KEY (primary_exchange) REFERENCES exchanges(exchange_code)
);

CREATE TABLE investors (
    investor_id VARCHAR(15) PRIMARY KEY,
    investor_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(20) CHECK (account_type IN ('Retail', 'Institutional', 'HNI', 'FII', 'DII')),
    pan_number VARCHAR(10) NOT NULL UNIQUE CHECK (LENGTH(pan_number) = 10),
    kyc_status VARCHAR(20) DEFAULT 'Pending' CHECK (kyc_status IN ('Verified', 'Pending', 'Suspended')),
    residential_status VARCHAR(20) DEFAULT 'Resident' CHECK (residential_status IN ('Resident', 'NRI', 'Foreign Portfolio'))
);

CREATE TABLE holdings (
    holding_id INT AUTO_INCREMENT PRIMARY KEY,
    investor_id VARCHAR(15),
    isin VARCHAR(12),
    quantity_held INT NOT NULL CHECK (quantity_held >= 0),
    avg_cost_price DECIMAL(18, 4) NOT NULL CHECK (avg_cost_price >= 0),
    FOREIGN KEY (investor_id) REFERENCES investors(investor_id),
    FOREIGN KEY (isin) REFERENCES instruments(isin),
    UNIQUE KEY uq_investor_isin (investor_id, isin)
);

CREATE TABLE corporate_actions (
    ca_id VARCHAR(15) PRIMARY KEY,
    ca_type VARCHAR(20) CHECK (ca_type IN ('Cash Dividend', 'Stock Split', 'Bonus Issue')),
    isin VARCHAR(12),
    ex_date DATE NOT NULL,
    record_date DATE NOT NULL,
    ratio_or_amount DECIMAL(18, 4) NOT NULL,
    CHECK (record_date >= ex_date),
    FOREIGN KEY (isin) REFERENCES instruments(isin)
);

CREATE TABLE ca_announcements (
    announcement_id VARCHAR(20) PRIMARY KEY,
    ca_id VARCHAR(15),
    exchange_code VARCHAR(10),
    circular_reference VARCHAR(50) NOT NULL UNIQUE,
    announcement_date DATE NOT NULL,
    pdf_attachment_url VARCHAR(255),
    FOREIGN KEY (ca_id) REFERENCES corporate_actions(ca_id) ON DELETE CASCADE,
    FOREIGN KEY (exchange_code) REFERENCES exchanges(exchange_code)
);

CREATE TABLE ca_entitlements (
    entitlement_id INT AUTO_INCREMENT PRIMARY KEY,
    ca_id VARCHAR(15),
    investor_id VARCHAR(15),
    eligible_quantity INT NOT NULL CHECK (eligible_quantity >= 0),
    gross_entitlement_amt DECIMAL(18, 4) DEFAULT 0.0000,
    shares_to_receive INT DEFAULT 0,
    FOREIGN KEY (ca_id) REFERENCES corporate_actions(ca_id),
    FOREIGN KEY (investor_id) REFERENCES investors(investor_id),
    UNIQUE KEY uq_ca_investor (ca_id, investor_id)
);

CREATE TABLE tax_withholding (
    tax_id INT PRIMARY KEY,
    entitlement_id INT,
    tax_rate_pct DECIMAL(5, 2) NOT NULL CHECK (tax_rate_pct >= 0.00),
    tds_deducted_amt DECIMAL(18, 4) NOT NULL CHECK (tds_deducted_amt >= 0.00),
    net_payout_amt DECIMAL(18, 4) NOT NULL CHECK (net_payout_amt >= 0.00),
    pan_verified_status VARCHAR(20) CHECK (pan_verified_status IN ('Matched', 'Mismatched', 'Not Provided')),
    FOREIGN KEY (entitlement_id) REFERENCES ca_entitlements(entitlement_id)
);

CREATE TABLE ca_processing_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    ca_id VARCHAR(15),
    processing_status VARCHAR(20) DEFAULT 'Pending' CHECK (processing_status IN ('Pending', 'Processed', 'Failed')),
    execution_date TIMESTAMP NULL,
    error_message VARCHAR(255),
    FOREIGN KEY (ca_id) REFERENCES corporate_actions(ca_id)
);

CREATE TABLE audit_trail (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id VARCHAR(50) NOT NULL,
    action_type VARCHAR(20) CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE', 'APPROVE')),
    performed_by VARCHAR(50) NOT NULL,
    action_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    previous_value TEXT,
    new_value TEXT
);

INSERT INTO exchanges VALUES 
('NSE', 'National Stock Exchange of India', 'India', 'IST'),
('BSE', 'Bombay Stock Exchange', 'India', 'IST'),
('MCX', 'Multi Commodity Exchange of India', 'India', 'IST');

INSERT INTO instruments VALUES 
('INE002A01018', 'RELIANCE', 'Reliance Industries Limited', 'Energy', 10.00, 'NSE'),
('INE238A01034', 'MARUTI', 'Maruti Suzuki India Limited', 'Automobile', 5.00, 'NSE'),
('INE040A01034', 'HDFCBANK', 'HDFC Bank Limited', 'Financial Services', 1.00, 'NSE'),
('INE009A01021', 'INFY', 'Infosys Limited', 'IT', 5.00, 'NSE'),
('INE467B01029', 'TCS', 'Tata Consultancy Services Limited', 'IT', 1.00, 'BSE'),
('INE062A01020', 'SBIN', 'State Bank of India', 'Financial Services', 1.00, 'NSE'),
('INE154A01025', 'ITC', 'ITC Limited', 'FMCG', 1.00, 'NSE');

INSERT INTO investors VALUES 
('INV-INST-001', 'BlackRock Global Funds', 'FII', 'BLKRK1234F', 'Verified', 'Foreign Portfolio'),
('INV-INST-002', 'SBI Mutual Fund - Bluechip', 'DII', 'SBIMF5678M', 'Verified', 'Resident'),
('INV-HNI-001', 'Radhakishan Damani Trust', 'HNI', 'RKDMN9911A', 'Verified', 'Resident'),
('INV-HNI-002', 'Ananya Birla Family Office', 'HNI', 'ABFAM4422K', 'Verified', 'Resident'),
('INV-RET-001', 'Amit Sharma', 'Retail', 'AMTSH8833P', 'Verified', 'Resident'),
('INV-RET-002', 'Priya Nair', 'Retail', 'PRYNR2277L', 'Pending', 'Resident'),
('INV-RET-003', 'Rajesh Patel', 'Retail', 'RJPTL5511Q', 'Verified', 'NRI'),
('INV-RET-004', 'Vikram Malhotra', 'Retail', 'VKMLH6644N', 'Suspended', 'Resident');

INSERT INTO holdings (investor_id, isin, quantity_held, avg_cost_price) VALUES 
('INV-INST-001', 'INE002A01018', 120000, 2450.00),
('INV-INST-002', 'INE002A01018', 350000, 2410.00),
('INV-HNI-001', 'INE002A01018', 15000, 2500.00),
('INV-INST-001', 'INE238A01034', 8000, 8100.00),
('INV-INST-002', 'INE238A01034', 15000, 8250.00),
('INV-RET-001', 'INE238A01034', 50, 8400.00),
('INV-RET-002', 'INE238A01034', 120, 8350.00),
('INV-INST-002', 'INE040A01034', 500000, 1600.00),
('INV-HNI-002', 'INE040A01034', 25000, 1620.00),
('INV-RET-003', 'INE009A01021', 400, 1420.00),
('INV-RET-001', 'INE154A01025', 2500, 410.00),
('INV-RET-004', 'INE154A01025', 1000, 425.00);

INSERT INTO corporate_actions VALUES 
('CA-2026-DIV01', 'Cash Dividend', 'INE238A01034', '2026-05-15', '2026-05-17', 90.0000), 
('CA-2026-SPL01', 'Stock Split', 'INE040A01034', '2026-05-20', '2026-05-22', 2.0000),    
('CA-2026-BON01', 'Bonus Issue', 'INE154A01025', '2026-06-05', '2026-06-07', 0.5000),    
('CA-2026-DIV02', 'Cash Dividend', 'INE002A01018', '2026-05-01', '2026-05-03', 15.0000); 

INSERT INTO ca_announcements VALUES 
('ANN-001', 'CA-2026-DIV01', 'NSE', 'NSE/LIST/C/2026/0041', '2026-04-15', 'http://nseindia.com'),
('ANN-002', 'CA-2026-SPL01', 'NSE', 'NSE/LIST/C/2026/0088', '2026-04-20', 'http://nseindia.com'),
('ANN-003', 'CA-2026-BON01', 'BSE', 'BSE/LIST/COMP/3321', '2026-05-10', 'http://bseindia.com'),
('ANN-004', 'CA-2026-DIV02', 'NSE', 'NSE/LIST/C/2026/0012', '2026-04-01', 'http://nseindia.com');

INSERT INTO ca_entitlements (ca_id, investor_id, eligible_quantity, gross_entitlement_amt, shares_to_receive) VALUES
('CA-2026-DIV01', 'INV-INST-001', 8000, 720000.00, 0),
('CA-2026-DIV01', 'INV-INST-002', 15000, 1350000.00, 0),
('CA-2026-DIV01', 'INV-RET-001', 50, 4500.00, 0),
('CA-2026-DIV01', 'INV-RET-002', 120, 10800.00, 0),
('CA-2026-SPL01', 'INV-INST-002', 500000, 0.00, 500000),
('CA-2026-SPL01', 'INV-HNI-002', 25000, 0.00, 25000),
('CA-2026-DIV02', 'INV-INST-001', 120000, 1800000.00, 0), 
('CA-2026-DIV02', 'INV-INST-002', 350000, 5250000.00, 0),
('CA-2026-DIV02', 'INV-HNI-001', 15000, 225000.00, 0);

INSERT INTO tax_withholding (tax_id, entitlement_id, tax_rate_pct, tds_deducted_amt, net_payout_amt, pan_verified_status) VALUES
(1, 1, 20.00, 144000.00, 576000.00, 'Matched'),
(2, 2, 10.00, 135000.00, 1215000.00, 'Matched'),
(3, 3, 0.00, 0.00, 4500.00, 'Matched'),
(4, 4, 20.00, 2160.00, 8640.00, 'Mismatched');

INSERT INTO ca_processing_log (ca_id, processing_status, execution_date, error_message) VALUES
('CA-2026-DIV01', 'Processed', '2026-05-18 11:00:00', NULL),
('CA-2026-SPL01', 'Processed', '2026-05-23 09:15:00', NULL),
('CA-2026-BON01', 'Pending', NULL, NULL),
('CA-2026-DIV02', 'Failed', '2026-05-04 15:30:00', 'RBI Liquidity Sweep Settlement Reject code E-09');

INSERT INTO audit_trail (table_name, record_id, action_type, performed_by, previous_value, new_value) VALUES
('corporate_actions', 'CA-2026-DIV01', 'INSERT', 'OPS_MGR_01', NULL, 'Type: Cash Div, ISIN: INE238A01034, Amt: 90.00'),
('ca_processing_log', 'CA-2026-DIV01', 'APPROVE', 'CUSTODY_DIR_02', 'Status: Pending', 'Status: Processed'),
('investors', 'INV-RET-004', 'UPDATE', 'KYC_TEAM_04', 'Status: Verified', 'Status: Suspended');

SELECT ticker, company_name, sector, face_value FROM instruments WHERE primary_exchange = 'NSE';

-- ============================================================
-- SECTION 3: ANALYTICAL QUERIES — CA OPS REPORTING
-- IronHub Capital | Corporate Actions Processing System
-- ============================================================

-- ── QUERY 1: Full Entitlement Summary by Corporate Action ────────────────────
-- Purpose: Shows gross payout / shares to be credited per CA event
-- Used by: CA Ops team for pre-settlement entitlement review

SELECT 
    ca.ca_id,
    ca.ca_type,
    i.ticker,
    i.company_name,
    ca.ex_date,
    ca.record_date,
    ca.ratio_or_amount,
    COUNT(e.investor_id)                        AS total_eligible_investors,
    SUM(e.eligible_quantity)                    AS total_eligible_shares,
    SUM(e.gross_entitlement_amt)                AS total_gross_payout_inr,
    SUM(e.shares_to_receive)                    AS total_shares_to_credit,
    pl.processing_status
FROM corporate_actions ca
JOIN instruments i         ON ca.isin = i.isin
LEFT JOIN ca_entitlements e ON ca.ca_id = e.ca_id
LEFT JOIN ca_processing_log pl ON ca.ca_id = pl.ca_id
GROUP BY ca.ca_id, ca.ca_type, i.ticker, i.company_name,
         ca.ex_date, ca.record_date, ca.ratio_or_amount, pl.processing_status
ORDER BY ca.ex_date;


-- ── QUERY 2: Investor-wise Net Payout Report (Post-TDS) ─────────────────────
-- Purpose: Net dividend payout per investor after TDS deduction
-- Used by: Custody/Depository team for payment instruction generation

SELECT
    inv.investor_name,
    inv.account_type,
    inv.residential_status,
    i.ticker,
    ca.ca_type,
    e.eligible_quantity                         AS shares_on_record_date,
    e.gross_entitlement_amt                     AS gross_payout_inr,
    COALESCE(tw.tax_rate_pct, 0)                AS tds_rate_pct,
    COALESCE(tw.tds_deducted_amt, 0)            AS tds_deducted_inr,
    COALESCE(tw.net_payout_amt, e.gross_entitlement_amt) AS net_payout_inr,
    COALESCE(tw.pan_verified_status, 'Not Provided') AS pan_status
FROM ca_entitlements e
JOIN investors inv               ON e.investor_id = inv.investor_id
JOIN corporate_actions ca        ON e.ca_id = ca.ca_id
JOIN instruments i               ON ca.isin = i.isin
LEFT JOIN tax_withholding tw     ON e.entitlement_id = tw.entitlement_id
WHERE ca.ca_type = 'Cash Dividend'
ORDER BY net_payout_inr DESC;


-- ── QUERY 3: TDS Exception Report — PAN Mismatches & Missing ────────────────
-- Purpose: Flag investors with PAN issues requiring ops intervention
-- Used by: KYC/Tax Ops team — escalation before payment run

SELECT
    inv.investor_id,
    inv.investor_name,
    inv.account_type,
    inv.kyc_status,
    inv.residential_status,
    i.ticker,
    ca.ca_id,
    e.gross_entitlement_amt,
    tw.tax_rate_pct,
    tw.tds_deducted_amt,
    tw.pan_verified_status,
    CASE 
        WHEN tw.pan_verified_status = 'Mismatched'    THEN 'ESCALATE — PAN mismatch, apply 20% TDS per Sec 206AA'
        WHEN tw.pan_verified_status = 'Not Provided'  THEN 'ESCALATE — No PAN, apply maximum 20% TDS'
        WHEN inv.kyc_status = 'Pending'               THEN 'HOLD — KYC not verified, freeze payout'
        WHEN inv.kyc_status = 'Suspended'             THEN 'BLOCK — Account suspended, do not pay'
        ELSE 'CLEAR'
    END AS ops_action
FROM ca_entitlements e
JOIN investors inv           ON e.investor_id = inv.investor_id
JOIN corporate_actions ca    ON e.ca_id = ca.ca_id
JOIN instruments i           ON ca.isin = i.isin
LEFT JOIN tax_withholding tw ON e.entitlement_id = tw.entitlement_id
WHERE 
    tw.pan_verified_status IN ('Mismatched', 'Not Provided')
    OR inv.kyc_status IN ('Pending', 'Suspended')
ORDER BY ops_action;


-- ── QUERY 4: Failed & Pending CA Processing Report ──────────────────────────
-- Purpose: Identify CAs not yet processed — ops escalation dashboard
-- Used by: CA Ops Manager for daily morning review

SELECT
    pl.ca_id,
    ca.ca_type,
    i.ticker,
    i.company_name,
    ca.ex_date,
    ca.record_date,
    pl.processing_status,
    pl.execution_date,
    pl.error_message,
    CASE
        WHEN pl.processing_status = 'Failed'  THEN 'CRITICAL — Investigate error code, retry settlement'
        WHEN pl.processing_status = 'Pending' 
         AND ca.record_date < CURDATE()        THEN 'OVERDUE — Record date passed, immediate action required'
        WHEN pl.processing_status = 'Pending' THEN 'UPCOMING — Monitor, prepare entitlement file'
        ELSE 'OK'
    END AS escalation_flag
FROM ca_processing_log pl
JOIN corporate_actions ca ON pl.ca_id = ca.ca_id
JOIN instruments i        ON ca.isin = i.isin
WHERE pl.processing_status IN ('Failed', 'Pending')
ORDER BY 
    FIELD(pl.processing_status, 'Failed', 'Pending'),
    ca.record_date;


-- ── QUERY 5: Holdings Impact Analysis — Post-CA Position Update ─────────────
-- Purpose: Show how positions change after bonus issue and stock split
-- Used by: Middle Office for position reconciliation post-CA

SELECT
    inv.investor_name,
    inv.account_type,
    i.ticker,
    ca.ca_type,
    h.quantity_held                             AS pre_ca_quantity,
    h.avg_cost_price                            AS pre_ca_avg_cost,
    CASE 
        WHEN ca.ca_type = 'Bonus Issue' 
            THEN h.quantity_held + FLOOR(h.quantity_held * ca.ratio_or_amount)
        WHEN ca.ca_type = 'Stock Split' 
            THEN h.quantity_held * ca.ratio_or_amount
        ELSE h.quantity_held
    END                                         AS post_ca_quantity,
    CASE
        WHEN ca.ca_type = 'Bonus Issue' 
            THEN ROUND(h.avg_cost_price / (1 + ca.ratio_or_amount), 4)
        WHEN ca.ca_type = 'Stock Split' 
            THEN ROUND(h.avg_cost_price / ca.ratio_or_amount, 4)
        ELSE h.avg_cost_price
    END                                         AS adjusted_avg_cost,
    CASE
        WHEN ca.ca_type = 'Bonus Issue' 
            THEN 'Cost basis diluted — no cash outflow, income neutral'
        WHEN ca.ca_type = 'Stock Split' 
            THEN 'Face value halved — market cap unchanged'
        ELSE 'No position change'
    END                                         AS accounting_note
FROM ca_entitlements e
JOIN investors inv           ON e.investor_id = inv.investor_id
JOIN corporate_actions ca    ON e.ca_id = ca.ca_id
JOIN instruments i           ON ca.isin = i.isin
JOIN holdings h              ON h.investor_id = e.investor_id AND h.isin = ca.isin
WHERE ca.ca_type IN ('Bonus Issue', 'Stock Split')
ORDER BY ca.ca_type, inv.investor_name;


-- ── QUERY 6: Audit Trail Review — Last 10 Ops Actions ───────────────────────
-- Purpose: Compliance review of all operations actions taken on CA records
-- Used by: Risk & Compliance team for audit sign-off

SELECT
    at.audit_id,
    at.table_name,
    at.record_id,
    at.action_type,
    at.performed_by,
    at.action_timestamp,
    at.previous_value,
    at.new_value
FROM audit_trail at
ORDER BY at.action_timestamp DESC
LIMIT 10;


-- ── QUERY 7: Bonus Issue Entitlement — Missing Records Detection ─────────────
-- Purpose: Flag investors holding ITC with no bonus entitlement record
-- Simulates a real break — entitlement file not generated for all eligible holders

SELECT
    h.investor_id,
    inv.investor_name,
    inv.account_type,
    i.ticker,
    ca.ca_id,
    ca.ca_type,
    h.quantity_held                             AS eligible_shares,
    FLOOR(h.quantity_held * ca.ratio_or_amount) AS bonus_shares_due,
    CASE 
        WHEN e.entitlement_id IS NULL THEN 'BREAK — Entitlement record missing'
        ELSE 'OK'
    END                                         AS entitlement_status
FROM holdings h
JOIN instruments i           ON h.isin = i.isin
JOIN corporate_actions ca    ON ca.isin = i.isin AND ca.ca_type = 'Bonus Issue'
JOIN investors inv            ON h.investor_id = inv.investor_id
LEFT JOIN ca_entitlements e  ON e.ca_id = ca.ca_id AND e.investor_id = h.investor_id
ORDER BY entitlement_status DESC;