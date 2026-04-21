@AbapCatalog.sqlViewName: 'ZV_SLOC_F4'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Storage Location F4'
define view ZI_SLOC_F4 as select from I_StorageLocation as sloc
{
 
 key sloc.Plant,
 key sloc.StorageLocation,
 sloc.StorageLocationName

}
