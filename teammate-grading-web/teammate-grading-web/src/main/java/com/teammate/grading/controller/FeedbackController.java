package com.teammate.grading.controller;

import com.teammate.grading.dto.FeedbackDTO;
import com.teammate.grading.dto.FeedbackRequest;
import com.teammate.grading.service.FeedbackService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.Optional;

@RestController
@RequiredArgsConstructor
public class FeedbackController {

    private final FeedbackService feedbackService;

    @GetMapping("/api/feedback")
    public Optional<FeedbackDTO> getFeedback(@RequestParam String clientId) {
        return feedbackService.getFeedback(clientId);
    }

    @PostMapping("/api/feedback")
    public Map<String, String> saveFeedback(@RequestBody FeedbackRequest request) {
        feedbackService.saveFeedback(request);
        return Map.of("message", "피드백이 저장되었습니다.");
    }
}
