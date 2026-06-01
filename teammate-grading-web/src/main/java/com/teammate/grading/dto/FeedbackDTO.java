package com.teammate.grading.dto;

public record FeedbackDTO(
        String project,
        String userKey,
        String email,
        Integer rating,
        String positive,
        String improvement,
        String status
) {
}
