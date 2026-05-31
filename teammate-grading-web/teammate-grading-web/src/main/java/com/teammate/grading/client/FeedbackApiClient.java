package com.teammate.grading.client;

import com.teammate.grading.dto.FeedbackDTO;
import com.teammate.grading.handler.FastApiExceptionMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.Optional;

@Component
public class FeedbackApiClient {

    private final RestClient restClient;
    private final FastApiExceptionMapper exceptionMapper;

    public FeedbackApiClient(
            @Value("${feedback.base-url:http://localhost:7000}") String baseUrl,
            FastApiExceptionMapper exceptionMapper
    ) {
        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .build();
        this.exceptionMapper = exceptionMapper;
    }

    public void saveFeedback(FeedbackDTO request) {
        try {
            restClient.post()
                    .uri("/api/feedback")
                    .body(request)
                    .retrieve()
                    .toBodilessEntity();
        } catch (HttpStatusCodeException exception) {
            throw exceptionMapper.toException(exception, "피드백 저장 중 오류가 발생했습니다.");
        } catch (RestClientException exception) {
            throw new IllegalStateException("피드백 저장 중 오류가 발생했습니다.", exception);
        }
    }

    public Optional<FeedbackDTO> getFeedback(String project, String userKey) {
        try {
            FeedbackDTO response = restClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/api/feedback")
                            .queryParam("project", project)
                            .queryParam("userKey", userKey)
                            .build())
                    .retrieve()
                    .body(FeedbackDTO.class);

            return Optional.ofNullable(response);
        } catch (HttpClientErrorException.NotFound exception) {
            return Optional.empty();
        } catch (HttpStatusCodeException exception) {
            throw exceptionMapper.toException(exception, "피드백 조회 중 오류가 발생했습니다.");
        } catch (RestClientException exception) {
            throw new IllegalStateException("피드백 조회 중 오류가 발생했습니다.", exception);
        }
    }
}
