@AbapCatalog.sqlViewName: 'ZV_NRGP_REP'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'nrgp Report'
@Metadata.ignorePropagatedAnnotations: true
define view ZI_NRGP_REPORT
  as select from zmm_nrgp_data as nrgp
{
      @UI.selectionField  : [{ position: 20 }]
      @EndUserText.label: 'NRGP No.'
      @UI.lineItem   : [{ position: 10, label: 'NRGP No.' }]
  key nrgp.nrgp_num          as nrgpNum,

      //      @UI.lineItem   : [{ position: 10, label: 'nrgp Year' }]
  key nrgp.nrgp_year         as nrgpYear,

      @UI.selectionField  : [{ position: 30 }]
      @EndUserText.label: 'PR No.'
      @UI.lineItem   : [{ position: 20, label: 'Purchase Req. No.' }]
  key nrgp.prnum,

      @UI.lineItem   : [{ position: 30, label: 'Purchase Req. Item' }]
  key nrgp.pritem            as Pritem,

      @UI.lineItem   : [{ position: 70, label: 'Item code' }]
  key nrgp.matnr             as Matnr,

      @UI.selectionField  : [{ position: 40 }]
      @EndUserText.label: 'Plant.'
      @UI.lineItem   : [{ position: 40, label: 'Plant' }]
      nrgp.werks             as Werks,

      @UI.selectionField  : [{ position: 50 }]
      @EndUserText.label: 'NRGP Date'
      @UI.lineItem   : [{ position: 160, label: 'NRGP Date' }]
      nrgp.nrgp_creationdate as nrgpCreationdate,

      @UI.selectionField  : [{ position: 10 }]
      @EndUserText.label: 'Vendor.'
      @UI.lineItem   : [{ position: 50, label: 'Vendor Code' }]
      nrgp.lifnr             as Lifnr,

      @UI.lineItem   : [{ position: 60, label: 'Vendor Description' }]
      nrgp.vendor_name       as VendorName,

      @UI.lineItem   : [{ position: 80, label: 'Item Description' }]
      nrgp.maktx             as Maktx,

      @UI.lineItem   : [{ position: 90, label: 'HSN Code' }]
      nrgp.hsncode           as Hsncode,

      @UI.lineItem   : [{ position: 100, label: 'UOM' }]
      nrgp.uom               as Uom,

      @UI.lineItem   : [{ position: 110, label: 'Qty' }]
      nrgp.prqty             as Prqty,


      @UI.lineItem   : [{ position: 120, label: 'Net Price' }]
      nrgp.netprice          as Netprice,

      @UI.lineItem   : [{ position: 130, label: 'Tax Code' }]
      nrgp.taxcode           as Taxcode,

      @UI.lineItem   : [{ position: 140, label: 'Gross Value' }]
      nrgp.grossvalue        as Grossvalue,

      @UI.lineItem   : [{ position: 150, label: 'Total Value' }]
      nrgp.tot_val           as TotVal,

      @UI.lineItem   : [{ position: 170, label: 'Vehicle No.' }]
      nrgp.vechnum           as Vechnum,

      @UI.lineItem   : [{ position: 180, label: 'Driver Name' }]
      nrgp.driver_name       as DriverName,

      @UI.lineItem   : [{ position: 180, label: 'Driver No.' }]
      nrgp.driver_num        as DriverNum,

      @UI.lineItem   : [{ position: 190, label: 'Requested By' }]
      nrgp.requestedby       as Requestedby,

      @UI.lineItem   : [{ position: 200, label: 'Purpose' }]
      nrgp.purpose           as Purpose,

      @UI.lineItem   : [{ position: 210, label: 'Through' }]
      nrgp.through           as Through,

      ////      @UI.lineItem   : [{ position: 220, label: 'Exp. Return Date' }]
      ////      nrgp.exp_returndate      as ExpReturndate,

      @UI.lineItem   : [{ position: 230, label: 'Gross Weight' }]
      nrgp.gross_wgt         as GrossWgt,

      @UI.lineItem   : [{ position: 240, label: 'Tare Weight' }]
      nrgp.tare_wgt          as TareWgt,

      @UI.lineItem   : [{ position: 250, label: 'Net Weight' }]
      nrgp.net_wgt           as NetWgt,

      @UI.lineItem   : [{ position: 260, label: 'Vehicle Out Flag' }]
      nrgp.vechout           as Vechout,

      @UI.lineItem   : [{ position: 270, label: 'Vehicle Out Date' }]
      nrgp.vehiout_date      as VehioutDate,

      @UI.lineItem   : [{ position: 280, label: 'Vehicle Out Time' }]
      nrgp.vehiout_time      as VehioutTime,

      @UI.lineItem   : [{ position: 290, label: 'Remarks' }]
      nrgp.remarks           as Remarks

}

where
  nrgp.nrgpdeleted = ''
