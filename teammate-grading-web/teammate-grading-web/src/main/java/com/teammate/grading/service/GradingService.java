package com.teammate.grading.service;

import com.teammate.grading.client.AiGradingClient;
import com.teammate.grading.dto.GradingRequest;
import com.teammate.grading.dto.GradingResult;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class GradingService {

	private final AiGradingClient aiGradingClient;

	public GradingResult evaluate(GradingRequest gradingRequest) {
		String role = gradingRequest.getRole();

		if ("developer".equals(role)) {
			if (gradingRequest.getGithubUsername() == null || gradingRequest.getGithubUsername().isBlank()) {
				throw new IllegalArgumentException("GitHub 이름을 입력해주세요.");
			}
			return aiGradingClient.evaluateDeveloper(gradingRequest.getGithubUsername());
		}

		if ("designer".equals(role)) {
			if (gradingRequest.getPortfolioImages() == null || gradingRequest.getPortfolioImages().isEmpty()) {
				throw new IllegalArgumentException("포트폴리오 이미지를 한 장 이상 첨부해주세요.");
			}
			return aiGradingClient.evaluateDesigner(gradingRequest.getPortfolioImages());
		}

		if ("planner".equals(role)) {
			if (gradingRequest.getPlanningPDF() == null || gradingRequest.getPlanningPDF().isEmpty()) {
				throw new IllegalArgumentException("기획서 PDF 파일을 첨부해주세요.");
			}
			return aiGradingClient.evaluatePlanner(gradingRequest.getPlanningPDF());
		}

		throw new IllegalArgumentException("지원하지 않는 직군입니다: " + role);
	}
}
