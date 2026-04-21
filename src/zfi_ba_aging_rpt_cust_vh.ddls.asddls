/*------------------------------------------------------------------------------------------*
* Title             : Aging Report                                                          *
* Author            : Neelam Goyal                                                          *
* Creation Date     : 20/02/2026                                                          *
* Application       : Aging Report                                                          *
* Description       : Value help for selection field Customer & customer name               *
* Description       : Value help for selection field Company & Company Name               *
*-------------------------------------------------------------------------------------------*
*                           CHANGE HISTORY                                                  *
*-------------------------------------------------------------------------------------------*
* Date    |   Author    | Change Description                                                *
*-------------------------------------------------------------------------------------------*
*         |             |                                                                   *
*-------------------------------------------------------------------------------------------**/
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for Customer'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #A,
    sizeCategory: #XL,
    dataClass: #MASTER
}

@VDM.viewType: #BASIC
define view entity ZFI_BA_AGING_RPT_CUST_VH
  as select from I_Customer
{
  key Customer,  
      CustomerName  
}
