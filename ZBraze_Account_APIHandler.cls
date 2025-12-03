/********************************************************************************************************
* (C) Copyright 2023 Charles & Keith. All rights reserved.
* This code is property of Charles & Keith. Use, duplication and
* disclosure in any form without permission of copyright holder is prohibited.
* 
******************************************************************************************************* 
* @author Gokilavani V
* @version 1.0
* @created 25/01/2023
* @description 
* This class is used to send custom attributes to Braze from SFDC
*
* @test class name - 
*
*  Change History:
*  MM/DD/YYYY			Developer Name			Comments
*  
* 
*/
public class ZBraze_Account_APIHandler {
    
    public static ID ckRecordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('CK').getRecordTypeId();
    public static ID pdRecordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('PD').getRecordTypeId();
    
    //VC JP Update
    public static ID jpRecordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('JP').getRecordTypeId();
    
    
    //────────────────────────────────────────────────────────────────────────────────────┐
    //This method is used to create standard/custom attributes into the Braze
    //@params: 
    //	accIds - set of account ids of CK or PD
    //────────────────────────────────────────────────────────────────────────────────────┘
    
    //Create braze customer detail from Trigger
    public static void createBrazeAccount(set<Id> accIds){
        system.debug('createBrazeAccount.start()--'+accIds);
        ZBraze_Syn_Activation__c activationDetailCK = ZBraze_Syn_Activation__c.getvalues('CK');
        ZBraze_Syn_Activation__c activationDetailPD = ZBraze_Syn_Activation__c.getvalues('PD');
        Set<id> pdId = new Set<id>();
        Set<id> ckId = new Set<id>();
        
        //VC JP Update                    
        Set<id> jpId = new Set<id>();
        
        try{
            if(!accIds.isEmpty()){
                for(Account acc:[Select id,RecordtypeId from Account where id in :accIds] ){
                    
                    if(acc.RecordtypeId == ckRecordTypeId){
                        ckId.add(acc.id);
                    }
                    if(acc.RecordtypeId == pdRecordTypeId){
                        pdId.add(acc.id);
                    }
                    
                    //VC JP Update
                    if(acc.RecordtypeId == jpRecordTypeId){
                        jpId.add(acc.id);
                    }
                } 
            } 
            if(!pdId.isEmpty() && activationDetailPD.Custom_Attribute_Sync__c == true){
                ZBraze_Account_Callout.exportUserDetailsByAlias('PD', pdId);
            }
            if(!ckId.isEmpty() && activationDetailCK.Custom_Attribute_Sync__c == true){
                ZBraze_Account_Callout.exportUserDetailsByAlias('CK', ckId);
            }
            
            //VC JP Update
          if(!jpId.isEmpty() && activationDetailCK.Custom_Attribute_Sync__c == true){
                 ZBraze_Account_Callout.exportUserDetailsByAlias('JP', jpId);
            }
            
            
            
        }catch(Exception e){ 
            
            ZBraze_Account_Callout.CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage(),
                                                  '','','','Trigger','Backend Process Error');  
        }
        system.debug('createBrazeAccount.End()--'+accIds);
    }
    //────────────────────────────────────────────────────────────────────────────────────┐
    //This method is used to Update standard/custom attributes into the Braze
    //@params: 
    //	accIds - set of account ids of CK or PD
    //────────────────────────────────────────────────────────────────────────────────────┘
    
    //Update braze customer Detail from Trigger
    
    public static void updateBrazeAccount(String brand,set<Id> accIds){
        system.debug('updateBrazeAccount.start()--'+accIds+'brand--'+brand);
        ZBraze_Syn_Activation__c activationDetail = ZBraze_Syn_Activation__c.getvalues(brand);
        set<id> pendingIds =  new set<Id>();
        Set<id> compIds = new set<Id>();
        try{
            if(activationDetail.Custom_Attribute_Sync__c == true){
                for(Id AccId : accIds){
                    Account newAccount = (Account)Trigger.NewMap.get(AccId);
                    if(newAccount.IF_Status__c!=null && (newAccount.IF_Status__c == 'Pending' || newAccount.IF_Status__c == 'Failed')){
                        pendingIds.add(newAccount.id);
                    }else{
                        compIds.add(newAccount.id);
                    }
                }
                system.debug('pendingIds--'+pendingIds);
                system.debug('compIds--'+compIds);
                if(pendingIds.size()>0){
                    TriggerpendinguserDetailUpdate(brand, pendingIds);
                }
                if(compIds.size() > 0){
                    ZBraze_Account_callout.UpdateAccountDetailsToBraze(brand,compIds);
                }
            }            
            
        }catch(Exception e){
            ZBraze_Account_Callout.CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage(),
                                                  '','','','Trigger','Backend Process Error'); 
        }
        system.debug('updateBrazeAccount.End()--'+accIds);
    }
    
    @future (callout = true)
    public static void TriggerpendinguserDetailUpdate(String brand,Set<id> pendingIds){
        ZBraze_Account_APIHelper.exportUserDetailsByAlias(brand, pendingIds);
    }
    //────────────────────────────────────────────────────────────────────────────────────┐
    //This method is used to create/update standard/custom attributes into the Braze
    //@params: 
    //	accIds - set of account ids of CK or PD
    //────────────────────────────────────────────────────────────────────────────────────┘
    //created or Update braze customer Detail from Batch
    public static void createUpdateAccountDetails(set<Id> accIds){
        Set<id> pdId = new Set<id>();
        Set<id> ckId = new Set<id>();
        
        //VC JP Update                    
        Set<id> jpId = new Set<id>();
        
        try{
            if(!accIds.isEmpty()){
                for(Account acc: [Select id,RecordtypeId from Account where id in:accIds]){
                    
                    
                    if(acc.RecordtypeId == ckRecordTypeId){
                        ckId.add(acc.id);
                    }
                    if(acc.RecordtypeId == pdRecordTypeId){
                        pdId.add(acc.id);
                    }
                    
                    //VC JP Update
                    if(acc.RecordtypeId == jpRecordTypeId){
                        jpId.add(acc.id);
                    }
                    
                } 
            } 
            if(!pdId.isEmpty()){
                
                ZBraze_Syn_Activation__c activationDetailPD = ZBraze_Syn_Activation__c.getvalues('PD');
                
                if(activationDetailPD.Custom_Attribute_Sync__c == true){
                    ZBraze_Account_APIHelper.exportUserDetailsByAlias('PD', pdId);
                }
            }
            if(!ckId.isEmpty()){
               
                ZBraze_Syn_Activation__c activationDetailCK = ZBraze_Syn_Activation__c.getvalues('CK');
                
                if(activationDetailCK.Custom_Attribute_Sync__c == true){
                    ZBraze_Account_APIHelper.exportUserDetailsByAlias('CK', ckId);
                }
            }     
            
            //VC JP Update
            if(!jpId.isEmpty()){
                
                ZBraze_Syn_Activation__c activationDetailCK = ZBraze_Syn_Activation__c.getvalues('CK');
                
                if(activationDetailCK.Custom_Attribute_Sync__c == true){
                    ZBraze_Account_APIHelper.exportUserDetailsByAlias('JP', jpId);
                }
            }
            
        }catch(Exception e){
            ZBraze_Account_Callout.CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage(),
                                                  '','','','Batch','Backend Process Error'); 
        }
    }
    
    public static Map<String, List<String>> getLangSiteurlForCustomers(){
        
        Map<String, List<String>> LangSiteurl_Map_Customer = new  Map<String, List<String>>();
        
        LangSiteurl_Map_Customer.put('AM_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('AU_EN',New List<String>{'en','au'});
        
        LangSiteurl_Map_Customer.put('AZ_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('BH_EN',New List<String>{'en','bh'});
        
        LangSiteurl_Map_Customer.put('BN_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('BG_EN',New List<String>{'en','bg'});
        LangSiteurl_Map_Customer.put('KH_EN',New List<String>{'en','kh'});
        LangSiteurl_Map_Customer.put('CA_EN',New List<String>{'en','ca'});
        LangSiteurl_Map_Customer.put('HR_EN',New List<String>{'en','hr'});
        LangSiteurl_Map_Customer.put('CZ_EN',New List<String>{'en','cz'});
        LangSiteurl_Map_Customer.put('DK_EN',New List<String>{'en','dk'});
        LangSiteurl_Map_Customer.put('EG_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('EE_EN',New List<String>{'en','ee'});
        
        LangSiteurl_Map_Customer.put('FI_EN',New List<String>{'en','fi'});
        LangSiteurl_Map_Customer.put('FR_EN',New List<String>{'en','fr-en'});
        LangSiteurl_Map_Customer.put('FR_FR',New List<String>{'fr','fr'});
        LangSiteurl_Map_Customer.put('GE_EN',New List<String>{'en','catalog'});
        
        //VC Update 23-09-2024
        LangSiteurl_Map_Customer.put('DE_EN',New List<String>{'en','de-en'});
        LangSiteurl_Map_Customer.put('DE_DE',New List<String>{'de','de'});
        LangSiteurl_Map_Customer.put('JP_JA',New List<String>{'ja','jp'});
        
        LangSiteurl_Map_Customer.put('GR_EN',New List<String>{'en','gr'});
        LangSiteurl_Map_Customer.put('HK_EN',New List<String>{'en','hk-en'});
        LangSiteurl_Map_Customer.put('HK_ZH',New List<String>{'zh','hk'});
        LangSiteurl_Map_Customer.put('HU_EN',New List<String>{'en','hu'});      
        LangSiteurl_Map_Customer.put('IR_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('IE_EN',New List<String>{'en','ie'});
        LangSiteurl_Map_Customer.put('IL_EN',New List<String>{'en','il'});
        
        LangSiteurl_Map_Customer.put('JO_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('KZ_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('KW_EN',New List<String>{'en','kw'});
        LangSiteurl_Map_Customer.put('LV_EN',New List<String>{'en','lv'});
        LangSiteurl_Map_Customer.put('LB_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('LY_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('LT_EN',New List<String>{'en','lt'});
        LangSiteurl_Map_Customer.put('LU_EN',New List<String>{'en','lu'});
        LangSiteurl_Map_Customer.put('MO_EN',New List<String>{'en','mo-en'});
        LangSiteurl_Map_Customer.put('MO_ZH',New List<String>{'zh','mo'});
        LangSiteurl_Map_Customer.put('MY_EN',New List<String>{'en','my'});
        LangSiteurl_Map_Customer.put('MT_EN',New List<String>{'en','mt'});
        
        //VC Update 04/02/2025
        LangSiteurl_Map_Customer.put('MX_ES',New List<String>{'es','mx'});
        LangSiteurl_Map_Customer.put('MX_EN',New List<String>{'en','mx-en'});
        
        LangSiteurl_Map_Customer.put('AR_ES',New List<String>{'es','ar'});
        LangSiteurl_Map_Customer.put('AR_EN',New List<String>{'en','ar-en'});
        LangSiteurl_Map_Customer.put('CL_ES',New List<String>{'es','cl'});
        LangSiteurl_Map_Customer.put('CL_EN',New List<String>{'en','cl-en'});
        LangSiteurl_Map_Customer.put('CO_ES',New List<String>{'es','co'});
        LangSiteurl_Map_Customer.put('CO_EN',New List<String>{'en','co-en'});
        LangSiteurl_Map_Customer.put('UY_ES',New List<String>{'es','uy'});
        LangSiteurl_Map_Customer.put('UY_EN',New List<String>{'en','uy-en'});
        
        
        //VC Update 27-02-2025
        LangSiteurl_Map_Customer.put('NL_NL',New List<String>{'nl','nl'});
        LangSiteurl_Map_Customer.put('NL_EN',New List<String>{'en','nl-en'});
        
        LangSiteurl_Map_Customer.put('AT_DE',New List<String>{'de','at'});
        LangSiteurl_Map_Customer.put('AT_EN',New List<String>{'en','at-en'});
        
        LangSiteurl_Map_Customer.put('BE_NL',New List<String>{'nl','be'});
        LangSiteurl_Map_Customer.put('BE_EN',New List<String>{'en','be-en'});
        LangSiteurl_Map_Customer.put('BE_FR',New List<String>{'fr','be-fr'});
        LangSiteurl_Map_Customer.put('BE_DE',New List<String>{'de','be-de'});
       
        //VC Update 01-04-2025
        LangSiteurl_Map_Customer.put('IT_IT',New List<String>{'it','it'});
        LangSiteurl_Map_Customer.put('IT_EN',New List<String>{'en','it-en'});
        
        
        //VC Update 22-04-2025
        LangSiteurl_Map_Customer.put('BR_PT',New List<String>{'pt','br'});
        LangSiteurl_Map_Customer.put('BR_EN',New List<String>{'en','br-en'});
        LangSiteurl_Map_Customer.put('PT_PT',New List<String>{'pt','pt'});
        LangSiteurl_Map_Customer.put('PT_EN',New List<String>{'en','pt-en'});
        LangSiteurl_Map_Customer.put('CH_DE',New List<String>{'de','ch'});
        LangSiteurl_Map_Customer.put('CH_EN',New List<String>{'en','ch-en'});
        LangSiteurl_Map_Customer.put('CH_IT',New List<String>{'it','ch-it'});
        LangSiteurl_Map_Customer.put('CH_FR',New List<String>{'fr','ch-fr'});
        
        
        
   
        LangSiteurl_Map_Customer.put('MN_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('MA_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('MM_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('NZ_EN',New List<String>{'en','nz'});
        LangSiteurl_Map_Customer.put('NO_EN',New List<String>{'en','no'});
        LangSiteurl_Map_Customer.put('HK_EN',New List<String>{'en','hk-en'});
        LangSiteurl_Map_Customer.put('others_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('OM_EN',New List<String>{'en','om'});
        LangSiteurl_Map_Customer.put('PK_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('PA_EN',New List<String>{'en','pa'});
        LangSiteurl_Map_Customer.put('PH_EN',New List<String>{'en','ph'});
        LangSiteurl_Map_Customer.put('PL_EN',New List<String>{'en','pl'});
        LangSiteurl_Map_Customer.put('QA_EN',New List<String>{'en','qa'});
        LangSiteurl_Map_Customer.put('RO_EN',New List<String>{'en','ro'});
        LangSiteurl_Map_Customer.put('SG_EN',New List<String>{'en','sg'});
        LangSiteurl_Map_Customer.put('SK_EN',New List<String>{'en','sk'});
        LangSiteurl_Map_Customer.put('SI_EN',New List<String>{'en','si'});
        LangSiteurl_Map_Customer.put('ZA_EN',New List<String>{'en','za'});
        LangSiteurl_Map_Customer.put('KR_EN',New List<String>{'en','kr-en'});
        LangSiteurl_Map_Customer.put('KR_KO',New List<String>{'ko','kr'});
        LangSiteurl_Map_Customer.put('ES_EN',New List<String>{'en','es-en'});
        LangSiteurl_Map_Customer.put('ES_ES',New List<String>{'es','es'});
        LangSiteurl_Map_Customer.put('LK_EN',New List<String>{'en','lk'});
        LangSiteurl_Map_Customer.put('SE_EN',New List<String>{'en','se'});
        LangSiteurl_Map_Customer.put('TW_EN',New List<String>{'en','tw-en'});
        LangSiteurl_Map_Customer.put('TW_ZH',New List<String>{'zh','tw'});
        LangSiteurl_Map_Customer.put('AE_EN',New List<String>{'en','ae'});
        LangSiteurl_Map_Customer.put('GB_EN',New List<String>{'en','gb'});
        LangSiteurl_Map_Customer.put('US_EN',New List<String>{'en','us'});
        LangSiteurl_Map_Customer.put('US_ES',New List<String>{'es','us-es'});
        LangSiteurl_Map_Customer.put('MU_EN',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('AW_EN',New List<String>{'en','aw'});
        LangSiteurl_Map_Customer.put('BS_EN',New List<String>{'en','bs'});
        LangSiteurl_Map_Customer.put('BD_EN',New List<String>{'en','bd'});
        LangSiteurl_Map_Customer.put('TR_EN',New List<String>{'en','tr'});
   
        
        LangSiteurl_Map_Customer.put('au',New List<String>{'en','au'});
        LangSiteurl_Map_Customer.put('at',New List<String>{'en','at'});
        LangSiteurl_Map_Customer.put('bh-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('bd-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('bg',New List<String>{'en','bg'});
        LangSiteurl_Map_Customer.put('be',New List<String>{'en','be'});
        LangSiteurl_Map_Customer.put('bn',New List<String>{'en','bn'});
        LangSiteurl_Map_Customer.put('ca',New List<String>{'en','ca'});
        LangSiteurl_Map_Customer.put('hr',New List<String>{'en','hr'});
        LangSiteurl_Map_Customer.put('cz',New List<String>{'en','cz'});
        LangSiteurl_Map_Customer.put('dk',New List<String>{'en','dk'});
        LangSiteurl_Map_Customer.put('ee',New List<String>{'en','ee'});
        LangSiteurl_Map_Customer.put('fi',New List<String>{'en','fi'});
        LangSiteurl_Map_Customer.put('fr',New List<String>{'en','fr'});
        LangSiteurl_Map_Customer.put('de',New List<String>{'en','de'});
        LangSiteurl_Map_Customer.put('gr',New List<String>{'en','gr'});
        LangSiteurl_Map_Customer.put('hk',New List<String>{'zh','hk'});
        LangSiteurl_Map_Customer.put('hk-en',New List<String>{'en','hk-en'});
        LangSiteurl_Map_Customer.put('hu',New List<String>{'en','hu'});
        LangSiteurl_Map_Customer.put('in-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('others-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('ir-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('ie',New List<String>{'en','ie'});
        LangSiteurl_Map_Customer.put('it',New List<String>{'en','it'});
        LangSiteurl_Map_Customer.put('jp-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('kw',New List<String>{'en','kw'});
        LangSiteurl_Map_Customer.put('lv',New List<String>{'en','lv'});
        LangSiteurl_Map_Customer.put('lt',New List<String>{'en','lt'});
        LangSiteurl_Map_Customer.put('lu',New List<String>{'en','lu'});
        LangSiteurl_Map_Customer.put('mo',New List<String>{'zh','mo'});
        LangSiteurl_Map_Customer.put('mo-en',New List<String>{'en','mo-en'});
        LangSiteurl_Map_Customer.put('my',New List<String>{'en','my'});
        LangSiteurl_Map_Customer.put('mx-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('Mn-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('ma-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('mm-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('nl',New List<String>{'en','nl'});
        LangSiteurl_Map_Customer.put('nz',New List<String>{'en','nz'});
        LangSiteurl_Map_Customer.put('no-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('om',New List<String>{'en','om'});
        LangSiteurl_Map_Customer.put('pk-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('ph',New List<String>{'en','ph'});
        LangSiteurl_Map_Customer.put('pl',New List<String>{'en','pl'});
        LangSiteurl_Map_Customer.put('pt',New List<String>{'en','pt'});
        LangSiteurl_Map_Customer.put('qa',New List<String>{'en','qa'});
        LangSiteurl_Map_Customer.put('ro',New List<String>{'en','ro'});
        LangSiteurl_Map_Customer.put('sa-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('sg',New List<String>{'en','sg'});
        LangSiteurl_Map_Customer.put('sk',New List<String>{'en','sk'});
        LangSiteurl_Map_Customer.put('si',New List<String>{'en','si'});
        LangSiteurl_Map_Customer.put('kr-en',New List<String>{'en','kr-en'});
        LangSiteurl_Map_Customer.put('kr',New List<String>{'en','kr'});
        LangSiteurl_Map_Customer.put('es',New List<String>{'en','es'});
        LangSiteurl_Map_Customer.put('lk-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('se',New List<String>{'en','se'});
        LangSiteurl_Map_Customer.put('ch-int',New List<String>{'en','catalog'});
        LangSiteurl_Map_Customer.put('tw-en',New List<String>{'en','tw-en'});
        LangSiteurl_Map_Customer.put('tw',New List<String>{'zh','tw'});
        LangSiteurl_Map_Customer.put('th',New List<String>{'en','th'});
        LangSiteurl_Map_Customer.put('ae',New List<String>{'en','ae'});
        LangSiteurl_Map_Customer.put('gb',New List<String>{'en','gb'});
        LangSiteurl_Map_Customer.put('us',New List<String>{'en','us'});
        LangSiteurl_Map_Customer.put('vn-int',New List<String>{'en','catalog'});
        
        System.debug('customMetadataMap_Customer : '+ LangSiteurl_Map_Customer);
        return LangSiteurl_Map_Customer;
    }
    
    //────────────────────────────────────────────────────────────────────────────────────┐
    //This method is used to update standard/custom attributes into the Braze
    //endpoint: 
    //@params: 
    //	recordType - CK or PD
    //	extIdAttributeMap - key ExtId and value braze user details
    //────────────────────────────────────────────────────────────────────────────────────┘
    public static void updateAccountInBraze(string recordType, map<string, ZBraze_CustomAttribute_Export_Wrapper.user> extIdAttributeMap){
        ZBraze_API_Master__c Apilist = ZBraze_API_Master__c.getvalues('recordType');
        list<map<string, string>> fieldMapList = new list<map<string, string>>();
        Set<Id> AccountIds = new Set<Id>();
        Set<Id> AccIds = new Set<Id>();
        Map<String, List<String>> languageSiteMap = getLangSiteurlForCustomers();        
        
        try{
            if(!extIdAttributeMap.isEmpty()){
                
                //VC Japan Update
                for(Account AccId:[SELECT Id,Name,LastName,FirstName,PersonEmail,Registration_Country__c,PersonBirthdate,Gender__c ,
                                   Residential_Address_City__c,Subscribed_Country_Email__c,PersonMobilePhone,Email_Subscription_Status__c,
                                   Customer_Type__c,Last_Login_Date__c,Last_purchase_date__c,/*Days_Since_Last_Login__c,Days_since_last_purchase__c,*/
                                   Favored_Medium_Of_Purchase__c, First_Date_Of_Purchase__c,Loyalty_Tier_AE__c,Loyalty_Tier_AU__c,Loyalty_Tier_CA__c,Loyalty_Tier_CH__c,
                                   Loyalty_Tier_EU__c,Loyalty_Tier_GB__c,Loyalty_Tier_HK__c,Loyalty_Tier_KH__c,Loyalty_Tier_KR__c,
                                   Loyalty_Tier_MO__c,Loyalty_Tier_MT__c,Loyalty_Tier_MY__c,Loyalty_Tier_NO__c,Loyalty_Tier_NZ__c,
                                   Loyalty_Tier_PAK__c,Loyalty_Tier_SG__c,Loyalty_Tier_TW__c,Loyalty_Tier_UK__c,Loyalty_Tier_US__c,Loyalty_Tier_JP__c,
                                   Mode_of_registration__c,Most_Purchased_Category__c,Most_Purchased_Color__c,Registration_Date__c,
                                   School_University_Name__c,School_University_Name_Other__c,Shoe_Size__c,Subscribed_Content_Gender__c,VIP_Since_Date_AE__c,
                                   VIP_Since_Date_AU__c,VIP_Since_Date_CA__c,VIP_Since_Date_CH__c,VIP_Since_Date_EU__c,
                                   VIP_Since_Date_GB__c,VIP_Since_Date_HK__c,VIP_Since_Date_KR__c,VIP_Since_Date_MO__c,
                                   VIP_Since_Date_MT__c,VIP_Since_Date_NO__c,VIP_Since_Date_NZ__c,VIP_Since_Date_PAK__c,
                                   VIP_Since_Date_SG__c,VIP_Since_Date_TW__c,VIP_Since_Date_UK__c,VIP_Since_Date_US__c,
                                   VIP_Since_Date_KH__c,VIP_Since_Date_MY__c,VIP_Since_Date_JP__c,Source__c,Subscribed_Country_SMS__c,Ocapi_Customer_ID__c,
                                   Customer_Mobile_Subscription_Status__c,UTM_Campaign__c,UTM_Content__c,UTM_Medium__c,
                                   UTM_Source__c,UTM_Term__c,Reseller_Flag__c,TotalOrderAmt_SGD__c,TotalRefundAmt_SGD__c,
                                   Lifetime_Value__c, Total_Value_spends_within_Last_12_months__c,Social_Account_Provider_ID__c,
                                   Last_Purchased_Store__c,Subscribed_Whatsapp__c,Subscribed_Country_Whatsapp__c from Account where id in :extIdAttributeMap.keyset()]){
                                       system.debug('checking update for ACCID: '+AccId.id);
                                       ZBraze_CustomAttribute_Export_Wrapper.user brazeDet = extIdAttributeMap.get(AccId.Id);
                                       
                                       List<String> cusMdt = new List<String> ();
                                       if(AccId.Subscribed_Country_Email__c!=null && AccId.Subscribed_Country_Email__c!=''){
                                           cusMdt = languageSiteMap.get(AccId.Subscribed_Country_Email__c);
                                       }
                                       
                                       map<string, string> fieldMap = new map<string, string>();
                                       fieldMap.put('external_id',AccId.id);
                                       
                                       if(AccId.FirstName!=NULL && AccId.FirstName!=''){
                                           if(brazeDet.first_name !=AccId.FirstName ){
                                               fieldMap.put('first_name', AccId.FirstName);
                                           }
                                       }
                                       if(AccId.LastName!=NULL && AccId.LastName!=''){
                                           if(brazeDet.last_name !=AccId.LastName ){
                                               fieldMap.put('last_name', AccId.LastName);
                                           }
                                       }
                                       if(AccId.PersonMobilePhone != null){
                                           if(brazeDet.phone !=AccId.PersonMobilePhone ){
                                               fieldMap.put('phone', AccId.PersonMobilePhone);
                                           }
                                       }
                                       if(AccId.PersonEmail!=NULL && AccId.PersonEmail!=''){
                                           if(brazeDet.email !=AccId.PersonEmail ){
                                               fieldMap.put('email', AccId.PersonEmail);
                                           }
                                       }
                                       if(AccId.PersonBirthdate!=NULL ){
                                           if(brazeDet.dob !=AccId.PersonBirthdate ){
                                               string dob = string.valueOf(AccId.PersonBirthdate);
                                               fieldMap.put('dob', dob);
                                           }
                                       }
                                       if(AccId.Registration_Country__c!=NULL && AccId.Registration_Country__c!=''){
                                           if(brazeDet.country !=AccId.Registration_Country__c ){
                                               fieldMap.put('country', AccId.Registration_Country__c);
                                           }
                                       }
                                       if(AccId.Residential_Address_City__c!=NULL && AccId.Residential_Address_City__c!=''){
                                           if(brazeDet.home_city !=AccId.Residential_Address_City__c ){
                                               fieldMap.put('home_city', AccId.Residential_Address_City__c);
                                           }
                                       }
                                       if(AccId.Gender__c!=NULL && AccId.Gender__c!=''){
                                           String gen;
                                           if(brazeDet.gender == 'M'){
                                               gen = 'Male';
                                           }else if(brazeDet.gender == 'F'){
                                               gen = 'Female';
                                           }else if(brazeDet.gender == 'P'){
                                               gen = 'Prefer Not To Say';
                                           }   
                                           if(gen!= AccId.Gender__c  ){
                                               fieldMap.put('gender', AccId.Gender__c);   
                                           }
                                           
                                       }
                                       if(AccId.Email_Subscription_Status__c!=NULL ){
                                           string accValue = AccId.Email_Subscription_Status__c == True ? 'subscribed':'unsubscribed';
                                           if( brazeDet.email_subscribe != accValue ){
                                               fieldMap.put('email_subscribe', accValue );
                                           }
                                       }
                                       if(AccId.Subscribed_Country_Email__c!=null && cusMdt != null){
                                           if(brazeDet.language != cusMdt[0]){
                                               fieldMap.put('language', cusMdt[0] );
                                           }
                                           if(brazeDet.custom_attributes.Site_URL != cusMdt[1]){
                                               fieldMap.put('Site_URL', cusMdt[1] );
                                           }
                                       }
                                       
                                       if(AccId.Source__c!=NULL && AccId.Source__c!=''){
                                           if(brazeDet.custom_attributes.source != AccId.Source__c ){
                                               fieldMap.put('Source', AccId.Source__c);
                                           }
                                       }
                                       if(AccId.School_University_Name__c!=NULL && AccId.School_University_Name__c!=''){
                                           if(brazeDet.custom_attributes.School_University_Name != AccId.School_University_Name__c ){
                                               fieldMap.put('School_University_Name', AccId.School_University_Name__c);
                                           }
                                       }
                                       
                                       if(AccId.School_University_Name_Other__c!=NULL && AccId.School_University_Name_Other__c!=''){
                                           if(brazeDet.custom_attributes.School_University_Name != AccId.School_University_Name_Other__c ){
                                               fieldMap.put('School_University_Name', AccId.School_University_Name_Other__c);
                                           }
                                       }
                                       if(AccId.Registration_Date__c!=NULL ){
                                           if(brazeDet.custom_attributes.Registration_Date != AccId.Registration_Date__c ){
                                               string regDate = string.valueOf(AccId.Registration_Date__c);
                                               fieldMap.put('Registration_Date', regDate);
                                           }
                                       }
                                       if(AccId.Most_Purchased_Color__c!=NULL && AccId.Most_Purchased_Color__c!=''){
                                           if(brazeDet.custom_attributes.Most_Purchased_Color != AccId.Most_Purchased_Color__c ){
                                               fieldMap.put('Most_Purchased_Color', AccId.Most_Purchased_Color__c);
                                           }
                                       }
                                       if(AccId.Most_Purchased_Category__c!=NULL && AccId.Most_Purchased_Category__c!=''){
                                           if(brazeDet.custom_attributes.Most_Purchased_Category != AccId.Most_Purchased_Category__c ){
                                               fieldMap.put('Most_Purchased_Category', AccId.Most_Purchased_Category__c);
                                           }
                                       }
                                       if(AccId.Mode_of_registration__c!=NULL && AccId.Mode_of_registration__c!=''){
                                           if(brazeDet.custom_attributes.Mode_of_registration != AccId.Mode_of_registration__c ){
                                               fieldMap.put('Mode_of_registration', AccId.Mode_of_registration__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_US__c!=NULL && AccId.Loyalty_Tier_US__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_US != AccId.Loyalty_Tier_US__c ){
                                               fieldMap.put('Loyalty_Tier_US', AccId.Loyalty_Tier_US__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_UK__c!=NULL && AccId.Loyalty_Tier_UK__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_UK != AccId.Loyalty_Tier_UK__c ){
                                               fieldMap.put('Loyalty_Tier_UK', AccId.Loyalty_Tier_UK__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_TW__c!=NULL && AccId.Loyalty_Tier_TW__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_TW != AccId.Loyalty_Tier_TW__c ){
                                               fieldMap.put('Loyalty_Tier_TW', AccId.Loyalty_Tier_TW__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_SG__c!=NULL && AccId.Loyalty_Tier_SG__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_SG != AccId.Loyalty_Tier_SG__c ){
                                               fieldMap.put('Loyalty_Tier_SG', AccId.Loyalty_Tier_SG__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_PAK__c!=NULL && AccId.Loyalty_Tier_PAK__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_PAK != AccId.Loyalty_Tier_PAK__c ){
                                               fieldMap.put('Loyalty_Tier_PAK', AccId.Loyalty_Tier_PAK__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_NZ__c!=NULL && AccId.Loyalty_Tier_NZ__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_NZ != AccId.Loyalty_Tier_NZ__c ){
                                               fieldMap.put('Loyalty_Tier_NZ', AccId.Loyalty_Tier_NZ__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_NO__c!=NULL && AccId.Loyalty_Tier_NO__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_NO != AccId.Loyalty_Tier_NO__c ){
                                               fieldMap.put('Loyalty_Tier_NO', AccId.Loyalty_Tier_NO__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_MY__c!=NULL && AccId.Loyalty_Tier_MY__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_MY != AccId.Loyalty_Tier_MY__c ){
                                               fieldMap.put('Loyalty_Tier_MY', AccId.Loyalty_Tier_MY__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_MT__c!=NULL && AccId.Loyalty_Tier_MT__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_MT != AccId.Loyalty_Tier_MT__c ){
                                               fieldMap.put('Loyalty_Tier_MT', AccId.Loyalty_Tier_MT__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_MO__c!=NULL && AccId.Loyalty_Tier_MO__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_MO != AccId.Loyalty_Tier_MO__c ){
                                               fieldMap.put('Loyalty_Tier_MO', AccId.Loyalty_Tier_MO__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_KR__c!=NULL && AccId.Loyalty_Tier_KR__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_KR != AccId.Loyalty_Tier_KR__c ){
                                               fieldMap.put('Loyalty_Tier_KR', AccId.Loyalty_Tier_KR__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_KH__c!=NULL && AccId.Loyalty_Tier_KH__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_KH != AccId.Loyalty_Tier_KH__c ){
                                               fieldMap.put('Loyalty_Tier_KH', AccId.Loyalty_Tier_KH__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_HK__c!=NULL && AccId.Loyalty_Tier_HK__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_HK != AccId.Loyalty_Tier_HK__c ){
                                               fieldMap.put('Loyalty_Tier_HK', AccId.Loyalty_Tier_HK__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_GB__c!=NULL && AccId.Loyalty_Tier_GB__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_GB != AccId.Loyalty_Tier_GB__c ){
                                               fieldMap.put('Loyalty_Tier_GB', AccId.Loyalty_Tier_GB__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_EU__c!=NULL && AccId.Loyalty_Tier_EU__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_EU != AccId.Loyalty_Tier_EU__c ){
                                               fieldMap.put('Loyalty_Tier_EU', AccId.Loyalty_Tier_EU__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_CH__c!=NULL && AccId.Loyalty_Tier_CH__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_CH != AccId.Loyalty_Tier_CH__c ){
                                               fieldMap.put('Loyalty_Tier_CH', AccId.Loyalty_Tier_CH__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_CA__c!=NULL && AccId.Loyalty_Tier_CA__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_CA != AccId.Loyalty_Tier_CA__c ){
                                               fieldMap.put('Loyalty_Tier_CA', AccId.Loyalty_Tier_CA__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_AU__c!=NULL && AccId.Loyalty_Tier_AU__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_AU != AccId.Loyalty_Tier_AU__c ){
                                               fieldMap.put('Loyalty_Tier_AU', AccId.Loyalty_Tier_AU__c);
                                           }
                                       }
                                       if(AccId.Loyalty_Tier_AE__c!=NULL && AccId.Loyalty_Tier_AE__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_AE != AccId.Loyalty_Tier_AE__c ){
                                               fieldMap.put('Loyalty_Tier_AE', AccId.Loyalty_Tier_AE__c);
                                           }
                                       }
                                       
                                       //VC Japan Update
                                       if(AccId.Loyalty_Tier_JP__c!=NULL && AccId.Loyalty_Tier_JP__c!=''){
                                           if(brazeDet.custom_attributes.Loyalty_Tier_JP != AccId.Loyalty_Tier_JP__c ){
                                               fieldMap.put('Loyalty_Tier_JP', AccId.Loyalty_Tier_JP__c);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_JP__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_JP != AccId.VIP_Since_Date_JP__c ){
                                               string jpDate = string.valueOf(AccId.VIP_Since_Date_JP__c);
                                               fieldMap.put('VIP_Since_Date_JP', jpDate);
                                           }
                                       }
                                       
                                       
                                       if(AccId.Customer_Type__c!=NULL && AccId.Customer_Type__c!=''){
                                           if(brazeDet.custom_attributes.Customer_Type != AccId.Customer_Type__c ){
                                               fieldMap.put('Customer_Type', AccId.Customer_Type__c);
                                           }
                                       }
                                       if(AccId.Subscribed_Country_SMS__c!=NULL && AccId.Subscribed_Country_SMS__c!=''){
                                           if(brazeDet.custom_attributes.sms_subscribed != AccId.Subscribed_Country_SMS__c ){
                                               fieldMap.put('sms_subscribed', AccId.Subscribed_Country_SMS__c);
                                           }
                                       }
                                       if(AccId.Customer_Mobile_Subscription_Status__c!=NULL){
                                           string value = AccId.Customer_Mobile_Subscription_Status__c == true ? 'True' : 'False';
                                           if(brazeDet.custom_attributes.sms_mobile_subscribed != value ){
                                               fieldMap.put('sms_mobile_subscribed', value);
                                           }
                                       }
                                       if(AccId.Ocapi_Customer_ID__c!=NULL && AccId.Ocapi_Customer_ID__c!=''){
                                           if(brazeDet.custom_attributes.Ocapi_Customer_Id != AccId.Ocapi_Customer_ID__c ){
                                               fieldMap.put('Ocapi_Customer_Id', AccId.Ocapi_Customer_ID__c);
                                           }
                                       }
                                       if(AccId.UTM_Term__c!=NULL && AccId.UTM_Term__c!=''){
                                           if(brazeDet.custom_attributes.utm_term != AccId.UTM_Term__c ){
                                               fieldMap.put('utm_term', AccId.UTM_Term__c);
                                           }
                                       }
                                       if(AccId.UTM_Source__c!=NULL && AccId.UTM_Source__c!=''){
                                           if(brazeDet.custom_attributes.utm_source != AccId.UTM_Source__c ){
                                               fieldMap.put('utm_source', AccId.UTM_Source__c);
                                           }
                                       }
                                       if(AccId.UTM_Medium__c!=NULL && AccId.UTM_Medium__c!=''){
                                           if(brazeDet.custom_attributes.utm_medium != AccId.UTM_Medium__c ){
                                               fieldMap.put('utm_medium', AccId.UTM_Medium__c);
                                           }
                                       }
                                       if(AccId.UTM_Content__c!=NULL && AccId.UTM_Content__c!=''){
                                           if(brazeDet.custom_attributes.utm_content != AccId.UTM_Content__c ){
                                               fieldMap.put('utm_content', AccId.UTM_Content__c);
                                           }
                                       }
                                       if(AccId.UTM_Campaign__c!=NULL && AccId.UTM_Campaign__c!=''){
                                           if(brazeDet.custom_attributes.utm_campaign != AccId.UTM_Campaign__c ){
                                               fieldMap.put('utm_campaign', AccId.UTM_Campaign__c);
                                           }
                                       }
                                       if(AccId.Last_purchase_date__c!=NULL){
                                           if(brazeDet.custom_attributes.Last_purchase_date != AccId.Last_purchase_date__c ){
                                               string pchDate = string.valueOf(AccId.Last_purchase_date__c);
                                               fieldMap.put('Last_purchase_date', pchDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_MY__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_MY != AccId.VIP_Since_Date_MY__c ){
                                               string myDate = string.valueOf(AccId.VIP_Since_Date_MY__c);
                                               fieldMap.put('VIP_Since_Date_MY', myDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_MO__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_MO != AccId.VIP_Since_Date_MO__c ){
                                               string moDate = string.valueOf(AccId.VIP_Since_Date_MO__c);
                                               fieldMap.put('VIP_Since_Date_MO', moDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_KR__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_KR != AccId.VIP_Since_Date_KR__c ){
                                               string krDate = string.valueOf(AccId.VIP_Since_Date_KR__c);
                                               fieldMap.put('VIP_Since_Date_KR', krDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_HK__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_HK != AccId.VIP_Since_Date_HK__c ){
                                               string hkDate = string.valueOf(AccId.VIP_Since_Date_HK__c);
                                               fieldMap.put('VIP_Since_Date_HK', hkDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_GB__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_GB != AccId.VIP_Since_Date_GB__c ){
                                               string gbDate = string.valueOf(AccId.VIP_Since_Date_GB__c);
                                               fieldMap.put('VIP_Since_Date_GB', gbDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_CH__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_CH != AccId.VIP_Since_Date_CH__c ){
                                               string chDate = string.valueOf(AccId.VIP_Since_Date_CH__c);
                                               fieldMap.put('VIP_Since_Date_CH', chDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_EU__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_EU != AccId.VIP_Since_Date_EU__c ){
                                               string euDate = string.valueOf(AccId.VIP_Since_Date_EU__c);
                                               fieldMap.put('VIP_Since_Date_EU', euDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_CA__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_CA != AccId.VIP_Since_Date_CA__c ){
                                               string caDate = string.valueOf(AccId.VIP_Since_Date_CA__c);
                                               fieldMap.put('VIP_Since_Date_CA', caDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_AU__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_AU != AccId.VIP_Since_Date_AU__c ){
                                               string auDate = string.valueOf(AccId.VIP_Since_Date_AU__c);
                                               fieldMap.put('VIP_Since_Date_AU', auDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_AE__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_AE != AccId.VIP_Since_Date_AE__c ){
                                               string aeDate = string.valueOf(AccId.VIP_Since_Date_AE__c);
                                               fieldMap.put('VIP_Since_Date_AE', aeDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_MT__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_MT != AccId.VIP_Since_Date_MT__c ){
                                               string mtDate = string.valueOf(AccId.VIP_Since_Date_MT__c);
                                               fieldMap.put('VIP_Since_Date_MT', mtDate);
                                               
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_NO__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_NO != AccId.VIP_Since_Date_NO__c ){
                                               string noDate = string.valueOf(AccId.VIP_Since_Date_NO__c);
                                               fieldMap.put('VIP_Since_Date_NO', noDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_NZ__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_NZ != AccId.VIP_Since_Date_NZ__c ){
                                               string nzDate = string.valueOf(AccId.VIP_Since_Date_NZ__c);
                                               fieldMap.put('VIP_Since_Date_NZ', nzDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_UK__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_UK != AccId.VIP_Since_Date_UK__c ){
                                               string ukDate = string.valueOf(AccId.VIP_Since_Date_UK__c);
                                               fieldMap.put('VIP_Since_Date_UK', ukDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_KH__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_KH != AccId.VIP_Since_Date_KH__c ){
                                               string khDate = string.valueOf(AccId.VIP_Since_Date_KH__c);
                                               fieldMap.put('VIP_Since_Date_KH', khDate);
                                           }
                                       }
                                       if(AccId.Shoe_Size__c!=NULL){
                                           if(brazeDet.custom_attributes.Shoe_Size != AccId.Shoe_Size__c ){
                                               string shoe = string.valueOf(AccId.Shoe_Size__c);
                                               fieldMap.put('Shoe_Size', shoe);
                                           }
                                       }
                                       if(AccId.First_Date_Of_Purchase__c!=NULL ){
                                           if(brazeDet.custom_attributes.First_Date_Of_Purchase != AccId.First_Date_Of_Purchase__c ){
                                               string firstDate = string.valueOf(AccId.First_Date_Of_Purchase__c);
                                               fieldMap.put('First_Date_Of_Purchase', firstDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_US__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_US != AccId.VIP_Since_Date_US__c ){
                                               string usDate = string.valueOf(AccId.VIP_Since_Date_US__c);
                                               fieldMap.put('VIP_Since_Date_US', usDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_TW__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_TW != AccId.VIP_Since_Date_TW__c ){
                                               string twDate = string.valueOf(AccId.VIP_Since_Date_TW__c);
                                               fieldMap.put('VIP_Since_Date_TW', twDate);
                                           }
                                       }
                                       if(AccId.VIP_Since_Date_SG__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_SG != AccId.VIP_Since_Date_SG__c ){
                                               string sgDate = string.valueOf(AccId.VIP_Since_Date_SG__c);
                                               fieldMap.put('VIP_Since_Date_SG', sgDate);
                                           }
                                       }
                                       if(AccId.Reseller_Flag__c!=NULL){
                                           string value = AccId.Reseller_Flag__c == true ? 'True':'False';
                                           if(brazeDet.custom_attributes.Reseller_Flag != value ){
                                               fieldMap.put('Reseller_Flag', value);
                                           }
                                       }
                                                                              
                                       if(AccId.VIP_Since_Date_PAK__c!=NULL ){
                                           if(brazeDet.custom_attributes.VIP_Since_Date_PAK != AccId.VIP_Since_Date_PAK__c ){
                                               string pakDate = string.valueOf(AccId.VIP_Since_Date_PAK__c);
                                               fieldMap.put('VIP_Since_Date_PAK', pakDate);
                                           }
                                       }
                                       
                                       if(AccId.Social_Account_Provider_ID__c!=NULL && AccId.Social_Account_Provider_ID__c!=''){
                                           if(brazeDet.custom_attributes.Social_Account_Provider_ID != AccId.Social_Account_Provider_ID__c ){
                                               fieldMap.put('Social_Account_Provider_ID', AccId.Social_Account_Provider_ID__c);
                                           }
                                       }
                                       
                                       if(AccId.Last_Purchased_Store__c!=NULL && AccId.Last_Purchased_Store__c!=''){
                                           if(brazeDet.custom_attributes.Last_Purchased_Store != AccId.Last_Purchased_Store__c ){
                                               fieldMap.put('Last_Purchased_Store', AccId.Last_Purchased_Store__c);
                                           }
                                       }   
                                       
                                         if(AccId.Subscribed_Whatsapp__c!=NULL){
                                           string value = AccId.Subscribed_Whatsapp__c == true ? 'True':'False';
                                           if(brazeDet.custom_attributes.Subscribed_Mobile_Messaging != value ){
                                               fieldMap.put('Subscribed_Mobile_Messaging', value);
                                           }
                                       }
                                       if(AccId.Subscribed_Country_Whatsapp__c!=NULL && AccId.Subscribed_Country_Whatsapp__c!=''){
                                           if(brazeDet.custom_attributes.Subscribed_Country_Mobile_Messaging != AccId.Subscribed_Country_Whatsapp__c ){
                                               fieldMap.put('Subscribed_Country_Mobile_Messaging', AccId.Subscribed_Country_Whatsapp__c);
                                           }
                                       }
                                       
                                       If(recordType!=null && recordType.endsWithIgnoreCase('PD')){
                                           if(brazeDet.custom_attributes.subscribed_content_gender != AccId.Subscribed_Content_Gender__c){
                                               fieldMap.put('subscribed_content_gender', AccId.Subscribed_Content_Gender__c);
                                           } 
                                       }
                                       
                                       if(AccId.TotalOrderAmt_SGD__c!=NULL || AccId.TotalRefundAmt_SGD__c!=NULL ){
                                           Decimal TotalOrderAmt=AccId.TotalOrderAmt_SGD__c!=null ? AccId.TotalOrderAmt_SGD__c: 0;
                                           Decimal TotalRefundAmt=AccId.TotalRefundAmt_SGD__c!=null ? AccId.TotalRefundAmt_SGD__c: 0;
                                           Decimal Total_LTV = TotalOrderAmt - TotalRefundAmt;
                                           if(brazeDet.custom_attributes.Total_LTV_Value_In_SGD != Total_LTV){
                                               string Total_LTV_SGD = string.valueof(Total_LTV);
                                               fieldMap.put('Total_LTV_Value_In_SGD', Total_LTV_SGD);
                                           }
                                       }
                                       
                                       if(AccId.Lifetime_Value__c!=NULL ){
                                           if(brazeDet.custom_attributes.Global_LTV_In_SGD != AccId.Lifetime_Value__c ){
                                               string ltvValue = string.valueOf(AccId.Lifetime_Value__c);
                                               fieldMap.put('Global_LTV_In_SGD', ltvValue);
                                           }
                                       }
                                       
                                       if(AccId.Total_Value_spends_within_Last_12_months__c!=NULL ){
                                           if(brazeDet.custom_attributes.Global_L12M_Spend_In_SGD != AccId.Total_Value_spends_within_Last_12_months__c ){
                                               string ltvValue = string.valueOf(AccId.Total_Value_spends_within_Last_12_months__c);
                                               fieldMap.put('Global_L12M_Spend_In_SGD', ltvValue);
                                           }
                                       }
                                       system.debug('fieldMap:: '+fieldMap);
                                       if(fieldMap.size() > 1){
                                           fieldMapList.add(fieldMap);
                                           AccountIds.add(AccId.id);
                                       }else{
                                           AccIds.add(AccId.id);
                                       }
                                   }
                
                JSONGenerator gen = json.createGenerator(true);
                gen.writeStartObject();
                gen.writeObjectField('attributes', fieldMapList);
                gen.writeEndObject();
                
                string request = gen.getAsString();
                
                system.debug('fieldMapList.size()--'+fieldMapList.size());
                List<Account> AccLst = new List<Account>();
                if(fieldMapList.size() > 0){
                    ZBraze_Account_Callout.AccountDetailsToBrazeCallOut(request, recordType, AccountIds);
                }
                system.debug('AccIds--'+AccIds);
                if(!AccIds.isEmpty() && AccIds.size() > 0){
                    List<Account> AccountLst = ZBraze_Account_Callout.updateIFStatus(AccIds,'Completed');
                    if(AccountLst.size()>0){
                        ICAccountTriggerHandler.suspendTrigger = true;
                        update AccountLst;
                    }
                }
                
            }
        }catch(Exception e){
            String Des='getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage();
            ZBraze_Account_Callout.CreateErrorLog(Des,'','','','Batch','Backend Process Error');     
        }
    }
    
    
    public class ResponseBody{
        public Integer attributes_processed{get;set;}
        public String message{get;set;}
        public List<error> errors{get;set;} 
    }
    public class error{
        public String type{get;set;} 
        public String input_array{get;set;} 
        public Integer index{get;set;} 
    }
}