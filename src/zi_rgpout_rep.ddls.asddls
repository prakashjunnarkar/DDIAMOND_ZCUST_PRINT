@EndUserText.label: 'RGPOUT REPORT'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_RGPOUT_REP'
@UI.headerInfo : { typeName : 'RGPOUT Report' , typeNamePlural: 'RGPOUT Report'}

define custom entity zi_rgpout_rep

{

      @UI.selectionField  : [{ position: 20 }]
      @EndUserText.label  : 'RGP Out No.'
      @UI.lineItem        : [{ position: 10, label: 'RGP Out No.' }]
  key rgpout_num          : abap.char(10);

      @UI.lineItem        : [{ position: 10, label: 'RGPOUT Year' }]
  key rgpout_year         : abap.numc(4);

      @UI.selectionField  : [{ position: 30 }]
      @EndUserText.label  : 'PR No.'
      @UI.lineItem        : [{ position: 20, label: 'Purchase Req. No.' }]
  key prnum               : abap.char(10);

      @UI.lineItem        : [{ position: 30, label: 'Purchase Req. Item' }]
  key pritem              : abap.char(5);

      @UI.adaptationHidden: true
  key rgpin_num           : abap.char(10);

      @UI.adaptationHidden: true
  key rgpin_year          : abap.numc(4);

      @UI.lineItem        : [{ position: 70, label: 'Item code' }]
  key matnr               : abap.char(40);

      @UI.selectionField  : [{ position: 40 }]
      @EndUserText.label  : 'Plant.'
      @UI.lineItem        : [{ position: 40, label: 'Plant' }]
      werks               : abap.char(4);

      @UI.selectionField  : [{ position: 50 }]
      @EndUserText.label  : 'RGP Out Date'
      @UI.lineItem        : [{ position: 160, label: 'RGP Out Date' }]
      rgpout_creationdate : abap.dats;

      @UI.selectionField  : [{ position: 10 }]
      @EndUserText.label  : 'Vendor.'
      @UI.lineItem        : [{ position: 50, label: 'Vendor Code' }]
      lifnr               : abap.char(10);

      @UI.lineItem        : [{ position: 60, label: 'Vendor Description' }]
      vendor_name         : abap.char(40);

      @UI.lineItem        : [{ position: 80, label: 'Item Description' }]
      maktx               : abap.string(0);

      @UI.lineItem        : [{ position: 90, label: 'HSN Code' }]
      hsncode             : abap.char(40);

      @UI.lineItem        : [{ position: 100, label: 'UOM' }]
      uom                 : abap.unit(3);

      @UI.lineItem        : [{ position: 110, label: 'Qty' }]
     
      prqty               : abap.dec(13,2);

      @UI.lineItem        : [{ position: 120, label: 'Net Price' }]
      netprice            : abap.dec(13,2);

      @UI.lineItem        : [{ position: 130, label: 'Tax Code' }]
      taxcode             : z_de_char2;

      @UI.lineItem        : [{ position: 140, label: 'Gross Value' }]
      grossvalue          : abap.dec(13,2);

      @UI.lineItem        : [{ position: 150, label: 'Total Value' }]
      tot_val             : abap.dec(13,2);


      @UI.lineItem        : [{ position: 170, label: 'Vehicle No.' }]
      vechnum             : abap.char(15);


      @UI.lineItem        : [{ position: 180, label: 'Driver Name' }]
      driver_name         : abap.char(20);

      @UI.lineItem        : [{ position: 180, label: 'Driver No.' }]
      driver_num          : abap.char(20);

      @UI.lineItem        : [{ position: 190, label: 'Requested By' }]
      requestedby         : abap.char(40);

      @UI.lineItem        : [{ position: 200, label: 'Purpose' }]
      purpose             : abap.char(40);

      @UI.lineItem        : [{ position: 210, label: 'Through' }]
      through             : abap.char(40);

      @UI.lineItem        : [{ position: 220, label: 'Exp. Return Date' }]
      exp_returndate      : abap.dats;

      @UI.lineItem        : [{ position: 230, label: 'Gross Weight' }]
      gross_wgt           : abap.dec(13,2);

      @UI.lineItem        : [{ position: 240, label: 'Tare Weight' }]
      tare_wgt            : abap.dec(13,2);

      @UI.lineItem        : [{ position: 250, label: 'Net Weight' }]
      net_wgt             : abap.dec(13,2);

      @UI.lineItem        : [{ position: 260, label: 'Vehicle Out Flag' }]
      vechout             : abap.char(10);
      @UI.lineItem        : [{ position: 270, label: 'Vehicle Out Date' }]
      vehiout_date        : abap.dats;

      @UI.lineItem        : [{ position: 280, label: 'Vehicle Out Time' }]
      vehiout_time        : abap.tims;

      @UI.lineItem        : [{ position: 290, label: 'Remarks' }]
      remarks             : abap.char(80);

      @UI.lineItem        : [{ position: 170, label: 'Ageing Days' }]
      ageingdays          : abap.char(10);

}
