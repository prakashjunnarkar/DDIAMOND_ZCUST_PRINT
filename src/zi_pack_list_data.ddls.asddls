@AbapCatalog.sqlViewName: 'ZV_PACK_DATA'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Packing list Data'
define view ZI_PACK_LIST_DATA
  as select from zsd_pack_data as pack
{
  key pack.pack_num,
  key pack.vbeln,
  key pack.posnr,
  pack.iec,
  pack.ex_pan,
  pack.ad_code,
  pack.pre_carig_by,
  pack.vessel,
  pack.port_of_discg,
  pack.mark_no_of_cont,
  pack.pre_carrier,
  pack.port_of_load,
  pack.final_dest,
  pack.country_org,
  pack.country_of_fdest,
  pack.pay_term,
  pack.pay_mode,
  pack.des_of_goods,
  pack.no_kind_pkg,
  pack.total_pcs,
  pack.tot_net_wgt,
  pack.tot_gross_wgt,
  pack.total_vol,
  pack.pallet_no,
  pack.type_pkg,
  pack.pkg_no,
  pack.pkg_length,
  pack.pkg_width,
  pack.pkg_height,
  pack.pkg_vol,
  pack.uom,
  pack.erdate,
  pack.uzeit
  
}
