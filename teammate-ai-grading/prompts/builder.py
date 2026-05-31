import json

from .common import build_common_prompt
from .developer import developer_prompt
from .designer import designer_prompt
from .planner import planner_prompt


def build_developer_prompt(github_data: dict) -> str:
    evidence = json.dumps(github_data, ensure_ascii=False, indent=2)
    return build_common_prompt("GitHub API 수집 데이터") + "\n\n" + developer_prompt(evidence)


def build_designer_prompt() -> str:
    return build_common_prompt("디자인 이미지") + "\n\n" + designer_prompt()


def build_planner_prompt() -> str:
    return build_common_prompt("기획 문서") + "\n\n" + planner_prompt()
