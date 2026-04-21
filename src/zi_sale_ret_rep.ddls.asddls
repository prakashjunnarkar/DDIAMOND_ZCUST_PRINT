@AbapCatalog.sqlViewName: 'ZV_RET_REP'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sale return report'
define view ZI_SALE_RET_REP
  as select from zmm_cust_ret as ret
{

  key ret.gentry_num,
  key ret.gentry_year,
  key ret.billingdocument,
  key ret.billingdocumentitem,
      ret.plant,
      ret.customer,
      ret.transmode,
      ret.invoiceno,
      ret.created_on,
      ret.created_time,
      ret.vehno,
      ret.driverno,
      ret.transporter,
      ret.challandate,
      ret.check_rc,
      ret.check_pollt,
      ret.check_tripal,
      ret.check_insur,
      ret.check_dl,
      ret.itemno,
      ret.itemcode,
      ret.itemdesc,
      ret.orderqty,
      ret.deliveredqty,
      ret.uom
      //  ret.erdat,
      //  ret.uzeit,
      //  ret.cuname,
      //  ret.gedeleted

}
