@AbapCatalog.sqlViewName: 'ZV_GE_REPORT'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Gate entry report'
define view ZI_GATE_ENTRY_REPORT
as select from zmm_ge_data as ge

//left outer join zmm_ge_token as getok
//on ge.gentry_num  = getok.gentry_num and
//   ge.gentry_year = getok.gentry_year

{

  key ge.gentry_num,
  key ge.gentry_year,
  key ge.ponum,
  key ge.poitem,
      ge.mblnr,
      ge.mjahr,
//      getok.insplotno,
      ge.created_on,
      ge.created_time,
      ge.out_date,
      ge.out_time,
      ge.werks,
      ge.lifnr,
      ge.billnum,
      ge.billdate,
      ge.ewaybill_num,
      ge.vechnum,
      ge.transporter,
      ge.driver_name,
      ge.driver_num,
      ge.trans_mode,
      ge.lr_num,
      ge.lr_date,
      ge.gross_wgt,
      ge.tare_wgt,
      ge.net_wgt,
      ge.weight_uom,
      ge.check_rc,
      ge.check_pollt,
      ge.check_tripal,
      ge.check_insur,
      ge.check_dl,
      ge.uname,
      ge.matnr,
      ge.maktx,
      ge.itemdesc,
      ge.docdate,
      ge.poqty,
      ge.uom,
      ge.ovrtol,
      ge.netprice,
      ge.currcy,
      ge.perqty,
      ge.openqty,
      ge.valtyp,
      ge.challnqty,
      ge.delnoteqty,
      ge.sloc,
      ge.mweight,
      ge.erdat,
      ge.uzeit,
      ge.cuname

} where ge.gedeleted = ''
