-- Create Transactions Table
CREATE TABLE transactions (
    transaction_id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    source_currency VARCHAR(3) NOT NULL, -- e.g., 'USD'
    target_currency VARCHAR(3) NOT NULL, -- e.g., 'PHP'
    amount DECIMAL(18, 2) NOT NULL,
    primary_rail_id VARCHAR(50) NOT NULL,
    actual_rail_used VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,         -- 'Success', 'Failed', 'Rerouted'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Rail Performance Logs Table
CREATE TABLE rail_performance_logs (
    log_id BIGSERIAL PRIMARY KEY,
    rail_id VARCHAR(50) NOT NULL,
    api_latency_ms INT NOT NULL,
    http_response_code INT NOT NULL,
    fx_spread_margin_bps INT NOT NULL,
    liquidity_available DECIMAL(18, 2) NOT NULL,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- =========================================================================
-- STEP 2: POPULATE SIMULATED PERFORMANCE & TRANSACTION DATA
-- =========================================================================

-- Insert Performance Logs (Simulating healthy vs degraded payment rails)
INSERT INTO rail_performance_logs (rail_id, api_latency_ms, http_response_code, fx_spread_margin_bps, liquidity_available, logged_at) VALUES
('Partner_Bank_A', 180, 200, 45, 750000.00, '2026-08-01 10:00:00'),
('Partner_Bank_B', 120, 200, 60, 400000.00, '2026-08-01 10:00:00'),
('Partner_Bank_A', 3100, 504, 45, 8000.00, '2026-08-01 14:30:00'), -- API Degraded / Liquidity Bottleneck during Peak Hour
('Partner_Bank_B', 210, 200, 62, 380000.00, '2026-08-01 14:30:00');

-- Insert Transaction History (Simulating the 12% failure drop on the SEA/PHP route)
INSERT INTO transactions (transaction_id, user_id, source_currency, target_currency, amount, primary_rail_id, actual_rail_used, status, created_at) VALUES
('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'u1111111-1111-1111-1111-111111111111', 'USD', 'EUR', 150.00, 'Partner_Bank_A', 'Partner_Bank_A', 'Success', '2026-08-01 10:05:00'),
('b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', 'u2222222-2222-2222-2222-222222222222', 'USD', 'PHP', 450.00, 'Partner_Bank_A', 'Partner_Bank_A', 'Success', '2026-08-01 10:15:00'),
('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', 'u3333333-3333-3333-3333-333333333333', 'USD', 'PHP', 250.00, 'Partner_Bank_A', 'Partner_Bank_A', 'Failed', '2026-08-01 14:31:00'),  -- Unhandled Timeout Failure
('d4e5f6a7-b8a9-0c1d-2e3f-4a5b6c7d8e9f', 'u4444444-4444-4444-4444-444444444444', 'USD', 'PHP', 1200.00, 'Partner_Bank_A', 'Partner_Bank_B', 'Rerouted', '2026-08-01 14:32:00'),-- Fallback Engine success route
('e5f6a7b8-c9b0-1d2e-3f4a-5b6c7d8e9f0a', 'u5555555-5555-5555-5555-555555555555', 'USD', 'PHP', 300.00, 'Partner_Bank_A', 'Partner_Bank_A', 'Failed', '2026-08-01 14:35:00');  -- Unhandled Timeout Failure


-- =========================================================================
-- STEP 3: ANALYTICAL REVENUE & PERFORMANCE QUERIES FOR PORTFOLIO
-- =========================================================================

-- KPI Query 1: Calculate Payment Success Rate (PSR) Corridor Metrics
-- Isolates the processing efficiency across target international currencies.
SELECT 
    target_currency,
    COUNT(transaction_id) AS total_attempts,
    SUM(CASE WHEN status = 'Success' THEN 1 ELSE 0 END) AS straight_through_success,
    SUM(CASE WHEN status = 'Rerouted' THEN 1 ELSE 0 END) AS fallback_success,
    SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) AS total_hard_failures,
    ROUND((SUM(CASE WHEN status = 'Success' OR status = 'Rerouted' THEN 1 ELSE 0 END) * 100.0) / COUNT(transaction_id), 2) AS effective_psr_percentage
FROM transactions
GROUP BY target_currency;

-- KPI Query 2: System Overload & Root Cause Mapping
-- Matches processing downtime instances with partner infrastructure latency indicators.
SELECT 
    t.primary_rail_id,
    AVG(r.api_latency_ms) AS business_avg_latency_ms,
    AVG(r.liquidity_available) AS business_avg_liquidity_pool,
    COUNT(CASE WHEN t.status = 'Failed' THEN 1 END) AS recorded_hard_failures
FROM transactions t
JOIN rail_performance_logs r ON t.primary_rail_id = r.rail_id
GROUP BY t.primary_rail_id;
