--need to limit adjustment types - we do want to reflect a gau change but account changes don't seem to pull in correctly?
--late entered gifts
--remove parent and final amount once script is final/dont need them for troubleshooting


/* generate affiliate c3 file */
SELECT 
acc.c3_affiliate_number as home_c3_affiliate,
opp.accountid as account_id,
acc.auto_account_number as sf_account_number,
opp.affiliate_number as affiliate_id,
acc.rc_bios__preferred_contact_ema as email,
con.title as title,
con.firstname as first,
con.lastname as last,
con.mailingstreet as add1,
con.mailingcity as city,
con.mailingstate as state,
con.mailingpostalcode as zip,
acc.rc_bios__preferred_contact_pho as phone,
par.rc_giving__expected_giving_amo::decimal(19,2) as parent_original_amount,
opp.amount::decimal(19,2) as amount, --probably base calculation on this
opp.final_amount as opp_final_amount,
(case when opp.gau_credit_code in ('C325015','C340100TR422ONL') then (opp.amount *1)::decimal(19,2)
when opp.gau_credit_code ='C340100UR422ONL' then (opp.amount *.546)::decimal(19,2)
 else null end) as payout_amount,
opp.gau_credit_code as gau_credit_code,
opp.closedate::date as gift_date,
opp.id as sf_gift_id,
par.acquired_batch_seq as contribution_id,
opp.gau_debit_code,
(case when (opp.gau_debit_code in ('C312610', 'C312615') OR opp.gau_credit_code='C340100TR422ONL' OR par.originator<>'EveryAction') then 'TRUE'
 else null end) as printable_form_gift,
alt.valuex as eavan_id,
par.originator,
opp.adjustment_type,
opp.adjustment_date,
null as subledger_universe,
null as subgau_1

FROM rounddata.opportunity opp 
left join (select * from rounddata.opportunity where recordtypeid='01236000001HtyQAAS') par on opp.rc_giving__parent=par.id
left join rounddata.accountx acc on opp.accountid=acc.id
left join rounddata.contact con on acc.rc_bios__preferred_contact=con.id
left join (select * from (select *,row_number() over (partition by accountx order by createddate desc, lastmodifieddate desc) as rank from rounddata.alternate_id where active='true' and typex='Van') where rank=1) alt on opp.accountid=alt.accountx
where opp.gau_credit_code in ('C325015', 'C340100UR422ONL','C340100TR422ONL')
and opp.closedate::date >= '{{calendar_year}}-{{calendar_month}}-01 00:00:00'
and opp.closedate::date < '{{calendar_year}}-{{end_month}}-01 00:00:00'
and opp.createddate < '{{calendar_year}}-{{end_month}}-15 00:00:00' --allow 15 days for gift entry, late entered gifts piece will pull in the rest
and opp.recordtypeid='01236000001HtyZAAS'
and opp.delete_flag<>'Y'
--and (opp.affiliate_number like '09%' or opp.affiliate_number like '9____')

union

/*** LATE ADJUSTMENTS ***/
/* gifts made before month X but adjusted between month X+15d and X+1m15d */

SELECT 
acc.c3_affiliate_number as home_c3_affiliate,
opp.accountid as account_id,
acc.auto_account_number as sf_account_number,
opp.affiliate_number as affiliate_id,
acc.rc_bios__preferred_contact_ema as email,
con.title as title,
con.firstname as first,
con.lastname as last,
con.mailingstreet as add1,
con.mailingcity as city,
con.mailingstate as state,
con.mailingpostalcode as zip,
acc.rc_bios__preferred_contact_pho as phone,
par.rc_giving__expected_giving_amo::decimal(19,2) as parent_original_amount,
coalesce(sub.amount,opp.amount)::decimal(19,2) as amount, --probably base calculation on this
opp.final_amount as opp_final_amount,
(case when opp.gau_credit_code in ('C325015','C340100TR422ONL') then (sub.amount *1)::decimal(19,2)
when opp.gau_credit_code ='C340100UR422ONL' then (sub.amount *.546)::decimal(19,2)
 else null end) as payout_amount,
coalesce(sub.gau_1,opp.gau_credit_code) as gau_credit_code,
opp.closedate::date as gift_date,
opp.id as sf_gift_id,
par.acquired_batch_seq as contribution_id,
opp.gau_debit_code,
(case when (opp.gau_debit_code in ('C312610', 'C312615') OR opp.gau_credit_code='C340100TR422ONL' OR par.originator<>'EveryAction') then 'TRUE'
 else null end) as printable_form_gift,
alt.valuex as eavan_id,
par.originator,
opp.adjustment_type,
opp.adjustment_date,
sub.subledger_universe,
sub.gau_1 as subgau1

FROM (select * from rounddata.subledger where subledger_universe <> 'New Transaction') sub
inner join rounddata.opportunity opp on opp.id=sub.transaction_id 
left join (select * from rounddata.opportunity where recordtypeid='01236000001HtyQAAS') par on opp.rc_giving__parent=par.id
left join rounddata.accountx acc on opp.accountid=acc.id
left join rounddata.contact con on acc.rc_bios__preferred_contact=con.id
left join (select * from (select *,row_number() over (partition by accountx order by createddate desc, lastmodifieddate desc) as rank from rounddata.alternate_id where active='true' and typex='Van') where rank=1) alt on opp.accountid=alt.accountx
where (opp.gau_credit_code in ('C325015', 'C340100UR422ONL','C340100TR422ONL') OR sub.gau_1 in ('C325015', 'C340100UR422ONL','C340100TR422ONL'))
and ((opp.closedate::date < '{{calendar_year}}-{{calendar_month}}-01 00:00:00' AND sub.adjustment_date::date >= '{{calendar_year}}-{{calendar_month}}-15 00:00:00' AND sub.adjustment_date::date < '{{calendar_year}}-{{end_month}}-15 00:00:00') -- late adjustments
OR (opp.closedate::date < '{{calendar_year}}-{{calendar_month}}-01 00:00:00' AND opp.createddate >= '{{calendar_year}}-{{calendar_month}}-15 00:00:00' AND opp.createddate < '{{calendar_year}}-{{end_month}}-15 00:00:00')) --late entries
and opp.recordtypeid='01236000001HtyZAAS'
and opp.delete_flag<>'Y'
and ((opp.adjustment_type='Refund' and sub.subledger_universe='Refund') OR (opp.adjustment_type<>'Refund'))
--and (opp.affiliate_number like '09%' or opp.affiliate_number like '9____')

order by affiliate_id asc, gift_date asc
