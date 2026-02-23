# mysql-binlog-encryption

본 실험은 MySQL 8.0 환경에서 **Binary Log 암호화(Encryption at Rest)** 적용 시 발생하는 시스템 성능 저하(Overhead)를 측정하기 위해 진행되었습니다.

## 1. 실험 환경 (Environment)
- **OS**: Ubuntu 24.04 LTS (Master-Replica 구조)
- **DB**: MySQL 8.0.45
- **Tool**: `sysbench 1.0.20`
- **Workload**: OLTP Read/Write (Table: 10, Size: 100,000)
- **Concurrency**: 4 Threads

## 2. 실험 시나리오
- **Scenario A**: `binlog_encryption = OFF` (평문 로그 저장)
- **Scenario B**: `binlog_encryption = ON` (AES-256 암호화 저장)

## 3. 벤치마크 결과 (Benchmark Results)

| 측정 지표 (Metric) | Scenario A (OFF) | Scenario B (ON) | 성능 변화량 |
|:---:|:---:|:---:|:---:|
| **TPS (Transactions per sec)** | **431.65** | **335.84** | **🔻 22.2% 감소** |
| **QPS (Queries per sec)** | **8,632.97** | **6,716.74** | **🔻 22.2% 감소** |
| **Avg Latency** | **9.26 ms** | **11.89 ms** | **🔺 28.4% 증가** |
| **95th% Latency** | **15.27 ms** | **19.29 ms** | **🔺 26.3% 증가** |

---
**binlog_encryption OFF**
<img width="1648" height="1114" alt="image" src="https://github.com/user-attachments/assets/f2e36fbe-5bca-462f-82ee-bec8f29b2fa0" />

---
**binlog_encryption ON**
<img width="1632" height="1116" alt="image" src="https://github.com/user-attachments/assets/1fce6624-0dc2-4ef3-b00f-82147878b98d" />

---

## 4. 결론: 보안과 성능의 Trade-off
본 실험 결과, Binlog 암호화는 데이터 탈취 시 발생할 수 있는 보안 위협을 원천 차단할 수 있는 강력한 수단이지만,  
약 **22%의 성능 하락**이라는 명확한 비용이 발생함을 확인했습니다.  

### 보안적 이득 (Security Gains)
- **Data-at-Rest 보호**: 공격자가 서버의 root 권한을 획득하여 `.00000x` 파일을 물리적으로 복제하더라도, Keyring 파일 없이는 내용을 복호화할 수 없습니다.
- **컴플라이언스 준수**: ISMS, GDPR 등 개인정보보호 규정에서 요구하는 '저장 데이터 암호화' 요건을 충족합니다.

### 시스템적 비용 (System Costs)
- **CPU Overhead**: 트랜잭션마다 발생하는 AES 연산으로 인해 CPU 점유율이 상승합니다.
- **I/O 병목 가중**: 암호화된 데이터를 쓰고 읽는 과정에서 디스크 I/O 응답 시간이 길어지며, 이는 전체적인 서비스 지연으로 이어집니다.

---

## 5. 도메인별 권장 전략 (Domain-Specific Strategies)

성능 저하를 감수하고 암호화를 적용할지 여부는 서비스의 특성에 따라 다르게 결정해야 합니다.

| 도메인 | 권장 설정 | 사유 |
| :--- | :---: | :--- |
| **금융/의료** | **필수** | 데이터 유출 시 법적/경제적 타격이 막대하므로, 성능을 희생하더라도 서버 자원을 증설하여 암호화를 적용해야 합니다. |
| **커머스/결제** | **선별** | 결제 정보 등 민감 데이터가 포함된 DB는 암호화를 적용하되, 일반 상품 정보 DB는 성능을 위해 해제하는 전략이 효율적입니다. |

---

## 6. 설정 방법 (How to Enable)
`/etc/mysql/mysql.conf.d/mysqld.cnf`
```ini
[mysqld]
early-plugin-load = keyring_file.so
keyring_file_data = /var/lib/mysql-keyring/keyring
binlog_encryption = ON
