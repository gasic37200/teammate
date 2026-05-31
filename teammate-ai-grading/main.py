import base64
import json
import os
import urllib.error
import urllib.request
from typing import Dict, List

from dotenv import load_dotenv
from fastapi import Body, FastAPI, File, HTTPException, UploadFile
from openai import OpenAI

from prompts import build_developer_prompt, build_designer_prompt, build_planner_prompt

app = FastAPI()

load_dotenv()

MODEL_NAME = "gpt-5-chat-latest"
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")

weights = {
    "developer": {
        "code_quality": 0.25,
        "environment_understanding": 0.13,
        "collaboration": 0.12,
        "testing_stability": 0.18,
        "test_presence": 0.08,
        "activity_consistency": 0.12,
        "commit_quality": 0.12,
    },
    "designer": {
        "color_contrast": 0.20,
        "layout_balance": 0.20,
        "typography": 0.15,
        "component_consistency": 0.15,
        "design_system_adherence": 0.15,
        "brand_identity": 0.10,
        "visual_refinement": 0.15,
    },
    "planner": {
        "problem_logic": 0.20,
        "terminology_expertise": 0.15,
        "info_hierarchy": 0.20,
        "readability": 0.15,
        "requirement_clarity": 0.15,
        "user_thinking": 0.10,
        "risk_timeline_management": 0.05,
    },
}

grade_scale = [
    (0.0, "Trainee"),
    (1.0, "Rookie IV"),
    (2.0, "Rookie III"),
    (3.0, "Rookie II"),
    (4.0, "Rookie I"),
    (5.0, "Junior III"),
    (6.0, "Junior II"),
    (7.0, "Junior I"),
    (8.0, "Pro III"),
    (8.5, "Pro II"),
    (9.0, "Pro I"),
    (9.5, "Elite"),
    (9.8, "Master"),
]


def calculate_weighted(role: str, result: Dict) -> float:
    role_weights = weights[role]
    weighted_sum = 0.0
    used_weight = 0.0

    for key, weight in role_weights.items():
        item = result.get(key, {})
        score = item.get("score") if isinstance(item, dict) else None
        if isinstance(score, (int, float)):
            weighted_sum += score * weight
            used_weight += weight

    if used_weight == 0:
        return 0.0

    return round(weighted_sum / used_weight, 2)


def get_grade(score: float) -> str:
    return next(grade for threshold, grade in reversed(grade_scale) if score >= threshold)


def parse_ai_json(content: str) -> Dict:
    return json.loads(content)


def github_headers() -> Dict[str, str]:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "teammate-ai-grading",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    if GITHUB_TOKEN:
        headers["Authorization"] = f"Bearer {GITHUB_TOKEN}"
    return headers


def github_get(path: str):
    request = urllib.request.Request(
        f"https://api.github.com{path}",
        headers=github_headers(),
    )

    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            return None
        if exc.code == 403:
            raise HTTPException(
                status_code=429,
                detail="GitHub API 요청 한도를 초과했거나 접근이 제한되었습니다. GITHUB_TOKEN을 설정해주세요.",
            ) from exc
        raise HTTPException(status_code=502, detail=f"GitHub API 요청 실패: {exc.code}") from exc
    except urllib.error.URLError as exc:
        raise HTTPException(status_code=502, detail="GitHub API에 연결할 수 없습니다.") from exc


def has_path(paths: List[str], candidates: List[str]) -> bool:
    normalized = {path.lower().strip("/") for path in paths}
    for candidate in candidates:
        value = candidate.lower().strip("/")
        if value in normalized or any(path.startswith(value + "/") for path in normalized):
            return True
    return False


def detect_repo_signals(owner: str, repo: Dict) -> Dict:
    repo_name = repo["name"]
    branch = repo.get("default_branch") or "main"
    tree = github_get(f"/repos/{owner}/{repo_name}/git/trees/{branch}?recursive=1") or {}
    paths = [item.get("path", "") for item in tree.get("tree", [])]
    lower_paths = [path.lower() for path in paths]

    commits = github_get(f"/repos/{owner}/{repo_name}/commits?per_page=5") or []
    languages = github_get(f"/repos/{owner}/{repo_name}/languages") or {}
    readme = github_get(f"/repos/{owner}/{repo_name}/readme")

    return {
        "name": repo_name,
        "full_name": repo.get("full_name"),
        "description": repo.get("description"),
        "primary_language": repo.get("language"),
        "languages": languages,
        "stars": repo.get("stargazers_count"),
        "forks": repo.get("forks_count"),
        "open_issues": repo.get("open_issues_count"),
        "created_at": repo.get("created_at"),
        "updated_at": repo.get("updated_at"),
        "pushed_at": repo.get("pushed_at"),
        "default_branch": branch,
        "has_readme": readme is not None,
        "has_tests": has_path(lower_paths, ["test", "tests", "__tests__", "src/test", "spec"]),
        "has_docker": has_path(lower_paths, ["dockerfile", "docker-compose.yml", "docker-compose.yaml"]),
        "has_ci": has_path(lower_paths, [".github/workflows", ".gitlab-ci.yml"]),
        "has_env_example": has_path(lower_paths, [".env.example", ".env.sample"]),
        "dependency_files": [
            path for path in paths
            if path.lower().split("/")[-1] in {
                "build.gradle", "pom.xml", "package.json", "requirements.txt",
                "pyproject.toml", "gradle.properties", "dockerfile",
            }
        ][:20],
        "sample_paths": paths[:80],
        "recent_commits": [
            commit.get("commit", {}).get("message", "").splitlines()[0]
            for commit in commits[:5]
        ],
    }


def collect_github_developer_data(github_name: str) -> Dict:
    user = github_get(f"/users/{github_name}")
    if user is None:
        raise HTTPException(status_code=404, detail="GitHub 사용자를 찾을 수 없습니다.")

    repos = github_get(f"/users/{github_name}/repos?sort=updated&direction=desc&per_page=8") or []
    source_repos = [repo for repo in repos if not repo.get("fork")]
    selected_repos = source_repos[:5] or repos[:5]

    return {
        "github_name": github_name,
        "profile": {
            "name": user.get("name"),
            "bio": user.get("bio"),
            "public_repos": user.get("public_repos"),
            "followers": user.get("followers"),
            "following": user.get("following"),
            "created_at": user.get("created_at"),
            "updated_at": user.get("updated_at"),
            "html_url": user.get("html_url"),
        },
        "repository_count_checked": len(selected_repos),
        "repositories": [detect_repo_signals(github_name, repo) for repo in selected_repos],
    }


@app.post("/api/grading/developer")
def developer(github_name: str = Body(..., embed=True)):
    role = "developer"
    github_data = collect_github_developer_data(github_name)
    prompt_text = build_developer_prompt(github_data)

    completion = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {"role": "system", "content": "당신은 시니어 소프트웨어 엔지니어링 평가자입니다."},
            {"role": "user", "content": prompt_text},
        ],
        response_format={"type": "json_object"},
    )

    ai_result = parse_ai_json(completion.choices[0].message.content)
    final_score = calculate_weighted(role, ai_result)
    return {
        "role": role,
        # "evidence": github_data,
        "result": ai_result,
        "final_score": final_score,
        "grade": get_grade(final_score),
    }


@app.post("/api/grading/designer")
async def designer(images: List[UploadFile] = File(...)):
    role = "designer"
    content_input = [{"type": "text", "text": build_designer_prompt()}]

    for image in images:
        image_bytes = await image.read()
        encoded_image = base64.b64encode(image_bytes).decode("utf-8")
        content_input.append(
            {
                "type": "image_url",
                "image_url": {"url": f"data:{image.content_type};base64,{encoded_image}"},
            }
        )

    completion = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {"role": "system", "content": "당신은 시니어 프로덕트 디자인 평가자입니다."},
            {"role": "user", "content": content_input},
        ],
        response_format={"type": "json_object"},
    )

    ai_result = parse_ai_json(completion.choices[0].message.content)
    final_score = calculate_weighted(role, ai_result)
    return {
        "role": role,
        "result": ai_result,
        "final_score": final_score,
        "grade": get_grade(final_score),
    }


@app.post("/api/grading/planner")
async def planner(pdf: UploadFile = File(...)):
    role = "planner"

    if pdf.content_type != "application/pdf":
        raise HTTPException(
            status_code=400,
            detail=f"PDF 파일만 업로드할 수 있습니다. 현재 타입: {pdf.content_type}"
        )

    file_bytes = await pdf.read()

    file_obj = client.files.create(
        file=(pdf.filename, file_bytes, "application/pdf"),
        purpose="user_data"
    )

    content_input = [{"type": "text", "text": build_planner_prompt()},
                     {"type": "file", "file": {"file_id": file_obj.id}}]

    completion = client.chat.completions.create(
        model=MODEL_NAME,
        messages=[
            {"role": "system", "content": "당신은 시니어 프로덕트 기획 평가자입니다."},
            {"role": "user", "content": content_input},
        ],
        response_format={"type": "json_object"},
    )

    ai_result = parse_ai_json(completion.choices[0].message.content)
    final_score = calculate_weighted(role, ai_result)
    return {
        "role": role,
        "result": ai_result,
        "final_score": final_score,
        "grade": get_grade(final_score),
    }
