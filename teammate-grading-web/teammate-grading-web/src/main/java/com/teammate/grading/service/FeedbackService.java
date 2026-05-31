package com.teammate.grading.service;

import com.teammate.grading.client.FeedbackApiClient;
import com.teammate.grading.dto.FeedbackDTO;
import com.teammate.grading.dto.FeedbackRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Optional;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class FeedbackService {

    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");
    private static final Pattern CLIENT_ID_PATTERN = Pattern.compile("^[a-zA-Z0-9-]{20,80}$");

    private final FeedbackApiClient feedbackApiClient;

    public void saveFeedback(FeedbackRequest request) {
        validate(request);

        feedbackApiClient.saveFeedback(new FeedbackDTO(
                "teammate",
                getUserKey(request.clientId()),
                request.email().trim(),
                request.rating(),
                trimToNull(request.positive()),
                trimToNull(request.improvement()),
                null
        ));
    }

    public Optional<FeedbackDTO> getFeedback(String clientId) {
        return feedbackApiClient.getFeedback("teammate", getUserKey(clientId));
    }

    private void validate(FeedbackRequest request) {
        getUserKey(request.clientId());

        if (request.email() == null || !EMAIL_PATTERN.matcher(request.email().trim()).matches()) {
            throw new IllegalArgumentException("이메일 형식을 확인해주세요.");
        }

        if (request.rating() == null || request.rating() < 1 || request.rating() > 5) {
            throw new IllegalArgumentException("별점을 선택해주세요.");
        }

        if (trimToNull(request.positive()) == null && trimToNull(request.improvement()) == null) {
            throw new IllegalArgumentException("좋았던 점이나 개선할 점 중 하나는 입력해주세요.");
        }
    }

    private String getUserKey(String clientId) {
        if (clientId == null || !CLIENT_ID_PATTERN.matcher(clientId).matches()) {
            throw new IllegalArgumentException("사용자 정보를 확인할 수 없습니다.");
        }
        return "client:" + clientId;
    }

    private String trimToNull(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        return value.trim();
    }
}
