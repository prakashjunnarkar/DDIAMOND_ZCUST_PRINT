@AbapCatalog.sqlViewName: 'ZV_USER'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'User Detail'
define view ZI_USER as select 
from I_User as user
{

user.UserID,
user.UserDescription,
user.IsTechnicalUser,
user.AddressPersonID,
user.AddressID
    
}
