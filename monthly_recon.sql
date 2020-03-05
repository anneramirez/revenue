--need to limit adjustment types - we do want to reflect a gau change but account changes don't seem to pull in correctly?
-- ^ it's pulling in the gau change rows to gaus we don't want
-- in first script piece, adjustments made after timeframe in LAR piece are still pulling in - but then they'll pull in next month too right? ex: 0061R00000tBY4YQAW

--remove final amount once script is final/dont need them for troubleshooting

---- 03/05/2020 NOTES
---pulling sub.gift id for one piece and opp.id on the other - could that throw things off?
----giving_id is PARENT, transaction_id is CHILD


/* generate affiliate c3 file */
/*** New Gifts and LATE ENTRIES ***/
/* gifts made before month X but entered between month X+15d and X+1m15d */

SELECT 
acc.c3_affiliate_number as home_c3_affiliate,
sub.account_id,
acc.auto_account_number as sf_account_number,
sub.affiliate_number as affiliate_id,
acc.rc_bios__preferred_contact_ema as email,
con.title as title,
con.firstname as first,
con.lastname as last,
con.mailingstreet as add1,
con.mailingcity as city,
con.mailingstate as state,
con.mailingpostalcode as zip,
acc.rc_bios__preferred_contact_pho as phone,
sub.amount::decimal(19,2) as amount, 
opp.final_amount as opp_final_amount,
(case when sub.gau_1 in ('C325015','C340100TR422ONL') then (sub.amount *1)::decimal(19,2)
when sub.gau_1 ='C340100UR422ONL' then (sub.amount *.546)::decimal(19,2)
 else null end) as payout_amount,
sub.gau_1 as gau_credit_code,
sub.close_date::date as gift_date,
sub.transaction_id as sf_gift_id,
par.acquired_batch_seq as contribution_id,
sub.gau_2 as gau_debit_code,
(case when (sub.gau_2 in ('C312610', 'C312615') OR sub.gau_1='C340100TR422ONL' OR par.originator<>'EveryAction') then 'TRUE'
 else null end) as printable_form_gift,
alt.valuex as eavan_id,
par.originator,
opp.createddate,
opp.adjustment_type,
opp.adjustment_date,
sub.adjustment_date,
sub.subledger_universe,
sub.gau_1 as subgau1

FROM rounddata.subledger sub
inner join rounddata.opportunity opp on opp.id=sub.transaction_id 
left join (select * from rounddata.opportunity where recordtypeid='01236000001HtyQAAS') par on opp.rc_giving__parent=par.id
left join rounddata.accountx acc on sub.account_id=acc.id
left join rounddata.contact con on acc.rc_bios__preferred_contact=con.id
left join (select * from (select *,row_number() over (partition by contact order by createddate desc, lastmodifieddate desc) as rank from rounddata.alternate_id where active='true' and typex='Van') where rank=1) alt on con.id=alt.contact
where ((sub.affiliate_number in ('090030','090330','090430','091410','091460') and sub.gau_1 in ('C325015','C340100TR422ONL')) OR (sub.affiliate_number not in ('090030','090330','090430','091410','091460') and sub.gau_1 in ('C325015','C340100UR422ONL','C340100TR422ONL')))
and ((sub.close_date::date >= '{{calendar_year}}-{{calendar_month}}-01 00:00:00' and sub.close_date::date < '{{end_year}}-{{end_month}}-01 00:00:00' and opp.createddate < '{{end_year}}-{{end_month}}-16 00:00:00')
OR (sub.close_date::date < '{{calendar_year}}-{{calendar_month}}-01 00:00:00' AND opp.createddate >= '{{calendar_year}}-{{calendar_month}}-16 00:00:00' AND opp.createddate < '{{end_year}}-{{end_month}}-16 00:00:00')) --late entries
and opp.recordtypeid='01236000001HtyZAAS'
and opp.delete_flag<>'Y'
and ((sub.adjustment_type='Refund' and sub.subledger_universe='Refund') OR (sub.adjustment_type<>'Refund') OR (sub.adjustment_type is null))
and (sub.adjustment_date is null or sub.adjustment_date < '{{end_year}}-{{end_month}}-16 00:00:00')

--and (opp.affiliate_number like '09%' or opp.affiliate_number like '9____')


union

/*** LATE ADJUSTMENTS ***/
/* gifts made before month X but adjusted between month X+15d and X+1m15d */

SELECT 
acc.c3_affiliate_number as home_c3_affiliate,
sub.account_id,
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
coalesce(sub.amount,opp.amount)::decimal(19,2) as amount, 
opp.final_amount as opp_final_amount,
(case when sub.gau_1 in ('C325015','C340100TR422ONL') then (sub.amount *1)::decimal(19,2)
when sub.gau_1 ='C340100UR422ONL' then (sub.amount *.546)::decimal(19,2)
 else null end) as payout_amount,
sub.gau_1 as gau_credit_code,
opp.closedate::date as gift_date,
opp.id as sf_gift_id,
par.acquired_batch_seq as contribution_id,
opp.gau_debit_code,
(case when (opp.gau_debit_code in ('C312610', 'C312615') OR opp.gau_credit_code='C340100TR422ONL' OR par.originator<>'EveryAction') then 'TRUE'
 else null end) as printable_form_gift,
alt.valuex as eavan_id,
par.originator,
opp.createddate,
opp.adjustment_type,
opp.adjustment_date,
sub.adjustment_date,
sub.subledger_universe,
sub.gau_1 as subgau1

FROM (select * from rounddata.subledger where subledger_universe <> 'New Transaction') sub
inner join rounddata.opportunity opp on opp.id=sub.transaction_id 
left join (select * from rounddata.opportunity where recordtypeid='01236000001HtyQAAS') par on opp.rc_giving__parent=par.id
left join rounddata.accountx acc on sub.account_id=acc.id
left join rounddata.contact con on acc.rc_bios__preferred_contact=con.id
left join (select * from (select *,row_number() over (partition by contact order by createddate desc, lastmodifieddate desc) as rank from rounddata.alternate_id where active='true' and typex='Van') where rank=1) alt on con.id=alt.contact
where ((sub.affiliate_number in ('090030','090330','090430','091410','091460') and sub.gau_1 in ('C325015','C340100TR422ONL')) OR (sub.affiliate_number not in ('090030','090330','090430','091410','091460') and sub.gau_1 in ('C325015','C340100UR422ONL','C340100TR422ONL')))
and (opp.closedate::date < '{{calendar_year}}-{{calendar_month}}-01 00:00:00' AND sub.adjustment_date::date >= '{{calendar_year}}-{{calendar_month}}-16 00:00:00' AND sub.adjustment_date::date < '{{end_year}}-{{end_month}}-16 00:00:00') -- late adjustments
and opp.recordtypeid='01236000001HtyZAAS'
and opp.delete_flag<>'Y'
and ((sub.adjustment_type='Refund' and sub.subledger_universe='Refund') OR (sub.adjustment_type<>'Refund'))
and sub.adjustment_type<>'Account Change'

order by affiliate_id asc, gift_date asc
