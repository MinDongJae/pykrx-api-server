# 문제 해결 가이드

> **PyKRX API Server** - 일반적인 문제와 해결 방법

---

## 목차

1. [로그인 관련](#로그인-관련)
2. [API 오류](#api-오류)
3. [Selenium/WebDriver](#seleniumwebdriver)
4. [환경 설정](#환경-설정)
5. [데이터 관련](#데이터-관련)

---

## 로그인 관련

### iframe 전환 실패

**증상**:
```
[KRXSessionAPI] iframe 전환 실패
```

**원인**: headless 모드에서 iframe이 제대로 로드되지 않음

**해결**:
1. `krx_session_api.py` 62번 줄에서 headless 모드 비활성화
```python
# options.add_argument("--headless=new")  # 주석 처리
```

2. 또는 wait 시간 증가
```python
time.sleep(5)  # 4 → 5초
```

---

### 로그인 상태 불확실

**증상**:
```
[KRXSessionAPI] ⚠️ 로그인 상태 불확실
```

**원인**:
- 잘못된 비밀번호
- NPPFS 가상 키보드 입력 실패
- 네트워크 지연

**해결**:
1. 환경 변수 확인
```bash
echo $KRX_USER_ID
echo $KRX_PASSWORD
```

2. 수동 로그인 테스트
```python
api = KRXSessionAPI(auto_login=False)
api.login()  # 브라우저 창에서 직접 확인
```

3. ActionChains 딜레이 증가
```python
for char in password:
    ActionChains(driver).send_keys(char).perform()
    time.sleep(0.1)  # 0.05 → 0.1초
```

---

### Alert 창 문제

**증상**: 로그인 후 Alert 창이 닫히지 않음

**해결**:
```python
try:
    alert = driver.switch_to.alert
    print(f"Alert: {alert.text}")
    alert.accept()
except:
    pass
```

---

## API 오류

### STAT API LOGOUT

**증상**:
```
[KRXSessionAPI] API 실패: dbms/MDC/STAT/... -> 400
Response: LOGOUT
```

**원인**: goguma 계정은 STAT 계열 API 접근 권한이 없음

**해결**:
1. **Naver fallback 사용** (권장)
```python
# STAT API 대신 Naver 사용
ohlcv = api.get_stock_ohlcv_naver("005930", "20241201", "20241220")
```

2. **MAIN API 사용**
```python
# STAT00101 대신 MAIN00102 사용
chart = api.get_index_chart_data("302", "1D")
```

3. **다른 계정 사용**
- STAT API 권한이 있는 계정 필요

**권한별 API 분류**:

| 권한 | API 패턴 | 예시 |
|------|----------|------|
| ✅ 일반 | `MDCMAIN*` | MDCMAIN00101 |
| ✅ 일반 | `finder_*` | finder_stkisu |
| ❌ 제한 | `MDCSTAT*` | MDCSTAT01501 |

---

### 세션 만료

**증상**:
```
[KRXSessionAPI] API 실패: ... -> 400
```

**원인**: 장시간 미사용으로 세션 만료

**해결**:
```python
# 재로그인
api = KRXSessionAPI()  # 새 인스턴스 생성
```

또는 싱글톤 인스턴스 초기화:
```python
import krx_session_api
krx_session_api._api_instance = None
tickers = krx_session_api.get_market_ticker_list()
```

---

### JSON 파싱 오류

**증상**:
```
json.decoder.JSONDecodeError: Expecting value
```

**원인**: API가 JSON 대신 HTML 에러 페이지 반환

**해결**:
1. 응답 내용 확인
```python
resp = session.post(url, data=params)
print(resp.text[:500])  # 응답 확인
```

2. 쿠키/헤더 재설정
```python
api._setup_session()
```

---

## Selenium/WebDriver

### ChromeDriver 찾을 수 없음

**증상**:
```
WebDriverException: Message: 'chromedriver' executable needs to be in PATH
```

**해결**:
1. **webdriver-manager 사용** (권장)
```bash
pip install webdriver-manager
```

```python
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager

service = Service(ChromeDriverManager().install())
driver = webdriver.Chrome(service=service)
```

2. **수동 설치**
   - [ChromeDriver 다운로드](https://chromedriver.chromium.org/downloads)
   - 시스템 PATH에 추가

---

### Chrome 버전 불일치

**증상**:
```
SessionNotCreatedException: Message: session not created: This version of ChromeDriver only supports Chrome version XX
```

**해결**:
1. Chrome 브라우저 버전 확인
   - `chrome://version/`

2. 맞는 ChromeDriver 다운로드
   - [ChromeDriver Downloads](https://chromedriver.chromium.org/downloads)

3. webdriver-manager 업데이트
```bash
pip install --upgrade webdriver-manager
```

---

### DevToolsActivePort 오류

**증상**:
```
WebDriverException: unknown error: DevToolsActivePort file doesn't exist
```

**해결**:
```python
options = Options()
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
options.add_argument("--remote-debugging-port=9222")
```

---

## 환경 설정

### 환경 변수 미설정

**증상**: 기본값 'goguma'가 아닌 다른 계정 사용 시 로그인 실패

**해결**:
1. `.env` 파일 생성
```bash
cp .env.example .env
```

2. 환경 변수 설정
```bash
# .env
KRX_USER_ID=your_id
KRX_PASSWORD=your_password
```

3. 환경 변수 로드
```python
from dotenv import load_dotenv
load_dotenv()
```

---

### pip 의존성 오류

**증상**: `ModuleNotFoundError: No module named 'pykrx'`

**해결**:
```bash
pip install -r requirements.txt
```

또는 개별 설치:
```bash
pip install pykrx pandas selenium requests
```

---

### 인코딩 오류 (Windows)

**증상**: 한글 출력 시 `UnicodeEncodeError`

**해결**:
```python
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
```

또는 환경 변수:
```bash
set PYTHONIOENCODING=utf-8
```

---

## 데이터 관련

### 빈 데이터 반환

**증상**: `get_ticker_list()`가 빈 리스트 반환

**원인**:
- 로그인 실패
- 잘못된 market 파라미터

**해결**:
1. 로그인 상태 확인
```python
print(api.logged_in)  # True 여야 함
```

2. 올바른 market 값 사용
```python
# 올바른 값: ALL, STK, KSQ
tickers = api.get_ticker_list("STK")
```

---

### DataFrame 컬럼 불일치

**증상**: 예상과 다른 컬럼명

**해결**: API 응답 구조 확인
```python
data = api._call_api("dbms/comm/finder/finder_stkisu", {
    "mktsel": "ALL",
    "searchText": "",
    "typeNo": "0"
})
print(data.keys())  # 응답 키 확인
print(data['block1'][0].keys())  # 데이터 키 확인
```

---

### 날짜 형식 오류

**증상**: OHLCV 조회 시 빈 데이터

**원인**: 잘못된 날짜 형식

**해결**:
```python
# 올바른 형식: YYYYMMDD (문자열)
ohlcv = api.get_stock_ohlcv_naver("005930", "20241201", "20241220")

# 잘못된 형식
# ohlcv = api.get_stock_ohlcv_naver("005930", "2024-12-01", "2024-12-20")  # ❌
```

---

## 디버깅 팁

### 로그 레벨 높이기

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### 네트워크 요청 확인

```python
# requests 디버깅
import http.client
http.client.HTTPConnection.debuglevel = 1
```

### Selenium 스크린샷

```python
try:
    # 작업 수행
except Exception as e:
    driver.save_screenshot("error.png")
    raise e
```

### 쿠키 상태 확인

```python
print("쿠키:", api.cookies)
print("세션 쿠키:", dict(api.session.cookies))
```

---

## 자주 묻는 질문

### Q: STAT API는 언제 사용 가능한가요?

A: 더 높은 권한의 KRX 계정이 필요합니다. goguma 계정은 기본 권한만 있어 MAIN/COMM API만 사용 가능합니다.

### Q: pykrx와 KRXSessionAPI 중 무엇을 사용해야 하나요?

A:
- **pykrx**: 개별 종목 시세, ETF 정보 (Naver 기반)
- **KRXSessionAPI**: 시장 요약, 투자자 동향, 공시 정보 (로그인 필요)

### Q: headless 모드 지원 계획이 있나요?

A: 현재 KRX의 NPPFS 보안 때문에 headless 모드가 불안정합니다. 향후 개선 예정입니다.

---

## 문의

추가 문제가 있으면 GitHub Issues에 등록해주세요.
