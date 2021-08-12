
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
where pub_year between 2000 and 2015

declare @tot_n_pubs float = (select count(*) from pub_selection)
declare @tot_n_pubs1 float = (select count(*) from pub_selection as a join pub_field_wos_LR as c on a.doi = c.doi where c.LR_main_field = 'Biomedical and health sciences')
declare @tot_n_pubs2 float = (select count(*) from pub_selection as a join pub_field_wos_LR as c on a.doi = c.doi where c.LR_main_field = 'Life and earth sciences')
declare @tot_n_pubs3 float = (select count(*) from pub_selection as a join pub_field_wos_LR as c on a.doi = c.doi where c.LR_main_field = 'Mathematics and computer science')
declare @tot_n_pubs4 float = (select count(*) from pub_selection as a join pub_field_wos_LR as c on a.doi = c.doi where c.LR_main_field = 'Physical sciences and engineering')
declare @tot_n_pubs5 float = (select count(*) from pub_selection as a join pub_field_wos_LR as c on a.doi = c.doi where c.LR_main_field = 'Social sciences and humanities')

-- only disagreement
select [Series] = 'All fields',
	[0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end) ,-- / @tot_n_pubs,
	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end) ,-- / @tot_n_pubs,
	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end) ,-- / @tot_n_pubs,
	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end) ,-- / @tot_n_pubs,
	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end) ,-- / @tot_n_pubs,
	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end) ,-- / @tot_n_pubs,
	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end) ,-- / @tot_n_pubs,
	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end) ,-- / @tot_n_pubs,
	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end) ,-- / @tot_n_pubs,
	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end) ,-- / @tot_n_pubs,
	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end) ,-- / @tot_n_pubs,
	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end) ,-- / @tot_n_pubs,
	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end) ,-- / @tot_n_pubs,
	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end) ,-- / @tot_n_pubs,
	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end) ,-- / @tot_n_pubs,
	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end) ,-- / @tot_n_pubs,
	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end) ,-- / @tot_n_pubs,
	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end) ,-- / @tot_n_pubs,
	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end) ,-- / @tot_n_pubs,
	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end) -- / @tot_n_pubs
from #pub_citance_location
where controversy = 1
union
select [Series] = 'Biomedical and health sciences', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end)
	,	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end)
	,	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end) 
	,	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end) 
	,	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end)
	,	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end)
	,	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end) 
	,	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end) 
	,	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end) 
	,	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end)
	,	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end) 
	,	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end)
	,	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end) 
	,	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end) 
	,	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end) 
	,	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end) 
	,	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end) 
	,	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end) 
	,	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end)
	,	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Biomedical and health sciences'
	and controversy = 1
union
select [Series] = 'Life and earth sciences', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end) 
	,	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end) 
	,	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end) 
	,	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end) 
	,	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end) 
	,	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end) 
	,	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end) 
	,	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end) 
	,	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end) 
	,	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end) 
	,	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end) 
	,	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end) 
	,	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end) 
	,	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end) 
	,	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end)
	,	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end) 
	,	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end) 
	,	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end) 
	,	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end)
	,	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end) 
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Life and earth sciences'
	and controversy = 1
union
select [Series] = 'Mathematics and computer science', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end)
	,	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end)
	,	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end)
	,	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end) 
	,	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end) 
	,	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end)
	,	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end) 
	,	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end) 
	,	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end) 
	,	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end) 
	,	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end) 
	,	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end)
	,	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end) 
	,	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end) 
	,	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end)
	,	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end)
	,	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end) 
	,	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end) 
	,	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end) 
	,	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Mathematics and computer science'
	and controversy = 1
union
select [Series] = 'Physical sciences and engineering', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end) 
	,	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end)
	,	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end),	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end),	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end),	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end),	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end),	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end),	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end),	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end),	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end),	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end),	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end),	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end),	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end),	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end),	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end),	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end),	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end),	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Physical sciences and engineering'
	and controversy = 1
union
select [Series] = 'Social sciences and humanities', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end),	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end),	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end),	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end),	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end),	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end),	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end),	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end),	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end),	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end),	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end),	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end),	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end),	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end),	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end),	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end),	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end),	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end),	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end),	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Social sciences and humanities'
	and controversy = 1

--all citances
select [Series] = 'All fields',
	[0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end) ,-- / @tot_n_pubs,
	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end) ,-- / @tot_n_pubs,
	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end) ,-- / @tot_n_pubs,
	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end) ,-- / @tot_n_pubs,
	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end) ,-- / @tot_n_pubs,
	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end) ,-- / @tot_n_pubs,
	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end) ,-- / @tot_n_pubs,
	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end) ,-- / @tot_n_pubs,
	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end) ,-- / @tot_n_pubs,
	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end) ,-- / @tot_n_pubs,
	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end) ,-- / @tot_n_pubs,
	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end) ,-- / @tot_n_pubs,
	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end) ,-- / @tot_n_pubs,
	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end) ,-- / @tot_n_pubs,
	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end) ,-- / @tot_n_pubs,
	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end) ,-- / @tot_n_pubs,
	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end) ,-- / @tot_n_pubs,
	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end) ,-- / @tot_n_pubs,
	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end) ,-- / @tot_n_pubs,
	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end) -- / @tot_n_pubs
from #pub_citance_location
union
select [Series] = 'Biomedical and health sciences', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end),	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end),	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end),	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end),	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end),	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end),	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end),	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end),	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end),	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end),	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end),	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end),	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end),	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end),	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end),	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end),	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end),	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end),	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end),	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Biomedical and health sciences'
union
select [Series] = 'Life and earth sciences', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end),	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end),	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end),	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end),	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end),	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end),	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end),	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end),	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end),	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end),	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end),	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end),	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end),	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end),	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end),	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end),	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end),	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end),	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end),	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Life and earth sciences'
union
select [Series] = 'Mathematics and computer science', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end),	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end),	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end),	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end),	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end),	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end),	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end),	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end),	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end),	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end),	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end),	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end),	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end),	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end),	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end),	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end),	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end),	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end),	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end),	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Mathematics and computer science'
union
select [Series] = 'Physical sciences and engineering', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end),	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end),	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end),	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end),	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end),	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end),	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end),	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end),	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end),	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end),	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end),	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end),	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end),	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end),	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end),	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end),	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end),	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end),	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end),	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Physical sciences and engineering'
union
select [Series] = 'Social sciences and humanities', [0-5] = sum(case when citance_location_character >= 0 and citance_location_character < 0.05 then 1 else 0 end),	[5-10] = sum(case when citance_location_character >= 0.05 and citance_location_character < 0.10 then 1 else 0 end),	[10-15] = sum(case when citance_location_character >= 0.10 and citance_location_character < 0.15 then 1 else 0 end),	[15-20] = sum(case when citance_location_character >= 0.15 and citance_location_character < 0.20 then 1 else 0 end),	[20-25] = sum(case when citance_location_character >= 0.20 and citance_location_character < 0.25 then 1 else 0 end),	[25-30] = sum(case when citance_location_character >= 0.25 and citance_location_character < 0.30 then 1 else 0 end),	[30-35] = sum(case when citance_location_character >= 0.30 and citance_location_character < 0.35 then 1 else 0 end),	[35-40] = sum(case when citance_location_character >= 0.35 and citance_location_character < 0.40 then 1 else 0 end),	[40-45] = sum(case when citance_location_character >= 0.40 and citance_location_character < 0.45 then 1 else 0 end),	[45-50] = sum(case when citance_location_character >= 0.45 and citance_location_character < 0.50 then 1 else 0 end),	[50-55] = sum(case when citance_location_character >= 0.50 and citance_location_character < 0.55 then 1 else 0 end),	[55-60] = sum(case when citance_location_character >= 0.55 and citance_location_character < 0.60 then 1 else 0 end),	[60-65] = sum(case when citance_location_character >= 0.60 and citance_location_character < 0.65 then 1 else 0 end),	[65-70] = sum(case when citance_location_character >= 0.65 and citance_location_character < 0.70 then 1 else 0 end),	[70-75] = sum(case when citance_location_character >= 0.70 and citance_location_character < 0.75 then 1 else 0 end),	[75-80] = sum(case when citance_location_character >= 0.75 and citance_location_character < 0.80 then 1 else 0 end),	[80-85] = sum(case when citance_location_character >= 0.80 and citance_location_character < 0.85 then 1 else 0 end),	[85-90] = sum(case when citance_location_character >= 0.85 and citance_location_character < 0.90 then 1 else 0 end),	[90-95] = sum(case when citance_location_character >= 0.90 and citance_location_character < 0.95 then 1 else 0 end),	[95-100] = sum(case when citance_location_character >= 0.95 and citance_location_character <= 1 then 1 else 0 end)
from #pub_citance_location as a
join pub_field_wos_LR as c on a.doi = c.doi
where c.LR_main_field = 'Social sciences and humanities'

