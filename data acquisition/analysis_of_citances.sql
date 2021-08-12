/*****
General data analysis query for Measuring Disagreement in Science
By Nees Jan van Eck and Wout S. Lamers
*****/

declare @threshold_validity as int = 80
declare @threshold_agreement as int = 80

drop table if exists #query_validity
select 
	query_id, 
	concat(a.signal_name, ' + ', a.filter_name) as query_name, 
	case when b.measure >= @threshold_validity and c.measure >= @threshold_agreement then 1 else 0 end as valid, 
	case when b.measure >= 80 and c.measure >= 80 then 1 else 0 end as valid80, 
	case when b.measure >= 75 and c.measure >= 75 then 1 else 0 end as valid75, 
	case when b.measure >= 70 and c.measure >= 70 then 1 else 0 end as valid70, 
	b.measure as validity_score, 
	c.measure as agreement_score
into #query_validity
from fulltext_project_query a
join fulltext_project_query_validity b on a.signal_name = b.signal_name and a.filter_name=b.filter_name and b.[type] = 'validity'
join fulltext_project_query_validity c on a.signal_name = c.signal_name and a.filter_name=c.filter_name and c.[type] = 'agreement' 

drop table if exists #pub_sentence_results
select a.doi, sentence_seq, 1 as found, max(valid) as valid
into #pub_sentence_results
from fulltext_project_pub_sentence_query a
join #query_validity b on a.query_id=b.query_id
group by doi, sentence_seq

drop table if exists #pub_sentence_results_valid
select doi, sentence_seq
into #pub_sentence_results_valid
from #pub_sentence_results
where valid = 1

drop table if exists fulltext_project_pub_reference_data
select b.doi, f.reference_seq, citation.cit_window, citation.self_cit
into fulltext_project_pub_reference_data
from pub as b
join pub_selection as c on b.doi = c.doi
join match_key_wos as d on b.match_key = d.match_key
join pub_reference f on b.doi=f.doi
join match_key_wos g on f.cited_match_key=g.match_key 
join wos_2013_indicators..pub as citingpub on d.ut=citingpub.ut
join wos_2013_indicators..pub as citedpub on g.ut=citedpub.ut
join wos_2013_indicators..citation as citation on citingpub.pub_no=citation.citing_pub_no and citedpub.pub_no=citation.cited_pub_no
where b.full_text=1 and b.pub_year between 1998 and 2016

-- Queries.

--avg n references over time
select LR_main_field, pub_year, avg(cast(n_references as float)) as avg_n_referenes
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_field_wos_LR as f on a.doi = f.doi
where a.pub_year between 2000 and 2015
group by LR_main_field, pub_year
union
select 'All', pub_year, avg(cast(n_references as float)) as avg_n_referenes
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_field_wos_LR as f on a.doi = f.doi
where a.pub_year between 2000 and 2015
group by pub_year
order by 1, 2


--results per signal
select signal_id, signal_name, n_sentences = count(*), n_intext_citations = sum(n_citations), sum(n_citations)/cast(tot_n_citances as float) as share_citances
from (
select distinct signal_id, signal_name, c.doi, c.sentence_seq, c.n_citations
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
join fulltext_project_pub_sentence_query as d on a.doi = d.doi and c.sentence_seq = d.sentence_seq
join #query_validity as e on d.query_id = e.query_id
join fulltext_project_query z on d.query_id=z.query_id and z.filter_id = 5
) a,
--total number of sentences, results in db
( select tot_pubs = count(distinct a.doi), 
	 tot_n_citances = count(*)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi ) b
group by a.signal_id, signal_name, tot_n_citances
order by 1

--results per filter
select filter_id, n_sentences = count(*), n_intext_citations = sum(n_citations)
from (
select distinct filter_id, c.doi, c.sentence_seq, c.n_citations
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
join fulltext_project_pub_sentence_query as d on a.doi = d.doi and c.sentence_seq = d.sentence_seq
join #query_validity as e on d.query_id = e.query_id
join fulltext_project_query z on d.query_id=z.query_id
) a
group by a.filter_id
order by 1

--results and validity per query
select e.query_id, e.query_name, e.valid80, e.valid75, e.valid70, n_sentences = count(*), n_intext_citations = sum(c.n_citations)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
join fulltext_project_pub_sentence_query as d on a.doi = d.doi and c.sentence_seq = d.sentence_seq
join #query_validity as e on d.query_id = e.query_id
group by e.query_id, e.query_name, e.valid80, e.valid75, e.valid70
order by 1, 2

--results and validity per query and field
select LR_main_field, e.query_id, e.query_name, e.valid80, e.valid75, e.valid70, n_sentences = count(*), n_intext_citations = sum(c.n_citations)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
join fulltext_project_pub_sentence_query as d on a.doi = d.doi and c.sentence_seq=d.sentence_seq
join #query_validity as e on d.query_id = e.query_id
join pub_field_wos_LR as f on a.doi = f.doi
where a.pub_year between 2000 and 2015
group by LR_main_field, e.query_id, e.query_name, e.valid80, e.valid75, e.valid70
order by 1, 2


--total intext citations, counts, percentages, valid and found
select tot_n_citances = count(*),
	n_citances_found = sum(case when d.doi is not null then 1 else 0 end),
	perc_citances_found = cast(sum(case when d.doi is not null then 1 else 0 end) as float) / cast(count(*) as float),
	n_citances_valid = sum(case when d.doi is not null then valid else 0 end),
	perc_citances_valid = cast(sum(case when d.doi is not null then valid else 0 end) as float) / cast(count(*) as float)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
left join #pub_sentence_results as d on c.doi = d.doi and c.sentence_seq = d.sentence_seq

--percentage citations per year
select a.pub_year,
	perc_citances_found = cast(sum(case when d.doi is not null then 1 else 0 end) as float) / cast(count(*) as float), 
	perc_citances_valid = cast(sum(case when d.doi is not null then valid else 0 end) as float) / cast(count(*) as float)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
left join #pub_sentence_results as d on c.doi = d.doi and c.sentence_seq = d.sentence_seq
group by a.pub_year
order by 1

drop table if exists #query_pub_year
select a.query_id, a.pub_year, a.n_citances, b.tot_n_citances, perc_citances = cast(a.n_citances as float) / b.tot_n_citances
into #query_pub_year
from
(
	select d.query_id, a.pub_year, n_citances = count(*)
	from pub as a
	join pub_selection as b on a.doi = b.doi
	join pub_sentence as c on a.doi = c.doi
	join fulltext_project_pub_sentence_query as d on c.doi = d.doi and c.sentence_seq = d.sentence_seq
	where pub_year between 1998 and 2016
	group by d.query_id, a.pub_year
) as a
join
(
	select a.pub_year, tot_n_citances = count(*)
	from pub as a
	join pub_selection as b on a.doi = b.doi
	join pub_sentence as c on a.doi = c.doi
	where pub_year between 1998 and 2016
	group by a.pub_year
) as b on a.pub_year = b.pub_year

--pivot table, pct intext citations per query per year
DECLARE @query_ids nvarchar(MAX);
SELECT @query_ids = COALESCE(@query_ids,'') +'['+cast(query_id as varchar(max))+']'+ ', ' 
FROM #query_validity WHERE valid = 1 order by query_id;

DECLARE @sqlToRun varchar(MAX)
SET @sqlToRun = '
SELECT *
FROM
(
	select query_id, pub_year, perc_citances
	from #query_pub_year
) AS src
PIVOT
( 
    sum(perc_citances) FOR query_id IN  ('+ substring(@query_ids,1,len(@query_ids)-1) +')  
) AS pvt
order by pub_year'   

EXEC (@sqlToRun)

-- Valid queries.
select *
from #query_validity
where valid = 1
order by 1

-- pct intext citations per field per year
select	LR_main_field, 
		a.pub_year, 
		perc_citances_found = cast(sum(case when d.doi is not null then 1 else 0 end) as float) / cast(count(*) as float), 
		perc_citances_valid = cast(sum(case when d.doi is not null then valid else 0 end) as float) / cast(count(*) as float)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
left join #pub_sentence_results as d on c.doi = d.doi and c.sentence_seq = d.sentence_seq
join pub_field_wos_LR as f on a.doi = f.doi
where a.pub_year between 2000 and 2015
group by LR_main_field, a.pub_year
order by 1, 2

-- pct intext citations per field
select e.LR_main_field,
	perc_citances_found = cast(sum(case when d.doi is not null then 1 else 0 end) as float) / cast(count(*) as float),
	n_citances_found = sum(case when d.doi is not null then 1 else 0 end),
	perc_citances_valid = cast(sum(case when d.doi is not null then valid else 0 end) as float) / cast(count(*) as float),
	n_citances_valid = sum(case when d.doi is not null then valid else 0 end),
	tot_n_citances = count(*)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
left join #pub_sentence_results as d on c.doi = d.doi and c.sentence_seq = d.sentence_seq
join pub_field_wos_LR as e on a.doi = e.doi
where a.pub_year between 2000 and 2015
group by e.LR_main_field
order by 1

-- overall pct intext citations
select 	perc_citances_found = cast(sum(case when d.doi is not null then 1 else 0 end) as float) / cast(count(*) as float),
	n_citances_found = sum(case when d.doi is not null then 1 else 0 end),
	perc_citances_valid = cast(sum(case when d.doi is not null then valid else 0 end) as float) / cast(count(*) as float),
	n_citances_valid = sum(case when d.doi is not null then valid else 0 end),
	tot_n_citances = count(*)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
left join #pub_sentence_results as d on c.doi = d.doi and c.sentence_seq = d.sentence_seq
where a.pub_year between 2000 and 2015

-- Gender.
select e.gender + cast(e.position as varchar(10)),
	a.pub_year, 
	perc_citances_found = cast(sum(case when d.doi is not null then 1 else 0 end) as float) / cast(count(*) as float),
	perc_citances_valid = cast(sum(case when d.doi is not null then valid else 0 end) as float) / cast(count(*) as float)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
left join #pub_sentence_results as d on c.doi = d.doi and c.sentence_seq = d.sentence_seq
join _pub_gender as e on a.doi = e.doi
where a.pub_year between 2008 and 2016
	and e.gender in ('F', 'M') and e.position in (1, 2)
group by  e.gender, e.position, a.pub_year
order by 1, 2

select e.gender + cast(e.position as varchar(10)), 
	perc_citances_found = cast(sum(case when d.doi is not null then 1 else 0 end) as float) / cast(count(*) as float),
	n_citances_found = sum(case when d.doi is not null then 1 else 0 end),
	perc_citances_valid = cast(sum(case when d.doi is not null then valid else 0 end) as float) / cast(count(*) as float),
	n_citances_valid = sum(case when d.doi is not null then valid else 0 end),
	tot_n_citances = count(*)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
left join #pub_sentence_results as d on c.doi = d.doi and c.sentence_seq = d.sentence_seq
join _pub_gender as e on a.doi = e.doi
where a.pub_year between 2008 and 2016
	and e.gender in ('F', 'M') and e.position in (1, 2)
group by e.gender, e.position
order by 1

select 	perc_citances_found = cast(sum(case when d.doi is not null then 1 else 0 end) as float) / cast(count(*) as float),
	n_citances_found = sum(case when d.doi is not null then 1 else 0 end),
	perc_citances_valid = cast(sum(case when d.doi is not null then valid else 0 end) as float) / cast(count(*) as float),
	n_citances_valid = sum(case when d.doi is not null then valid else 0 end),
	tot_n_citances = count(*)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
left join #pub_sentence_results as d on c.doi = d.doi and c.sentence_seq = d.sentence_seq
join _pub_gender as e on a.doi = e.doi
where a.pub_year between 2008 and 2016
	--and e.gender in ('F', 'M') and e.position in (1, 2)

select e.LR_main_field,
	f.gender + cast(f.position as varchar(10)), 
	n_citances_found = sum(case when d.doi is not null then 1 else 0 end),
	perc_citances_found = cast(sum(case when d.doi is not null then 1 else 0 end) as float) / cast(count(*) as float),
	n_citances_valid = sum(case when d.doi is not null then valid else 0 end),
	perc_citances_valid = cast(sum(case when d.doi is not null then valid else 0 end) as float) / cast(count(*) as float),
	tot_n_citances = count(*)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
left join #pub_sentence_results as d on c.doi = d.doi and c.sentence_seq = d.sentence_seq
join pub_field_wos_LR as e on a.doi = e.doi
join _pub_gender as f on a.doi = f.doi
where a.pub_year between 2008 and 2015
	and f.gender in ('F', 'M') and f.position in (1, 2)
group by e.LR_main_field,  f.gender, f.position
order by 1, 2

select f.gender + cast(f.position as varchar(10)), 
	perc_citances_found = cast(sum(case when d.doi is not null then 1 else 0 end) as float) / cast(count(*) as float),
	n_citances_found = sum(case when d.doi is not null then 1 else 0 end),
	perc_citances_valid = cast(sum(case when d.doi is not null then valid else 0 end) as float) / cast(count(*) as float),
	n_citances_valid = sum(case when d.doi is not null then valid else 0 end),
	tot_n_citances = count(*)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
left join #pub_sentence_results as d on c.doi = d.doi and c.sentence_seq = d.sentence_seq
join pub_field_wos_LR as e on a.doi = e.doi
join _pub_gender as f on a.doi = f.doi
where a.pub_year between 2008 and 2015
	and f.gender in ('F', 'M') and f.position in (1, 2)
group by f.gender, f.position
order by 1

select e.LR_main_field,
	n_citances_found = sum(case when d.doi is not null then 1 else 0 end),
	perc_citances_found = cast(sum(case when d.doi is not null then 1 else 0 end) as float) / cast(count(*) as float),
	n_citances_valid = sum(case when d.doi is not null then valid else 0 end),
	perc_citances_valid = cast(sum(case when d.doi is not null then valid else 0 end) as float) / cast(count(*) as float),
	tot_n_citances = count(*)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
left join #pub_sentence_results as d on c.doi = d.doi and c.sentence_seq = d.sentence_seq
join pub_field_wos_LR as e on a.doi = e.doi
join _pub_gender as f on a.doi = f.doi
where a.pub_year between 2008 and 2015 
	and f.gender in ('F', 'M') and f.position in (1, 2)
group by e.LR_main_field
order by 1

select n_citances_found = sum(case when d.doi is not null then 1 else 0 end),
	perc_citances_found = cast(sum(case when d.doi is not null then 1 else 0 end) as float) / cast(count(*) as float),
	n_citances_valid = sum(case when d.doi is not null then valid else 0 end),
	perc_citances_valid = cast(sum(case when d.doi is not null then valid else 0 end) as float) / cast(count(*) as float),
	tot_n_citances = count(*)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
left join #pub_sentence_results as d on c.doi = d.doi and c.sentence_seq = d.sentence_seq
join pub_field_wos_LR as e on a.doi = e.doi
join _pub_gender as f on a.doi = f.doi
where a.pub_year between 2008 and 2015
	and f.gender in ('F', 'M') and f.position in (1, 2)

-- Text progression.
drop table if exists #pub_citance_location
select a.doi,
	a.sentence_seq,
	a.section_seq,
	a.character_seq,
	citance_location_section = cast(a.section_seq as float) / b.n_sections,
	citance_location_character = cast(a.character_seq as float) / b.n_characters,
	controversy = case when e.doi is not null and e.valid = 1 then 1 else 0 end
into #pub_citance_location
from pub_sentence as a
join pub as b on a.doi = b.doi
join pub_selection as d on a.doi = d.doi
left join #pub_sentence_results as e on a.doi = e.doi and a.sentence_seq = e.sentence_seq

declare @tot_n_pubs float = (select count(*) from pub_selection)
declare @tot_n_pubs1 float = (select count(*) from pub_selection as a join pub_field_wos_LR as c on a.doi = c.doi where c.LR_main_field = 'Biomedical and health sciences')
declare @tot_n_pubs2 float = (select count(*) from pub_selection as a join pub_field_wos_LR as c on a.doi = c.doi where c.LR_main_field = 'Life and earth sciences')
declare @tot_n_pubs3 float = (select count(*) from pub_selection as a join pub_field_wos_LR as c on a.doi = c.doi where c.LR_main_field = 'Mathematics and computer science')
declare @tot_n_pubs4 float = (select count(*) from pub_selection as a join pub_field_wos_LR as c on a.doi = c.doi where c.LR_main_field = 'Physical sciences and engineering')
declare @tot_n_pubs5 float = (select count(*) from pub_selection as a join pub_field_wos_LR as c on a.doi = c.doi where c.LR_main_field = 'Social sciences and humanities')

select [Series] = 'All fields',
	[0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end) / @tot_n_pubs,
	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end) / @tot_n_pubs,
	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end) / @tot_n_pubs,
	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end) / @tot_n_pubs,
	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end) / @tot_n_pubs,
	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end) / @tot_n_pubs,
	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end) / @tot_n_pubs,
	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end) / @tot_n_pubs,
	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end) / @tot_n_pubs,
	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end) / @tot_n_pubs,
	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end) / @tot_n_pubs,
	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end) / @tot_n_pubs,
	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end) / @tot_n_pubs,
	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end) / @tot_n_pubs,
	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end) / @tot_n_pubs,
	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end) / @tot_n_pubs,
	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end) / @tot_n_pubs,
	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end) / @tot_n_pubs,
	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end) / @tot_n_pubs,
	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end) / @tot_n_pubs
from #pub_citance_location
where controversy = 1
union
select [Series] = 'Biomedical and health sciences', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end) / @tot_n_pubs1,	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end) / @tot_n_pubs1,	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end) / @tot_n_pubs1,	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end) / @tot_n_pubs1,	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end) / @tot_n_pubs1,	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end) / @tot_n_pubs1,	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end) / @tot_n_pubs1,	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end) / @tot_n_pubs1,	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end) / @tot_n_pubs1,	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end) / @tot_n_pubs1,	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end) / @tot_n_pubs1,	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end) / @tot_n_pubs1,	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end) / @tot_n_pubs1,	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end) / @tot_n_pubs1,	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end) / @tot_n_pubs1,	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end) / @tot_n_pubs1,	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end) / @tot_n_pubs1,	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end) / @tot_n_pubs1,	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end) / @tot_n_pubs1,	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end) / @tot_n_pubs1
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Biomedical and health sciences'
	and controversy = 1
union
select [Series] = 'Life and earth sciences', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end) / @tot_n_pubs2,	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end) / @tot_n_pubs2,	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end) / @tot_n_pubs2,	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end) / @tot_n_pubs2,	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end) / @tot_n_pubs2,	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end) / @tot_n_pubs2,	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end) / @tot_n_pubs2,	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end) / @tot_n_pubs2,	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end) / @tot_n_pubs2,	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end) / @tot_n_pubs2,	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end) / @tot_n_pubs2,	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end) / @tot_n_pubs2,	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end) / @tot_n_pubs2,	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end) / @tot_n_pubs2,	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end) / @tot_n_pubs2,	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end) / @tot_n_pubs2,	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end) / @tot_n_pubs2,	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end) / @tot_n_pubs2,	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end) / @tot_n_pubs2,	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end) / @tot_n_pubs2
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Life and earth sciences'
	and controversy = 1
union
select [Series] = 'Mathematics and computer science', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end) / @tot_n_pubs3,	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end) / @tot_n_pubs3,	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end) / @tot_n_pubs3,	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end) / @tot_n_pubs3,	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end) / @tot_n_pubs3,	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end) / @tot_n_pubs3,	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end) / @tot_n_pubs3,	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end) / @tot_n_pubs3,	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end) / @tot_n_pubs3,	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end) / @tot_n_pubs3,	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end) / @tot_n_pubs3,	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end) / @tot_n_pubs3,	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end) / @tot_n_pubs3,	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end) / @tot_n_pubs3,	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end) / @tot_n_pubs3,	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end) / @tot_n_pubs3,	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end) / @tot_n_pubs3,	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end) / @tot_n_pubs3,	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end) / @tot_n_pubs3,	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end) / @tot_n_pubs3
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Mathematics and computer science'
	and controversy = 1
union
select [Series] = 'Physical sciences and engineering', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end) / @tot_n_pubs4,	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end) / @tot_n_pubs4,	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end) / @tot_n_pubs4,	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end) / @tot_n_pubs4,	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end) / @tot_n_pubs4,	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end) / @tot_n_pubs4,	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end) / @tot_n_pubs4,	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end) / @tot_n_pubs4,	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end) / @tot_n_pubs4,	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end) / @tot_n_pubs4,	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end) / @tot_n_pubs4,	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end) / @tot_n_pubs4,	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end) / @tot_n_pubs4,	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end) / @tot_n_pubs4,	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end) / @tot_n_pubs4,	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end) / @tot_n_pubs4,	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end) / @tot_n_pubs4,	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end) / @tot_n_pubs4,	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end) / @tot_n_pubs4,	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end) / @tot_n_pubs4
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Physical sciences and engineering'
	and controversy = 1
union
select [Series] = 'Social sciences and humanities', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end) / @tot_n_pubs5,	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end) / @tot_n_pubs5,	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end) / @tot_n_pubs5,	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end) / @tot_n_pubs5,	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end) / @tot_n_pubs5,	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end) / @tot_n_pubs5,	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end) / @tot_n_pubs5,	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end) / @tot_n_pubs5,	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end) / @tot_n_pubs5,	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end) / @tot_n_pubs5,	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end) / @tot_n_pubs5,	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end) / @tot_n_pubs5,	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end) / @tot_n_pubs5,	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end) / @tot_n_pubs5,	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end) / @tot_n_pubs5,	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end) / @tot_n_pubs5,	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end) / @tot_n_pubs5,	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end) / @tot_n_pubs5,	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end) / @tot_n_pubs5,	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end) / @tot_n_pubs5
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Social sciences and humanities'
	and controversy = 1

select [Series] = 'All fields',
	[0-5] = cast(sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end),
	[5-10] = cast(sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end),
	[10-15] = cast(sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end),
	[15-20] = cast(sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end),
	[20-25] = cast(sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end),
	[25-30] = cast(sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end),
	[30-35] = cast(sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end),
	[35-40] = cast(sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end),
	[40-45] = cast(sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end),
	[45-50] = cast(sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end),
	[50-55] = cast(sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end),
	[55-60] = cast(sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end),
	[60-65] = cast(sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end),
	[65-70] = cast(sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end),
	[70-75] = cast(sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end),
	[75-80] = cast(sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end),
	[80-85] = cast(sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end),
	[85-90] = cast(sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end),
	[90-95] = cast(sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end),
	[95-100] = cast(sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location
union
select [Series] = 'Biomedical and health sciences', [0-5] = cast(sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end), [5-10] = cast(sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end), [10-15] = cast(sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end), [15-20] = cast(sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end), [20-25] = cast(sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end), [25-30] = cast(sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end), [30-35] = cast(sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end), [35-40] = cast(sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end), [40-45] = cast(sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end), [45-50] = cast(sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end), [50-55] = cast(sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end), [55-60] = cast(sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end), [60-65] = cast(sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end), [65-70] = cast(sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end), [70-75] = cast(sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end), [75-80] = cast(sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end), [80-85] = cast(sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end), [85-90] = cast(sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end), [90-95] = cast(sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end), [95-100] = cast(sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Biomedical and health sciences'
union
select [Series] = 'Life and earth sciences', [0-5] = cast(sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end), [5-10] = cast(sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end), [10-15] = cast(sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end), [15-20] = cast(sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end), [20-25] = cast(sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end), [25-30] = cast(sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end), [30-35] = cast(sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end), [35-40] = cast(sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end), [40-45] = cast(sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end), [45-50] = cast(sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end), [50-55] = cast(sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end), [55-60] = cast(sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end), [60-65] = cast(sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end), [65-70] = cast(sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end), [70-75] = cast(sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end), [75-80] = cast(sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end), [80-85] = cast(sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end), [85-90] = cast(sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end), [90-95] = cast(sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end), [95-100] = cast(sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Life and earth sciences'
union
select [Series] = 'Mathematics and computer science', [0-5] = cast(sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end), [5-10] = cast(sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end), [10-15] = cast(sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end), [15-20] = cast(sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end), [20-25] = cast(sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end), [25-30] = cast(sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end), [30-35] = cast(sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end), [35-40] = cast(sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end), [40-45] = cast(sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end), [45-50] = cast(sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end), [50-55] = cast(sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end), [55-60] = cast(sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end), [60-65] = cast(sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end), [65-70] = cast(sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end), [70-75] = cast(sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end), [75-80] = cast(sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end), [80-85] = cast(sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end), [85-90] = cast(sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end), [90-95] = cast(sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end), [95-100] = cast(sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Mathematics and computer science'
union
select [Series] = 'Physical sciences and engineering', [0-5] = cast(sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end), [5-10] = cast(sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end), [10-15] = cast(sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end), [15-20] = cast(sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end), [20-25] = cast(sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end), [25-30] = cast(sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end), [30-35] = cast(sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end), [35-40] = cast(sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end), [40-45] = cast(sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end), [45-50] = cast(sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end), [50-55] = cast(sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end), [55-60] = cast(sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end), [60-65] = cast(sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end), [65-70] = cast(sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end), [70-75] = cast(sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end), [75-80] = cast(sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end), [80-85] = cast(sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end), [85-90] = cast(sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end), [90-95] = cast(sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end), [95-100] = cast(sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Physical sciences and engineering'
union
select [Series] = 'Social sciences and humanities', [0-5] = cast(sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end), [5-10] = cast(sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end), [10-15] = cast(sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end), [15-20] = cast(sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end), [20-25] = cast(sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end), [25-30] = cast(sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end), [30-35] = cast(sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end), [35-40] = cast(sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end), [40-45] = cast(sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end), [45-50] = cast(sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end), [50-55] = cast(sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end), [55-60] = cast(sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end), [60-65] = cast(sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end), [65-70] = cast(sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end), [70-75] = cast(sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end), [75-80] = cast(sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end), [80-85] = cast(sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end), [85-90] = cast(sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end), [90-95] = cast(sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end), [95-100] = cast(sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then controversy else 0 end) as float) / sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Social sciences and humanities'

--gender, citing and cited
-- percentage citations found and valid when joined with gender data
select 	perc_intext_citations_found = cast(sum(case when d.doi is not null then n_citations else 0 end) as float) / cast(sum(n_citations) as float),
	n_intext_citations_found = sum(case when d.doi is not null then n_citations else 0 end),
	perc_intext_citations_valid = cast(sum(case when d.doi is not null then n_citations*valid else 0 end) as float) / cast(sum(n_citations) as float),
	n_intext_citations_valid = sum(case when d.doi is not null then n_citations*valid else 0 end),
	tot_n_intext_citations = sum(n_citations)
from pub as a
join pub_selection as b on a.doi = b.doi
join pub_sentence as c on a.doi = c.doi
left join #pub_sentence_results as d on c.doi = d.doi and c.sentence_seq = d.sentence_seq
join _pub_gender as e on a.doi = e.doi
where e.gender in ('F', 'M') and e.position in (1, 2) and a.pub_year between 2008 and 2016

--citing-cited pairs table
drop table if exists #pairs
select c.doi as citing_doi, f.found, f.valid, c.sentence_seq, c.citation_seq, e.doi as cited_doi
into #pairs
from pub a
join pub_selection b on a.doi=b.doi
join pub_citation_sentence c on b.doi=c.doi --and b.sentence_seq=cb.sentence_seq
join pub_reference d on c.doi=d.doi and c.reference_seq=d.reference_seq
join pub_selection e on d.cited_match_key=e.match_key
left join #pub_sentence_results f on f.doi=c.doi and c.sentence_seq=f.sentence_seq
where a.pub_year between 2008 and 2016

--citations (total, found, valid) per gender, position and field
drop table if exists #gender_citations
select *
into #gender_citations
from(
select 'All' as citing_LR_main_field, upper(b.gender) as citing_gender, b.position as citing_position, upper(c.gender) as cited_gender, c.position as cited_position,
	count(*) as n_citations, 
	sum(found) as n_found, 
	sum(valid) as n_valid, 
	sum(found)/cast(count(*) as float) as pct_found, 
	sum(valid)/cast(count(*) as float) as pct_valid
from #pairs a
join _pub_gender b on a.citing_doi=b.doi
join _pub_gender c on a.cited_doi=c.doi
group by b.gender, b.position, c.gender, c.position
--order by b.gender, b.position, c.gender, c.position 
union
select LR_Main_Field as citing_LR_main_field, upper(b.gender) as citing_gender, b.position as citing_position, upper(c.gender) as cited_gender, c.position as cited_position,
	count(*) as n_citations, 
	sum(found) as n_found, 
	sum(valid) as n_valid, 
	sum(found)/cast(count(*) as float) as pct_found, 
	sum(valid)/cast(count(*) as float) as pct_valid
from #pairs a
join _pub_gender b on a.citing_doi=b.doi
join _pub_gender c on a.cited_doi=c.doi
join pub_field_wos_LR d on a.citing_doi = d.doi
group by LR_main_field, b.gender, b.position, c.gender, c.position
--order by LR_main_field, b.gender, b.position, c.gender, c.position 
) wrap
order by citing_LR_main_field, citing_gender, cited_gender

--citations per field, gender, and position, as share of gendered citations for position, and a factor showing amplification of the signal compared to the overall expectation based on all gendered citations
select a.*, n_citations_gendered, n_found_gendered, n_valid_gendered,
	n_citations/cast(n_citations_gendered as float) as share_citations, 
	n_found/cast(n_found_gendered as float) as share_found, 
	n_valid/cast(n_valid_gendered as float) as share_valid,
	(n_found/cast(n_found_gendered as float))/(n_citations/cast(n_citations_gendered as float)) as amp_found,
	(n_valid/cast(n_valid_gendered as float))/(n_citations/cast(n_citations_gendered as float)) as amp_valid
from #gender_citations a
join (
	select citing_LR_main_field, citing_position, cited_position, sum(n_citations) as n_citations_gendered, sum(n_found) as n_found_gendered, sum(n_valid) as n_valid_gendered 
	from #gender_citations 
	group by citing_LR_main_field, citing_position, cited_position
) b on a.citing_LR_main_field=b.citing_LR_main_field and a.citing_position=b.citing_position and a.cited_position=b.cited_position
order by citing_LR_main_field, citing_gender, citing_position, cited_gender, cited_position

--self citations
drop table if exists #reference_citation_data
select a.*, count(*) as n_citations, sum(case when c.sentence_seq is null then 0 else 1 end) as n_citations_disagreement
into #reference_citation_data
from fulltext_project_pub_reference_data a
join pub_citation_sentence b on a.doi=b.doi and a.reference_seq=b.reference_seq
left join #pub_sentence_results_valid c on b.doi=c.doi and b.sentence_seq=c.sentence_seq
group by a.doi, a.reference_seq, a.cit_window, a.self_cit	

drop table if exists #reference_citation_filter_data
select filter_id, a.doi, a.reference_seq, a.cit_window, a.self_cit, count(*) as n_citations_disagreement
into #reference_citation_filter_data
from (
select distinct e.filter_id, a.doi, a.reference_seq, a.cit_window, a.self_cit, citation_seq
from fulltext_project_pub_reference_data a
join pub_citation_sentence b on a.doi=b.doi and a.reference_seq=b.reference_seq
join fulltext_project_pub_sentence_query c on b.doi=c.doi and b.sentence_seq=c.sentence_seq
join #query_validity d on c.query_id=d.query_id and d.valid=1
join fulltext_project_query e on d.query_id=e.query_id
) a
group by filter_id, doi, reference_seq, cit_window, self_cit

drop table if exists #reference_citation_query_data
select query_id, a.doi, a.reference_seq, a.cit_window, a.self_cit, count(*) as n_citations_disagreement
into #reference_citation_query_data
from (
select distinct e.query_id, a.doi, a.reference_seq, a.cit_window, a.self_cit, citation_seq
from fulltext_project_pub_reference_data a
join pub_citation_sentence b on a.doi=b.doi and a.reference_seq=b.reference_seq
join fulltext_project_pub_sentence_query c on b.doi=c.doi and b.sentence_seq=c.sentence_seq
join #query_validity d on c.query_id=d.query_id and d.valid=1
join fulltext_project_query e on d.query_id=e.query_id
) a
group by query_id, doi, reference_seq, cit_window, self_cit

select *
into #self_cit_data
from (
	select 
		'All publications' as LR_main_field,
		self_cit, 
		sum(n_citations) as n_citations, 
		sum(n_citations_disagreement) as n_citations_disagreement, 
		sum(n_citations_disagreement)/cast(sum(n_citations) as float) as share_disagreement 
	from #reference_citation_data a
	group by self_cit
	union
	select 
		LR_main_field, 
		self_cit, 
		sum(n_citations) as n_citations, 
		sum(n_citations_disagreement) as n_citations_disagreement, 
		sum(n_citations_disagreement)/cast(sum(n_citations) as float) as share_disagreement 
	from #reference_citation_data a
	join pub_field_wos_LR b on a.doi=b.doi
	join pub c on a.doi=c.doi
	where pub_year between 2000 and 2015
	group by LR_main_field, self_cit
) wrap

select * 
from #self_cit_data
order by LR_main_field, self_cit

select c.filter_name, a.filter_id, a.LR_main_field, a.self_cit, b.n_citations, a.n_citations_disagreement, a.n_citations_disagreement/cast(b.n_citations as float) as share_disagreement
from (
select
	filter_id,
	'All publications' as LR_main_field,
	a.self_cit, 
	sum(a.n_citations_disagreement) as n_citations_disagreement
from #reference_citation_filter_data a
group by filter_id, a.self_cit
union
select 
	filter_id,
	LR_main_field, 
	self_cit, 
	sum(n_citations_disagreement) as n_citations_disagreement
from #reference_citation_filter_data a
join pub_field_wos_LR b on a.doi=b.doi
join pub c on a.doi=c.doi
where pub_year between 2000 and 2015
group by filter_id, LR_main_field, self_cit
) a
join #self_cit_data b on a.self_cit=b.self_cit and b.LR_main_field=a.LR_main_field
join (select distinct filter_id, filter_name from fulltext_project_query) c on a.filter_id=c.filter_id
order by LR_main_field, filter_id, self_cit

--citation windows
drop table if exists #cit_window_bin_data
select *
into #cit_window_bin_data
from (
select 
	'All publications' as LR_main_field,
	citation_window as citation_window_bin, 
	sum(n_citations) as n_citations, 
	sum(n_citations_disagreement) as n_citations_disagreement, 
	sum(n_citations_disagreement)/cast(sum(n_citations) as float) as share_disagreement 
from (select *, case when cit_window >= 20 then '20+' when cit_window >= 15 then '15-19' when cit_window >= 10 then '10-14' when cit_window >= 5 then '05-09' else '00-05' end as citation_window from #reference_citation_data) a
group by citation_window
union
select 
	LR_main_field, 
	citation_window as citation_window_bin, 
	sum(n_citations) as n_citations, 
	sum(n_citations_disagreement) as n_citations_disagreement, 
	sum(n_citations_disagreement)/cast(sum(n_citations) as float) as share_disagreement 
from (select *, case when cit_window >= 20 then '20+' when cit_window >= 15 then '15-19' when cit_window >= 10 then '10-14' when cit_window >= 5 then '05-09' else '00-05' end as citation_window from #reference_citation_data) a
join pub_field_wos_LR b on a.doi=b.doi
join pub c on a.doi=c.doi
where pub_year between 2000 and 2015
group by LR_main_field, citation_window
) wrap

select *
from #cit_window_bin_data
order by LR_main_field, citation_window_bin

select c.filter_name, a.filter_id, a.LR_main_field, a.citation_window_bin, b.n_citations, a.n_citations_disagreement, a.n_citations_disagreement/cast(b.n_citations as float) as share_disagreement
from (
select 
	filter_id, 
	'All publications' as LR_main_field,
	citation_window as citation_window_bin, 
	sum(n_citations_disagreement) as n_citations_disagreement
from (select *, case when cit_window >= 20 then '20+' when cit_window >= 15 then '15-19' when cit_window >= 10 then '10-14' when cit_window >= 5 then '05-09' else '00-05' end as citation_window from #reference_citation_filter_data) a
group by filter_id, citation_window
union
select 
	filter_id, 
	LR_main_field, 
	citation_window as citation_window_bin, 
	sum(n_citations_disagreement) as n_citations_disagreement
from (select *, case when cit_window >= 20 then '20+' when cit_window >= 15 then '15-19' when cit_window >= 10 then '10-14' when cit_window >= 5 then '05-09' else '00-05' end as citation_window from #reference_citation_filter_data) a
join pub_field_wos_LR b on a.doi=b.doi
join pub c on a.doi=c.doi
where pub_year between 2000 and 2015
group by filter_id, LR_main_field, citation_window
) a
join #cit_window_bin_data b on a.LR_main_field=b.LR_main_field and a.citation_window_bin=b.citation_window_bin
join (select distinct filter_id, filter_name from fulltext_project_query) c on a.filter_id=c.filter_id
order by a.LR_main_field, filter_id, a.citation_window_bin

drop table if exists #cit_window_year_data
select *
into #cit_window_year_data
from (
select 
	'All publications' as LR_main_field,
	citation_window, 
	sum(n_citations) as n_citations, 
	sum(n_citations_disagreement) as n_citations_disagreement, 
	sum(n_citations_disagreement)/cast(sum(n_citations) as float) as share_disagreement 
from (select *, case when cit_window >= 20 then '20+' else str(cit_window, 2) end as citation_window from #reference_citation_data) a
group by citation_window
union
select 
	LR_main_field, 
	citation_window, 
	sum(n_citations) as n_citations, 
	sum(n_citations_disagreement) as n_citations_disagreement, 
	sum(n_citations_disagreement)/cast(sum(n_citations) as float) as share_disagreement 
from (select *, case when cit_window >= 20 then '20+' else str(cit_window, 2) end as citation_window from #reference_citation_data) a
join pub_field_wos_LR b on a.doi=b.doi
join pub c on a.doi=c.doi
where pub_year between 2000 and 2015
group by LR_main_field, citation_window
) wrap

select *
from #cit_window_year_data
order by LR_main_field, citation_window

select c.filter_name, a.filter_id, a.LR_main_field, a.citation_window, b.n_citations, a.n_citations_disagreement, a.n_citations_disagreement/cast(b.n_citations as float) as share_disagreement
from (
select 
	filter_id,
	'All publications' as LR_main_field,
	citation_window, 
	sum(n_citations_disagreement) as n_citations_disagreement
from (select *, case when cit_window >= 20 then '20+' else str(cit_window, 2) end as citation_window from #reference_citation_filter_data) a
group by filter_id, citation_window
union
select 
	filter_id,
	LR_main_field, 
	citation_window, 
	sum(n_citations_disagreement) as n_citations_disagreement
from (select *, case when cit_window >= 20 then '20+' else str(cit_window, 2) end as citation_window from #reference_citation_filter_data) a
join pub_field_wos_LR b on a.doi=b.doi
join pub c on a.doi=c.doi
where pub_year between 2000 and 2015
group by filter_id, LR_main_field, citation_window
) a
join #cit_window_year_data b on a.LR_main_field=b.LR_main_field and a.citation_window=b.citation_window
join (select distinct filter_id, filter_name from fulltext_project_query) c on a.filter_id=c.filter_id
order by a.LR_main_field, filter_id, a.citation_window

-- top disagreeable publications
drop table if exists #cited_match_keys_disagreement
select c.cited_match_key, count(*) as n_citances_disagreement
into #cited_match_keys_disagreement
from #pub_sentence_results_valid a 
join pub_citation_sentence b on a.doi=b.doi and a.sentence_seq=b.sentence_seq
join pub_reference c on b.doi=c.doi and b.reference_seq=c.reference_seq
join pub as d on a.doi=d.doi
join pub_selection as e on d.doi = e.doi
group by c.cited_match_key

drop table if exists #cited_match_keys_disagreement_all
select a.cited_match_key, a.n_citances_disagreement, count(*) as n_citances_all
into #cited_match_keys_disagreement_all
from #cited_match_keys_disagreement a
join pub_reference b on a.cited_match_key=b.cited_match_key
join pub_citation_sentence c on b.reference_seq=c.reference_seq and b.doi=c.doi
group by a.cited_match_key, a.n_citances_disagreement

drop table if exists #temp_top_pubs
select *
into #temp_top_pubs
from (
select top 8 a.*, b.doi, b.doc_type as doc_type_doi, f.ut, g.doc_type as doc_type_ut, isnull(b.title, d.title) as title
from (
	select *, n_citances_disagreement/cast(n_citances_all as float) as ratio_disagreement 
	from #cited_match_keys_disagreement_all 
	where n_citances_all >= 50 
--	order by n_citances_disagreement desc
) a
left join pub b on a.cited_match_key=b.match_key
left join match_key_wos c on a.cited_match_key=c.match_key
left join wos_2013..pub_title d on c.ut=d.ut
left join wos_2013..pub f on c.ut=f.ut
left join wos_2013..doc_type g on f.doc_type_id=g.doc_type_id
order by ratio_disagreement desc
union
select top 8 a.*, b.doi, b.doc_type as doc_type_doi, f.ut, g.doc_type as doc_type_ut, isnull(b.title, d.title) as title
from (
	select *, n_citances_disagreement/cast(n_citances_all as float) as ratio_disagreement 
	from #cited_match_keys_disagreement_all 
	where n_citances_all >= 50 
--	order by n_citances_disagreement desc
) a
left join pub b on a.cited_match_key=b.match_key
left join match_key_wos c on a.cited_match_key=c.match_key
left join wos_2013..pub_title d on c.ut=d.ut
left join wos_2013..pub f on c.ut=f.ut
left join wos_2013..doc_type g on f.doc_type_id=g.doc_type_id
order by n_citances_disagreement desc
) a

select * from #temp_top_pubs

select a.*, b.doi, c.citation_seq, c.sentence_seq, case when e.sentence_seq is not null then 1 else 0 end as disagreement, d.text 
from #temp_top_pubs a
join pub_reference b on a.cited_match_key=b.cited_match_key
join pub_citation_sentence c on b.doi=c.doi and b.reference_seq=c.reference_seq
join pub_sentence d on c.doi=d.doi and c.sentence_seq=d.sentence_seq
left join #pub_sentence_results_valid e on d.doi=e.doi and d.sentence_seq=e.sentence_seq
order by a.cited_match_key, b.doi, c.citation_seq, c.sentence_seq

--save publication level data
drop table if exists fulltext_project_pub_level_data
select a.*, b.doi, b.doc_type as doc_type_doi, f.ut, g.doc_type as doc_type_ut, isnull(b.title, d.title) as title
into fulltext_project_pub_level_data
from (
	select *, n_citances_disagreement/cast(n_citances_all as float) as ratio_disagreement 
	from #cited_match_keys_disagreement_all 
--	where n_citances_all >= 50 
--	order by n_citances_disagreement desc
) a
left join pub b on a.cited_match_key=b.match_key
left join match_key_wos c on a.cited_match_key=c.match_key
left join wos_2013..pub_title d on c.ut=d.ut
left join wos_2013..pub f on c.ut=f.ut
left join wos_2013..doc_type g on f.doc_type_id=g.doc_type_id

select * from fulltext_project_pub_level_data
