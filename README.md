# PyKRX API Server

> **한국거래소(KRX) 주식 데이터 API 서버** - 자연어 질의 지원

FastAPI 기반 REST API 서버로, 자연어 질문을 분석하여 적절한 주식 데이터를 반환합니다.

---

## 주요 기능

| 기능 | 설명 |
|------|------|
| **자연어 API** | "삼성전자 주가" → 자동으로 API 호출 |
| **하이브리드 분류** | 키워드 → 임베딩 → LLM 3단계 폴백 |
| **KRX 로그인** | PER/PBR, 외국인 보유율 등 로그인 필요 API 지원 |
| **pykrx 통합** | pykrx 라이브러리 기반 안정적 데이터 수집 |

---

## 빠른 시작

### 1. 설치

```bash
git clone https://github.com/YOUR_USERNAME/pykrx-api-server.git
cd pykrx-api-server

# 가상환경 생성 (권장)
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt
```

### 2. 환경 설정 (선택)

```bash
# LLM 분류 사용 시 (선택)
export GEMINI_API_KEY=your_api_key
```

### 3. 서버 실행

```bash
python main.py
```

서버가 `http://localhost:8000`에서 실행됩니다.

---

## API 사용법

### 자연어 API (추천)

```bash
# 시가총액 상위 종목
curl "http://localhost:8000/api/nl?query=코스피+시가총액+상위+10개"

# 특정 종목 주가
curl "http://localhost:8000/api/nl?query=삼성전자+주가"

# ETF 목록
curl "http://localhost:8000/api/nl?query=ETF+목록"

# 지수 조회
curl "http://localhost:8000/api/nl?query=코스닥150+지수"

# 외국인 보유율
curl "http://localhost:8000/api/nl?query=SK하이닉스+외국인+보유율"
```

### REST API (직접 호출)

```bash
# 주가 조회
curl "http://localhost:8000/api/stocks/ohlcv?ticker=005930"

# 시가총액
curl "http://localhost:8000/api/stocks/market-cap?market=KOSPI&top_n=10"

# ETF 목록
curl "http://localhost:8000/api/etf/all"

# 지수 시세
curl "http://localhost:8000/api/index/ohlcv?index_code=1001"

# 서버 상태
curl "http://localhost:8000/api/status"
```

---

## 응답 예시

### 자연어 질의 응답

```json
{
  "success": true,
  "query": "코스피 시가총액 상위 10개",
  "intent": "market_cap",
  "confidence": 0.82,
  "method": "embedding",
  "data": [
    {
      "종목코드": "005930",
      "종목명": "삼성전자",
      "시가총액": 398456000000000,
      "시가총액_조": 398.46
    }
  ],
  "count": 10,
  "latency_ms": 245.3
}
```

---

## 하이브리드 인텐트 분류기

3단계 폴백 시스템으로 높은 정확도를 보장합니다:

| 단계 | 방식 | 속도 | 신뢰도 임계값 |
|------|------|------|--------------|
| 1 | 키워드 매칭 | ~1ms | 0.7 |
| 2 | 임베딩 유사도 | ~100ms | 0.6 |
| 3 | LLM (Gemini) | ~1s | - |

### 지원 인텐트

| 인텐트 | 키워드 예시 | API 엔드포인트 |
|--------|-------------|---------------|
| `stock_price` | 주가, 종가, 시세 | `/api/stocks/ohlcv` |
| `market_cap` | 시가총액, 시총 | `/api/stocks/market-cap` |
| `etf_list` | ETF, 상장지수펀드 | `/api/etf/all` |
| `index_price` | 지수, 코스피, 코스닥 | `/api/index/ohlcv` |
| `foreign_holding` | 외국인 보유율, 외인 지분 | `/api/stocks/foreign-holding` |
| `fundamental` | PER, PBR, 배당 | `/api/stocks/fundamental` |
| `investor_trading` | 외국인 매매, 기관 순매수 | `/api/stocks/investor-trading` |
| `short_selling` | 공매도, 대차 | `/api/short-selling/trading` |

---

## KRX 로그인 (선택)

일부 API는 KRX 로그인이 필요합니다:

- PER/PBR/배당수익률
- 외국인 보유율
- 투자자별 거래
- 공매도 현황
- ETF/ETN/ELW (일부)

### 로그인 세션 생성

```python
# krx_session.py 실행으로 쿠키 생성
python krx_session.py
```

생성된 `.krx_cookies.pkl` 파일이 서버 시작 시 자동 로드됩니다.

---

## 프로젝트 구조

```
pykrx-api-server/
├── main.py                 # FastAPI 서버 (2,300+ lines)
├── intent_classifier.py    # 하이브리드 인텐트 분류기
├── krx_session.py          # KRX 로그인 세션 관리
├── requirements.txt        # 의존성
├── PYKRX_API_SPEC.md       # API 상세 명세서
├── api_schema.json         # API 스키마 (LLM용)
└── KRX_DATA_COLLECTION_GUIDE.md  # 데이터 수집 가이드
```

---

## 의존성

### 필수

```
fastapi>=0.100.0
uvicorn>=0.23.0
pykrx>=1.0.45
pandas>=2.0.0
requests>=2.28.0
```

### 선택 (인텐트 분류 고도화)

```
sentence-transformers>=2.2.0  # 임베딩 기반 분류
numpy>=1.24.0
google-generativeai>=0.3.0    # LLM 폴백
```

---

## 테스트

### 자연어 API 테스트

```bash
# PowerShell
.\test-nl-api.ps1

# Python
python test_nl_api.py
```

### 브라우저 테스트

Swagger UI: http://localhost:8000/docs

---

## 라이선스

MIT License

---

## 기여

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 참고

- [pykrx 라이브러리](https://github.com/sharebook-kr/pykrx)
- [FastAPI 문서](https://fastapi.tiangolo.com/)
- [한국거래소 데이터](https://data.krx.co.kr/)
