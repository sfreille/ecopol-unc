# Latinobarometro full-archive audit

## Archive at a glance

- 23 repeated cross-sectional survey waves: 1995, 1996, 1997, 1998, 2000–2011, 2013, 2015–2018, 2020, and 2023.
- 470,557 respondent records and 7,474 wave-variable records in the English SPSS files.
- Typical wave: about 20,000–22,700 respondents and 270–400 variables.
- Country coverage changes: 8 countries in 1995, usually 17–19 afterward, and 17 observed in 2023.
- Each row is a respondent. Columns mix substantive questions, demographics, geography, interview metadata, country identifiers, and survey weights.
- These are repeated cross-sections, not a respondent panel. Individuals cannot be followed over time.

## Architecture and coding

The SPSS files are the best machine-readable source because they retain question labels and response labels. Variable names are not stable across time: capitalization, question number, suffix, and module naming all change. A harmonization key must therefore use question wording, response categories, and questionnaires rather than exact names.

Common structural fields include a country identifier (`pais`, `idenpa`, or `IDENPA`) and a weight (`wt`, `WT`, or `pondera`). Negative codes generally identify non-substantive responses, but conventions vary by wave: `-1` through `-5` commonly represent don't know, refusal/no answer, not applicable, not asked, or combined missing categories. Some older waves also use positive codes such as 8, 97, or 0 for non-substantive answers. Never treat all nonnegative values as valid without reading the value labels.

The country value-label dictionary can contain countries not actually sampled in a wave. Country coverage must be calculated from observed values, not the label dictionary.

Weights also require care. Before pooled estimates, determine whether the supplied weight is intended for within-country representativeness, cross-country regional estimates, or both. For regional trends, do not let different national sample sizes implicitly determine country influence; report country-weighted and population-weighted estimands separately when relevant.

## Continuity of priority constructs

The automated inventory finds the following conservative availability. This is based on labels and should be verified against questionnaires before publication.

| Construct | Waves found | Assessment |
|---|---:|---|
| Left–right self-placement | 23 | Excellent backbone; usually 0–10, but special codes vary |
| Support for democracy | 22 | Excellent; standard three-category item, missing in the label search for 2011 |
| Satisfaction with democracy | 22 | Excellent; stable four-category scale |
| Interpersonal trust | 22 | Excellent; standard binary generalized-trust item, absent in 1995 |
| Tax-evasion justification | 11 | Good intermittent series: 1998, 2003, 2005, 2008–11, 2013, 2015–16, 2023 |
| Corruption tolerance | 2 clearly matched | Module item in 2018 and 2020; broader corruption measures occur much more often |
| Connections versus effort / merit | 7 | Episodic early series: 1995–98, 2000, 2002, 2007; related opportunity items occur later |

Institutional confidence is extensive, especially for congress/parliament, political parties, police, armed forces, judiciary, church, and government. The wording and variable numbers change after 2011, but equivalent batteries continue in recent waves.

Corruption is not one series. The archive contains distinct concepts: perceived prevalence, change over time, personal/family exposure, sector or actor involvement, government progress, willingness to report, and tolerance of corruption. These should not be collapsed into a single measure.

Polarization also needs a precise definition. Left–right dispersion can be studied in every wave, but affective polarization requires party/leader like-dislike measures that are not uniformly available. Useful operationalizations include ideological dispersion, bimodality, ideological sorting by vote choice, and country-year gaps between partisan camps.

## Recommended starting point

Start with a narrow harmonized core rather than stacking all variables:

1. Build a respondent-level file containing wave, country, weight, age, sex/gender, education, income or subjective class, left–right placement, support for democracy, satisfaction with democracy, interpersonal trust, and the main institutional-confidence battery.
2. Create a hand-audited crosswalk with one row per construct-wave: source variable, exact wording, response labels, valid range, missing codes, polarity, and a comparability grade (`A` exact, `B` recode-compatible, `C` related but not directly comparable).
3. Produce country-wave weighted means/proportions with confidence intervals and explicit sample sizes.
4. Plot small multiples by country. Do not connect across nonexistent survey years without visibly marking gaps.
5. Only then add episodic modules such as tax morale, corruption, and meritocracy.

The best first teaching dataset is the democratic-attitudes core. It supports clean demonstrations of repeated cross-sections, survey weights, recoding labelled data, country-year aggregation, composition versus attitude change, and ecological versus individual-level inference.

## Research and teaching directions

- **Democratic discontent:** separate diffuse support for democracy from satisfaction with how democracy works; relate their divergence to institutional confidence and economic evaluations.
- **Trust syndrome:** compare generalized interpersonal trust with confidence in state, representative, coercive, media, and religious institutions; test whether these form distinct latent dimensions.
- **Ideological polarization:** measure country-year dispersion and mass at scale endpoints; distinguish polarization from simple rightward or leftward movement and from nonresponse/`none` responses.
- **Corruption and regime attitudes:** compare corruption exposure, perceived prevalence, and tolerance as separate predictors of democratic support and authoritarian openness.
- **Tax morale:** study justification of evasion alongside institutional trust, corruption perceptions, service satisfaction, and distributive attitudes. The intermittent design is suitable for country-wave panels, not annual time series.
- **Meritocratic beliefs:** contrast effort/connection beliefs and equality-of-opportunity items with education, class, mobility perceptions, and support for redistribution or markets. Treat early and later modules as related families unless wording equivalence is established.
- **Dataset complements:** merge only at country-year (or country-period) level with V-Dem, World Bank WDI, CEPALSTAT, SWIID/WIID, Transparency International, QoG, IMF/OECD tax data, and election results. Preserve temporal ordering and cluster inference at the country level.

## Files produced by this audit

- `output/wave_inventory.csv`: dimensions, observed country count, identifiers, weights, and filenames.
- `output/variable_inventory.csv`: every variable in every wave with question/value labels and missingness.
- `output/exact_wording_continuity.csv`: normalized exact-wording recurrence across waves.
- `output/thematic_inventory.csv`: heuristic theme-filtered catalog for the requested topics.
- `code/01_inventory_all_waves.R`: reproducible generator for all four inventories.

The theme tagging is a discovery aid, not a final harmonization. False positives and missed paraphrases are expected; questionnaires and response labels remain authoritative.
