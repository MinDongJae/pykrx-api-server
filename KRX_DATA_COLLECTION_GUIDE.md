# KRX 데이터 수집 가이드

## ✅ 역공학 결과 (2026-01-17)

### 로그인 메커니즘 분석 완료

| 항목 | 내용 |
|------|------|
| **로그인 URL** | `https://data.krx.co.kr/contents/MDC/COMS/client/MDCCOMS001D1.cmd` |
| **로그인 방식** | iframe 기반 + NPPFS E2E 암호화 |
| **암호화 라이브러리** | `nppfs-1.13.0.js` (Non-Plugin Free Solution) |
| **비밀번호 전송** | `__E2E_RESULT__` 필드로 암호화된 값 전송 |
| **세션 쿠키** | `JSESSIONID` (JWT 형식) |

### 해결 방안: Selenium 기반 로그인

E2E 암호화를 직접 구현하기 어렵기 때문에, **Selenium으로 실제 브라우저 로그인 후 세션 쿠키 추출**

```python
from krx_session import KRXSession

# 로그인
krx = KRXSession(headless=True)
krx.login("your_id", "your_password")

# API 호출 (로그인 세션 사용)
data = krx.get_per_pbr_div("20250116")  # PER/PBR/배당수익률
data = krx.get_investor_trading("20250116")  # 투자자별 거래실적
data = krx.get_foreign_holding("20250116")  # 외국인 보유량
```

### 지원하는 API

| API | 메서드 | 로그인 필요 |
|-----|--------|:-----------:|
| 전종목 시세 | `get_all_stocks()` | ✅ |
| PER/PBR/배당수익률 | `get_per_pbr_div()` | ✅ |
| 투자자별 거래실적 | `get_investor_trading()` | ✅ |
| 외국인 보유량 | `get_foreign_holding()` | ✅ |
| 공매도 종합정보 | `get_short_selling()` | ✅ |

---

## 분석 결과 요약

### 1. KRX Data Marketplace (data.krx.co.kr) API 분석

#### 발견된 사항

| 항목 | 내용 |
|------|------|
| **API 엔드포인트** | `http://data.krx.co.kr/comm/bldAttendant/getJsonData.cmd` |
| **요청 방식** | POST |
| **인증 필요** | ✅ 대부분의 통계 API는 **로그인 필수** |
| **로그인 없이 가능** | 종목 검색 (`finder_stkisu`)만 가능 |

#### PyKRX가 사용하는 주요 bld 값

```python
BLD_ENDPOINTS = {
    # 종목 검색 (로그인 불필요)
    "상장종목검색": "dbms/comm/finder/finder_stkisu",

    # 시세 정보 (로그인 필요)
    "전종목시세": "dbms/MDC/STAT/standard/MDCSTAT01501",
    "개별종목시세": "dbms/MDC/STAT/standard/MDCSTAT01701",

    # 기업 정보 (로그인 필요)
    "PER_PBR_배당수익률": "dbms/MDC/STAT/standard/MDCSTAT03501",

    # 투자자 정보 (로그인 필요)
    "투자자별_거래실적": "dbms/MDC/STAT/standard/MDCSTAT02201",
    "외국인보유량": "dbms/MDC/STAT/standard/MDCSTAT03701",

    # 공매도 (로그인 필요)
    "공매도_종합정보": "dbms/MDC/STAT/srt/MDCSTAT30001",
}
```

#### 테스트 결과

| API | 로그인 없이 | 결과 |
|-----|------------|------|
| 종목 검색 | ✅ | 성공 (30개 종목) |
| 전종목 시세 | ❌ | 400 Bad Request |
| PER/PBR/배당 | ❌ | 400 Bad Request |
| 투자자별 거래 | ❌ | 400 Bad Request |
| 외국인 보유량 | ❌ | 400 Bad Request |
| 공매도 | ❌ | 400 Bad Request |
| 주가지수 | ❌ | 400 Bad Request |

### 2. 데이터 수집 방법 비교

| 방법 | 장점 | 단점 | 권장 |
|------|------|------|:----:|
| **PyKRX** | 간편한 사용, 파이썬 네이티브 | 일부 API 불안정, 세션 의존 | ⚠️ |
| **KRX OPEN API** | 공식 API, 안정적, 인증키 기반 | 회원가입/인증키 신청 필요 | ✅ |
| **직접 스크래핑** | 모든 데이터 접근 가능 | 로그인 필요, 차단 위험 | ❌ |

### 3. KRX OPEN API 서비스 목록

#### 제공 데이터 (2010년 이후)

| 구분 | API 명 | 데이터 시작일 |
|------|--------|--------------|
| **지수** | KRX/KOSPI/KOSDAQ 시리즈 일별시세 | 2010-01-04 |
| **주식** | 유가증권/코스닥/코넥스 일별매매정보 | 2010-01-04 |
| **증권상품** | ETF/ETN/ELW 일별매매정보 | 2010-01-04 |
| **채권** | 국채/일반/소액채권 일별매매정보 | 2010-01-04 |
| **파생상품** | 선물/옵션 일별매매정보 | 2010-01-04 |
| **일반상품** | 석유/금/배출권 일별매매정보 | 2012-03-30~ |
| **ESG** | ESG 지수/채권/증권상품 | 2019-01-01~ |

#### OPEN API 사용 절차

1. **회원가입**: https://openapi.krx.co.kr/contents/OPP/COMS/client/OPPCOMS002_S0.cmd
2. **인증키 신청**: 마이페이지 → API 인증키 신청
3. **API 호출**: 인증키로 REST API 호출

## 권장 솔루션

### Option 1: KRX OPEN API 사용 (권장)

```python
import requests

# KRX OPEN API 기본 URL
OPEN_API_URL = "https://openapi.krx.co.kr/svc/apis/sto/stk_bydd_trd"

headers = {
    "AUTH_KEY": "YOUR_API_KEY_HERE"
}

params = {
    "basDd": "20250110"  # 기준일
}

response = requests.get(OPEN_API_URL, headers=headers, params=params)
data = response.json()
```

### Option 2: PyKRX + 세션 유지 (차선책)

```python
import pykrx.stock as stock
import time

# 날짜별 데이터 수집 (안정적인 API만 사용)
def get_market_data(date):
    """안정적인 PyKRX API만 사용"""
    try:
        # OHLCV 데이터 (안정적)
        ohlcv = stock.get_market_ohlcv(date)

        # 시가총액 (안정적)
        cap = stock.get_market_cap(date)

        return {"ohlcv": ohlcv, "cap": cap}
    except Exception as e:
        print(f"Error: {e}")
        return None

# 요청 간 딜레이 추가
time.sleep(1)
```

### Option 3: 세션 기반 직접 호출 (복잡)

```python
import requests

class KRXSession:
    """로그인 세션을 유지하며 API 호출"""

    def __init__(self, user_id, password):
        self.session = requests.Session()
        self.login(user_id, password)

    def login(self, user_id, password):
        login_url = "https://data.krx.co.kr/contents/MDC/COMS/client/MDCCOMS001.cmd"
        # 로그인 로직 구현 필요
        pass

    def get_all_stocks(self, date):
        url = "http://data.krx.co.kr/comm/bldAttendant/getJsonData.cmd"
        data = {
            "bld": "dbms/MDC/STAT/standard/MDCSTAT01501",
            "mktId": "STK",
            "trdDd": date,
            # ... 추가 파라미터
        }
        return self.session.post(url, data=data).json()
```

## 결론

1. **KRX OPEN API 회원가입 및 인증키 발급을 권장합니다**
   - 가장 안정적이고 공식적인 방법
   - 세션 관리 불필요
   - Rate limit만 준수하면 됨

2. **PyKRX는 OHLCV, 시가총액 등 기본 데이터에만 사용**
   - 일부 API가 None을 반환하는 문제 존재
   - 세션 의존적이라 불안정

3. **직접 스크래핑은 권장하지 않음**
   - 로그인 필수
   - 차단 위험
   - 유지보수 어려움

## 다음 단계

1. [ ] KRX OPEN API 회원가입
2. [ ] API 인증키 신청
3. [ ] OPEN API 기반 데이터 수집 스크립트 작성
4. [ ] 기존 PyKRX 코드를 OPEN API로 마이그레이션
