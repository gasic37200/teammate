def planner_prompt() -> str:
    return f"""
        역할: 기획자 평가
        제공된 기획 문서 또는 PDF 자료를 기준으로 문제 정의, 요구사항, 정보 구조, 실행 가능성을 평가하세요.
        PDF가 여러 개라면 하나의 기획 패키지로 보고 종합 평가하세요.
        
        평가 항목:
        1. problem_logic
        - 문제 정의의 명확성, 원인과 해결책의 논리성, 기획 방향의 일관성을 평가합니다.
        
        2. terminology_expertise
        - 도메인 용어 사용의 정확성, 서비스/기술 이해도, 전문적인 표현 수준을 평가합니다.
        
        3. info_hierarchy
        - 정보 구조, 문서 구성, 우선순위, 섹션 흐름, 읽는 사람이 빠르게 파악할 수 있는 구조인지 평가합니다.
        
        4. readability
        - 문장 명확성, 표현의 간결함, 모호한 정보 여부, 문서 가독성을 평가합니다.
        
        5. requirement_clarity
        - 기능 요구사항과 비기능 요구사항의 구체성, 예외 케이스, 제약 조건, 수용 기준의 명확성을 평가합니다.
        
        6. user_thinking
        - 사용자 페르소나, 사용자 여정, 시나리오, UX 관점, 실제 사용자 문제에 대한 이해도를 평가합니다.
        
        7. risk_timeline_management
        - 일정 현실성, 마일스톤, 리스크 식별, 대응 전략, 범위 관리 능력을 평가합니다.
        
        출력 JSON 형식:
        {{
          "problem_logic": {{"score": 0, "reason": ""}},
          "terminology_expertise": {{"score": 0, "reason": ""}},
          "info_hierarchy": {{"score": 0, "reason": ""}},
          "readability": {{"score": 0, "reason": ""}},
          "requirement_clarity": {{"score": 0, "reason": ""}},
          "user_thinking": {{"score": 0, "reason": ""}},
          "risk_timeline_management": {{"score": 0, "reason": ""}}
        }}
    """.strip()
