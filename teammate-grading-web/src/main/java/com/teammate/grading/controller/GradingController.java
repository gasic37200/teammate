package com.teammate.grading.controller;

import com.teammate.grading.dto.GradingRequest;
import com.teammate.grading.dto.GradingResult;
import com.teammate.grading.service.GradingService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
public class GradingController {
	private final GradingService gradingService;

	@PostMapping("/api/grading")
	public GradingResult grading(@ModelAttribute GradingRequest gradingRequest) {
		return gradingService.evaluate(gradingRequest);
	}
}
