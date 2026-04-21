@AbapCatalog.sqlViewName: 'ZV_ISSUE_SLIP'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Material Issue Slip'
define view ZI_ISSUE_SLIP as select from I_ReservationDocumentHeader as rkpf
{
  
  key rkpf.Reservation,
  rkpf.GoodsMovementType,
  rkpf.ReservationDate,
  rkpf.IssuingOrReceivingPlant
  //rkpf.CreationDateTime,
  //rkpf.LastChangedByUser,
  //rkpf.LastChangeDateTime
    
}
