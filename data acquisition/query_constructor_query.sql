/*****
Query constructor query for Measuring Disagreement in Science
By Nees Jan van Eck and Wout S. Lamers
*****/


/*****
Setup signal term table
*****/
if object_id('tempdb.dbo.#signal_terms', 'U') is not null drop table #signal_terms
create table #signal_terms(signal_id int identity(1,1), signal_name varchar(100), signal_terms varchar(100), query_append varchar(1000))
insert into #signal_terms values('challenge*',		'challenge*',							'')
insert into #signal_terms values('contradict*',		'contradict*',							'')
insert into #signal_terms values('contrast*',		'contrast*',							'')
insert into #signal_terms values('contrary',		'contrary',								'')
insert into #signal_terms values('conflict*',		'conflict*',							'')
insert into #signal_terms values('disagree*',		'disagree*|not agree*|no agreement', 	'AND NOT ("range" OR "scale" OR "kappa" OR "likert" OR NEAR(("agree*", "disagree*"), 10) OR NEAR(("agree*", "agree*"), 10) OR NEAR(("disagree*", "disagree*"), 10))')
insert into #signal_terms values('differ*',			'differ*',								'AND NOT ("different*")')
insert into #signal_terms values('controvers*',		'controvers*',							'')
insert into #signal_terms values('disprov*',		'disprov*',								'AND NOT NEAR(("prov*", "disprov*"), 10)')
insert into #signal_terms values('refut*',			'refut*',								'AND NOT ("refutab*")')
insert into #signal_terms values('debat*',			'debat*',								'AND NOT ("parliament* debat*" OR "congress* debat*" OR "senate* debat*" OR "polic* debat*" OR "politic* debat*" OR "public* debat*" OR "societ* debat*")')	--many of these filter just a small number of sentences and might be removed for the sake of simplicity
insert into #signal_terms values('no consensus',	'no consensus|lack of consensus',		'AND NOT ("consensus sequence" OR "consensus site")')
insert into #signal_terms values('questionable',	'questionable',							'')
select * from #signal_terms

/*****
Setup filter term table
The fifth category, 'standalone', is not included as it requires no insertions of terms into the query - it is handled in the section that puts together the queries instead.
*****/
if object_id('tempdb.dbo.#filter_terms', 'U') is not null drop table #filter_terms
create table #filter_terms (filter_id int identity(1,1), filter_name varchar(100), filter_terms varchar(1000))
insert into #filter_terms values ('studies',	'studies|study|previous work|earlier work|literature|analysis|analyses|report|reports')
insert into #filter_terms values ('results',	'result|results|finding|findings|outcome|outcomes|evidence|data|conclusion|conclusions|observation|observations')
insert into #filter_terms values ('methods',	'model|models|method|methods|approach|approaches|technique|techniques')
insert into #filter_terms values ('ideas',		'idea|ideas|theory|theories|assumption|assumptions|hypothesis|hypotheses')
select * from #filter_terms

/*****	
Declare global variables for setup
For negation, here is where we define the generic negation terms that we want to ignore, their distance, and whether they should appear exclusively before the signal terms.
*****/
declare @near_dist					varchar(10)		= '4'
declare @generic_negation_terms		varchar(1000)	= 'no|not|cannot|nor|neither'
declare @generic_negation_dist		varchar(10)		= '2'
declare @generic_negation_order		varchar(10)		= 'FALSE'

/*****	
Set up generic negation template for disagreement signal terms
The query splits bits off of the original term by pipes, handles them, and discards them sequentially until there are no pipes left, at which point we have processed all terms.
This is the approach I use throughout this query to handle lists of signal and filter terms, as you will see in the section following this one.
*****/
declare @generic_negation_template	varchar(1000)	= ''
while charindex('|', @generic_negation_terms) != 0
begin
	set @generic_negation_template = @generic_negation_template + 'NEAR(("' + left(@generic_negation_terms, charindex('|', @generic_negation_terms)-1) + '", "@"), ' + @generic_negation_dist + ', ' + @generic_negation_order + ') OR '
	set @generic_negation_terms = right(@generic_negation_terms, len(@generic_negation_terms)-charindex('|', @generic_negation_terms))
end
set @generic_negation_template = @generic_negation_template + 'NEAR(("' + @generic_negation_terms + '", "@"), ' + @generic_negation_dist + ', ' + @generic_negation_order + ') '

/*****
For each group of disagreement signal terms, build a query builder template and fill the generic negation template
*****/	
declare @signal_id int = 1
while @signal_id <= (select max(signal_id) from #signal_terms)
begin
	declare @signal_name	varchar(100)	= (select signal_name	from #signal_terms where signal_id = @signal_id)
	declare @query_terms	varchar(1000)	= (select signal_terms	from #signal_terms where signal_id = @signal_id)
	declare @query_append	varchar(1000)	= (select query_append	from #signal_terms where signal_id = @signal_id)
	declare @query_builder	varchar(max)	= ''
	declare @query_negation	varchar(max) 	= ''

	while charindex('|', @query_terms) != 0
	begin
		set @query_builder = @query_builder + 'NEAR(("' + left(@query_terms, charindex('|', @query_terms)-1) + '", "@"), ' + @near_dist + ') OR '
		set @query_negation = @query_negation + replace(@generic_negation_template, '@', left(@query_terms, charindex('|', @query_terms)-1)) + 'OR '
		set @query_terms = right(@query_terms, len(@query_terms)-charindex('|', @query_terms))
	end
	set @query_builder = @query_builder + 'NEAR(("' + @query_terms + '", "@"), ' + @near_dist + ') '
	set @query_negation = 'AND NOT (' + @query_negation + replace(@generic_negation_template, '@', @query_terms) + ') ' + @query_append

	/*****
	Then fill the query builder with approporiate disagreement filter phrases for each filter group
	*****/
	declare @query_reinforced varchar(max)
	declare @filter_terms varchar(1000)
	declare @filter_name varchar(100)
	declare @filter_id int = 1

	while @filter_id <= (select max(filter_id) from #filter_terms)
	begin

				
		set @query_reinforced = ''
		set @filter_terms = (select filter_terms from #filter_terms where filter_id = @filter_id)
		set @filter_name = (select filter_name from #filter_terms where filter_id = @filter_id)
				
		while charindex('|', @filter_terms) != 0
		begin
			set @query_reinforced = @query_reinforced + replace(@query_builder, '@', left(@filter_terms, charindex('|', @filter_terms)-1)) + 'OR '
			set @filter_terms = right(@filter_terms, len(@filter_terms)-charindex('|', @filter_terms))
		end
		set @query_reinforced = @query_reinforced + replace(@query_builder, '@', @filter_terms)
				
		insert into fulltext_project_query 
			(signal_id, signal_name, filter_id, filter_name, query)
		select @signal_id, @signal_name, @filter_id, @filter_name, '( ' + @query_reinforced + ') ' + @query_negation

		set @filter_id += 1

	end

	set @query_builder  = ''
	set @query_negation	= ''
	set @query_terms	= (select signal_terms	from #signal_terms where signal_id = @signal_id)

	while charindex('|', @query_terms) != 0
	begin
		set @query_builder = @query_builder + '"' + left(@query_terms, charindex('|', @query_terms)-1) + '" OR '
		set @query_negation = @query_negation + replace(@generic_negation_template, '@', left(@query_terms, charindex('|', @query_terms)-1)) + 'OR '
		set @query_terms = right(@query_terms, len(@query_terms)-charindex('|', @query_terms))
	end
	set @query_builder = '(' + @query_builder + '"' + @query_terms + '") '
	set @query_negation = 'AND NOT ( ' + @query_negation + replace(@generic_negation_template, '@', @query_terms) + ') ' + @query_append

	insert into fulltext_project_query
		(signal_id, signal_name, filter_id, filter_name, query)
	select @signal_id, @signal_name, 5, 'standalone', @query_builder + @query_negation

	set @signal_id += 1
end

select * from fulltext_project_query order by query_id

/*****
Run the queries and store the results
*****/	
drop table if exists fulltext_project_pub_sentence_query
create table fulltext_project_pub_sentence_query(query_id int, doi varchar(100), sentence_seq smallint)

declare @n_queries int = (select max(query_id) from fulltext_project_query)
declare @ii int = 1
while @ii <= @n_queries
begin
	declare @queryy varchar(5000) = (select query from fulltext_project_query where (query_id = @ii))
	
	insert into fulltext_project_pub_sentence_query
	select @ii, b.doi, b.sentence_seq--, [text]
	from pub_selection a 
	join pub_sentence b on a.doi=b.doi
	where contains(text, @queryy)

	declare @message varchar(100) = 'Processed query ' + cast(@ii as varchar(10))
	raiserror (@message, 0, 1) with nowait

	set @ii += 1
end		

/****
Validity scores and flags
****/	
drop table if exists fulltext_project_query_validity
create table fulltext_project_query_validity(query_id int identity(1,1), query_name varchar(100), validity_score float, valid80 bit, valid75 bit, valid70 bit)

insert into fulltext_project_query_validity
--values(query_name, agreement_score, validity_score, valid80, valid75, valid70)
select a.query_name, b.validity as validity_score, case when b.validity >= 80 then 1 else 0 end valid80, case when b.validity >= 75 then 1 else 0 end valid75, case when b.validity >= 70 then 1 else 0 end valid70
from (
	select *, concat(signal_name, ' + ', filter_name) as query_name 
	from fulltext_project_query
) a
left join signal_phrase_agreement b on a.signal_name=b.signal_name and a.filter_name=b.filter_name
order by query_id

/*****
Let's count the results each query delivers
*****/
select a.*, [1 studies], [2 results], [3 methods], [4 ideas], [total], [5 standalone]
from #signal_terms a
left join (
	select a.signal_id, 
		max(case when filter_id != 1 then 0 else n_results end) as [1 studies], 
		max(case when filter_id != 2 then 0 else n_results end) as [2 results], 
		max(case when filter_id != 3 then 0 else n_results end) as [3 methods], 
		max(case when filter_id != 4 then 0 else n_results end) as [4 ideas], 
		max(case when filter_id != 5 then 0 else n_results end) as [5 standalone]
	from #signal_terms a
	join fulltext_project_query b on a.signal_id=b.signal_id
	join (select query_id, count(*) as n_results from fulltext_project_pub_sentence_query group by query_id) c on b.query_id = c.query_id
	group by a.signal_id
) b on a.signal_id = b.signal_id
left join (
	select signal_id, count(*) as total
	from(
		select distinct a.signal_id, b.doi, b.sentence_seq
		from fulltext_project_query a
		join fulltext_project_pub_sentence_query b on a.query_id = b.query_id
		where filter_id != 5
	) w
	group by signal_id
) c on a.signal_id = c.signal_id
order by a.signal_id

/*****
Selection of random results for coding
*****/ 
declare @n_queries int = (select max(query_id) from fulltext_project_query)
declare @ii int = 1
while @ii <= @n_queries
begin
	
	select top 100 a.query_id, a.signal_id, a.signal_name, a.filter_id as filter_id, a.filter_name as filter_name, '' as code_1, '' as code_2, c.*
	from (select * from fulltext_project_query where query_id = @ii) a
	join fulltext_project_pub_sentence_query b on a.query_id = b.query_id
	join projectdb_tdm_elsevier..pub_sentence c on b.doi=c.doi and b.sentence_seq=c.sentence_seq
	order by newid()

	declare @message varchar(100) = 'Processed query ' + cast(@ii as varchar(10))
	raiserror (@message, 0, 1) with nowait

	set @ii += 1
end	
