@AbapCatalog.sqlViewName: 'ZV_RGPOUT_REP'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RGP Out Report'
@Metadata.ignorePropagatedAnnotations: true
define view ZI_RGP_out_REPORT
  as select from zmm_rgp_data as rgpout

{

      @UI.selectionField  : [{ position: 20 }]
      @EndUserText.label  : 'RGP Out No.'
      @UI.lineItem        : [{ position: 10, label: 'RGP Out No.' }]
  key rgpout_num as RgpoutNum,

      @UI.lineItem        : [{ position: 10, label: 'RGPOUT Year' }]
  key rgpout_year as RgpoutYear,

      @UI.selectionField  : [{ position: 30 }]
      @EndUserText.label  : 'PR No.'
      @UI.lineItem        : [{ position: 20, label: 'Purchase Req. No.' }]
  key prnum as Prnum,
  
      @UI.lineItem        : [{ position: 30, label: 'Purchase Req. Item' }]
 key pritem as Pritem,

      @UI.adaptationHidden: true
  key rgpin_num as RgpinNum,

      @UI.adaptationHidden: true
 key rgpin_year as RgpinYear,

      @UI.lineItem        : [{ position: 70, label: 'Item code' }]
   key matnr as Matnr,

      @UI.selectionField  : [{ position: 40 }]
      @EndUserText.label  : 'Plant.'
      @UI.lineItem        : [{ position: 40, label: 'Plant' }]
      werks               as Werks,

      @UI.selectionField  : [{ position: 50 }]
      @EndUserText.label  : 'RGP Out Date'
      @UI.lineItem        : [{ position: 160, label: 'RGP Out Date' }]
      rgpout_creationdate as RgpoutCreationdate,

      @UI.selectionField  : [{ position: 10 }]
      @EndUserText.label  : 'Vendor.'
      @UI.lineItem        : [{ position: 50, label: 'Vendor Code' }]
      lifnr               as Lifnr,

      @UI.lineItem        : [{ position: 60, label: 'Vendor Description' }]
      vendor_name         as VendoName,

      @UI.lineItem        : [{ position: 80, label: 'Item Description' }]
      maktx               as Maktx,

      @UI.lineItem        : [{ position: 90, label: 'HSN Code' }]
      hsncode             as Hsncode,

      @UI.lineItem        : [{ position: 100, label: 'UOM' }]
      uom                as Uom,
      @UI.lineItem        : [{ position: 110, label: 'Qty' }]
     
      prqty               as Prqty,

      @UI.lineItem        : [{ position: 120, label: 'Net Price' }]
      netprice            as Netprice,

      @UI.lineItem        : [{ position: 130, label: 'Tax Code' }]
      taxcode             as Taxcode,

      @UI.lineItem        : [{ position: 140, label: 'Gross Value' }]
      grossvalue          as Grossvalue,

      @UI.lineItem        : [{ position: 150, label: 'Total Value' }]
      tot_val             as TotVal,


      @UI.lineItem        : [{ position: 170, label: 'Vehicle No.' }]
      vechnum             as Vechnum,


      @UI.lineItem        : [{ position: 180, label: 'Driver Name' }]
      driver_name         as DriverName,

      @UI.lineItem        : [{ position: 180, label: 'Driver No.' }]
      driver_num          as DriverNum,

      @UI.lineItem        : [{ position: 190, label: 'Requested By' }]
      requestedby         as Requestedby,

      @UI.lineItem        : [{ position: 200, label: 'Purpose' }]
      purpose             as Purpose,

      @UI.lineItem        : [{ position: 210, label: 'Through' }]
      through             as Through,

      @UI.lineItem        : [{ position: 220, label: 'Exp. Return Date' }]
      exp_returndate      as ExpReturndate,

      @UI.lineItem        : [{ position: 230, label: 'Gross Weight' }]
      gross_wgt           as Grosswgt,

      @UI.lineItem        : [{ position: 240, label: 'Tare Weight' }]
      tare_wgt            as TareWgt,

      @UI.lineItem        : [{ position: 250, label: 'Net Weight' }]
      net_wgt             as NetWgt,

      @UI.lineItem        : [{ position: 260, label: 'Vehicle Out Flag' }]
      vechout             as Vechout,
      
      @UI.lineItem        : [{ position: 270, label: 'Vehicle Out Date' }]
      vehiout_date        as VehioutDate,

      @UI.lineItem        : [{ position: 280, label: 'Vehicle Out Time' }]
      vehiout_time        as VechioutTime,

      @UI.lineItem        : [{ position: 290, label: 'Remarks' }]
      remarks             as Remarks           

}

where  rgpoutdeleted = ''
      and rgpindeleted  = ''
      and rgpin_num     = ''
