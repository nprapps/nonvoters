CREATE VIEW vs_nonvoter AS (
	SELECT state_abbr,
		county_fips,
		SUM(
			CASE
				WHEN vote_frequency <= 1 THEN count
				ELSE 0
			END
		)::DECIMAL / SUM(count) AS share_nonvoter,
		SUM(
			CASE
				WHEN ethnic_group = 'Hispanic and Portuguese' THEN count
				ELSE 0
			END
		)::DECIMAL / SUM(
			CASE
				WHEN ethnic_group != 'Unknown' THEN count
				ELSE 0
			END
		) AS l2_share_hispanic,
		SUM(
			CASE
				WHEN ethnic_group != 'European' AND ethnic_group != 'Unknown' THEN count
				ELSE 0
			END
		)::DECIMAL / SUM(
			CASE
				WHEN ethnic_group != 'Unknown' THEN count
				ELSE 0
			END
		) AS l2_share_nonwhite
	FROM l2
	GROUP BY state_abbr,
		county_fips
	ORDER BY state_abbr,
		county_fips
);

CREATE VIEW vs_nonvoter_joined AS (
	SELECT vs_nonvoter.*,
		ers_poverty.rural_urban_continuum_code_2013 AS rural_urban_code,
		ers_poverty.pctpovall_2016 AS poverty_rate,
		ers_poverty.medhhinc_2016 AS median_hh_income,
		ers_education.pct_no_high_school,
		ers_education.pct_bachelors_or_higher,
		ap_presidential.trump_margin
	FROM vs_nonvoter
	LEFT JOIN ers_poverty
		ON vs_nonvoter.state_abbr = ers_poverty.state AND vs_nonvoter.county_fips = SUBSTRING(ers_poverty.fipstxt, 3, 3)
	LEFT JOIN ers_education
		ON vs_nonvoter.state_abbr = ers_education.state AND vs_nonvoter.county_fips = SUBSTRING(ers_education.fips_code, 3, 3)
	LEFT JOIN ap_presidential
		ON vs_nonvoter.state_abbr = ap_presidential.state AND vs_nonvoter.county_fips = SUBSTRING(ap_presidential.fips, 3, 3)
);

\copy (SELECT * FROM vs_nonvoter_joined) TO 'l2-vs-nonvoter.csv' CSV HEADER;


SELECT CASE
		WHEN (state_abbr = 'AZ' AND county_fips IN ('003', '019', '023', '027'))
			OR (state_abbr = 'CA' AND county_fips IN ('025', '073'))
			OR (state_abbr = 'NM' AND county_fips IN ('013', '023', '029'))
			OR (state_abbr = 'TX' AND county_fips IN ('043', '061', '141', '215', '229', '271', '323', '377', '427', '443', '465', '479', '505'))
			THEN 'Mexican border county'
		ELSE 'Interior county'
	END AS mexican_border,
	SUM(CASE WHEN vote_frequency <= 1 THEN count ELSE 0 END)::DECIMAL / SUM(count) AS share_of_hispanics_who_are_nonvoters
FROM l2
WHERE ethnic_group = 'Hispanic and Portuguese'
GROUP BY mexican_border;


CREATE VIEW income_vs_nonvoter AS (
	SELECT estimated_hh_income,
		SUM(CASE WHEN vote_frequency <= 1 THEN count ELSE 0 END)::DECIMAL / SUM(count) AS share_nonvoter
	FROM l2
	WHERE estimated_hh_income != 'Unknown'
	GROUP BY estimated_hh_income
);
\copy (SELECT * FROM income_vs_nonvoter) TO 'l2-income-vs-nonvoter.csv' CSV HEADER;


CREATE VIEW age_vs_nonvoter AS (
	SELECT age_range,
		SUM(count) number_registered,
		SUM(CASE WHEN vote_frequency <= 1 THEN count ELSE 0 END)::DECIMAL / SUM(count) AS share_nonvoter
	FROM l2
	GROUP BY age_range
);
\copy (SELECT * FROM age_vs_nonvoter) TO 'l2-age-vs-nonvoter.csv' CSV HEADER;


CREATE VIEW party_vs_nonvoter AS (
	SELECT party,
		SUM(count) number_registered,
		SUM(CASE WHEN vote_frequency <= 1 THEN count ELSE 0 END)::DECIMAL / SUM(count) AS share_nonvoter
	FROM l2
	GROUP BY party
);


CREATE VIEW race_vs_nonvoter AS (
	SELECT ethnic_group,
		SUM(count) number_registered,
		SUM(CASE WHEN vote_frequency <= 1 THEN count ELSE 0 END)::DECIMAL / SUM(count) AS share_nonvoter
	FROM l2
	GROUP BY ethnic_group
);
