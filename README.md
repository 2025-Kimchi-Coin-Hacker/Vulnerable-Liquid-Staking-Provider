# Vulnerable-Liquid-Staking-uyl

학습/연구용 취약 리퀴드 스테이킹 프로토콜 샘플입니다. 프로덕션/메인넷 사용 금지.

## 구조

- `src/access/AccessManager.sol`: 단일 오너 기반 접근 제어(중앙 집중 위험).
- `src/core/LSToken.sol`: 매니저 전용 민트/번 가능한 단순 파생 토큰.
- `src/core/ValidatorRegistry.sol`: 아무나 등록·크레덴셜 변경 가능(프런트런 위험).
- `src/core/StakingManager.sol`: 예치/출금, 슬래싱, 비콘 입금 루프, 오라클 의존.
- `src/oracle/SimpleOracle.sol`: 누구나 가격을 바꿀 수 있는 오라클.
- `src/rewards/RewardDistributor.sol`: 재진입 취약한 보상 청구.
- `test/exploits/*.t.sol`: 익스플로잇 시나리오 모음.

## 취약점(체크리스트 대응)

- 출금 재진입, 보상 재진입(외부 호출 후 상태 변경).
- 무제한 밸리데이터 루프 → 가스 DoS.
- 오라클 조작/샌드위치로 과도한 shares 민팅.
- 오너의 미담보 민팅/슬래싱으로 디페깅.
- WithdrawCredentials 임의 설정/변경(프런트런).
- 비콘 입금 반복 호출로 가스 폭탄.
- 중앙집중 권한: 오너 단독 제어, 멀티시그 없음.

## 실행

```bash
forge install
forge test -vv
```

주요 시나리오:
- `test/exploits/ReentrancyAttack.t.sol`: 출금 재진입으로 잔고 유출.
- `test/exploits/DoSAttack.t.sol`: 밸리데이터 스팸 → 예치 실패.
- `test/exploits/OracleManipulation.t.sol`: 오라클 조작으로 과민팅.
- `test/exploits/InflationAttack.t.sol`: 오너 미담보 민팅 → 디페깅.
- `test/exploits/SlashingDepeg.t.sol`: 슬래싱 회계 부재 → 디페깅.

## 완화 아이디어(간단)

- CEI/`nonReentrant` 적용, 외부 호출 최소화.
- 밸리데이터 등록/루프 상한, 배치 처리.
- 신뢰 최소화된 오라클 + 타임락/멀티시그 승인.
- 슬래싱 시 파생 토큰 소각/리베이스 연동.
- WithdrawCredentials 사전 고정·검증, 등록 권한 제한.
- 보상 풀/예치 금액의 독립 회계 및 감사 가능한 이벤트.
