def developer_prompt(github_evidence: str) -> str:
    return f"""
        역할: 개발자 평가
        아래 GitHub API 수집 데이터를 기준으로 개발 역량을 평가하세요.
        URL만 보고 추측하지 말고, 제공된 profile/repositories/languages/files/commits 정보만 근거로 판단하세요.
        
        GitHub API 수집 데이터:
        {github_evidence}
        
        평가 항목:
        1. code_quality
        - 파일 구조, 모듈 분리 신호, 네이밍/가독성을 추정할 수 있는 경로, 기술 스택 구성, 중복 가능성, 예외 처리 신호를 평가합니다.
        - 실제 코드 내용이 부족하면 그 한계를 reason에 명시하세요.
        
        2. environment_understanding
        - Dockerfile, docker-compose, CI 설정, 환경변수 예시 파일, 빌드/의존성 파일, 실행 환경 재현 가능성을 평가합니다.
        
        3. collaboration
        - README 존재, 저장소 설명, 이슈/PR을 직접 볼 수 없는 한계, 프로젝트 공개성, 협업 준비 신호를 평가합니다.
        
        4. testing_stability
        - 테스트 디렉터리/파일 존재, CI와 함께 검증되는 구조인지, 안정성 확보 신호가 있는지 평가합니다.
        
        5. test_presence
        - test/tests/src/test/spec/__tests__ 등 테스트 관련 경로 존재 여부와 범위를 중심으로 평가합니다.
        
        6. activity_consistency
        - 최근 push/update 시각, 저장소 수, 장기 활동 가능성, 공개 저장소의 유지 흐름을 평가합니다.
        
        7. commit_quality
        - recent_commits에 포함된 커밋 메시지의 구체성, 기능 단위 분리, 일관성을 평가합니다.
        
        출력 JSON 형식:
        {{
          "code_quality": {{"score": 0, "reason": ""}},
          "environment_understanding": {{"score": 0, "reason": ""}},
          "collaboration": {{"score": 0, "reason": ""}},
          "testing_stability": {{"score": 0, "reason": ""}},
          "test_presence": {{"score": 0, "reason": ""}},
          "activity_consistency": {{"score": 0, "reason": ""}},
          "commit_quality": {{"score": 0, "reason": ""}}
        }}
    """.strip()
