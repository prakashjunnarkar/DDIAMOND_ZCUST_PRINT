@AbapCatalog.sqlViewName: 'ZV_RGPIN_REP'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'RGP Out Report'
@Metadata.ignorePropagatedAnnotations: true
define view ZI_RGPin_REPORT
  as select from zmm_rgp_data as RGPIn
{
      @UI.selectionField  : [{ position: 20 }]
      @EndUserText.label: 'RGP Out No.'
      @UI.lineItem   : [{ position: 20, label: 'RGP Out No.' }]
  key RGPIn.rgpout_num          as RgpoutNum,

      //      @UI.lineItem   : [{ position: 10, label: 'RGPOUT Year' }]
      @UI.adaptationHidden: true
  key RGPIn.rgpout_year         as RgpoutYear,

      @UI.selectionField  : [{ position: 40 }]
      @EndUserText.label: 'PR No.'
      @UI.lineItem   : [{ position: 30, label: 'Purchase Req. No.' }]
  key RGPIn.prnum,

      @UI.lineItem   : [{ position: 40, label: 'Purchase Req. Item' }]
  key RGPIn.pritem              as Pritem,

      @UI.selectionField  : [{ position: 30 }]
      @EndUserText.label: 'RGP In No.'
      @UI.lineItem   : [{ position: 10, label: 'RGP In No.' }]
  key RGPIn.rgpin_num           as RgpinNum,

      @UI.adaptationHidden: true
  key RGPIn.rgpin_year          as RgpinYear,

      @UI.lineItem   : [{ position: 80, label: 'Item code' }]
  key RGPIn.matnr               as Matnr,

      @UI.selectionField  : [{ position: 50 }]
      @EndUserText.label: 'Plant.'
      @UI.lineItem   : [{ position: 50, label: 'Plant' }]
      RGPIn.werks               as Werks,

      @UI.selectionField  : [{ position: 60 }]
      @EndUserText.label: 'RGP Out Date'
      @UI.lineItem   : [{ position: 140, label: 'RGP Out Date' }]
      RGPIn.rgpout_creationdate as RgpoutCreationdate,

      @UI.selectionField  : [{ position: 10 }]
      @EndUserText.label: 'Vendor.'
      @UI.lineItem   : [{ position: 60, label: 'Vendor Code' }]
      RGPIn.lifnr               as Lifnr,

      @UI.lineItem   : [{ position: 70, label: 'Vendor Description' }]
      RGPIn.vendor_name         as VendorName,

      @UI.lineItem   : [{ position: 90, label: 'Item Description' }]
      RGPIn.maktx               as Maktx,


      @UI.lineItem   : [{ position: 100, label: 'UOM' }]
      RGPIn.uom                 as Uom,

      @UI.lineItem   : [{ position: 110, label: 'RGP Out Qty' }]
      RGPIn.prqty               as Prqty,


      @UI.lineItem   : [{ position: 120, label: 'Recieve Qty' }]
      RGPIn.recqty              as Recqty,


      @UI.lineItem   : [{ position: 130, label: 'Balance Qty' }]
      RGPIn.balqty              as Balqty,

      @UI.lineItem   : [{ position: 150, label: 'RGP In Date' }]
      RGPIn.rgpin_creationdate  as RgpinCreationdate,

      ////
      ////      @UI.lineItem   : [{ position: 120, label: 'Net Price' }]
      ////      RGPOUT.netprice           as Netprice,
      ////
      ////      @UI.lineItem   : [{ position: 130, label: 'Tax Code' }]
      ////      RGPOUT.taxcode            as Taxcode,
      ////
      ////      @UI.lineItem   : [{ position: 140, label: 'Gross Value' }]
      ////      RGPOUT.grossvalue         as Grossvalue,
      ////
      ////      @UI.lineItem   : [{ position: 150, label: 'Total Value' }]
      ////      RGPOUT.tot_val            as TotVal,



      @UI.lineItem   : [{ position: 160, label: 'Vehicle No.' }]
      RGPIn.rinvechnum          as Rinvechnum,

      @UI.lineItem   : [{ position: 170, label: 'Driver Name' }]
      RGPIn.rindriver_name      as DriverName,

      @UI.lineItem   : [{ position: 180, label: 'Driver No.' }]
      RGPIn.rindriver_num       as DriverNum,

      @UI.lineItem   : [{ position: 190, label: 'Requested By' }]
      RGPIn.rinrequestedby      as Requestedby,

      @UI.lineItem   : [{ position: 200, label: 'Through' }]
      RGPIn.rinthrough          as Through,

      @UI.lineItem   : [{ position: 210, label: 'GR/LR No.' }]
      RGPIn.lr_num              as LrNum,

      @UI.lineItem   : [{ position: 220, label: 'GR/LR Date' }]
      RGPIn.lr_date             as LrDate,

      @UI.lineItem   : [{ position: 230, label: 'Invoice No.' }]
      RGPIn.invno               as Invno,

      @UI.lineItem   : [{ position: 240, label: 'Invoice Date' }]
      RGPIn.invdt               as Invdt,

      ////      @UI.lineItem   : [{ position: 220, label: 'Exp. Return Date' }]
      ////      RGPIn.exp_returndate      as ExpReturndate

      @UI.lineItem   : [{ position: 250, label: 'Gross Weight' }]
      RGPIn.ringross_wgt        as GrossWgt,

      @UI.lineItem   : [{ position: 260, label: 'Tare Weight' }]
      RGPIn.rintare_wgt         as TareWgt,


      @UI.lineItem   : [{ position: 260, label: 'Net Weight' }]
      RGPIn.rinnet_wgt          as NetWgt,

      @UI.lineItem   : [{ position: 260, label: 'Vehicle Out Flag' }]
      RGPIn.rinvechout          as Vechout,

      @UI.lineItem   : [{ position: 270, label: 'Vehicle Out Date' }]
      RGPIn.rinvehiout_date     as VehioutDate,

      @UI.lineItem   : [{ position: 280, label: 'Vehicle Out Time' }]
      RGPIn.rinvehiout_time     as VehioutTime,

      @UI.lineItem   : [{ position: 290, label: 'Remarks' }]
      RGPIn.rinremarks          as Remarks
   
}

where
      RGPIn.rgpoutdeleted =  ''
  and RGPIn.rgpindeleted  =  ''
  and RGPIn.rgpin_num     <> ''
//and RGPOUT.rgpin_year = ''
