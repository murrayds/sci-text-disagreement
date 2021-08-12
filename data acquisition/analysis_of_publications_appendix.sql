/*****
Analysis query for interaction disagreement citations and received citations
By Wout S. Lamers
*****/

use projectdb_tdm_elsevier
go

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

create index idx_temp_results
on #pub_sentence_results_valid (doi, sentence_seq)


--most disagreeing papers
drop table if exists #most_disagreeing
select *
into #most_disagreeing
from (
	select a.doi, a.n_sentences, a.n_sentences_disagreement, a.n_sentences_disagreement/cast(a.n_sentences as float) as share_disagreement, 
	row_number() over (order by n_sentences_disagreement desc, a.n_sentences_disagreement/cast(a.n_sentences as float) desc, doi) rk1, row_number() over (order by a.n_sentences_disagreement/cast(a.n_sentences as float) desc, n_sentences_disagreement desc, doi) rk2
	from (
		select a.doi, count(*) as n_sentences, sum(case when c.doi is null then 0 else 1 end) as n_sentences_disagreement
		from pub a
		join pub_sentence b on a.doi=b.doi
		left join #pub_sentence_results_valid c on b.doi=c.doi and b.sentence_seq=c.sentence_seq
		group by a.doi
		--order by n_sentences_disagreement desc
	) a
	where n_sentences >= 50
) wrap
where rk1 <= 10 or rk2 <= 10

--most disagreed with papers
drop table if exists #most_disagreed
select *
into #most_disagreed
from (
	select a.cited_match_key, a.n_sentences, a.n_sentences_disagreement, a.n_sentences_disagreement/cast(a.n_sentences as float) as share_disagreement, 
	row_number() over (order by n_sentences_disagreement desc, a.n_sentences_disagreement/cast(a.n_sentences as float) desc, cited_match_key) rk1, row_number() over (order by a.n_sentences_disagreement/cast(a.n_sentences as float) desc, n_sentences_disagreement desc, cited_match_key) rk2
	from (
		select a.cited_match_key, count(*) as n_sentences, sum(case when d.doi is null then 0 else 1 end) as n_sentences_disagreement
		from pub_reference a
		join pub b on a.cited_match_key=b.match_key
		join pub_citation_sentence c on a.doi=c.doi and a.reference_seq=c.reference_seq
		left join #pub_sentence_results_valid d on c.doi=d.doi and c.sentence_seq=d.sentence_seq
		where left(a.cited_match_key, 5) != 'anon_'
		group by a.cited_match_key
		--order by n_sentences_disagreement desc
	) a
	where n_sentences >= 50
) wrap
where rk1 <= 10 or rk2 <= 10

-- most disagreeing, select them
select *
from #most_disagreeing a
join pub b on a.doi=b.doi
order by rk1, rk2, n_sentences_disagreement desc, b.doi

-- most disagreed with, select them
select *
from #most_disagreed a
join pub b on a.cited_match_key=b.match_key
order by rk1, rk2, n_sentences_disagreement desc, b.doi

-- most disagreeing, citing sentences
select b.*, case when c.doi is null then 0 else 1 end as disagreement
from #most_disagreeing a
join pub_sentence b on a.doi=b.doi
left join #pub_sentence_results_valid c on c.doi=b.doi and c.sentence_seq=b.sentence_seq
order by rk1, rk2, n_sentences_disagreement desc, b.doi, b.sentence_seq

-- most disagreed with, citing sentences
select a.cited_match_key, d.*, case when e.doi is null then 0 else 1 end as disagreement
from #most_disagreed a
join pub_reference b on a.cited_match_key=b.cited_match_key
join pub_citation_sentence c on b.doi=c.doi and b.reference_seq=c.reference_seq
join pub_sentence d on c.doi=d.doi and c.sentence_seq=d.sentence_seq
left join #pub_sentence_results_valid e on d.doi=e.doi and d.sentence_seq=e.sentence_seq
order by rk1, rk2, n_sentences_disagreement desc, d.doi, d.sentence_seq


--within sample, stats per field
use projectdb_tdm_elsevier
go

drop table if exists #temp
select a.doi as doi_citing, count(*) as n_citances, sum(case when cv.doi is null then 0 else 1 end) as n_citances_disagreement, e.cited_match_key
into #temp
from pub a
join pub_selection b on a.doi=b.doi and a.pub_year between 2000 and 2015
join pub_sentence c on a.doi=c.doi
--join pub_field_wos_LR cc on a.doi=cc.doi
left join #pub_sentence_results_valid cv on c.doi=cv.doi and c.sentence_seq=cv.sentence_seq
join pub_citation_sentence d on c.doi=d.doi and c.sentence_seq=d.sentence_seq
join pub_reference e on d.doi=e.doi and d.reference_seq=e.reference_seq
group by a.doi, e.cited_match_key

drop table if exists #dois
select a.doi
into #dois
from pub a
join pub_selection b on a.doi=b.doi
--join (select distinct doi from pub_sentence) c on a.doi=c.doi
join pub_field_wos_LR d on a.doi=d.doi
where pub_year between 2000 and 2015

drop table if exists #temp2
select a.doi_citing, a.n_citances, a.n_citances_disagreement, b.doi as doi_cited
into #temp2
from #temp a 
join pub b on a.cited_match_key=b.match_key
join pub_selection c on b.doi=c.doi
join pub_field_wos_LR z1 on a.doi_citing=z1.doi
join pub_field_wos_LR z2 on b.doi=z2.doi
join #dois d1 on a.doi_citing=d1.doi
join #dois d2 on b.doi=d2.doi
--where doi_citing is not null and cited_match_key is not null and b.pub_year between 2000 and 2015

drop table if exists #temp_citing
select aa.doi as doi_citing, case when sum(n_citances_disagreement) > 0 then 1 else 0 end as disagreement, sum(n_citances) n_citances, sum(n_citances_disagreement) n_citances_disagreement
into #temp_citing
from #dois aa
left join #temp2 a on a.doi_citing=aa.doi
group by aa.doi

drop table if exists #temp_cited
select aa.doi as doi_cited, case when sum(n_citances_disagreement) > 0 then 1 else 0 end as disagreement, sum(n_citances) n_citances, sum(n_citances_disagreement) n_citances_disagreement
into #temp_cited
from #dois aa
left join #temp2 a on a.doi_cited=aa.doi
group by aa.doi

select LR_main_field, 
	count(*) as n_pubs, sum(case when n_citances > 0 then 1 else 0 end) as n_pubs_citances, sum(disagreement) as n_pubs_disagreement, 
	sum(disagreement)/cast(count(*) as float) as share_pubs_disagreement,
	sum(disagreement)/cast(sum(case when n_citances > 0 then 1 else 0 end) as float) as share_pubs_citances_disagreement,
	sum(n_citances) as n_citances, sum(n_citances_disagreement) as n_citances_disagreement, sum(n_citances_disagreement)/cast(sum(n_citances) as float) as share_citances_disagreement
from #temp_citing a
join pub_field_wos_LR b on a.doi_citing=b.doi
group by LR_main_field
union
select 'All fields', 
	count(*) as n_pubs, sum(case when n_citances > 0 then 1 else 0 end) as n_pubs_citances, sum(disagreement) as n_pubs_disagreement, 
	sum(disagreement)/cast(count(*) as float) as share_pubs_disagreement,
	sum(disagreement)/cast(sum(case when n_citances > 0 then 1 else 0 end) as float) as share_pubs_citances_disagreement,
	sum(n_citances) as n_citances, sum(n_citances_disagreement) as n_citances_disagreement, sum(n_citances_disagreement)/cast(sum(n_citances) as float) as share_citances_disagreement
from #temp_citing a
join pub_field_wos_LR b on a.doi_citing=b.doi

select LR_main_field, 
	count(*) as n_pubs, sum(case when n_citances > 0 then 1 else 0 end) as n_pubs_citances, sum(disagreement) as n_pubs_disagreement, 
	sum(disagreement)/cast(count(*) as float) as share_pubs_disagreement,
	sum(disagreement)/cast(sum(case when n_citances > 0 then 1 else 0 end) as float) as share_pubs_citances_disagreement,
	sum(n_citances) as n_citances, sum(n_citances_disagreement) as n_citances_disagreement, sum(n_citances_disagreement)/cast(sum(n_citances) as float) as share_citances_disagreement
from #temp_cited a
join pub_field_wos_LR b on a.doi_cited=b.doi
group by LR_main_field
union
select 'All fields', 
	count(*) as n_pubs, sum(case when n_citances > 0 then 1 else 0 end) as n_pubs_citances, sum(disagreement) as n_pubs_disagreement, 
	sum(disagreement)/cast(count(*) as float) as share_pubs_disagreement,
	sum(disagreement)/cast(sum(case when n_citances > 0 then 1 else 0 end) as float) as share_pubs_citances_disagreement,
	sum(n_citances) as n_citances, sum(n_citances_disagreement) as n_citances_disagreement, sum(n_citances_disagreement)/cast(sum(n_citances) as float) as share_citances_disagreement
from #temp_cited a
join pub_field_wos_LR b on a.doi_cited=b.doi

--doc type
select doc_type, count(*) n_pub, avg(share_disagreement) as avg_share_disagreement
from (
	select a.doi, a.doc_type, sum(case when c.doi is null then 0 else 1 end)/cast(count(*) as float) as share_disagreement
	from projectdb_tdm_elsevier..pub a 
	join projectdb_tdm_elsevier..pub_selection z on a.doi=z.doi
	left join projectdb_tdm_elsevier..pub_sentence b on a.doi=b.doi
	left join #pub_sentence_results_valid c on a.doi=c.doi and b.sentence_seq=c.sentence_seq
	group by a.doi, a.doc_type
) wrap
group by doc_type
order by doc_type

-- cited
use projectdb_tdm_elsevier
go

select LR_main_field, 
	n_records_nodis, 
	n_records_dis, 
	sum_cits_y1_nodis/cast(n_records_nodis as float) as avg_cits_y1_nodis, 
	sum_cits_y2_nodis/cast(n_records_nodis as float) as avg_cits_y2_nodis, 
	sum_cits_y3_nodis/cast(n_records_nodis as float) as avg_cits_y3_nodis, 
	sum_cits_y4_nodis/cast(n_records_nodis as float) as avg_cits_y4_nodis, 
	sum_cits_y1_dis/cast(n_records_dis as float) as avg_cits_y1_dis, 
	sum_cits_y2_dis/cast(n_records_dis as float) as avg_cits_y2_dis, 
	sum_cits_y3_dis/cast(n_records_dis as float) as avg_cits_y3_dis, 
	sum_cits_y4_dis/cast(n_records_dis as float) as avg_cits_y4_dis, 
	sum_ncs_y1_nodis/cast(n_records_nodis as float) as mncs_y1_nodis, 
	sum_ncs_y2_nodis/cast(n_records_nodis as float) as mncs_y2_nodis, 
	sum_ncs_y3_nodis/cast(n_records_nodis as float) as mncs_y3_nodis, 
	sum_ncs_y4_nodis/cast(n_records_nodis as float) as mncs_y4_nodis,
	sum_ncs_y1_dis/cast(n_records_dis as float) as mncs_y1_dis, 
	sum_ncs_y2_dis/cast(n_records_dis as float) as mncs_y2_dis, 
	sum_ncs_y3_dis/cast(n_records_dis as float) as mncs_y3_dis, 
	sum_ncs_y4_dis/cast(n_records_dis as float) as mncs_y4_dis, 
	(sum_cits_y3_nodis/cast(n_records_nodis as float))/(sum_cits_y1_nodis/cast(n_records_nodis as float)) as change_cits_nodis,
	(sum_cits_y3_dis/cast(n_records_dis as float))/(sum_cits_y1_dis/cast(n_records_dis as float)) as change_cits_dis,
	(sum_ncs_y3_nodis/cast(n_records_nodis as float))/(sum_ncs_y1_nodis/cast(n_records_nodis as float)) as change_mncs_nodis,
	(sum_ncs_y3_dis/cast(n_records_dis as float))/(sum_ncs_y1_dis/cast(n_records_dis as float)) as change_mncs_dis
from (
select LR_main_field,
	count(*) as n_records,
	sum(case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as n_records_dis,
	sum(case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as n_records_nodis,
	sum(cs_1 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_cits_y1_dis,
	sum(cs_1 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_cits_y1_nodis,
	sum(cs_3 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_cits_y3_dis, 
	sum(cs_3 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_cits_y3_nodis, 
	sum(ncs_1 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_ncs_y1_dis,
	sum(ncs_1 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_ncs_y1_nodis, 
	sum(ncs_3 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_ncs_y3_dis,
	sum(ncs_3 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_ncs_y3_nodis,
	sum(cs_2 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_cits_y2_dis,
	sum(cs_2 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_cits_y2_nodis,
	sum(cs_4 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_cits_y4_dis, 
	sum(cs_4 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_cits_y4_nodis, 
	sum(ncs_2 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_ncs_y2_dis,
	sum(ncs_2 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_ncs_y2_nodis, 
	sum(ncs_4 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_ncs_y4_dis,
	sum(ncs_4 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_ncs_y4_nodis
from fulltext_project_pub_cited_stats a
join fulltext_project_ut_impact b on a.cited_ut = b.ut
join pub c on a.cited_match_key = c.match_key
join pub_field_wos_LR d on c.doi = d.doi
group by d.LR_main_field
) a
union
select LR_main_field, 
	n_records_nodis, 
	n_records_dis, 
	sum_cits_y1_nodis/cast(n_records_nodis as float) as avg_cits_y1_nodis, 
	sum_cits_y2_nodis/cast(n_records_nodis as float) as avg_cits_y2_nodis, 
	sum_cits_y3_nodis/cast(n_records_nodis as float) as avg_cits_y3_nodis, 
	sum_cits_y4_nodis/cast(n_records_nodis as float) as avg_cits_y4_nodis, 
	sum_cits_y1_dis/cast(n_records_dis as float) as avg_cits_y1_dis, 
	sum_cits_y2_dis/cast(n_records_dis as float) as avg_cits_y2_dis, 
	sum_cits_y3_dis/cast(n_records_dis as float) as avg_cits_y3_dis, 
	sum_cits_y4_dis/cast(n_records_dis as float) as avg_cits_y4_dis, 
	sum_ncs_y1_nodis/cast(n_records_nodis as float) as mncs_y1_nodis, 
	sum_ncs_y2_nodis/cast(n_records_nodis as float) as mncs_y2_nodis, 
	sum_ncs_y3_nodis/cast(n_records_nodis as float) as mncs_y3_nodis, 
	sum_ncs_y4_nodis/cast(n_records_nodis as float) as mncs_y4_nodis,
	sum_ncs_y1_dis/cast(n_records_dis as float) as mncs_y1_dis, 
	sum_ncs_y2_dis/cast(n_records_dis as float) as mncs_y2_dis, 
	sum_ncs_y3_dis/cast(n_records_dis as float) as mncs_y3_dis, 
	sum_ncs_y4_dis/cast(n_records_dis as float) as mncs_y4_dis, 
	(sum_cits_y3_nodis/cast(n_records_nodis as float))/(sum_cits_y1_nodis/cast(n_records_nodis as float)) as change_cits_nodis,
	(sum_cits_y3_dis/cast(n_records_dis as float))/(sum_cits_y1_dis/cast(n_records_dis as float)) as change_cits_dis,
	(sum_ncs_y3_nodis/cast(n_records_nodis as float))/(sum_ncs_y1_nodis/cast(n_records_nodis as float)) as change_mncs_nodis,
	(sum_ncs_y3_dis/cast(n_records_dis as float))/(sum_ncs_y1_dis/cast(n_records_dis as float)) as change_mncs_dis
from (
select 'All' as LR_main_field,
	count(*) as n_records,
	sum(case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as n_records_dis,
	sum(case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as n_records_nodis,
	sum(cs_1 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_cits_y1_dis,
	sum(cs_1 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_cits_y1_nodis,
	sum(cs_3 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_cits_y3_dis, 
	sum(cs_3 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_cits_y3_nodis, 
	sum(ncs_1 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_ncs_y1_dis,
	sum(ncs_1 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_ncs_y1_nodis, 
	sum(ncs_3 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_ncs_y3_dis,
	sum(ncs_3 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_ncs_y3_nodis,
	sum(cs_2 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_cits_y2_dis,
	sum(cs_2 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_cits_y2_nodis,
	sum(cs_4 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_cits_y4_dis, 
	sum(cs_4 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_cits_y4_nodis, 
	sum(ncs_2 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_ncs_y2_dis,
	sum(ncs_2 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_ncs_y2_nodis, 
	sum(ncs_4 * case when n_citances_disagreement_y5 > 0 then 1 else 0 end) as sum_ncs_y4_dis,
	sum(ncs_4 * case when n_citances_disagreement_y5 > 0 then 0 else 1 end) as sum_ncs_y4_nodis
from fulltext_project_pub_cited_stats a
join fulltext_project_ut_impact b on a.cited_ut = b.ut
join pub c on a.cited_match_key = c.match_key
join pub_field_wos_LR d on c.doi = d.doi
) a

--citing
select LR_main_field, 
	n_records_nodis, 
	n_records_dis, 
	sum_cits_y1_nodis/cast(n_records_nodis as float) as avg_cits_y1_nodis, 
	sum_cits_y2_nodis/cast(n_records_nodis as float) as avg_cits_y2_nodis, 
	sum_cits_y3_nodis/cast(n_records_nodis as float) as avg_cits_y3_nodis, 
	sum_cits_y4_nodis/cast(n_records_nodis as float) as avg_cits_y4_nodis, 
	sum_cits_y1_dis/cast(n_records_dis as float) as avg_cits_y1_dis, 
	sum_cits_y2_dis/cast(n_records_dis as float) as avg_cits_y2_dis, 
	sum_cits_y3_dis/cast(n_records_dis as float) as avg_cits_y3_dis, 
	sum_cits_y4_dis/cast(n_records_dis as float) as avg_cits_y4_dis, 
	sum_ncs_y1_nodis/cast(n_records_nodis as float) as mncs_y1_nodis, 
	sum_ncs_y2_nodis/cast(n_records_nodis as float) as mncs_y2_nodis, 
	sum_ncs_y3_nodis/cast(n_records_nodis as float) as mncs_y3_nodis, 
	sum_ncs_y4_nodis/cast(n_records_nodis as float) as mncs_y4_nodis,
	sum_ncs_y1_dis/cast(n_records_dis as float) as mncs_y1_dis, 
	sum_ncs_y2_dis/cast(n_records_dis as float) as mncs_y2_dis, 
	sum_ncs_y3_dis/cast(n_records_dis as float) as mncs_y3_dis, 
	sum_ncs_y4_dis/cast(n_records_dis as float) as mncs_y4_dis, 
	(sum_cits_y4_nodis/cast(n_records_nodis as float))/(sum_cits_y2_nodis/cast(n_records_nodis as float)) as change_cits_nodis,
	(sum_cits_y4_dis/cast(n_records_dis as float))/(sum_cits_y2_dis/cast(n_records_dis as float)) as change_cits_dis,
	(sum_ncs_y4_nodis/cast(n_records_nodis as float))/(sum_ncs_y2_nodis/cast(n_records_nodis as float)) as change_mncs_nodis,
	(sum_ncs_y4_dis/cast(n_records_dis as float))/(sum_ncs_y2_dis/cast(n_records_dis as float)) as change_mncs_dis
from (
select LR_main_field,
	count(*) as n_records,
	sum(case when n_citances_disagreement > 0 then 1 else 0 end) as n_records_dis,
	sum(case when n_citances_disagreement > 0 then 0 else 1 end) as n_records_nodis,
	sum(cs_2 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_cits_y2_dis,
	sum(cs_2 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_cits_y2_nodis,
	sum(cs_4 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_cits_y4_dis, 
	sum(cs_4 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_cits_y4_nodis, 
	sum(cs_1 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_cits_y1_dis,
	sum(cs_1 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_cits_y1_nodis,
	sum(cs_3 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_cits_y3_dis, 
	sum(cs_3 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_cits_y3_nodis, 
	sum(ncs_2 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_ncs_y2_dis,
	sum(ncs_2 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_ncs_y2_nodis, 
	sum(ncs_4 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_ncs_y4_dis,
	sum(ncs_4 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_ncs_y4_nodis,
	sum(ncs_1 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_ncs_y1_dis,
	sum(ncs_1 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_ncs_y1_nodis, 
	sum(ncs_3 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_ncs_y3_dis,
	sum(ncs_3 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_ncs_y3_nodis
from fulltext_project_pub_citing_stats a
join fulltext_project_ut_impact b on a.citing_ut = b.ut
join pub c on a.citing_match_key = c.match_key
join pub_field_wos_LR d on c.doi = d.doi
group by d.LR_main_field
) a
union
select LR_main_field, 
	n_records_nodis, 
	n_records_dis, 
	sum_cits_y1_nodis/cast(n_records_nodis as float) as avg_cits_y1_nodis, 
	sum_cits_y2_nodis/cast(n_records_nodis as float) as avg_cits_y2_nodis, 
	sum_cits_y3_nodis/cast(n_records_nodis as float) as avg_cits_y3_nodis, 
	sum_cits_y4_nodis/cast(n_records_nodis as float) as avg_cits_y4_nodis, 
	sum_cits_y1_dis/cast(n_records_dis as float) as avg_cits_y1_dis, 
	sum_cits_y2_dis/cast(n_records_dis as float) as avg_cits_y2_dis, 
	sum_cits_y3_dis/cast(n_records_dis as float) as avg_cits_y3_dis, 
	sum_cits_y4_dis/cast(n_records_dis as float) as avg_cits_y4_dis, 
	sum_ncs_y1_nodis/cast(n_records_nodis as float) as mncs_y1_nodis, 
	sum_ncs_y2_nodis/cast(n_records_nodis as float) as mncs_y2_nodis, 
	sum_ncs_y3_nodis/cast(n_records_nodis as float) as mncs_y3_nodis, 
	sum_ncs_y4_nodis/cast(n_records_nodis as float) as mncs_y4_nodis,
	sum_ncs_y1_dis/cast(n_records_dis as float) as mncs_y1_dis, 
	sum_ncs_y2_dis/cast(n_records_dis as float) as mncs_y2_dis, 
	sum_ncs_y3_dis/cast(n_records_dis as float) as mncs_y3_dis, 
	sum_ncs_y4_dis/cast(n_records_dis as float) as mncs_y4_dis, 
	(sum_cits_y4_nodis/cast(n_records_nodis as float))/(sum_cits_y2_nodis/cast(n_records_nodis as float)) as change_cits_nodis,
	(sum_cits_y4_dis/cast(n_records_dis as float))/(sum_cits_y2_dis/cast(n_records_dis as float)) as change_cits_dis,
	(sum_ncs_y4_nodis/cast(n_records_nodis as float))/(sum_ncs_y2_nodis/cast(n_records_nodis as float)) as change_mncs_nodis,
	(sum_ncs_y4_dis/cast(n_records_dis as float))/(sum_ncs_y2_dis/cast(n_records_dis as float)) as change_mncs_dis
from (
select 'All' as LR_main_field,
	count(*) as n_records,
	sum(case when n_citances_disagreement > 0 then 1 else 0 end) as n_records_dis,
	sum(case when n_citances_disagreement > 0 then 0 else 1 end) as n_records_nodis,
	sum(cs_2 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_cits_y2_dis,
	sum(cs_2 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_cits_y2_nodis,
	sum(cs_4 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_cits_y4_dis, 
	sum(cs_4 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_cits_y4_nodis, 
	sum(cs_1 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_cits_y1_dis,
	sum(cs_1 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_cits_y1_nodis,
	sum(cs_3 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_cits_y3_dis, 
	sum(cs_3 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_cits_y3_nodis, 
	sum(ncs_2 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_ncs_y2_dis,
	sum(ncs_2 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_ncs_y2_nodis, 
	sum(ncs_4 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_ncs_y4_dis,
	sum(ncs_4 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_ncs_y4_nodis,
	sum(ncs_1 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_ncs_y1_dis,
	sum(ncs_1 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_ncs_y1_nodis, 
	sum(ncs_3 * case when n_citances_disagreement > 0 then 1 else 0 end) as sum_ncs_y3_dis,
	sum(ncs_3 * case when n_citances_disagreement > 0 then 0 else 1 end) as sum_ncs_y3_nodis
from fulltext_project_pub_citing_stats a
join fulltext_project_ut_impact b on a.citing_ut = b.ut
join pub c on a.citing_match_key = c.match_key
join pub_field_wos_LR d on c.doi = d.doi
) a

--citances vs ratio disagreement
drop table if exists #temp_cited_pub_data
select b.doi, a.n_citances_all, a.n_citances_disagreement, a.ratio_disagreement
into #temp_cited_pub_data
from fulltext_project_pubdata a
join pub b on a.cited_match_key=b.match_key
join pub_selection c on b.doi=c.doi
where pub_year between 2000 and 2015

create index idx_doi_cited_pub
on #temp_cited_pub_data (doi)

select LR_main_field,
	sum(case when n_citances_all < 25 then n_citances_disagreement else 0 end)/cast(sum(case when n_citances_all <= 25 then n_citances_all else 0 end) as float) as [1-24],
	sum(case when n_citances_all between 25 and 49 then n_citances_disagreement else 0 end)/cast(sum(case when n_citances_all between 25 and 49 then n_citances_all else 0 end) as float) as [25-49],
	sum(case when n_citances_all between 50 and 99 then n_citances_disagreement else 0 end)/cast(case when sum(case when n_citances_all between 50 and 99 then n_citances_all else 0 end) = 0 then 1 else sum(case when n_citances_all between 50 and 99 then n_citances_all else 0 end) end as float) as [50-99],
	sum(case when n_citances_all between 100 and 199 then n_citances_disagreement else 0 end)/cast(case when sum(case when n_citances_all between 100 and 199 then n_citances_all else 0 end) = 0 then 1 else sum(case when n_citances_all between 100 and 199 then n_citances_all else 0 end) end as float) as [100-199],
--	sum(case when n_citances_all >= 200 then n_citances_disagreement else 0 end)/cast(case when sum(case when n_citances_all >= 200 then n_citances_all else 0 end) = 0 then 1 else sum(case when n_citances_all >= 200 then n_citances_all else 0 end) end as float) as [200+],
	sum(case when n_citances_all between 200 and 399 then n_citances_disagreement else 0 end)/cast(case when sum(case when n_citances_all between 200 and 399 then n_citances_all else 0 end) = 0 then 1 else sum(case when n_citances_all between 200 and 399 then n_citances_all else 0 end) end as float) as [200-399],
	sum(case when n_citances_all >= 400 then n_citances_disagreement else 0 end)/cast(case when sum(case when n_citances_all >= 400 then n_citances_all else 0 end) = 0 then 1 else sum(case when n_citances_all >= 400 then n_citances_all else 0 end) end as float) as [400+],

	sum(case when n_citances_all < 25 then 1 else 0 end) as [1-24],
	sum(case when n_citances_all between 25 and 49 then 1 else 0 end) as [25-49],
	sum(case when n_citances_all between 50 and 99 then 1 else 0 end) as [50-99],
	sum(case when n_citances_all between 100 and 199 then 1 else 0 end) as [100-199],
--	sum(case when n_citances_all >= 200 then 1 else 0 end) as [>200]
	sum(case when n_citances_all between 200 and 399 then 1 else 0 end) as [200-399],
	sum(case when n_citances_all >= 400 then 1 else 0 end) as [400+]
from (
	select 'All fields' as LR_main_field, a.*
	from #temp_cited_pub_data a
	join pub_field_wos_LR b on a.doi=b.doi
	union
	select LR_main_field, a.*
	from #temp_cited_pub_data a
	join pub_field_wos_LR b on a.doi=b.doi
) a
group by LR_main_field
order by LR_main_field

--for dakota, underlying data for visualization
select LR_main_field, n_citances_all, count(*) as n_pub, avg(cast(n_citances_disagreement as float)) as avg_n_citances_disagreement, avg(cast(n_citances_disagreement as float))/cast(n_citances_all as float) as avg_share_citances_disagreement
from (
	select 'All fields' as LR_main_field, a.*
	from #temp_cited_pub_data a
	join pub_field_wos_LR b on a.doi=b.doi
	union
	select LR_main_field, a.*
	from #temp_cited_pub_data a
	join pub_field_wos_LR b on a.doi=b.doi
) a
group by LR_main_field, n_citances_all
order by LR_main_field, n_citances_all

-- citing perspective
drop table if exists #temp_citing_pub_data
select a.doi, a.n_sentences as n_sentences_all, isnull(c.n_sentences_disagreement, 0) as n_sentences_disagreement, isnull(c.n_sentences_disagreement, 0)/cast(a.n_sentences as float) as ratio_disagreement
into #temp_citing_pub_data
from pub a
	join pub_selection b on a.doi=b.doi
	left join ( select doi, count(*) as n_sentences_disagreement from  #pub_sentence_results_valid group by doi ) c on b.doi=c.doi
	join pub_field_wos_LR d on b.doi=d.doi
where pub_year between 2000 and 2015 and n_sentences > 0

create index idx_doi_citing_pub
on #temp_citing_pub_data (doi)

select LR_main_field,
	sum(case when n_sentences_all between 1 and 24 then n_sentences_disagreement else 0 end)/cast(sum(case when n_sentences_all between 1 and 24 then n_sentences_all else 0 end) as float) as [1-24],
	sum(case when n_sentences_all between 25 and 49 then n_sentences_disagreement else 0 end)/cast(sum(case when n_sentences_all between 25 and 49 then n_sentences_all else 0 end) as float) as [25-49],
	sum(case when n_sentences_all between 50 and 99 then n_sentences_disagreement else 0 end)/cast(case when sum(case when n_sentences_all between 50 and 99 then n_sentences_all else 0 end) = 0 then 1 else sum(case when n_sentences_all between 50 and 99 then n_sentences_all else 0 end) end as float) as [50-99],
	sum(case when n_sentences_all between 100 and 199 then n_sentences_disagreement else 0 end)/cast(case when sum(case when n_sentences_all between 100 and 199 then n_sentences_all else 0 end) = 0 then 1 else sum(case when n_sentences_all between 100 and 199 then n_sentences_all else 0 end) end as float) as [100-199],
	sum(case when n_sentences_all between 200 and 399 then n_sentences_disagreement else 0 end)/cast(case when sum(case when n_sentences_all between 200 and 399 then n_sentences_all else 0 end) = 0 then 1 else sum(case when n_sentences_all between 200 and 399 then n_sentences_all else 0 end) end as float) as [200-399],
	sum(case when n_sentences_all >= 400 then n_sentences_disagreement else 0 end)/cast(case when sum(case when n_sentences_all between 400 and 799 then n_sentences_all else 0 end) = 0 then 1 else sum(case when n_sentences_all between 400 and 799 then n_sentences_all else 0 end) end as float) as [400-799],
	sum(case when n_sentences_all >= 800 then n_sentences_disagreement else 0 end)/cast(case when sum(case when n_sentences_all >= 800 then n_sentences_all else 0 end) = 0 then 1 else sum(case when n_sentences_all >= 800 then n_sentences_all else 0 end) end as float) as [800+],

	sum(case when n_sentences_all between 1 and 24 then 1 else 0 end) as [1-24],
	sum(case when n_sentences_all between 25 and 49 then 1 else 0 end) as [25-49],
	sum(case when n_sentences_all between 50 and 99 then 1 else 0 end) as [50-99],
	sum(case when n_sentences_all between 100 and 199 then 1 else 0 end) as [100-199],
	sum(case when n_sentences_all between 200 and 399 then 1 else 0 end) as [200-399],
	sum(case when n_sentences_all between 400 and 799 then 1 else 0 end) as [400-799],
	sum(case when n_sentences_all >= 800 then 1 else 0 end) as [800+],

	sum(case when n_sentences_all between 1 and 24 then case when n_sentences_disagreement>0 then 1 else 0 end else 0 end)/cast(sum(case when n_sentences_all between 1 and 24 then 1 else 0 end) as float) as [1-24],
	sum(case when n_sentences_all between 25 and 49 then case when n_sentences_disagreement>0 then 1 else 0 end else 0 end)/cast(sum(case when n_sentences_all between 25 and 49 then 1 else 0 end) as float) as [25-49],
	sum(case when n_sentences_all between 50 and 99 then case when n_sentences_disagreement>0 then 1 else 0 end else 0 end)/cast(case when sum(case when n_sentences_all between 50 and 99 then 1 else 0 end) = 0 then 1 else sum(case when n_sentences_all between 50 and 99 then 1 else 0 end) end as float) as [50-99],
	sum(case when n_sentences_all between 100 and 199 then case when n_sentences_disagreement>0 then 1 else 0 end else 0 end)/cast(case when sum(case when n_sentences_all between 100 and 199 then 1 else 0 end) = 0 then 1 else sum(case when n_sentences_all between 100 and 199 then 1 else 0 end) end as float) as [100-199],
	sum(case when n_sentences_all between 200 and 399 then case when n_sentences_disagreement>0 then 1 else 0 end else 0 end)/cast(case when sum(case when n_sentences_all between 200 and 399 then 1 else 0 end) = 0 then 1 else sum(case when n_sentences_all between 200 and 399 then 1 else 0 end) end as float) as [200-399],
	sum(case when n_sentences_all between 400 and 799 then case when n_sentences_disagreement>0 then 1 else 0 end else 0 end)/cast(case when sum(case when n_sentences_all between 400 and 799 then 1 else 0 end) = 0 then 1 else sum(case when n_sentences_all between 400 and 799 then 1 else 0 end) end as float) as [400-799],
	sum(case when n_sentences_all >= 800 then case when n_sentences_disagreement>0 then 1 else 0 end else 0 end)/cast(case when sum(case when n_sentences_all >= 800 then 1 else 0 end) = 0 then 1 else sum(case when n_sentences_all > 800 then 1 else 0 end) end as float) as [800+]

from (
	select 'All fields' as LR_main_field, a.*
	from #temp_citing_pub_data a
	join pub_field_wos_LR b on a.doi=b.doi
	union
	select LR_main_field, a.*
	from #temp_citing_pub_data a
	join pub_field_wos_LR b on a.doi=b.doi
) a
group by LR_main_field
order by LR_main_field

--for dakota, underlying data for visualization
select LR_main_field, n_sentences_all, count(*) as n_pub, avg(cast(n_sentences_disagreement as float)) as avg_n_citances_disagreement, avg(cast(n_sentences_disagreement as float))/cast(n_sentences_all as float) as avg_share_citances_disagreement, sum(case when n_sentences_disagreement > 0 then 1 else 0 end) as n_pub_disagreement,  sum(case when n_sentences_disagreement > 0 then 1 else 0 end)/cast(count(*) as float) as share_pub_disagreement
from (
	select 'All fields' as LR_main_field, a.*
	from #temp_citing_pub_data a
	join pub_field_wos_LR b on a.doi=b.doi
	union
	select LR_main_field, a.*
	from #temp_citing_pub_data a
	join pub_field_wos_LR b on a.doi=b.doi
) a
group by LR_main_field, n_sentences_all
order by LR_main_field, n_sentences_all

-- Table SI 5, disagreement weighing factor on subsequent citations
drop table if exists #temp
select a.cited_doi, b.pub_year, c.pub_year as citing_year, count(distinct citing_doi) as n_citations, sum(n_citances) as n_citances, sum(n_citances_d) as n_citances_d
into #temp
from [userdb_lamersws1].[dbo].[fulltext_project_pub_citation_data] a
join pub b on a.cited_doi=b.doi
join pub c on a.citing_doi=c.doi
group by a.cited_doi, b.pub_year, c.pub_year

drop table if exists #cited_data
select a.*, isnull(b.n_citations, 0) as n_citations_next, c.first_disagreement
into #cited_data
from #temp a 
left join #temp b on a.cited_doi=b.cited_doi and a.citing_year=(b.citing_year-1)
left join (
	select cited_doi, citing_year as first_disagreement
	from (
		select cited_doi, citing_year, row_number() over (partition by cited_doi order by citing_year) rk 
		from #temp
		where n_citances_d > 0 and citing_year >= pub_year
	) a
	where rk = 1
) c on a.cited_doi=c.cited_doi
where a.citing_year>=a.pub_year and a.citing_year <= 2015

drop table if exists #cited_data_nodisagreement
select 'All fields' as LR_main_field, citing_year-a.pub_year as years_passed, n_citations cits_on_event, count(*) as n_records, avg(cast(n_citations_next as float)) as cits_past_event
into #cited_data_nodisagreement
from #cited_data a join pub_field_wos_LR b on a.cited_doi=b.doi --join pub x on a.cited_doi=x.doi join match_key_wos y on x.match_key=y.match_key
where first_disagreement is null or citing_year<first_disagreement
group by citing_year-a.pub_year, n_citations
union
select LR_main_field, citing_year-a.pub_year as years_passed, n_citations cits_on_event, count(*) as n_records, avg(cast(n_citations_next as float)) as cits_past_event
from #cited_data a join pub_field_wos_LR b on a.cited_doi=b.doi --join pub x on a.cited_doi=x.doi join match_key_wos y on x.match_key=y.match_key
where first_disagreement is null or citing_year<first_disagreement
group by LR_main_field, citing_year-a.pub_year, n_citations

drop table if exists #cited_data_all
select 'All fields' as LR_main_field, citing_year-a.pub_year as years_passed, n_citations cits_on_event, count(*) as n_records, avg(cast(n_citations_next as float)) as cits_past_event
into #cited_data_all
from #cited_data a join pub_field_wos_LR b on a.cited_doi=b.doi --join pub x on a.cited_doi=x.doi join match_key_wos y on x.match_key=y.match_key
--where first_disagreement is null or citing_year<first_disagreement
group by citing_year-a.pub_year, n_citations
union
select LR_main_field, citing_year-a.pub_year as years_passed, n_citations cits_on_event, count(*) as n_records, avg(cast(n_citations_next as float)) as cits_past_event
from #cited_data a join pub_field_wos_LR b on a.cited_doi=b.doi --join pub x on a.cited_doi=x.doi join match_key_wos y on x.match_key=y.match_key
--where first_disagreement is null or citing_year<first_disagreement
group by LR_main_field, citing_year-a.pub_year, n_citations

drop table if exists #cited_data_disagreement
select 'All fields' as LR_main_field, citing_year-a.pub_year as years_passed, n_citations cits_on_event, count(*) as n_records, avg(cast(n_citations_next as float)) as cits_past_event
into #cited_data_disagreement
from #cited_data a join pub_field_wos_LR b on a.cited_doi=b.doi --join pub x on a.cited_doi=x.doi join match_key_wos y on x.match_key=y.match_key
where citing_year=first_disagreement
group by citing_year-a.pub_year, n_citations
union
select LR_main_field, citing_year-a.pub_year as years_passed, n_citations cits_on_event, count(*) as n_records, avg(cast(n_citations_next as float)) as cits_past_event
from #cited_data a join pub_field_wos_LR b on a.cited_doi=b.doi --join pub x on a.cited_doi=x.doi join match_key_wos y on x.match_key=y.match_key
where citing_year=first_disagreement
group by LR_main_field, citing_year-a.pub_year, n_citations

select 
	a.LR_main_field, --group_disagreement, 
	sum(b.n_records) as n_records_d,
	sum((a.cits_on_event)*b.n_records)/cast(sum(b.n_records) as float) as avg_cits_on_event_all, 
	sum((b.cits_on_event)*b.n_records)/cast(sum(b.n_records) as float) as avg_cits_on_event_d, 
	sum((a.cits_past_event)*b.n_records)/cast(sum(b.n_records) as float) as avg_cits_past_event_all, 
	sum((b.cits_past_event)*b.n_records)/cast(sum(b.n_records) as float) as avg_cits_past_event_d, 
	avg(b.cits_past_event-a.cits_past_event) as avg_diff_cits, 
	sum((b.cits_past_event-a.cits_past_event)*b.n_records)/cast(sum(b.n_records) as float) as weighted_avg_diff_cits, 
	(sum((b.cits_past_event)*b.n_records)/cast(sum(b.n_records) as float)) / (sum((a.cits_past_event)*b.n_records)/cast(sum(b.n_records) as float)) as avg_ratio_cits 
from #cited_data_all a
join #cited_data_disagreement b on a.years_passed=b.years_passed and a.cits_on_event=b.cits_on_event and a.LR_main_field=b.LR_main_field
group by a.LR_main_field
order by a.LR_main_field

