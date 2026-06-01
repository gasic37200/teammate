package com.teammate.grading.dto;

import lombok.Getter;
import lombok.Setter;
import lombok.ToString;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Getter
@Setter
@ToString
public class GradingRequest {
	private String role;

	private String githubUsername;

	private List<MultipartFile> portfolioImages;

	private MultipartFile planningPDF;
}