# API 레퍼런스

> **PyKRX API Server** - FastAPI 기반 REST API 레퍼런스

---

## 기본 정보

| 항목 | 값 |
|------|-----|
| Base URL | `http://localhost:8000` |
| Content-Type | `application/json` |
| Swagger UI | `http://localhost:8000/docs` |
| ReDoc | `http://localhost:8000/redoc` |

---

## 자연어 API

### `GET /api/nl`

자연어 질의를 분석하여 적절한 데이터를 반환합니다.

**파라미터**:

| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `query` | string | ✅ | 자연어 질의 |

**요청 예시**:

```bash
curl "http://localhost:8000/api/nl?query=삼성전자+주가"
curl "http://localhost:8000/api/nl?query=코스피+시가총액+상위+10개"
curl "http://localhost:8000/api/nl?query=ETF+목록"
```

**응답 예시**:

```json
{
  "success": true,
  "query": "삼성전자 주가",
  "intent": "stock_price",
  "confidence": 0.92,
  "method": "keyword",
  "data": {
    "ticker": "005930",
    "name": "삼성전자",
    "close": 55000,
    "change": -500,
    "change_rate": -0.90
  },
  "count": 1,
  "latency_ms": 245.3
}
```

**지원 인텐트**:

| 인텐트 | 키워드 예시 | 설명 |
|--------|-------------|------|
| `stock_price` | 주가, 종가, 시세 | 개별 종목 가격 |
| `market_cap` | 시가총액, 시총 | 시가총액 순위 |
| `etf_list` | ETF, 상장지수펀드 | ETF 목록 |
| `index_price` | 지수, 코스피 | 지수 시세 |
| `foreign_holding` | 외국인 보유율 | 외국인 지분 |
| `fundamental` | PER, PBR, 배당 | 기본 지표 |
| `investor_trading` | 외국인 매매 | 투자자 매매 동향 |
| `short_selling` | 공매도 | 공매도 현황 |

---

## 주식 API

### `GET /api/stocks/ohlcv`

개별 종목의 OHLCV(시가/고가/저가/종가/거래량)를 조회합니다.

**파라미터**:

| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `ticker` | string | ✅ | - | 종목코드 (6자리) |
| `start_date` | string | ❌ | 30일 전 | 시작일 (YYYYMMDD) |
| `end_date` | string | ❌ | 오늘 | 종료일 (YYYYMMDD) |

**요청 예시**:

```bash
curl "http://localhost:8000/api/stocks/ohlcv?ticker=005930"
curl "http://localhost:8000/api/stocks/ohlcv?ticker=005930&start_date=20241201&end_date=20241220"
```

**응답 예시**:

```json
{
  "success": true,
  "ticker": "005930",
  "name": "삼성전자",
  "data": [
    {
      "date": "2024-12-20",
      "open": 55500,
      "high": 56000,
      "low": 54800,
      "close": 55000,
      "volume": 12345678
    }
  ],
  "count": 14
}
```

---

### `GET /api/stocks/market-cap`

시가총액 순위를 조회합니다.

**파라미터**:

| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `market` | string | ❌ | `KOSPI` | 시장 (`KOSPI`, `KOSDAQ`, `ALL`) |
| `top_n` | int | ❌ | 10 | 상위 N개 |

**요청 예시**:

```bash
curl "http://localhost:8000/api/stocks/market-cap?market=KOSPI&top_n=10"
```

**응답 예시**:

```json
{
  "success": true,
  "market": "KOSPI",
  "data": [
    {
      "rank": 1,
      "ticker": "005930",
      "name": "삼성전자",
      "market_cap": 398456000000000,
      "market_cap_trillion": 398.46
    }
  ],
  "count": 10
}
```

---

### `GET /api/stocks/fundamental`

종목의 기본 지표(PER, PBR, 배당수익률 등)를 조회합니다.

**파라미터**:

| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `ticker` | string | ✅ | 종목코드 |

**응답 예시**:

```json
{
  "success": true,
  "ticker": "005930",
  "name": "삼성전자",
  "data": {
    "per": 12.5,
    "pbr": 1.2,
    "eps": 4400,
    "bps": 45833,
    "dividend_yield": 2.5
  }
}
```

---

### `GET /api/stocks/foreign-holding`

외국인 보유 비율을 조회합니다.

**파라미터**:

| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `ticker` | string | ✅ | 종목코드 |

**응답 예시**:

```json
{
  "success": true,
  "ticker": "005930",
  "name": "삼성전자",
  "data": {
    "foreign_holding_ratio": 52.3,
    "foreign_shares": 3123456789,
    "total_shares": 5969782550
  }
}
```

---

## 지수 API

### `GET /api/index/ohlcv`

지수의 OHLCV를 조회합니다.

**파라미터**:

| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `index_code` | string | ✅ | - | 지수코드 |
| `period` | string | ❌ | `1D` | 기간 |

**지수코드**:

| 코드 | 지수명 |
|------|--------|
| `1001` | KOSPI |
| `2001` | KOSDAQ |
| `1028` | KOSPI 200 |

**요청 예시**:

```bash
curl "http://localhost:8000/api/index/ohlcv?index_code=1001"
```

---

### `GET /api/index/chart`

지수 차트 데이터를 조회합니다 (KRX Session API 사용).

**파라미터**:

| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `index_code` | string | ❌ | `302` | 지수코드 |
| `days` | string | ❌ | `1D` | 기간 |

**기간 옵션**: `1D`, `5D`, `1M`, `3M`, `1Y`

---

## ETF API

### `GET /api/etf/all`

전체 ETF 목록을 조회합니다.

**요청 예시**:

```bash
curl "http://localhost:8000/api/etf/all"
```

**응답 예시**:

```json
{
  "success": true,
  "data": [
    {
      "ticker": "069500",
      "name": "KODEX 200",
      "nav": 42150,
      "volume": 5678901
    }
  ],
  "count": 500
}
```

---

### `GET /api/etf/info`

특정 ETF의 상세 정보를 조회합니다.

**파라미터**:

| 이름 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `ticker` | string | ✅ | ETF 종목코드 |

---

## 시장 API

### `GET /api/market/summary`

시장 요약 정보를 조회합니다 (KRX Session API 사용).

**파라미터**:

| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `market` | string | ❌ | `STK` | 시장 (`STK`, `KSQ`) |

---

### `GET /api/market/investor`

투자자별 매매 동향을 조회합니다.

---

### `GET /api/market/disclosures`

최근 공시 목록을 조회합니다 (KRX Session API 사용).

---

## 공매도 API

### `GET /api/short-selling/trading`

공매도 거래 현황을 조회합니다.

**파라미터**:

| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `market` | string | ❌ | `KOSPI` | 시장 |
| `date` | string | ❌ | 오늘 | 조회일 |

---

## 유틸리티 API

### `GET /api/status`

서버 상태를 확인합니다.

**응답 예시**:

```json
{
  "status": "ok",
  "version": "1.0.0",
  "krx_session": {
    "logged_in": true,
    "user_id": "goguma"
  },
  "timestamp": "2024-12-20T10:30:00"
}
```

---

### `GET /api/tickers`

전체 종목 목록을 조회합니다 (KRX Session API 사용).

**파라미터**:

| 이름 | 타입 | 필수 | 기본값 | 설명 |
|------|------|------|--------|------|
| `market` | string | ❌ | `ALL` | 시장 |

---

## 에러 응답

모든 API는 에러 시 다음 형식으로 응답합니다.

```json
{
  "success": false,
  "error": {
    "code": "INVALID_TICKER",
    "message": "종목코드를 찾을 수 없습니다: 999999"
  }
}
```

**에러 코드**:

| 코드 | HTTP | 설명 |
|------|------|------|
| `INVALID_TICKER` | 400 | 유효하지 않은 종목코드 |
| `INVALID_DATE` | 400 | 유효하지 않은 날짜 형식 |
| `DATA_NOT_FOUND` | 404 | 데이터 없음 |
| `KRX_SESSION_ERROR` | 500 | KRX 세션 오류 |
| `INTERNAL_ERROR` | 500 | 내부 서버 오류 |

---

## 데이터 소스

| API 그룹 | 데이터 소스 |
|----------|-------------|
| `/api/stocks/ohlcv` | pykrx (Naver Finance) |
| `/api/stocks/market-cap` | pykrx |
| `/api/index/*` | KRX Session API / pykrx |
| `/api/market/*` | KRX Session API |
| `/api/etf/*` | pykrx |

---

## Rate Limit

현재 Rate Limit은 적용되지 않습니다. 단, KRX API의 자체 제한이 있을 수 있습니다.

---

## 인증

현재 인증은 필요하지 않습니다. KRX Session API는 서버에서 자동으로 로그인합니다.
