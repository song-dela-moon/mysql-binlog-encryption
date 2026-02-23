#!/bin/bash

# =================================================================
# MySQL Binlog Encryption Performance Benchmark Script
# =================================================================

# 1. Configuration
DB_NAME="sbtest"
DB_USER="root"
DB_PASS="1234"
DB_HOST="127.0.0.1"
TABLES=10
TABLE_SIZE=100000
THREADS=4
RUNTIME=300

# 2. Setup Database
echo ">>> Resetting database: $DB_NAME"
mysql -u$DB_USER -p$DB_PASS -h$DB_HOST -e "DROP DATABASE IF EXISTS $DB_NAME; CREATE DATABASE $DB_NAME;"

# 3. Prepare Data
echo ">>> Preparing data (this may take a while)..."
sysbench oltp_read_write \
    --mysql-host=$DB_HOST \
    --mysql-user=$DB_USER \
    --mysql-password=$DB_PASS \
    --mysql-db=$DB_NAME \
    --tables=$TABLES \
    --table-size=$TABLE_SIZE \
    prepare

# 4. Run Benchmark
ENC_STATUS=$(mysql -u$DB_USER -p$DB_PASS -h$DB_HOST -se "SHOW VARIABLES LIKE 'binlog_encryption';" | awk '{print $2}')
LOG_FILE="result_enc_${ENC_STATUS:-OFF}.txt"

echo ">>> Running benchmark (Encryption: ${ENC_STATUS:-OFF})..."
echo ">>> Results will be saved to: $LOG_FILE"

sysbench oltp_read_write \
    --mysql-host=$DB_HOST \
    --mysql-user=$DB_USER \
    --mysql-password=$DB_PASS \
    --mysql-db=$DB_NAME \
    --tables=$TABLES \
    --table-size=$TABLE_SIZE \
    --threads=$THREADS \
    --time=$RUNTIME \
    --report-interval=10 \
    run | tee $LOG_FILE

echo ">>> Benchmark complete."
