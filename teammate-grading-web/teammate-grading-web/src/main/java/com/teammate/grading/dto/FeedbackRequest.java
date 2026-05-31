package com.teammate.grading.dto;

public record FeedbackRequest(
        String clientId,
        String email,
        Integer rating,
        String positive,
        String improvement
) {
}
