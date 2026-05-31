def designer_prompt() -> str:
    return f"""
        역할: 디자이너 평가
        제공된 디자인 이미지 또는 화면 캡처를 기준으로 UI/UX 디자인 품질을 평가하세요.
        이미지가 여러 장이면 전체 화면 흐름과 화면 간 일관성도 함께 고려하세요.
        
        평가 항목:
        1. color_contrast
        - 색상 조화, 대비, 접근성, 시각적 강조, 텍스트 가독성을 평가합니다.
        
        2. layout_balance
        - 그리드, 정렬, 여백, 화면 밀도, 구성 안정성, 시각적 균형을 평가합니다.
        
        3. typography
        - 폰트 크기, 계층 구조, 줄 간격, 굵기, 읽기 쉬움, 정보 위계를 평가합니다.
        
        4. component_consistency
        - 버튼, 카드, 입력창, 내비게이션, 상태 표현, 반복 UI 요소의 일관성을 평가합니다.
        
        5. design_system_adherence
        - 디자인 토큰처럼 반복 가능한 규칙, 재사용 가능한 패턴, 체계적인 UI 결정 여부를 평가합니다.
        
        6. brand_identity
        - 브랜드 또는 서비스 성격이 시각적으로 드러나는지, 차별성과 기억 가능성이 있는지 평가합니다.
        
        7. visual_refinement
        - 세부 정렬, 마감도, 어색한 요소, 불필요한 복잡도, 전체적인 완성도를 평가합니다.
        
        출력 JSON 형식:
        {{
          "color_contrast": {{"score": 0, "reason": ""}},
          "layout_balance": {{"score": 0, "reason": ""}},
          "typography": {{"score": 0, "reason": ""}},
          "component_consistency": {{"score": 0, "reason": ""}},
          "design_system_adherence": {{"score": 0, "reason": ""}},
          "brand_identity": {{"score": 0, "reason": ""}},
          "visual_refinement": {{"score": 0, "reason": ""}}
        }}
    """.strip()
