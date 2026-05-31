package com.teammate.grading.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class GradingResult {
	private String role;

	private Map<String, Object> result;

	@JsonProperty("final_score")
	private float finalScore;

	private String grade;
}
