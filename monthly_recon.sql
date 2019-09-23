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
opp.final_amount as final_amount,
(case when opp.gau_credit_code in ('C325015','C340100TR422ONL') then (opp.amount *1)::decimal(19,2)
when opp.gau_credit_code ='C340100UR422ONL' then (opp.amount *.546)::decimal(19,2)
 else null end) as payout_amount,
opp.gau_credit_code as gau_credit_code,
opp.closedate::date as gift_date,
opp.id as sf_gift_id,
par.acquired_batch_seq as contribution_id,
opp.gau_debit_code,
(case when (opp.gau_debit_code in ('C312610', 'C312615') OR opp.gau_credit_code='C340100TR422ONL') then 'TRUE'
 else null end) as printable_form_gift,
alt.valuex as eavan_id,
par.originator,
opp.adjustment_type,
opp.adjustment_date

FROM rounddata.opportunity opp 
left join (select * from rounddata.opportunity where recordtypeid='01236000001HtyQAAS') par on opp.rc_giving__parent=par.id
left join rounddata.accountx acc on opp.accountid=acc.id
left join rounddata.contact con on acc.rc_bios__preferred_contact=con.id
left join (select * from (select *,row_number() over (partition by accountx order by createddate desc, lastmodifieddate desc) as rank from rounddata.alternate_id where active='true' and typex='Van') where rank=1) alt on opp.accountid=alt.accountx
where opp.gau_credit_code in ('C325015', 'C340100UR422ONL','C340100TR422ONL')
and opp.close_date_year='2019' --parameterize
and opp.close_date_month in ('April','May','June') --parameterize
and opp.recordtypeid='01236000001HtyZAAS'
and opp.delete_flag<>'Y'
and (opp.affiliate_number like '09%' or opp.affiliate_number like '9____')
order by opp.affiliate_number asc, opp.closedate asc





--union with anywhere is_refunded='true' pull in final amount from actual refund record - where is_refunded=true, pull final amount from matching record where is_refunded=false (for negative amount); match on acquired batch sequence? or giving parent id
--could continue providing reports as they are now OR switch to including original amount and final amount with an adjusted/refunded flag? maybe do a survey?

/*union

SELECT 
opp.id,
opp.accountid,
opp.closedate::date,
par.rc_giving__expected_giving_amo,
opp.final_amount,
opp.affiliate_number,
opp.gau_credit_code,
opp.gau_debit_code,
par.giving_number,
opp.rc_giving__giving_number,
par.acquired_batch_seq,
par.originator,
par.external_id
--add contact data
FROM rounddata.opportunity opp 
left join (select * from rounddata.opportunity where recordtypeid='01236000001HtyQAAS') par on opp.rc_giving__parent=par.id
--left join rounddata contacts
--left join (select * from rounddata.alternate_id) alt on opp.accountid=alt.accountx pull into single row or select one id
where (opp.gau_credit_code in ('C325015', 'C340100TR422GOP') or opp.gau_credit_code like '%ONL')
and opp.close_date_year='2019'
and opp.close_date_month='March'
and opp.recordtypeid='01236000001HtyZAAS'
and opp.adjusted='true'
and opp.is_refunded='false'
*/

/* generate master file */
/*
SELECT 
opp.id,
opp.accountid,
opp.closedate::date,
par.rc_giving__expected_giving_amo,
opp.final_amount,
opp.affiliate_number,
opp.gau_credit_code,
opp.gau_debit_code,
par.giving_number,
opp.rc_giving__giving_number,
par.acquired_batch_seq,
par.originator,
par.external_id
--add contact data
FROM rounddata.opportunity opp 
left join (select * from rounddata.opportunity where recordtypeid='01236000001HtyQAAS') par on opp.rc_giving__parent=par.id
--left join rounddata contacts
--left join (select * from rounddata.alternate_id) alt on opp.accountid=alt.accountx pull into single row or select one id
where (opp.gau_credit_code in ('C325015', 'C340100TR422GOP') or opp.gau_credit_code like '%ONL')
and opp.close_date_year='2019'
and opp.close_date_month='March'
and opp.recordtypeid='01236000001HtyZAAS'
*/