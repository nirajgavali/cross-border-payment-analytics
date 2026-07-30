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
