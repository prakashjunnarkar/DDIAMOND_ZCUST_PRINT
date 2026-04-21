@AbapCatalog.sqlViewName: 'ZV_SCHAGR_QTY'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Schedule line qty'
define view ZI_SCHAGR_QTY as select from I_SchedglineApi01 as schd
{

key schd.SchedulingAgreement,
key schd.SchedulingAgreementItem,
sum(schd.ScheduleLineOrderQuantity) as ScheduleLineOrderQuantity

}

group by 
schd.SchedulingAgreement,
schd.SchedulingAgreementItem
