CREATE TABLE l2 (
	state_abbr CHARACTER(2),
	county_fips CHARACTER(3),
	party TEXT,
	vote_frequency INTEGER,
	estimated_hh_income TEXT,
	ethnic_group TEXT,
	age_range TEXT,
	count INTEGER,
	PRIMARY KEY(state_abbr, county_fips, party, vote_frequency, estimated_hh_income, ethnic_group, age_range)
);
\copy l2 FROM '$CSV_FILE' CSV HEADER;

CREATE TABLE ap_presidential (
	state CHARACTER(2),
	fips CHARACTER(5),
	trump_votes INTEGER,
	clinton_votes INTEGER,
	total_votes INTEGER,
	trump_share DECIMAL,
	trump_margin DECIMAL,
	PRIMARY KEY(state, fips)
);
CREATE TEMPORARY TABLE temp_ap_json (
	data JSONB
);
\copy temp_ap_json FROM 'ap_2016_presidential_races.json';
CREATE VIEW ap_candidates AS (
	SELECT data->>'statePostal' AS state,
		data->>'fipsCode' AS fips,
		JSONB_ARRAY_ELEMENTS(data->'candidates') AS candidate
	FROM temp_ap_json
);
CREATE VIEW ap_presidential_votes AS (
	SELECT state,
		fips,
		SUM(
			CASE
				WHEN candidate->>'last' = 'Trump' THEN (candidate->>'voteCount')::INTEGER
				ELSE 0
			END
		) AS trump_votes,
		SUM(
			CASE
				WHEN candidate->>'last' = 'Clinton' THEN (candidate->>'voteCount')::INTEGER
				ELSE 0
			END
		) AS clinton_votes,
		SUM((candidate->>'voteCount')::INTEGER) AS total_votes
	FROM ap_candidates
	GROUP BY state,
		fips
);
INSERT INTO ap_presidential
	SELECT *,
		trump_votes::DECIMAL / total_votes AS trump_share,
		(trump_votes::DECIMAL / total_votes) - (clinton_votes::DECIMAL / total_votes)::DECIMAL AS trump_margin
	FROM ap_presidential_votes
	WHERE fips IS NOT NULL;
DROP TABLE temp_ap_json CASCADE;

CREATE TABLE ers_poverty (
	fipstxt CHARACTER(5) PRIMARY KEY,
	state CHARACTER(2),
	rural_urban_continuum_code_2013 NUMERIC,
	pctpovall_2016 NUMERIC,
	medhhinc_2016 NUMERIC
);
\copy ers_poverty FROM 'PovertyEstimates-cut.csv' CSV HEADER;
DELETE FROM ers_poverty
	WHERE SUBSTR(fipstxt, 3, 3) = '000';

CREATE TABLE ers_education (
	fips_code CHARACTER(5) PRIMARY KEY,
	state CHARACTER(2),
	pct_no_high_school NUMERIC,
	pct_bachelors_or_higher NUMERIC
);
\copy ers_education FROM 'Education-cut.csv' CSV HEADER;
DELETE FROM ers_education
	WHERE SUBSTR(fips_code, 3, 3) = '000';
