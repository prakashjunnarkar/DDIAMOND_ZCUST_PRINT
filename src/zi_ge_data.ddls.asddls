@AbapCatalog.sqlViewName: 'ZV_GE_DATA'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Gate entry view'
define root view ZI_GE_DATA
  as select from    zmm_ge_data as gehdr
{

  key gehdr.gentry_num,
  key gehdr.gentry_year,
  key gehdr.ponum,
  key gehdr.poitem,

      gehdr.created_on,
      gehdr.created_time,
      gehdr.out_date,
      gehdr.out_time,
      gehdr.werks,
      gehdr.lifnr,
      gehdr.billnum,
      gehdr.billdate,
      gehdr.ewaybill_num,
      gehdr.vechnum,
      gehdr.transporter,
      gehdr.driver_name,
      gehdr.driver_num,
      gehdr.trans_mode,
      gehdr.lr_num,
      gehdr.lr_date,
      gehdr.gross_wgt,
      gehdr.tare_wgt,
      gehdr.net_wgt,
      gehdr.weight_uom,
      gehdr.check_rc,
      gehdr.check_pollt,
      gehdr.check_tripal,
      gehdr.check_insur,
      gehdr.check_dl,
      gehdr.uname,

      gehdr.matnr,
      gehdr.maktx,
      gehdr.itemdesc,
      gehdr.docdate,
      gehdr.poqty,
      gehdr.uom,
      gehdr.ovrtol,
      gehdr.netprice,
      gehdr.currcy,
      gehdr.perqty,
      gehdr.openqty,
      gehdr.valtyp,
      gehdr.challnqty,
      gehdr.sloc,
      gehdr.mweight

} where gehdr.gedeleted = ''
