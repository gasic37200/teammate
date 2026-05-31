package com.teammate.grading.client;

import com.teammate.grading.dto.GradingResult;
import com.teammate.grading.handler.FastApiExceptionMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.MultipartBodyBuilder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@Service
public class AiGradingClient {
	@Value("${ai.module.grading-path}")
	private String gradingPath;

	private final RestClient restClient;
	private final FastApiExceptionMapper exceptionMapper;

	public AiGradingClient(
			@Value("${ai.module.base-url}") String baseUrl,
			FastApiExceptionMapper exceptionMapper
	) {
		this.restClient = RestClient.builder()
				.baseUrl(baseUrl)
				.build();
		this.exceptionMapper = exceptionMapper;
	}

	public GradingResult evaluateDeveloper(String githubUsername) {
		try {
			return restClient.post()
					.uri(gradingPath + "/developer")
					.body(Map.of("github_name", githubUsername))
					.retrieve()
					.body(GradingResult.class);
		} catch (HttpStatusCodeException exception) {
			throw exceptionMapper.toException(exception, "개발자 평가 중 오류가 발생했습니다.");
		}
	}

	public GradingResult evaluateDesigner(List<MultipartFile> images) {
		MultipartBodyBuilder builder = new MultipartBodyBuilder();

		for (MultipartFile image : images) {
			MultipartBodyBuilder.PartBuilder part = builder.part("images", image.getResource())
					.filename(image.getOriginalFilename());

			if (image.getContentType() != null) {
				part.contentType(MediaType.parseMediaType(image.getContentType()));
			}
		}

		try {
			return restClient.post()
					.uri(gradingPath + "/designer")
					.contentType(MediaType.MULTIPART_FORM_DATA)
					.body(builder.build())
					.retrieve()
					.body(GradingResult.class);
		} catch (HttpStatusCodeException exception) {
			throw exceptionMapper.toException(exception, "디자이너 평가 중 오류가 발생했습니다.");
		}
	}

	public GradingResult evaluatePlanner(MultipartFile pdf) {
		MultipartBodyBuilder builder = new MultipartBodyBuilder();

		builder.part("pdf", pdf.getResource())
				.filename(pdf.getOriginalFilename())
				.contentType(MediaType.APPLICATION_PDF);

		try {
			return restClient.post()
					.uri(gradingPath + "/planner")
					.contentType(MediaType.MULTIPART_FORM_DATA)
					.body(builder.build())
					.retrieve()
					.body(GradingResult.class);
		} catch (HttpStatusCodeException exception) {
			throw exceptionMapper.toException(exception, "기획자 평가 중 오류가 발생했습니다.");
		}
	}
}
