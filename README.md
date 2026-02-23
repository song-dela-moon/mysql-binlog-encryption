# mysql-binlog-encryption
## MySQL 8.0 Binary Log Encryption Performance Benchmark

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
<img width="1648" height="1114" alt="image" src="https://github.com/user-attachments/assets/f2e36fbe-5bca-462f-82ee-bec8f29b2fa0" />
---
<img width="1632" height="1116" alt="image" src="https://github.com/user-attachments/assets/1fce6624-0dc2-4ef3-b00f-82147878b98d" />
---

## 4. 결과 분석 (Analysis)

1. **처리량(Throughput) 감소**: 암호화 활성화 시, 트랜잭션 커밋 단계에서 발생하는 AES 암호화 연산 오버헤드로 인해 전체적인 처리량이 **약 22% 하락**하는 것을 확인했습니다.
2. **응답 지연(Latency) 증가**: 쿼리당 평균 응답 시간이 **약 2.6ms 증가**하였으며, 특히 부하가 몰리는 구간(95th%)에서도 일관된 지연 시간 증가가 관측되었습니다.
3. **결론**: 데이터 보안(Encryption at Rest)을 확보하는 대신 시스템의 가용 자원 중 약 1/4 가량을 보안 연산에 할당해야 함을 시사합니다. 높은 TPS가 요구되는 서비스에서는 CPU 자원의 추가 할당이 필요합니다.

## 5. 설정 방법 (How to Enable)
`/etc/mysql/mysql.conf.d/mysqld.cnf`
```ini
[mysqld]
early-plugin-load = keyring_file.so
keyring_file_data = /var/lib/mysql-keyring/keyring
binlog_encryption = ON
