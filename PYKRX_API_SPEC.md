# PyKRX API 명세서 (LLM 자연어 호출용)

> **목적**: 자연어 질문을 REST API 호출로 자동 변환
> **Base URL**: `http://localhost:8000`
> **인증**: KRX 로그인 필요 API는 🔐 표시

---

## 📋 API 인텐트 분류표

| 인텐트 ID | 자연어 패턴 | 매핑 API | 필수 파라미터 |
|-----------|-------------|----------|---------------|
| `stock_price` | "주가", "종가", "시세", "OHLCV" | `/api/stocks/ohlcv` | ticker |
| `stock_list` | "종목 목록", "상장 종목" | `/api/stocks/list` | market |
| `market_cap` | "시가총액", "시총" | `/api/stocks/market-cap` | market |
| `fundamental` | "PER", "PBR", "배당수익률" | `/api/stocks/fundamental` | market 🔐 |
| `all_markets` | "전체 시장", "코스피 코스닥" | `/api/stocks/all-markets` | - |
| `investor` | "투자자별", "외국인/기관 매매" | `/api/stocks/investor-trading` | market 🔐 |
| `foreign` | "외국인 보유", "외인 지분" | `/api/stocks/foreign-holding` | market 🔐 |
| `sector` | "업종", "섹터" | `/api/stocks/sector` | market |
| `etf` | "ETF" | `/api/etf/all` | - 🔐 |
| `etn` | "ETN" | `/api/etn/all` | - 🔐 |
| `short_sell` | "공매도", "대차" | `/api/short-selling/trading` | market 🔐 |
| `short_balance` | "공매도 잔고" | `/api/short-selling/balance` | market 🔐 |
| `credit` | "신용거래", "신용잔고" | `/api/credit/trading` | market 🔐 |
| `program` | "프로그램 매매" | `/api/program/trading` | market 🔐 |
| `index_list` | "지수 목록" | `/api/index/list` | market |
| `index_price` | "지수 시세", "코스피 지수" | `/api/index/ohlcv` | index_code |
| `index_comp` | "지수 구성종목" | `/api/index/components` | index_code |
| `futures` | "선물", "선물 시세" | `/api/derivatives/futures` | - 🔐 |
| `options` | "옵션", "옵션 시세" | `/api/derivatives/options` | - 🔐 |
| `dividend` | "배당", "배당금" | `/api/dividend/info` | ticker 🔐 |
| `halt` | "거래정지" | `/api/special/trading-halt` | - 🔐 |
| `admin` | "관리종목" | `/api/special/admin-issue` | - 🔐 |

---

## 🔍 엔드포인트 상세 명세

### 1. 서버 상태

#### `GET /api/status`
서버 및 KRX 로그인 상태 확인

**자연어 예시**:
- "서버 상태 확인해줘"
- "로그인 됐어?"
- "API 사용 가능해?"

**응답 필드**:
| 필드 | 타입 | 설명 |
|------|------|------|
| `server` | string | 서버 상태 ("running") |
| `krx_login.logged_in` | boolean | 로그인 여부 |
| `available_endpoints` | array | 사용 가능한 API 목록 |

---

### 2. 주식 종목 목록

#### `GET /api/stocks/list`
특정 시장의 종목 목록 조회

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `market` | string | ❌ | KOSPI | KOSPI, KOSDAQ, KONEX |
| `date` | string | ❌ | 최근 거래일 | YYYYMMDD 형식 |

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "코스피 종목 보여줘" | `GET /api/stocks/list?market=KOSPI` |
| "코스닥 상장 종목" | `GET /api/stocks/list?market=KOSDAQ` |
| "1월 15일 코스피 종목" | `GET /api/stocks/list?market=KOSPI&date=20260115` |

**응답 예시**:
```json
{
  "date": "20260117",
  "market": "KOSPI",
  "count": 500,
  "data": [
    {"ticker": "005930", "name": "삼성전자", "market": "코스피"},
    {"ticker": "000660", "name": "SK하이닉스", "market": "코스피"}
  ]
}
```

---

### 3. 주가(OHLCV) 조회

#### `GET /api/stocks/ohlcv`
특정 종목의 시가/고가/저가/종가/거래량 조회

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `ticker` | string | ✅ | - | 종목코드 (6자리) |
| `start` | string | ❌ | end-period일 | 시작일 (YYYYMMDD) |
| `end` | string | ❌ | 오늘 | 종료일 (YYYYMMDD) |
| `period` | int | ❌ | 30 | 조회 기간 (일) |

**종목코드 사전** (자연어 → ticker 변환):
| 자연어 | ticker |
|--------|--------|
| 삼성전자 | 005930 |
| SK하이닉스 | 000660 |
| LG에너지솔루션 | 373220 |
| 현대차 | 005380 |
| 카카오 | 035720 |
| 네이버, NAVER | 035420 |
| 셀트리온 | 068270 |
| 삼성SDI | 006400 |

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "삼성전자 주가" | `GET /api/stocks/ohlcv?ticker=005930` |
| "하이닉스 최근 7일 주가" | `GET /api/stocks/ohlcv?ticker=000660&period=7` |
| "카카오 1월 주가" | `GET /api/stocks/ohlcv?ticker=035720&start=20260101&end=20260131` |
| "005930 종가" | `GET /api/stocks/ohlcv?ticker=005930` |

**응답 필드**:
| 필드 | 타입 | 설명 |
|------|------|------|
| `ticker` | string | 종목코드 |
| `name` | string | 종목명 |
| `data[].날짜` | string | 거래일 (YYYY-MM-DD) |
| `data[].시가` | int | 시가 |
| `data[].고가` | int | 고가 |
| `data[].저가` | int | 저가 |
| `data[].종가` | int | 종가 |
| `data[].거래량` | int | 거래량 |

---

### 4. 시가총액 조회

#### `GET /api/stocks/market-cap`
시가총액 상위 종목 조회

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `market` | string | ❌ | KOSPI | 시장 구분 |
| `date` | string | ❌ | 최근 거래일 | YYYYMMDD |
| `top_n` | int | ❌ | 50 | 상위 N개 |

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "시가총액 상위 10개" | `GET /api/stocks/market-cap?top_n=10` |
| "코스닥 시총 순위" | `GET /api/stocks/market-cap?market=KOSDAQ` |
| "시가총액 1위" | `GET /api/stocks/market-cap?top_n=1` |

**응답 필드**:
| 필드 | 타입 | 설명 |
|------|------|------|
| `data[].종목코드` | string | 종목코드 |
| `data[].종목명` | string | 종목명 |
| `data[].시가총액` | int | 시가총액 (원) |
| `data[].시가총액_조` | float | 시가총액 (조원) |
| `data[].상장주식수` | int | 상장주식수 |

---

### 5. 펀더멘털 지표 🔐

#### `GET /api/stocks/fundamental`
PER, PBR, 배당수익률 등 투자지표 조회

**⚠️ KRX 로그인 필요**

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `market` | string | ❌ | KOSPI | 시장 구분 |
| `date` | string | ❌ | 최근 거래일 | YYYYMMDD |
| `top_n` | int | ❌ | 100 | 상위 N개 |

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "코스피 PER 순위" | `GET /api/stocks/fundamental?market=KOSPI` |
| "PBR 낮은 종목" | `GET /api/stocks/fundamental` → 클라이언트 정렬 |
| "배당수익률 높은 종목" | `GET /api/stocks/fundamental` → 클라이언트 정렬 |
| "삼성전자 PER" | `GET /api/stocks/fundamental` → ticker 필터 |

**응답 필드**:
| 필드 | 타입 | 설명 |
|------|------|------|
| `data[].PER` | float | 주가수익비율 |
| `data[].PBR` | float | 주가순자산비율 |
| `data[].배당수익률` | float | 배당수익률 (%) |
| `data[].EPS` | int | 주당순이익 |
| `data[].BPS` | int | 주당순자산 |

---

### 6. 전체 시장 데이터

#### `GET /api/stocks/all-markets`
코스피 + 코스닥 통합 데이터 (분석용)

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `date` | string | ❌ | 최근 거래일 | YYYYMMDD |
| `top_n` | int | ❌ | 50 | 시장별 상위 N개 |

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "전체 시장 현황" | `GET /api/stocks/all-markets` |
| "코스피 코스닥 비교" | `GET /api/stocks/all-markets` |
| "오늘 주식 시장" | `GET /api/stocks/all-markets` |

---

### 7. 투자자별 거래 🔐

#### `GET /api/stocks/investor-trading`
기관/외국인/개인 투자자별 거래실적

**⚠️ KRX 로그인 필요**

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `date` | string | ❌ | 최근 거래일 | YYYYMMDD |
| `market` | string | ❌ | KOSPI | 시장 구분 |

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "외국인 매매 현황" | `GET /api/stocks/investor-trading` |
| "기관 순매수" | `GET /api/stocks/investor-trading` |
| "개인 투자자 거래" | `GET /api/stocks/investor-trading` |

---

### 8. 외국인 보유량 🔐

#### `GET /api/stocks/foreign-holding`
외국인 보유 현황

**⚠️ KRX 로그인 필요**

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `date` | string | ❌ | 최근 거래일 | YYYYMMDD |
| `market` | string | ❌ | KOSPI | 시장 구분 |
| `top_n` | int | ❌ | 50 | 상위 N개 |

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "외국인 보유 비중" | `GET /api/stocks/foreign-holding` |
| "외인 지분율 높은 종목" | `GET /api/stocks/foreign-holding` |

---

### 9. 업종별 데이터

#### `GET /api/stocks/sector`
업종(섹터)별 시세 데이터

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `market` | string | ❌ | KOSPI | 시장 구분 |
| `date` | string | ❌ | 최근 거래일 | YYYYMMDD |

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "업종별 등락률" | `GET /api/stocks/sector` |
| "반도체 업종" | `GET /api/stocks/sector` → 필터 |
| "오늘 강세 업종" | `GET /api/stocks/sector` → 정렬 |

---

### 10. ETF 데이터 🔐

#### `GET /api/etf/all`
ETF 전종목 데이터

**⚠️ KRX 로그인 필요**

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `date` | string | ❌ | 최근 거래일 | YYYYMMDD |
| `top_n` | int | ❌ | 100 | 상위 N개 |

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "ETF 목록" | `GET /api/etf/all` |
| "ETF 거래량 순위" | `GET /api/etf/all` |
| "레버리지 ETF" | `GET /api/etf/all` → 이름 필터 |

---

### 11. ETN 데이터 🔐

#### `GET /api/etn/all`
ETN 전종목 데이터

**⚠️ KRX 로그인 필요**

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `date` | string | ❌ | 최근 거래일 | YYYYMMDD |
| `top_n` | int | ❌ | 100 | 상위 N개 |

---

### 12. 공매도 거래 🔐

#### `GET /api/short-selling/trading`
공매도 거래현황

**⚠️ KRX 로그인 필요**

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `date` | string | ❌ | 최근 거래일 | YYYYMMDD |
| `market` | string | ❌ | KOSPI | 시장 구분 |
| `top_n` | int | ❌ | 100 | 상위 N개 |

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "공매도 현황" | `GET /api/short-selling/trading` |
| "공매도 많은 종목" | `GET /api/short-selling/trading` |

---

### 13. 공매도 잔고 🔐

#### `GET /api/short-selling/balance`
공매도 잔고현황

**⚠️ KRX 로그인 필요**

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `date` | string | ❌ | 최근 거래일 | YYYYMMDD |
| `market` | string | ❌ | KOSPI | 시장 구분 |
| `top_n` | int | ❌ | 100 | 상위 N개 |

---

### 14. 신용거래 🔐

#### `GET /api/credit/trading`
신용거래 현황

**⚠️ KRX 로그인 필요**

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "신용거래 현황" | `GET /api/credit/trading` |
| "신용잔고 많은 종목" | `GET /api/credit/trading` |

---

### 15. 프로그램 매매 🔐

#### `GET /api/program/trading`
프로그램 매매 현황

**⚠️ KRX 로그인 필요**

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "프로그램 매매" | `GET /api/program/trading` |
| "차익거래 현황" | `GET /api/program/trading` |

---

### 16. 지수 목록

#### `GET /api/index/list`
주가지수 목록 조회

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `market` | string | ❌ | KOSPI | 시장 구분 |
| `date` | string | ❌ | 최근 거래일 | YYYYMMDD |

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "지수 목록" | `GET /api/index/list` |
| "코스피 지수 종류" | `GET /api/index/list?market=KOSPI` |

---

### 17. 지수 시세

#### `GET /api/index/ohlcv`
지수 OHLCV 조회

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `index_code` | string | ✅ | - | 지수코드 (예: 1001) |
| `start` | string | ❌ | end-period일 | 시작일 |
| `end` | string | ❌ | 오늘 | 종료일 |
| `period` | int | ❌ | 30 | 기간 (일) |

**지수코드 사전**:
| 자연어 | index_code |
|--------|------------|
| 코스피, KOSPI | 1001 |
| 코스피200 | 1028 |
| 코스닥, KOSDAQ | 2001 |
| 코스닥150 | 2203 |

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "코스피 지수" | `GET /api/index/ohlcv?index_code=1001` |
| "코스피200 30일" | `GET /api/index/ohlcv?index_code=1028&period=30` |

---

### 18. 지수 구성종목

#### `GET /api/index/components`
지수 구성종목 조회

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `index_code` | string | ✅ | - | 지수코드 |
| `date` | string | ❌ | 최근 거래일 | YYYYMMDD |

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "코스피200 구성종목" | `GET /api/index/components?index_code=1028` |
| "코스닥150 편입 종목" | `GET /api/index/components?index_code=2203` |

---

### 19. 선물 시세 🔐

#### `GET /api/derivatives/futures`
선물 시세 조회

**⚠️ KRX 로그인 필요**

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "선물 시세" | `GET /api/derivatives/futures` |
| "코스피200 선물" | `GET /api/derivatives/futures` |

---

### 20. 옵션 시세 🔐

#### `GET /api/derivatives/options`
옵션 시세 조회

**⚠️ KRX 로그인 필요**

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "옵션 시세" | `GET /api/derivatives/options` |
| "콜옵션 풋옵션" | `GET /api/derivatives/options` |

---

### 21. 배당 정보 🔐

#### `GET /api/dividend/info`
종목별 배당 정보

**⚠️ KRX 로그인 필요**

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `ticker` | string | ✅ | - | 종목코드 |
| `year` | int | ❌ | 올해 | 연도 |

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "삼성전자 배당" | `GET /api/dividend/info?ticker=005930` |
| "SK하이닉스 2025년 배당" | `GET /api/dividend/info?ticker=000660&year=2025` |

---

### 22. 거래정지 종목 🔐

#### `GET /api/special/trading-halt`
거래정지 종목 목록

**⚠️ KRX 로그인 필요**

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "거래정지 종목" | `GET /api/special/trading-halt` |
| "오늘 거래정지" | `GET /api/special/trading-halt` |

---

### 23. 관리종목 🔐

#### `GET /api/special/admin-issue`
관리종목 목록

**⚠️ KRX 로그인 필요**

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "관리종목 목록" | `GET /api/special/admin-issue` |
| "상장폐지 위험 종목" | `GET /api/special/admin-issue` |

---

### 24. KRX 직접 조회 🔐

#### `GET /api/krx/by-screen`
화면번호 기반 KRX 데이터 직접 조회

**⚠️ KRX 로그인 필요**

**파라미터**:
| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `screen` | string | ✅ | - | 화면번호 (예: 12005) |
| `date` | string | ❌ | 최근 거래일 | YYYYMMDD |
| `market` | string | ❌ | STK | STK/KSQ/KNX |

---

### 25. BLD 엔드포인트 목록

#### `GET /api/krx/bld-list`
사용 가능한 KRX BLD 엔드포인트 목록 (46개)

**자연어 → API 매핑**:
| 자연어 질문 | API 호출 |
|-------------|----------|
| "사용 가능한 API" | `GET /api/krx/bld-list` |
| "BLD 목록" | `GET /api/krx/bld-list` |

---

## 🧠 LLM 인텐트 분류 로직

### 키워드 기반 인텐트 감지

```python
def detect_intent(query: str) -> dict:
    """자연어 질문에서 인텐트와 파라미터 추출"""

    # 인텐트 키워드 매핑
    intent_keywords = {
        "stock_price": ["주가", "종가", "시세", "ohlcv", "가격"],
        "market_cap": ["시가총액", "시총"],
        "fundamental": ["per", "pbr", "배당수익률", "eps", "bps"],
        "investor": ["투자자", "외국인 매매", "기관 매매", "개인 매매"],
        "foreign": ["외국인 보유", "외인 지분", "외국인 비중"],
        "sector": ["업종", "섹터"],
        "etf": ["etf"],
        "etn": ["etn"],
        "short_sell": ["공매도"],
        "credit": ["신용거래", "신용잔고"],
        "program": ["프로그램 매매", "차익거래"],
        "index": ["지수", "kospi", "코스피", "코스닥"],
        "futures": ["선물"],
        "options": ["옵션"],
        "dividend": ["배당"],
        "halt": ["거래정지"],
        "admin": ["관리종목"],
    }

    query_lower = query.lower()

    for intent, keywords in intent_keywords.items():
        for kw in keywords:
            if kw in query_lower:
                return {"intent": intent, "confidence": 0.9}

    return {"intent": "unknown", "confidence": 0.0}
```

### 종목코드 추출

```python
TICKER_MAP = {
    "삼성전자": "005930",
    "sk하이닉스": "000660",
    "lg에너지솔루션": "373220",
    "삼성바이오로직스": "207940",
    "현대차": "005380",
    "기아": "000270",
    "삼성sdi": "006400",
    "lg화학": "051910",
    "네이버": "035420",
    "naver": "035420",
    "카카오": "035720",
    "kb금융": "105560",
    "신한지주": "055550",
    "셀트리온": "068270",
    "포스코퓨처엠": "003670",
    "현대모비스": "012330",
}

def extract_ticker(query: str) -> Optional[str]:
    """자연어에서 종목코드 추출"""
    query_lower = query.lower()

    # 직접 종목코드 (6자리 숫자)
    import re
    match = re.search(r'\b(\d{6})\b', query)
    if match:
        return match.group(1)

    # 종목명 → 코드 변환
    for name, ticker in TICKER_MAP.items():
        if name in query_lower:
            return ticker

    return None
```

### 날짜 추출

```python
def extract_date(query: str) -> Optional[str]:
    """자연어에서 날짜 추출 (YYYYMMDD 형식)"""
    import re
    from datetime import datetime, timedelta

    # YYYYMMDD 형식
    match = re.search(r'(\d{8})', query)
    if match:
        return match.group(1)

    # "1월 15일" 형식
    match = re.search(r'(\d{1,2})월\s*(\d{1,2})일', query)
    if match:
        month, day = int(match.group(1)), int(match.group(2))
        year = datetime.now().year
        return f"{year}{month:02d}{day:02d}"

    # "오늘", "어제" 처리
    if "오늘" in query:
        return datetime.now().strftime("%Y%m%d")
    if "어제" in query:
        return (datetime.now() - timedelta(days=1)).strftime("%Y%m%d")

    return None
```

---

## 📊 응답 분석 가이드

### 주가 데이터 분석 패턴

```python
def analyze_ohlcv(data: list) -> dict:
    """OHLCV 데이터 분석"""
    if not data:
        return {"error": "데이터 없음"}

    latest = data[-1]
    oldest = data[0]

    # 기간 수익률
    period_return = (latest["종가"] - oldest["종가"]) / oldest["종가"] * 100

    # 변동성 (고가-저가 평균)
    avg_range = sum(d["고가"] - d["저가"] for d in data) / len(data)

    # 평균 거래량
    avg_volume = sum(d["거래량"] for d in data) / len(data)

    return {
        "현재가": latest["종가"],
        "기간수익률": f"{period_return:.2f}%",
        "평균변동폭": avg_range,
        "평균거래량": int(avg_volume),
        "최고가": max(d["고가"] for d in data),
        "최저가": min(d["저가"] for d in data),
    }
```

### 시가총액 순위 분석

```python
def analyze_market_cap(data: list) -> str:
    """시가총액 데이터 요약"""
    if not data:
        return "데이터 없음"

    top3 = data[:3]
    summary = "시가총액 상위 3개:\n"
    for i, item in enumerate(top3, 1):
        summary += f"{i}. {item['종목명']}: {item['시가총액_조']}조원\n"

    return summary
```

---

## 🔗 통합 예시: 자연어 → API → 분석

### 예시 1: "삼성전자 최근 주가 분석해줘"

```python
# 1. 인텐트 감지
intent = detect_intent("삼성전자 최근 주가 분석해줘")
# → {"intent": "stock_price", "confidence": 0.9}

# 2. 파라미터 추출
ticker = extract_ticker("삼성전자 최근 주가 분석해줘")
# → "005930"

# 3. API 호출
response = requests.get(f"http://localhost:8000/api/stocks/ohlcv?ticker={ticker}")
data = response.json()

# 4. 분석
analysis = analyze_ohlcv(data["data"])
# → {"현재가": 82000, "기간수익률": "3.5%", ...}
```

### 예시 2: "코스피 시총 상위 10개 보여줘"

```python
# 1. 인텐트 감지
intent = detect_intent("코스피 시총 상위 10개 보여줘")
# → {"intent": "market_cap", "confidence": 0.9}

# 2. 파라미터 추출
market = "KOSPI"  # "코스피" 감지
top_n = 10  # "10개" 감지

# 3. API 호출
response = requests.get(f"http://localhost:8000/api/stocks/market-cap?market={market}&top_n={top_n}")
data = response.json()

# 4. 요약
summary = analyze_market_cap(data["data"])
```

---

## 📌 사용 가이드 요약

| 목적 | 자연어 예시 | API |
|------|-------------|-----|
| 특정 종목 주가 | "삼성전자 주가" | `/api/stocks/ohlcv?ticker=005930` |
| 시장 현황 | "오늘 코스피 현황" | `/api/stocks/all-markets` |
| 시총 순위 | "시가총액 상위 10개" | `/api/stocks/market-cap?top_n=10` |
| 밸류에이션 | "PER 낮은 종목" | `/api/stocks/fundamental` |
| 수급 분석 | "외국인 매매 동향" | `/api/stocks/investor-trading` |
| 공매도 | "공매도 많은 종목" | `/api/short-selling/trading` |
| 지수 | "코스피 지수 추이" | `/api/index/ohlcv?index_code=1001` |
| 파생상품 | "선물 시세" | `/api/derivatives/futures` |

---

*Last Updated: 2026-01-20*
*Version: 2.0.0*
