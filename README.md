# Nonvoters analysis

This repository contains analysis code for the September 10, 2018 story ["On The Sidelines Of Democracy: Exploring Why So Many Americans Don't Vote"](https://www.npr.org/2018/09/10/645223716/on-the-sidelines-of-democracy-exploring-why-so-many-americans-dont-vote).

## Requirements

- Python and `csvkit`
- Postgres
- ImageMagick
- `wget`
- `jq`
- AP Elections API key, as an environment variable named `AP_API_KEY`

## Charts and data analysis

### Data sources

_Some of these sources were only used for exploratory data analysis that didn't appear in the story._

- L2 provided us with a custom data export: population count tabulated by county, `Voting Frequency`, `Political Party` (the `Likely Democratic`, `Likely Republican`, and `Likely Independent` variable), `Estimated Income` (bucket), `Broad Ethnic Groupings`, and `Age Range Based On Birth Year`. This file is available in the `Orion` SFTP server, in the `L2_DATA` directory.
- county-level poverty rates from the USDA ERS:
```bash
wget https://www.ers.usda.gov/webdocs/DataFiles/48747/PovertyEstimates.xls
in2csv --no-inference --skip-lines 3 PovertyEstimates.xls > PovertyEstimates.csv
csvcut --columns FIPStxt,State,"Rural-urban_Continuum_Code_2013",PCTPOVALL_2016,MEDHHINC_2016 \
	PovertyEstimates.csv > PovertyEstimates-cut.csv
```
- county-level education attainment rates from
```bash
wget https://www.ers.usda.gov/webdocs/DataFiles/48747/Education.xls
in2csv --no-inference --skip-lines 4 Education.xls > Education.csv
# Need to use column indices instead of names, due to string parsing issues
csvcut --columns 1,2,44,47 Education.csv > Education-cut.csv
```
- foo
```bash
wget "https://api.ap.org/v2/elections/2016-11-08?level=fipscode&format=json&officeID=P&apikey=${AP_API_KEY}" \
	--output-document ap_2016_presidential.json
jq -c '.races[].reportingUnits[]' < ap_2016_presidential.json > ap_2016_presidential_races.json
```

### Loading data into Postgres

The data are about 14M rows, too big to quickly store and query in Excel. We used Postgres to store and analyze. Load the data into a local Postgres database using the `load-data.sql` Postgres script.

### Analyzing the data

Some of our analysis queries, including several that were used to produce figures for the story, can be found by running the `analyze.sql` Postgres script.

## Maps

The maps for this story are screenshots from [the L2 VoterMapping tool](https://login.votermapping.com/client); at the time of publishing, L2 did not allow export of their map layers, so we had to utilize screenshots instead. We cropped the screenshots using ImageMagick's `convert` command, similar to:

```bash
convert "Screen Shot 2018-08-23 at 15.59.35.png" -crop 1500x1080+120+510 el-paso-nonvoter.png
```
