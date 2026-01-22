# KRX Session API 상세 문서

> **KRX 로그인 세션 기반 API 클라이언트** - Selenium 로그인 + requests 세션 관리

---

## 개요

`krx_session_api.py`는 한국거래소(KRX) 정보데이터시스템에 로그인하여 세션 기반 API를 호출하는 래퍼입니다.

### 왜 필요한가?

1. **pykrx 한계**: pykrx는 공개 API만 사용하여 일부 데이터 접근 불가
2. **로그인 필요 API**: KRX의 일부 API는 로그인 세션이 필요
3. **NPPFS 보안**: KRX는 Non-Plugin FS 가상 키보드를 사용하여 일반적인 자동화 불가

---

## 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│  KRXSessionAPI 클래스                                           │
├─────────────────────────────────────────────────────────────────┤
│  1. Selenium 로그인                                             │
│     ├── Chrome WebDriver                                        │
│     ├── iframe 전환 (로그인 폼)                                  │
│     ├── NPPFS 가상키보드 우회 (ActionChains)                     │
│     └── 세션 쿠키 수집                                          │
├─────────────────────────────────────────────────────────────────┤
│  2. requests 세션                                               │
│     ├── 쿠키 주입                                               │
│     ├── User-Agent 동기화                                       │
│     └── API 호출 (POST)                                         │
├─────────────────────────────────────────────────────────────────┤
│  3. 데이터 반환                                                 │
│     ├── JSON → Dict                                             │
│     └── JSON → DataFrame                                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 클래스 구조

### KRXSessionAPI

```python
class KRXSessionAPI:
    def __init__(self, user_id=None, password=None, auto_login=True):
        """
        Args:
            user_id: KRX 사용자 ID (기본값: 환경변수 또는 'goguma')
            password: KRX 비밀번호 (기본값: 환경변수)
            auto_login: 초기화 시 자동 로그인 여부
        """
```

### 주요 속성

| 속성 | 타입 | 설명 |
|------|------|------|
| `user_id` | str | KRX 로그인 ID |
| `password` | str | KRX 비밀번호 |
| `session` | requests.Session | HTTP 세션 객체 |
| `cookies` | dict | 로그인 후 수집된 쿠키 |
| `logged_in` | bool | 로그인 상태 |

---

## API 메서드

### 종목 관련

#### `get_ticker_list(market="ALL")`

종목 코드 목록을 조회합니다.

```python
api = KRXSessionAPI()
tickers = api.get_ticker_list("STK")  # 유가증권
print(tickers[:5])  # ['005930', '000660', '005380', ...]
```

**파라미터**:
- `market`: `ALL`, `STK`(유가증권), `KSQ`(코스닥)

**반환값**: `List[str]` - 종목 코드 리스트

---

#### `get_ticker_info(market="ALL")`

종목 상세 정보를 DataFrame으로 반환합니다.

```python
df = api.get_ticker_info("STK")
print(df.columns)
# ['ticker', 'name', 'market_code', 'market_name', 'isin', ...]
```

**반환값**: `pd.DataFrame`

| 컬럼 | 설명 |
|------|------|
| ticker | 종목코드 (6자리) |
| name | 종목명 |
| market_code | 시장코드 |
| market_name | 시장명 |
| isin | ISIN 코드 |

---

#### `get_ticker_name(ticker)`

종목 코드로 종목명을 조회합니다.

```python
name = api.get_ticker_name("005930")
print(name)  # 삼성전자
```

---

### 시장 정보

#### `get_market_summary(market="STK")`

시장 요약 정보를 조회합니다.

```python
summary = api.get_market_summary("STK")
print(summary)
# {'TRD_DD': '2024/12/20', 'MKT_ID': 'STK', ...}
```

**반환값**: `Dict` - 기관/외국인/개인 매매 현황

---

#### `get_investor_summary(market="STK")`

투자자 동향 요약을 조회합니다.

```python
investor = api.get_investor_summary("STK")
```

---

#### `get_trading_trend(market="STK")`

거래 동향을 조회합니다.

```python
trend = api.get_trading_trend("STK")
```

---

### 지수 정보

#### `get_index_chart_data(index_code="302", days="1D")`

지수 차트 데이터를 조회합니다.

```python
chart = api.get_index_chart_data("302", "1D")  # KOSPI 1일
print(chart.shape)  # (391, N)
```

**파라미터**:
- `index_code`: 지수 코드 (302: KOSPI)
- `days`: 기간 (`1D`, `5D`, `1M`, `3M`, `1Y`)

**반환값**: `pd.DataFrame` - 시간/종가/등락률 등

---

### 공시 정보

#### `get_disclosures()`

최근 공시 목록을 조회합니다.

```python
disclosures = api.get_disclosures()
print(len(disclosures))  # 7
```

---

### Naver 대체 API

#### `get_stock_ohlcv_naver(ticker, fromdate, todate)`

개별 종목 시세를 Naver Finance에서 조회합니다.

> STAT 계열 API가 권한 제한으로 작동하지 않아 Naver를 대체로 사용합니다.

```python
ohlcv = api.get_stock_ohlcv_naver("005930", "20241201", "20241220")
print(ohlcv.columns)
# ['시가', '고가', '저가', '종가', '거래량', '등락률']
```

---

## 싱글톤 편의 함수

매번 인스턴스를 생성하지 않고 사용할 수 있습니다.

```python
from krx_session_api import (
    get_market_ticker_list,
    get_market_ticker_name,
    get_ticker_info,
    get_market_summary,
    get_index_chart,
    get_stock_ohlcv
)

# 첫 호출 시 자동 로그인
tickers = get_market_ticker_list("STK")
name = get_market_ticker_name("005930")
```

---

## 내부 API 호출

### `_call_api(bld, params)`

KRX JSON API를 직접 호출합니다.

```python
data = api._call_api(
    "dbms/MDC/MAIN/MDCMAIN00103",
    {"mktId": "STK"}
)
```

**엔드포인트**: `https://data.krx.co.kr/comm/bldAttendant/getJsonData.cmd`

---

## 작동하는 API 목록

| bld | 메서드 | 설명 |
|-----|--------|------|
| `dbms/comm/finder/finder_stkisu` | `get_ticker_list()` | 종목 검색 |
| `dbms/MDC/MAIN/MDCMAIN00101` | `get_disclosures()` | 공시 목록 |
| `dbms/MDC/MAIN/MDCMAIN00102` | `get_index_chart_data()` | 지수 차트 |
| `dbms/MDC/MAIN/MDCMAIN00103` | `get_market_summary()` | 시장 요약 |
| `dbms/MDC/MAIN/MDCMAIN00104` | `get_investor_summary()` | 투자자 동향 |
| `dbms/MDC/MAIN/MDCMAIN00105` | `get_trading_trend()` | 거래 동향 |
| `dbms/MDC/MAIN/MDCMAIN00106` | `get_orderbook_summary()` | 호가 요약 |

---

## 권한 제한 API (작동 안함)

goguma 계정으로는 STAT 계열 API에 접근할 수 없습니다.

| bld | 설명 | 대체 방법 |
|-----|------|----------|
| `dbms/MDC/STAT/standard/MDCSTAT01501` | 전종목 시세 | pykrx (Naver) |
| `dbms/MDC/STAT/standard/MDCSTAT00101` | 지수 현황 | MDCMAIN00102 |
| `dbms/MDC/STAT/standard/MDCSTAT00901` | 코스피 지수 | MDCMAIN00102 |

---

## 로그인 프로세스 상세

### 1. 로그인 페이지 접속

```python
driver.get("https://data.krx.co.kr/contents/MDC/COMS/client/MDCCOMS001.cmd")
```

### 2. iframe 전환

로그인 폼은 iframe 내부에 있습니다.

```python
iframe = wait.until(EC.presence_of_element_located((By.TAG_NAME, "iframe")))
driver.switch_to.frame(iframe)
```

### 3. ID 입력

```python
id_input = wait.until(EC.presence_of_element_located((By.NAME, "mbrId")))
id_input.send_keys(user_id)
```

### 4. 비밀번호 입력 (NPPFS 우회)

KRX는 NPPFS 가상 키보드를 사용합니다. ActionChains로 한 글자씩 입력해야 합니다.

```python
pw_input.click()
for char in password:
    ActionChains(driver).send_keys(char).perform()
    time.sleep(0.05)
```

### 5. 폼 제출

```python
driver.execute_script("document.querySelector('form').submit();")
```

### 6. 쿠키 수집

```python
for c in driver.get_cookies():
    self.cookies[c['name']] = c['value']
```

### 7. requests 세션 설정

```python
self.session.cookies.set(name, value, domain='data.krx.co.kr')
```

---

## 환경 변수

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `KRX_USER_ID` | KRX 로그인 ID | `goguma` |
| `KRX_PASSWORD` | KRX 비밀번호 | - |

---

## 주의사항

1. **headless 모드 비활성화**: iframe 전환 문제로 headless 모드 사용 불가
2. **STAT API 제한**: goguma 계정은 통계 API 접근 권한 없음
3. **세션 만료**: 장시간 미사용 시 세션 만료 가능
4. **동시 접속 제한**: KRX는 동일 계정 다중 로그인 제한 가능

---

## 참고

- [KRX 정보데이터시스템](https://data.krx.co.kr/)
- [Selenium 문서](https://www.selenium.dev/documentation/)
- [pykrx 라이브러리](https://github.com/sharebook-kr/pykrx)
