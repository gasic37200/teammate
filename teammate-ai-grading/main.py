import os
import base64
import json
from typing import List
from dotenv import load_dotenv  # .env 로드를 위한 라이브러리
from fastapi import FastAPI, File, UploadFile
from openai import OpenAI
from pydantic import BaseModel
from starlette.middleware.cors import CORSMiddleware

# 1. .env 파일의 환경 변수 로드
load_dotenv()

app = FastAPI()

# 2. 환경 변수 읽어오기
FACTCHAT_KEY = os.getenv("FACTCHAT_API_KEY")
FACTCHAT_URL = os.getenv("FACTCHAT_BASE_URL")
OPENAI_KEY = os.getenv("OPENAI_API_KEY")
MODEL_NAME = os.getenv("MODEL_NAME")

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 평가 가중치 및 등급 체계 (기존과 동일) ---
weights = {
    "developer": {
        "code_quality": 0.25, "environment_understanding": 0.13, "collaboration": 0.12,
        "testing_stability": 0.18, "test_presence": 0.08, "activity_consistency": 0.12, "commit_quality": 0.12,
    },
    "designer": {
        "color_contrast": 0.20, "layout_balance": 0.20, "typography": 0.15,
        "component_consistency": 0.15, "design_system_adherence": 0.15, "brand_identity": 0.10,
        "visual_refinement": 0.15
    },
    "planner": {
        "problem_logic": 0.20, "terminology_expertise": 0.15, "info_hierarchy": 0.20,
        "readability": 0.15, "requirement_clarity": 0.15, "user_thinking": 0.10, "risk_timeline_management": 0.05
    }
}

grade_scale = [
    (0.0, "원두 (The Bean) 🌱"), (4.1, "그라인드 (The Grind) 🔧"), (5.1, "에스프레소샷 (The Shot) ☕"),
    (6.1, "아메리카노 (The Americano) 🔵"), (7.1, "브루잉마스터 (Brewing Master) 🛠️"),
    (8.1, "시그니처 블렌더 (Signature Blend) 🌟"), (8.6, "로스터 (The Roaster) 🔥"),
    (9.1, "스페셜티 그레이드 (Specialty Grade) 🏅"), (9.6, "Q그레이더 (Q-Grader) 🎖️"), (9.9, "오리진 마스터 (Origin Master) 👑")
]


def calculate_weighted(role, result):
    w = weights[role]
    weighted_sum = sum(result[k]["score"] * w[k] for k in result if k in w)
    return round(weighted_sum / sum(w.values()), 2)


def get_grade(score):
    return next(g for t, g in reversed(grade_scale) if score >= t)


class DeveloperRequest(BaseModel):
    github_name: str


# --- 1️⃣ 개발자 평가 API ---
@app.post("/grading/developer")
def developer(req: DeveloperRequest):
    github_name = req.github_name
    role = "developer"
    github_url = f"https://github.com/{github_name}?tab=repositories"

    client = OpenAI(api_key=FACTCHAT_KEY, base_url=FACTCHAT_URL)

    prompt_text = f"""
            다음에 제공되는 GitHub 프로젝트 데이터를 분석하여 아래의 7개 항목을 각각 0~10점으로 평가하고,
            각 항목은 score 먼저 계산하고,
            그 score가 의미하는 수준에 정확히 맞도록 reason을 생성하라.
            reason은 절대 score보다 더 긍정적/부정적이어서는 안 된다.
            반드시 지정된 JSON 형식으로만 출력해줘.

            [평가 기준]

            1. 코드 품질 및 안정성 (code_quality)
                - Cyclomatic Complexity 평균
                - 중복 코드 비율(DRY 원칙)
                - 코드 스멜 발생 빈도
                - Lint 규칙 준수 여부
                - 함수/모듈 분리 수준
                - 안전한 예외 처리 구조

            2. 개발 환경 이해 (environment_understanding)
                - CI/CD 구성 파일(GitHub Actions, GitLab CI 등) 존재 여부
                - Dockerfile 구성 수준 및 multi-stage build 여부
                - .dockerignore 및 환경변수(.env) 관리 여부
                - 환경별 설정(dev/stage/prod) 분리 여부
                - 패키지 의존성 관리(버전 고정/불필요한 의존성)
                - 로컬 개발환경 재현 가능성(README 구성)

            3. 협업 및 소통 (collaboration)
                - PR 코멘트 양/깊이 및 감성 분석
                - 리뷰 피드백 반영 속도
                - Issue/PR 템플릿 사용 여부
                - 라벨링 및 프로젝트 관리 체계
                - 브랜치 전략(Git-flow, feature-branch) 준수 여부
                - 커밋 메시지 품질(Conventional Commit 등)

            4. 테스트 및 안정성 (testing_stability)
                - 자동화 테스트 존재 여부
                - 테스트 커버리지 리포트 존재 여부
                - 예외 처리 구조의 일관성
                - 회귀 테스트(regression) 작성 여부
                - flaky test(불안정 테스트) 존재 여부

            5. 테스트 코드 유무 (test_presence)
                - 테스트 파일 비율
                - 엣지 케이스 테스트 여부
                - 단위 테스트/통합 테스트 구성
                - mock/stub 활용 여부
                - 테스트 코드 스타일 일관성

            6. 활동 지속성 (activity_consistency)
                - 지난 1년간 커밋 빈도
                - 활동 그래프(잔디) 일관성
                - 중단 기간/스파이크 활동 분석
                - 유효한 프로젝트 수(토이 vs 실제 프로젝트)
                - 장기 프로젝트 유지 여부

            7. 커밋 규모 및 의미 (commit_quality)
                - 커밋당 평균 변경 라인 수(LOC)
                - 커밋 메시지의 구체성
                - 기능 단위로 커밋 분리 여부
                - 커밋 규칙(Conventional Commit 등) 준수 여부
                - 불필요한 파일 커밋 여부(.idea, build 등)

            [출력 규칙]

            - 반드시 아래 JSON 형식으로만 출력할 것
            - score는 0~10 사이의 숫자 (정수 또는 소수)
            - reason은 분석한 설명
            - JSON 외의 텍스트는 절대 출력하지 말 것

            [출력 JSON 형식]

            {{
              "code_quality": {{
                "score": 0,
                "reason": ""
              }},
              "environment_understanding": {{
                "score": 0,
                "reason": ""
              }},
              "collaboration": {{
                "score": 0,
                "reason": ""
              }},
              "testing_stability": {{
                "score": 0,
                "reason": ""
              }},
              "test_presence": {{
                "score": 0,
                "reason": ""
              }},
              "activity_consistency": {{
                "score": 0,
                "reason": ""
              }},
              "commit_quality": {{
                "score": 0,
                "reason": ""
              }},
            }}

            GitHub Repository:
            {github_url}
        """

    completion = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {"role": "system", "content": "너는 코드 품질 전문가다."},
            {"role": "user", "content": prompt_text}
        ],
        response_format={"type": "json_object"}
    )

    ai_result = json.loads(completion.choices[0].message.content)
    final_score = calculate_weighted(role, ai_result)
    return {"role": role, "nickname": github_name, "result": ai_result, "final_score": final_score,
            "grade": get_grade(final_score)}


# --- 2️⃣ 디자이너 평가 API ---
@app.post("/grading/designer")
async def designer(images: List[UploadFile] = File(...)):
    role = "designer"
    client = OpenAI(api_key=FACTCHAT_KEY, base_url=FACTCHAT_URL)

    # 기본 프롬프트 텍스트
    prompt_text = f"""
        다음에 제공되는 디자인 시안 또는 디자인 관련 GitHub 데이터를 분석하여
        아래의 7개 항목을 각각 0~10점으로 평가하고,
        각 항목은 score 먼저 계산하고,
        그 score가 의미하는 수준에 정`확히 맞도록 reason을 생성하라.
        reason은 절대 score보다 더 긍`정적/부정적이어서는 안 된다.
        반드시 지정된 JSON 형식으로만 출력해줘.
        이미지가 여러 개일 경우 각각의 이미지에 점수를 부여해.

        [평가 항목]

        1. 색상 조화 및 대비 (color_contrast)
           - 전체적인 색상 팔레트 조화, 대비, 접근성(A11y) 수준

        2. 레이아웃 균형 및 구조 (layout_balance)
           - 그리드 정렬, 여백 spacing, 시각적 안정성

        3. 타이포그래피 일관성 (typography)
           - 폰트 크기/스타일/간격의 일관성, 정보 계층 설계

        4. 컴포넌트 일관성 (component_consistency)
           - 버튼/카드/입력창 등 UI 구성요소의 스타일 통일성

        5. 디자인 시스템 준수도 (design_system_adherence)
           - 디자인 토큰 사용 여부, 일관된 컴포넌트 원칙 준수

        6. 브랜드 정체성 반영 (brand_identity)
           - 색상/폰트/톤앤매너가 브랜드 가이드라인과 얼마나 부합하는지

        7. 시각적 완성도 및 정교함 (visual_refinement)
           - 미세 정렬, 픽셀 퍼펙트 정도, 불필요한 요소 최소화


        [출력 규칙]

        - 반드시 아래 JSON 형식으로만 출력할 것
        - score는 0~10 사이의 숫자
        - reason은 분석한 설명
        - JSON 외 텍스트는 절대 출력하지 말 것


        [출력 JSON 형식]

        {
          "color_contrast": {
            "score": 0,
            "reason": ""
          },
          "layout_balance": {
            "score": 0,
            "reason": ""
          },
          "typography": {
            "score": 0,
            "reason": ""
          },
          "component_consistency": {
            "score": 0,
            "reason": ""
          },
          "design_system_adherence": {
            "score": 0,
            "reason": ""
          },
          "brand_identity": {
            "score": 0,
            "reason": ""
          },
          "visual_refinement": {
            "score": 0,
            "reason": ""
          }
        }
    """

    content_input = [{"type": "text", "text": prompt_text}]

    for img in images:
        img_bytes = await img.read()
        b64 = base64.b64encode(img_bytes).decode("utf-8")
        content_input.append({"type": "image_url", "image_url": {"url": f"data:{img.content_type};base64,{b64}"}})

    completion = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[{"role": "system", "content": "디자인 전문가"}, {"role": "user", "content": content_input}],
        response_format={"type": "json_object"}
    )

    ai_result = json.loads(completion.choices[0].message.content)
    final_score = calculate_weighted(role, ai_result)
    return {"role": role, "result": ai_result, "final_score": final_score, "grade": get_grade(final_score)}


# --- 3️⃣ 기획자 평가 API ---
@app.post("/grading/planner")
async def planner(pdf_files: List[UploadFile] = File(...)):
    role = "planner"
    openai_client = OpenAI(api_key=OPENAI_KEY)  # 순수 OpenAI 키 사용

    prompt_text = f"""
        다음에 제공되는 기획 문서 또는 기획 관련 GitHub 데이터를 분석하여
        아래의 7개 항목을 각각 0~10점으로 평가하고,
        각 항목은 score 먼저 계산하고,
        그 score가 의미하는 수준에 정확히 맞도록 reason을 생성하라.
        reason은 절대 score보다 더 긍정적/부정적이어서는 안 된다.
        반드시 지정된 JSON 형식으로만 출력해줘.

        [평가 항목]

        1. 문제 정의 및 논리 구조 (problem_logic)
           - 문제를 얼마나 명확히 정의했는지, 논리 전개가 일관적인지

        2. 도메인/서비스 전문성 (terminology_expertise)
           - 용어 사용 정확성, 서비스 도메인 이해 수준

        3. 정보 구조 및 계층화 (info_hierarchy)
           - IA(Information Architecture), 구조도·흐름도·유스케이스의 완성도

        4. 문서 가독성 및 명확성 (readability)
           - 문서 흐름, 표현의 명확성, 불필요한 정보 여부

        5. 요구사항 정교함 (requirement_clarity)
           - 기능 요구사항의 구체성, 예외 케이스 명시 여부

        6. 사용자 관점 사고력 (user_thinking)
           - 페르소나/유저 시나리오 설계, UX 고려 정도

        7. 일정·리스크 관리 능력 (risk_timeline_management)
           - 일정 산정 근거, 리스크 예측 및 대응 전략


        [출력 규칙]

        - 반드시 아래 JSON 형식으로만 출력할 것
        - score는 0~10 사이의 숫자 (정수 또는 소수)
        - reason은 분석한 설명
        - JSON 외의 텍스트는 절대 출력하지 말 것


        [출력 JSON 형식]

        {{
          "problem_logic": {{
            "score": 0,
            "reason": ""
          }},
          "terminology_expertise": {{
            "score": 0,
            "reason": ""
          }},
          "info_hierarchy": {{
            "score": 0,
            "reason": ""
          }},
          "readability": {{
            "score": 0,
            "reason": ""
          }},
          "requirement_clarity": {{
            "score": 0,
            "reason": ""
          }},
          "user_thinking": {{
            "score": 0,
            "reason": ""
          }},
          "risk_timeline_management": {{
            "score": 0,
            "reason": ""
          }}
        }}
    """

    file_objs = []
    for pdf in pdf_files:
        file_obj = openai_client.files.create(file=pdf.file, purpose="user_data")
        file_objs.append(file_obj)

    content_input = [{"type": "text", "text": prompt_text}]
    for f in file_objs:
        content_input.append({"type": "file", "file": {"file_id": f.id}})

    completion = openai_client.chat.completions.create(
        model=MODEL_NAME,
        messages=[{"role": "system", "content": "기획 전문가"}, {"role": "user", "content": content_input}],
        response_format={"type": "json_object"}
    )

    ai_result = json.loads(completion.choices[0].message.content)
    final_score = calculate_weighted(role, ai_result)
    return {"role": role, "result": ai_result, "final_score": final_score, "grade": get_grade(final_score)}