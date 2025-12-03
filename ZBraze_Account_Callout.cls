/********************************************************************************************************
* (C) Copyright 2023 Charles & Keith. All rights reserved.
* This code is property of Charles & Keith. Use, duplication and
* disclosure in any form without permission of copyright holder is prohibited.
* 
******************************************************************************************************* 
* @author Gokilavani V
* @version 1.0
* @created 07/08/2023
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
public class ZBraze_Account_Callout {
    
    
    @future (callout = true)
    public static void exportUserDetailsByAlias(string recordType,set<Id> accountIds){
        map<string,id> accIdEmailMap = new map<string,id>(); // key - email and values accid
        list<UserAliases> UserAliasesList = new list<UserAliases>();
        UserAliasWrapper wrapper = new UserAliasWrapper(); //main wrapper
        
        //VC JP Update
        String newrecordtype;
        if ((recordType == 'CK') || (recordType == 'JP')){
            newrecordtype = 'CK';
        }else if(recordType == 'PD'){
            newrecordtype = 'PD';
        }        
        ZBraze_API_Master__c exportApiDetials = ZBraze_API_Master__c.getvalues(newrecordtype);
       
        ExportUsers userResponse = new ExportUsers();
        map<string, string> extIdMap = new map<string, string>();
        map<string, string> aliasMap = new map<string, string>();
        Set<Id> createIds = new Set<Id>();
        List<String> createEmails = new List<String>();
        Set<ID> invalidAliasIdList = new Set<ID>();
        List<string> invalidAliasList = new List<string>();
        List<string> createIds1 = new List<string>();
        List<Account> AccLst = new List<Account>();
        try{
            for(Account acc:[select id,personemail from account where id in :accountIds]){
                accIdEmailMap.put(acc.personEmail, acc.id);
                
                UserAliases userAlias = new UserAliases();
                userAlias.alias_name = acc.personEmail;
                userAlias.alias_label = 'Identifier';
                UserAliasesList.add(userAlias);
                createIds1.add(acc.id);
            }
            wrapper.User_Aliases = UserAliasesList;
            wrapper.fields_to_export = new list<string>{
                'external_id',
                    'user_aliases'
                    };
                        string ExportRequest = JSON.serialize(wrapper);
            system.debug('ExportRequest:: '+ExportRequest);
            HttpResponse ExportResponse =ZBraze_HTTPConnector.performHTTPCallout(ExportRequest,exportApiDetials.ExportIds__c,exportApiDetials.Method__c,exportApiDetials.Header__c,exportApiDetials.Access_Token__c,36000,
                                                                                 'ZBraze_Account_Callout','exportUserDetailsByAlias');
            
            system.debug('ExportResponse:: '+ExportResponse);
            
            if(ExportResponse != null){
                userResponse=(ExportUsers)JSON.deserialize(ExportResponse.getbody(), ExportUsers.class);
            }
            if(ExportResponse.getStatusCode() >=200 && ExportResponse.getStatusCode()<=299){
                if(userResponse != null && userResponse.users != null && userResponse.users.size()>0){
                    system.debug('enter userResponse.users');
                    for(user userObj: userResponse.users){
                        if(userObj.external_id == null){
                            string email = userObj.user_aliases[0].alias_name;
                            string extId = accIdEmailMap.get(email);
                            extIdMap.put(extId,email);
                            createIds.add(extId);
                            createEmails.add(email);
                        }
                    }
                    //VC JP Update
                    if(!extIdMap.isEmpty()){
                        updateBrazeExternalIdUsingAlias(newrecordtype, extIdMap);
                    }
                     if(!createEmails.isEmpty() && createEmails.size()>0){
                        createAccountInBraze(recordType, createEmails);
                     }
                }
                if(userResponse != null && userResponse.invalid_aliases != null  && userResponse.invalid_aliases.size()>0){
                    
                    system.debug('enter userResponse.invalid_aliases');
                    for(UserAliases invalid: userResponse.invalid_aliases){
                        invalidAliasList.add(invalid.alias_name);
                        invalidAliasIdList.add(accIdEmailMap.get(invalid.alias_name));
                        aliasMap.put(accIdEmailMap.get(invalid.alias_name),invalid.alias_name);
                    }
                    system.debug('invalidAliasIdList--'+invalidAliasIdList);
                    system.debug('recordtype--'+recordtype);
                    system.debug('aliasMap--'+aliasMap);
                    
                     if(!invalidAliasList.isempty() && !aliasMap.isempty()&& invalidAliasList.size()>0){
                        createAccountInBraze(recordType,invalidAliasList);
                        
                    }
                    
                }
            }else{
                accLst=ZBraze_account_callout.updateIFStatus(accountIds,'Pending');
                ZBraze_account_callout.CreateErrorLog('Message :: '+ExportResponse.getStatusCode()+' :: '+userResponse.message+'  Account ID :: '+accountIds,exportApiDetials.Endpoint_Url__c,ExportRequest,String.valueOf(ExportResponse.getbody()),'Trigger','Integration Error');
                
            }
            if(AccLst.size()>0){
                ICAccountTriggerHandler.suspendTrigger = true;
                update AccLst;
            }
            
        }catch(Exception e){
            CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage()+' Account ID'+accountIds,'','','','Trigger','Backend Process Error');
        }
        
    }
    
    
    public class invalisAliasWrapper{
        public list<string> external_ids;
        public list<string> fields_to_export;
    }
    //────────────────────────────────────────────────────────────────────────────────────┐
    //This method is used to update the ExternalId using aliasName as email into the Braze
    //endpoint: https://rest.iad-05.braze.com/users/identify
    //@params: 
    //	recordType - CK or PD
    //	ExtIdwithAliasMap - key ExtId and value alias
    //────────────────────────────────────────────────────────────────────────────────────┘
    public static void updateBrazeExternalIdUsingAlias(string recordType, map<string, string> ExtIdwithAliasMap){
        system.debug('updateBrazeExternalIdwithAlias recordType:: '+recordType);
        system.debug('updateBrazeExternalIdwithAlias ExtIdwithAliasMap:: '+ExtIdwithAliasMap);
        
        ZBraze_API_Master__c apiDetials = ZBraze_API_Master__c.getvalues(recordType);
        UpdateAliaswithExtIdWrapper wrapper = new UpdateAliaswithExtIdWrapper();
        list<UpdateAliaswithExtId> aliases_to_identifyList = new list<UpdateAliaswithExtId>();
        try{
            if(string.isNotBlank(recordType) && !ExtIdwithAliasMap.isEmpty()){
                for(string extId: ExtIdwithAliasMap.keyset()){
                    UpdateAliaswithExtId wrap = new UpdateAliaswithExtId();
                    wrap.external_id = extId;
                    
                    UserAliases aliasWrap = new UserAliases();
                    aliasWrap.alias_name = ExtIdwithAliasMap.get(extId);
                    aliasWrap.alias_label = 'Identifier';
                    
                    wrap.user_alias = aliasWrap;
                    aliases_to_identifyList.add(wrap);
                }
                wrapper.aliases_to_identify = aliases_to_identifyList;
                wrapper.merge_behavior = 'merge';
                
                string request = JSON.serialize(wrapper);
                system.debug('updateBrazeExternalIdwithAlias Request:: '+request);
                
                HttpResponse response =ZBraze_HTTPConnector.performHTTPCallout(request,apiDetials.User_Identity_EndPoint__c,apiDetials.Method__c,apiDetials.Header__c,apiDetials.Access_Token__c,36000,
                                                                               'ZBraze_Account_Callout','updateBrazeExternalIdUsingAlias');
                system.debug('updateBrazeExternalIdwithAlias response:: '+response.getbody());
                
                
            }
        }catch(Exception e){
            CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage()+' ExtIdwithAliasMap :: '+ExtIdwithAliasMap,'','','','Trigger','Backend Process Error');     
        } 
    }
    
    
    
    //────────────────────────────────────────────────────────────────────────────────────┐
    //This method is used to create standard/custom attributes into the Braze
    //endpoint: 
    //@params: 
    //	recordType - CK or PD
    //	AliasNameList - list of PersonEmails from account
    //────────────────────────────────────────────────────────────────────────────────────┘
    //This method is common for both trigger and Batch apporach
    public static void createAccountInBraze(string recordType,List<String> createEmails /*Set<Id> inputIds*/){
        
        //VC JP Update
        String newrecordtype;
        if ((recordType == 'CK') || (recordType == 'JP')){
            newrecordtype = 'CK';
        }else if(recordType == 'PD'){
            newrecordtype = 'PD';
        }
        ZBraze_API_Master__c Apilist = ZBraze_API_Master__c.getvalues(newrecordtype);
        
        Map<String, List<String>> languageSiteMap = ZBraze_Account_APIHandler.getLangSiteurlForCustomers();
        list<map<string, string>> fieldMapList = new list<map<string, string>>();
        ID RecordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        set<id> accids=new set<Id>();

        try{
            //VC Japan Update
            for(Account AccId:[SELECT Id,Name,LastName,FirstName,PersonEmail,Registration_Country__c,PersonBirthdate,Gender__c ,
                               Residential_Address_City__c,Subscribed_Country_Email__c,PersonMobilePhone,Email_Subscription_Status__c,
                               Customer_Type__c,Last_Login_Date__c,Last_purchase_date__c,/*Days_Since_Last_Login__c,Days_since_last_purchase__c,*/
                               Favored_Medium_Of_Purchase__c,
                               First_Date_Of_Purchase__c,Loyalty_Tier_AE__c,Loyalty_Tier_AU__c,Loyalty_Tier_CA__c,Loyalty_Tier_CH__c,
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
                               Customer_Mobile_Subscription_Status__c,UTM_Campaign__c,UTM_Content__c,UTM_Medium__c,Retail_store__c,
                               UTM_Source__c,UTM_Term__c,Reseller_Flag__c,Last_purchase_Channel__c,Social_Account_Provider_ID__c,
                               Last_Purchased_Store__c,Subscribed_Whatsapp__c,Subscribed_Country_Whatsapp__c  from Account where /*id=: inputIds*/ PersonEmail = :createEmails AND RecordTypeId =: RecordTypeId]){
                                   
                                   List<String> cusMdt = new List<String> ();
                                   accids.add(AccId.id);
                                   
                                   
                                   
                                   if(AccId.Subscribed_Country_Email__c!=null && AccId.Subscribed_Country_Email__c!=''){
                                       cusMdt = languageSiteMap.get(AccId.Subscribed_Country_Email__c);
                                   }                                  
                                   map<string, string> fieldMap = new map<string, string>();
                                   fieldMap.put('external_id', AccId.id);
                                   
                                   if(AccId.FirstName!=NULL && AccId.FirstName!=''){                                           
                                       fieldMap.put('first_name', AccId.FirstName);                                           
                                   }
                                   if(AccId.LastName!=NULL && AccId.LastName!=''){                                           
                                       fieldMap.put('last_name', AccId.LastName);                                           
                                   }
                                   if(AccId.PersonEmail!=NULL && AccId.PersonEmail!=''){                                          
                                       fieldMap.put('email', AccId.PersonEmail);                                           
                                   }
                                   if(AccId.Registration_Country__c!=NULL && AccId.Registration_Country__c!=''){                                           
                                       fieldMap.put('country', AccId.Registration_Country__c);                                           
                                   }
                                   if(AccId.PersonBirthdate!=NULL ){                                          
                                       string dob = string.valueOf(AccId.PersonBirthdate);
                                       fieldMap.put('dob', dob);                                           
                                   }
                                   
                                   if(AccId.Gender__c!=NULL && AccId.Gender__c!=''){                                         
                                       fieldMap.put('gender', AccId.Gender__c);                                                                                        
                                   }
                                   if(AccId.Residential_Address_City__c!=NULL && AccId.Residential_Address_City__c!=''){                                          
                                       fieldMap.put('home_city', AccId.Residential_Address_City__c);
                                   } 
                                   
                                   
                                   if(AccId.Subscribed_Country_Email__c!=null && cusMdt != null){                                          
                                       fieldMap.put('language', cusMdt[0] );                              
                                       
                                       fieldMap.put('Site_URL', cusMdt[1] );                                           
                                   }
                                   if(AccId.PersonMobilePhone != null){                                        
                                       fieldMap.put('phone', AccId.PersonMobilePhone);                                           
                                   }
                                   
                                   if(AccId.Email_Subscription_Status__c!=NULL ){
                                       string accValue = AccId.Email_Subscription_Status__c == True ? 'subscribed':'unsubscribed';                                           
                                       fieldMap.put('email_subscribe', accValue );                                           
                                   }
                                   
                                   if(AccId.Customer_Type__c!=NULL && AccId.Customer_Type__c!=''){                                         
                                       fieldMap.put('Customer_Type', AccId.Customer_Type__c);                                           
                                   }  
                                   
                                   if(AccId.Last_Login_Date__c!=NULL ){                                          
                                       string loginDate = string.valueOf(AccId.Last_Login_Date__c);
                                       fieldMap.put('Last_Login_Date', loginDate);                                           
                                   }
                                   
                                   if(AccId.Last_purchase_date__c!=NULL){                                          
                                       string pchDate = string.valueOf(AccId.Last_purchase_date__c);
                                       fieldMap.put('Last_purchase_date', pchDate);
                                   }                                  
                                   
                                   
                                   if(AccId.First_Date_Of_Purchase__c!=NULL ){                                          
                                       string firstDate = string.valueOf(AccId.First_Date_Of_Purchase__c);
                                       fieldMap.put('First_Date_Of_Purchase', firstDate);                                           
                                   }
                                   
                                   if(AccId.Loyalty_Tier_AE__c!=NULL && AccId.Loyalty_Tier_AE__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_AE', AccId.Loyalty_Tier_AE__c);                                           
                                   }
                                   if(AccId.Loyalty_Tier_AU__c!=NULL && AccId.Loyalty_Tier_AU__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_AU', AccId.Loyalty_Tier_AU__c);                                           
                                   }     
                                   if(AccId.Loyalty_Tier_CA__c!=NULL && AccId.Loyalty_Tier_CA__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_CA', AccId.Loyalty_Tier_CA__c);                                           
                                   }
                                   if(AccId.Loyalty_Tier_CH__c!=NULL && AccId.Loyalty_Tier_CH__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_CH', AccId.Loyalty_Tier_CH__c);                                           
                                   }     
                                   if(AccId.Loyalty_Tier_EU__c!=NULL && AccId.Loyalty_Tier_EU__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_EU', AccId.Loyalty_Tier_EU__c);                                           
                                   }       
                                   if(AccId.Loyalty_Tier_GB__c!=NULL && AccId.Loyalty_Tier_GB__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_GB', AccId.Loyalty_Tier_GB__c);                                           
                                   }
                                   if(AccId.Loyalty_Tier_HK__c!=NULL && AccId.Loyalty_Tier_HK__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_HK', AccId.Loyalty_Tier_HK__c);                                           
                                   }
                                   if(AccId.Loyalty_Tier_KH__c!=NULL && AccId.Loyalty_Tier_KH__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_KH', AccId.Loyalty_Tier_KH__c);                                           
                                   }
                                   if(AccId.Loyalty_Tier_KR__c!=NULL && AccId.Loyalty_Tier_KR__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_KR', AccId.Loyalty_Tier_KR__c);                                           
                                   }
                                   if(AccId.Loyalty_Tier_MO__c!=NULL && AccId.Loyalty_Tier_MO__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_MO', AccId.Loyalty_Tier_MO__c);                                           
                                   }
                                   if(AccId.Loyalty_Tier_MT__c!=NULL && AccId.Loyalty_Tier_MT__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_MT', AccId.Loyalty_Tier_MT__c);                                           
                                   }
                                   if(AccId.Loyalty_Tier_MY__c!=NULL && AccId.Loyalty_Tier_MY__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_MY', AccId.Loyalty_Tier_MY__c);                                           
                                   }
                                   if(AccId.Loyalty_Tier_NO__c!=NULL && AccId.Loyalty_Tier_NO__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_NO', AccId.Loyalty_Tier_NO__c);                                           
                                   }
                                   if(AccId.Loyalty_Tier_NZ__c!=NULL && AccId.Loyalty_Tier_NZ__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_NZ', AccId.Loyalty_Tier_NZ__c);                                           
                                   }
                                   if(AccId.Loyalty_Tier_PAK__c!=NULL && AccId.Loyalty_Tier_PAK__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_PAK', AccId.Loyalty_Tier_PAK__c);                                           
                                   }
                                   if(AccId.Loyalty_Tier_SG__c!=NULL && AccId.Loyalty_Tier_SG__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_SG', AccId.Loyalty_Tier_SG__c);                                           
                                   }
                                   
                                   if(AccId.Loyalty_Tier_TW__c!=NULL && AccId.Loyalty_Tier_TW__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_TW', AccId.Loyalty_Tier_TW__c);                                           
                                   }
                                   
                                   if(AccId.Loyalty_Tier_UK__c!=NULL && AccId.Loyalty_Tier_UK__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_UK', AccId.Loyalty_Tier_UK__c);                                           
                                   }
                                   if(AccId.Loyalty_Tier_US__c!=NULL && AccId.Loyalty_Tier_US__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_US', AccId.Loyalty_Tier_US__c);                                           
                                   }
                                   
                                   //VC Japan Update 
                                   if(AccId.Loyalty_Tier_JP__c!=NULL && AccId.Loyalty_Tier_JP__c!=''){                                           
                                       fieldMap.put('Loyalty_Tier_JP', AccId.Loyalty_Tier_JP__c);                                           
                                   }
    							   if(AccId.VIP_Since_Date_JP__c !=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_JP__c );
                                       fieldMap.put('VIP_Since_Date_JP', myDate);                                           
                                   }	
                                   
                                   if(AccId.Mode_of_registration__c!=NULL && AccId.Mode_of_registration__c!=''){                                          
                                       fieldMap.put('Mode_of_registration', AccId.Mode_of_registration__c);                                           
                                   }
                                   
                                   if(AccId.Most_Purchased_Category__c!=NULL && AccId.Most_Purchased_Category__c!=''){                                         
                                       fieldMap.put('Most_Purchased_Category', AccId.Most_Purchased_Category__c);                                           
                                   }
                                   if(AccId.Most_Purchased_Color__c!=NULL && AccId.Most_Purchased_Color__c!=''){                                           
                                       fieldMap.put('Most_Purchased_Color', AccId.Most_Purchased_Color__c);
                                   }
                                   
                                   if(AccId.Registration_Date__c!=NULL ){                                          
                                       string regDate = string.valueOf(AccId.Registration_Date__c);
                                       fieldMap.put('Registration_Date', regDate);                                           
                                   }
                                   
                                   if(AccId.School_University_Name__c!=NULL && AccId.School_University_Name__c!=''){                                           
                                       fieldMap.put('School_University_Name', AccId.School_University_Name__c);
                                   }
                                   else if(AccId.School_University_Name_Other__c!=NULL && AccId.School_University_Name_Other__c!='')
                                   {
                                       fieldMap.put('School_University_Name', AccId.School_University_Name_Other__c);
                                   }
                                   
                                   
                                   if(AccId.Shoe_Size__c!=NULL){                                           
                                       string shoe = string.valueOf(AccId.Shoe_Size__c);
                                       fieldMap.put('Shoe_Size', shoe);                                           
                                   }
                                   
                                   if(AccId.VIP_Since_Date_AE__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_AE__c);
                                       fieldMap.put('VIP_Since_Date_AE', myDate);
                                   }
                                   if(AccId.VIP_Since_Date_AU__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_AU__c);
                                       fieldMap.put('VIP_Since_Date_AU', myDate);                                           
                                   }
                                   if(AccId.VIP_Since_Date_CA__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_CA__c);
                                       fieldMap.put('VIP_Since_Date_CA', myDate);                                           
                                   }   
                                   if(AccId.VIP_Since_Date_CH__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_CH__c);
                                       fieldMap.put('VIP_Since_Date_CH', myDate);                                           
                                   }  
                                   if(AccId.VIP_Since_Date_EU__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_EU__c);
                                       fieldMap.put('VIP_Since_Date_EU', myDate);                                           
                                   }  
                                   if(AccId.VIP_Since_Date_GB__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_GB__c);
                                       fieldMap.put('VIP_Since_Date_GB', myDate);                                           
                                   }   
                                   if(AccId.VIP_Since_Date_HK__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_HK__c);
                                       fieldMap.put('VIP_Since_Date_HK', myDate);                                           
                                   }   
                                   
                                   if(AccId.VIP_Since_Date_KR__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_KR__c);
                                       fieldMap.put('VIP_Since_Date_KR', myDate);                                           
                                   }
                                   if(AccId.VIP_Since_Date_MO__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_MO__c);
                                       fieldMap.put('VIP_Since_Date_MO', myDate);                                           
                                   }
                                   if(AccId.VIP_Since_Date_MT__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_MT__c);
                                       fieldMap.put('VIP_Since_Date_MT', myDate);                                           
                                   }
                                   
                                   if(AccId.VIP_Since_Date_NO__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_NO__c);
                                       fieldMap.put('VIP_Since_Date_NO', myDate);                                           
                                   }
                                   
                                   if(AccId.VIP_Since_Date_NZ__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_NZ__c);
                                       fieldMap.put('VIP_Since_Date_NZ', myDate);                                           
                                   }
                                   if(AccId.VIP_Since_Date_PAK__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_PAK__c);
                                       fieldMap.put('VIP_Since_Date_PAK', myDate);                                           
                                   } 
                                   if(AccId.VIP_Since_Date_SG__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_SG__c);
                                       fieldMap.put('VIP_Since_Date_SG', myDate);                                           
                                   }
                                   if(AccId.VIP_Since_Date_TW__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_TW__c);
                                       fieldMap.put('VIP_Since_Date_TW', myDate);                                           
                                   }
                                   if(AccId.VIP_Since_Date_UK__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_UK__c);
                                       fieldMap.put('VIP_Since_Date_UK', myDate);                                           
                                   }
                                   if(AccId.VIP_Since_Date_US__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_US__c);
                                       fieldMap.put('VIP_Since_Date_US', myDate);                                           
                                   }
                                   if(AccId.VIP_Since_Date_KH__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_KH__c);
                                       fieldMap.put('VIP_Since_Date_KH', myDate);                                           
                                   }
                                   if(AccId.VIP_Since_Date_MY__c!=NULL ){                                          
                                       string myDate = string.valueOf(AccId.VIP_Since_Date_MY__c);
                                       fieldMap.put('VIP_Since_Date_MY', myDate);                                           
                                   }
                                   if(AccId.Source__c!=NULL && AccId.Source__c!=''){                                           
                                       fieldMap.put('Source', AccId.Source__c);                                           
                                   }
                                   if(AccId.Subscribed_Country_SMS__c!=NULL && AccId.Subscribed_Country_SMS__c!=''){                                           
                                       fieldMap.put('sms_subscribed', AccId.Subscribed_Country_SMS__c);                                           
                                   }
                                   if(AccId.Customer_Mobile_Subscription_Status__c!=NULL){  
                                       
                                       fieldMap.put('sms_mobile_subscribed',AccId.Customer_Mobile_Subscription_Status__c==true?'True':'False');                                           
                                   }							   
                                   
                                   if(AccId.Ocapi_Customer_ID__c!=NULL && AccId.Ocapi_Customer_ID__c!=''){                                           
                                       fieldMap.put('Ocapi_Customer_Id', AccId.Ocapi_Customer_ID__c);  	}						
                                   if(AccId.UTM_Campaign__c!=NULL && AccId.UTM_Campaign__c!=''){                                           
                                       fieldMap.put('utm_campaign', AccId.UTM_Campaign__c);  
                                   }						
                                   if(AccId.UTM_Content__c!=NULL && AccId.UTM_Content__c!=''){                                           
                                       fieldMap.put('utm_content', AccId.UTM_Content__c);  
                                   }	
                                   if(AccId.UTM_Medium__c!=NULL && AccId.UTM_Medium__c!=''){                                           
                                       fieldMap.put('utm_medium', AccId.UTM_Medium__c);  
                                   }								   
                                   if(AccId.UTM_Source__c!=NULL && AccId.UTM_Source__c!=''){                                           
                                       fieldMap.put('utm_source', AccId.UTM_Source__c);  
                                   }								   
                                   if(AccId.UTM_Term__c!=NULL && AccId.UTM_Term__c!=''){                                           
                                       fieldMap.put('utm_term', AccId.UTM_Term__c);  
                                   }	
                                   if(AccId.Last_purchase_Channel__c !=NULL && AccId.Last_purchase_Channel__c!=''){                                           
                                       fieldMap.put('Last_Purchase_Channel', AccId.Last_purchase_Channel__c);  
                                   }
                                   if(AccId.Retail_store__c !=NULL && AccId.Retail_store__c !=''){                                           
                                       fieldMap.put('Registered_Retail_Store', AccId.Retail_store__c);  
                                   }
                                   if(AccId.Reseller_Flag__c!=NULL ){                                           
                                       fieldMap.put('Reseller_Flag', AccId.Reseller_Flag__c==true?'True':'False');                                           
                                   }
                                   if(AccId.Social_Account_Provider_ID__c!=null && AccId.Social_Account_Provider_ID__c!=''){
                                       fieldMap.put('Social_Account_Provider_ID', AccId.Social_Account_Provider_ID__c);  
                                   }
                                    if(AccId.Last_Purchased_Store__c!=null && AccId.Last_Purchased_Store__c!=''){
                                       fieldMap.put('Last_Purchased_Store', AccId.Last_Purchased_Store__c);  
                                   }
                                     if(AccId.Subscribed_Whatsapp__c!=NULL ){                                           
                                       fieldMap.put('Subscribed_Mobile_Messaging', AccId.Subscribed_Whatsapp__c==true?'True':'False');                                           
                                   }
                                   if(AccId.Subscribed_Country_Whatsapp__c!=null && AccId.Subscribed_Country_Whatsapp__c!=''){
                                       fieldMap.put('Subscribed_Country_Mobile_Messaging', AccId.Subscribed_Country_Whatsapp__c);  
                                   }
                              
                                   if(recordType!=null && recordType.endsWithIgnoreCase('PD')){
                                       if(AccId.Subscribed_Content_Gender__c!=NULL && AccId.Subscribed_Content_Gender__c!=''){                                           
                                           fieldMap.put('subscribed_content_gender', AccId.Subscribed_Content_Gender__c);  
                                       }
                                   }							   
                                   system.debug('fieldMap:: '+fieldMap);
                                   if(fieldMap.size() > 1){
                                       fieldMapList.add(fieldMap);
                                   }
                               }   
            if(fieldMapList.size() > 0){
                JSONGenerator gen = json.createGenerator(true);
                gen.writeStartObject();
                gen.writeObjectField('attributes', fieldMapList);
                gen.writeEndObject();
                
                string request = gen.getAsString();
                
                //VC JP Update
                AccountDetailsToBrazeCallOut(request,newrecordtype,accids);
                
             }
            
        }catch(Exception e){ 
            CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage()+'Account ID :: '+accids+' createEmails ::'+createEmails,'','','','Trigger','Backend Process Error');     
        }
    }
    
    public static void UpdateAccountDetailsToBraze(string recordType,Set<id> inputnewAccount){  
        
        list<map<string, string>> fieldMapList = new list<map<string, string>>();
        Map<String, List<String>> languageSiteMap = ZBraze_Account_APIHandler.getLangSiteurlForCustomers();
        Set<Id> AccountIds = new Set<Id>();
        try{
            for(Id AccId: Trigger.newMap.keySet()){
                
                Account oldAccount = (Account)Trigger.oldMap.get(AccId);
                Account newAccount = (Account)Trigger.NewMap.get(AccId);
                
                List<String> cusMdt = new List<String> ();
                if(newAccount.Subscribed_Country_Email__c!=null && newAccount.Subscribed_Country_Email__c!=''){
                    cusMdt = languageSiteMap.get(newAccount.Subscribed_Country_Email__c);
                }
                
                map<string, string> fieldMap = new map<string, string>();
                fieldMap.put('external_id', newAccount.id);
                
                if(newAccount.FirstName!=NULL && newAccount.FirstName!=''){
                    if(oldAccount.FirstName !=newAccount.FirstName ){
                        fieldMap.put('first_name', newAccount.FirstName);
                    }
                }
                if(newAccount.LastName!=NULL && newAccount.LastName!=''){
                    if(oldAccount.LastName !=newAccount.LastName ){
                        fieldMap.put('last_name', newAccount.LastName);
                    }
                }
                if(newAccount.PersonMobilePhone != null){
                    if(oldAccount.PersonMobilePhone != newAccount.PersonMobilePhone ){
                        fieldMap.put('phone', newAccount.PersonMobilePhone);
                    }
                }
                if(newAccount.PersonEmail!=NULL && newAccount.PersonEmail!=''){
                    if(oldAccount.PersonEmail !=newAccount.PersonEmail ){
                        fieldMap.put('email', newAccount.PersonEmail);
                    }
                }
                if(newAccount.PersonBirthdate!=NULL ){
                    if(oldAccount.PersonBirthdate !=newAccount.PersonBirthdate ){
                        string dob = string.valueOf(newAccount.PersonBirthdate);
                        fieldMap.put('dob', dob);
                    }
                }
                if(newAccount.Registration_Country__c!=NULL && newAccount.Registration_Country__c!=''){
                    if(oldAccount.Registration_Country__c !=newAccount.Registration_Country__c ){
                        fieldMap.put('country', newAccount.Registration_Country__c);
                    }
                }
                if(newAccount.Residential_Address_City__c!=NULL && newAccount.Residential_Address_City__c!=''){
                    if(oldAccount.Residential_Address_City__c !=newAccount.Residential_Address_City__c ){
                        fieldMap.put('home_city', newAccount.Residential_Address_City__c);
                    }
                }
                if(newAccount.Gender__c!=NULL && newAccount.Gender__c!=''){
                    
                    if(oldAccount.Gender__c!= newAccount.Gender__c  ){
                        fieldMap.put('gender', newAccount.Gender__c);   
                    }
                    
                }
                if(newAccount.Email_Subscription_Status__c!=NULL ){
                    string accValue = newAccount.Email_Subscription_Status__c == True ? 'subscribed':'unsubscribed';
                    if( oldAccount.Email_Subscription_Status__c != newAccount.Email_Subscription_Status__c ){
                        fieldMap.put('email_subscribe', accValue );
                    }
                }
                if(newAccount.Subscribed_Country_Email__c!=null && cusMdt != null){
                    if(oldAccount.Subscribed_Country_Email__c != newAccount.Subscribed_Country_Email__c ){
                        fieldMap.put('language', cusMdt[0] );
                        fieldMap.put('Site_URL', cusMdt[1] );
                    }
                }
                
                if(newAccount.Source__c!=NULL && newAccount.Source__c!=''){
                    if(oldAccount.Source__c != newAccount.Source__c ){
                        fieldMap.put('Source', newAccount.Source__c);
                    }
                }
                if(newAccount.School_University_Name__c!=NULL && newAccount.School_University_Name__c!=''){
                    if(oldAccount.School_University_Name__c != newAccount.School_University_Name__c ){
                        fieldMap.put('School_University_Name', newAccount.School_University_Name__c);
                    }
                }
                else if(newAccount.School_University_Name_Other__c!=NULL && newAccount.School_University_Name_Other__c!=''){
                    if(oldAccount.School_University_Name_Other__c != newAccount.School_University_Name_Other__c ){
                        fieldMap.put('School_University_Name', newAccount.School_University_Name_Other__c);
                    }
                }
                if(newAccount.Registration_Date__c!=NULL ){
                    if(oldAccount.Registration_Date__c != newAccount.Registration_Date__c ){
                        string regDate = string.valueOf(newAccount.Registration_Date__c);
                        fieldMap.put('Registration_Date', regDate);
                    }
                }
                if(newAccount.Most_Purchased_Color__c!=NULL && newAccount.Most_Purchased_Color__c!=''){
                    if(oldAccount.Most_Purchased_Color__c != newAccount.Most_Purchased_Color__c ){
                        fieldMap.put('Most_Purchased_Color', newAccount.Most_Purchased_Color__c);
                    }
                }
                if(newAccount.Most_Purchased_Category__c!=NULL && newAccount.Most_Purchased_Category__c!=''){
                    if(oldAccount.Most_Purchased_Category__c != newAccount.Most_Purchased_Category__c ){
                        fieldMap.put('Most_Purchased_Category', newAccount.Most_Purchased_Category__c);
                    }
                }
                if(newAccount.Mode_of_registration__c!=NULL && newAccount.Mode_of_registration__c!=''){
                    if(oldAccount.Mode_of_registration__c != newAccount.Mode_of_registration__c ){
                        fieldMap.put('Mode_of_registration', newAccount.Mode_of_registration__c);
                    }
                }
                if(newAccount.Loyalty_Tier_US__c!=NULL && newAccount.Loyalty_Tier_US__c!=''){
                    if(oldAccount.Loyalty_Tier_US__c != newAccount.Loyalty_Tier_US__c ){
                        fieldMap.put('Loyalty_Tier_US', newAccount.Loyalty_Tier_US__c);
                    }
                }
                if(newAccount.Loyalty_Tier_UK__c!=NULL && newAccount.Loyalty_Tier_UK__c!=''){
                    if(oldAccount.Loyalty_Tier_UK__c != newAccount.Loyalty_Tier_UK__c ){
                        fieldMap.put('Loyalty_Tier_UK', newAccount.Loyalty_Tier_UK__c);
                    }
                }
                if(newAccount.Loyalty_Tier_TW__c!=NULL && newAccount.Loyalty_Tier_TW__c!=''){
                    if(oldAccount.Loyalty_Tier_TW__c != newAccount.Loyalty_Tier_TW__c ){
                        fieldMap.put('Loyalty_Tier_TW', newAccount.Loyalty_Tier_TW__c);
                    }
                }
                if(newAccount.Loyalty_Tier_SG__c!=NULL && newAccount.Loyalty_Tier_SG__c!=''){
                    if(oldAccount.Loyalty_Tier_SG__c != newAccount.Loyalty_Tier_SG__c ){
                        fieldMap.put('Loyalty_Tier_SG', newAccount.Loyalty_Tier_SG__c);
                    }
                }
                if(newAccount.Loyalty_Tier_PAK__c!=NULL && newAccount.Loyalty_Tier_PAK__c!=''){
                    if(oldAccount.Loyalty_Tier_PAK__c != newAccount.Loyalty_Tier_PAK__c ){
                        fieldMap.put('Loyalty_Tier_PAK', newAccount.Loyalty_Tier_PAK__c);
                    }
                }
                if(newAccount.Loyalty_Tier_NZ__c!=NULL && newAccount.Loyalty_Tier_NZ__c!=''){
                    if(oldAccount.Loyalty_Tier_NZ__c != newAccount.Loyalty_Tier_NZ__c ){
                        fieldMap.put('Loyalty_Tier_NZ', newAccount.Loyalty_Tier_NZ__c);
                    }
                }
                if(newAccount.Loyalty_Tier_NO__c!=NULL && newAccount.Loyalty_Tier_NO__c!=''){
                    if(oldAccount.Loyalty_Tier_NO__c != newAccount.Loyalty_Tier_NO__c ){
                        fieldMap.put('Loyalty_Tier_NO', newAccount.Loyalty_Tier_NO__c);
                    }
                }
                if(newAccount.Loyalty_Tier_MY__c!=NULL && newAccount.Loyalty_Tier_MY__c!=''){
                    if(oldAccount.Loyalty_Tier_MY__c != newAccount.Loyalty_Tier_MY__c ){
                        fieldMap.put('Loyalty_Tier_MY', newAccount.Loyalty_Tier_MY__c);
                    }
                }
                if(newAccount.Loyalty_Tier_MT__c!=NULL && newAccount.Loyalty_Tier_MT__c!=''){
                    if(oldAccount.Loyalty_Tier_MT__c != newAccount.Loyalty_Tier_MT__c ){
                        fieldMap.put('Loyalty_Tier_MT', newAccount.Loyalty_Tier_MT__c);
                    }
                }
                if(newAccount.Loyalty_Tier_MO__c!=NULL && newAccount.Loyalty_Tier_MO__c!=''){
                    if(oldAccount.Loyalty_Tier_MO__c != newAccount.Loyalty_Tier_MO__c ){
                        fieldMap.put('Loyalty_Tier_MO', newAccount.Loyalty_Tier_MO__c);
                    }
                }
                if(newAccount.Loyalty_Tier_KR__c!=NULL && newAccount.Loyalty_Tier_KR__c!=''){
                    if(oldAccount.Loyalty_Tier_KR__c != newAccount.Loyalty_Tier_KR__c ){
                        fieldMap.put('Loyalty_Tier_KR', newAccount.Loyalty_Tier_KR__c);
                    }
                }
                if(newAccount.Loyalty_Tier_KH__c!=NULL && newAccount.Loyalty_Tier_KH__c!=''){
                    if(oldAccount.Loyalty_Tier_KH__c != newAccount.Loyalty_Tier_KH__c ){
                        fieldMap.put('Loyalty_Tier_KH', newAccount.Loyalty_Tier_KH__c);
                    }
                }
                if(newAccount.Loyalty_Tier_HK__c!=NULL && newAccount.Loyalty_Tier_HK__c!=''){
                    if(oldAccount.Loyalty_Tier_HK__c != newAccount.Loyalty_Tier_HK__c ){
                        fieldMap.put('Loyalty_Tier_HK', newAccount.Loyalty_Tier_HK__c);
                    }
                }
                if(newAccount.Loyalty_Tier_GB__c!=NULL && newAccount.Loyalty_Tier_GB__c!=''){
                    if(oldAccount.Loyalty_Tier_GB__c != newAccount.Loyalty_Tier_GB__c ){
                        fieldMap.put('Loyalty_Tier_GB', newAccount.Loyalty_Tier_GB__c);
                    }
                }
                if(newAccount.Loyalty_Tier_EU__c!=NULL && newAccount.Loyalty_Tier_EU__c!=''){
                    if(oldAccount.Loyalty_Tier_EU__c != newAccount.Loyalty_Tier_EU__c ){
                        fieldMap.put('Loyalty_Tier_EU', newAccount.Loyalty_Tier_EU__c);
                    }
                }
                if(newAccount.Loyalty_Tier_CH__c!=NULL && newAccount.Loyalty_Tier_CH__c!=''){
                    if(oldAccount.Loyalty_Tier_CH__c != newAccount.Loyalty_Tier_CH__c ){
                        fieldMap.put('Loyalty_Tier_CH', newAccount.Loyalty_Tier_CH__c);
                    }
                }
                if(newAccount.Loyalty_Tier_CA__c!=NULL && newAccount.Loyalty_Tier_CA__c!=''){
                    if(oldAccount.Loyalty_Tier_CA__c != newAccount.Loyalty_Tier_CA__c ){
                        fieldMap.put('Loyalty_Tier_CA', newAccount.Loyalty_Tier_CA__c);
                    }
                }
                if(newAccount.Loyalty_Tier_AU__c!=NULL && newAccount.Loyalty_Tier_AU__c!=''){
                    if(oldAccount.Loyalty_Tier_AU__c != newAccount.Loyalty_Tier_AU__c ){
                        fieldMap.put('Loyalty_Tier_AU', newAccount.Loyalty_Tier_AU__c);
                    }
                }
                if(newAccount.Loyalty_Tier_AE__c!=NULL && newAccount.Loyalty_Tier_AE__c!=''){
                    if(oldAccount.Loyalty_Tier_AE__c != newAccount.Loyalty_Tier_AE__c ){
                        fieldMap.put('Loyalty_Tier_AE', newAccount.Loyalty_Tier_AE__c);
                    }
                }
                
                //VC Japan Update
                if(newAccount.Loyalty_Tier_JP__c!=NULL && newAccount.Loyalty_Tier_JP__c!=''){
                    if(oldAccount.Loyalty_Tier_JP__c != newAccount.Loyalty_Tier_JP__c ){
                        fieldMap.put('Loyalty_Tier_JP', newAccount.Loyalty_Tier_JP__c);
                    }
                }
                if(newAccount.VIP_Since_Date_JP__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_JP__c != newAccount.VIP_Since_Date_JP__c ){
                        string myDate = string.valueOf(newAccount.VIP_Since_Date_JP__c);
                        fieldMap.put('VIP_Since_Date_JP', myDate);
                    }
                }
                
                
                if(newAccount.Customer_Type__c!=NULL && newAccount.Customer_Type__c!=''){
                    if(oldAccount.Customer_Type__c != newAccount.Customer_Type__c ){
                        fieldMap.put('Customer_Type', newAccount.Customer_Type__c);
                    }
                }
                if(newAccount.Subscribed_Country_SMS__c!=NULL && newAccount.Subscribed_Country_SMS__c!=''){
                    if(oldAccount.Subscribed_Country_SMS__c != newAccount.Subscribed_Country_SMS__c ){
                        fieldMap.put('sms_subscribed', newAccount.Subscribed_Country_SMS__c);
                    }
                }
                if(newAccount.Customer_Mobile_Subscription_Status__c!=NULL){
                    string value = newAccount.Customer_Mobile_Subscription_Status__c == true ? 'True' : 'False';
                    if(oldAccount.Customer_Mobile_Subscription_Status__c != newAccount.Customer_Mobile_Subscription_Status__c ){
                        fieldMap.put('sms_mobile_subscribed', value);
                    }
                }
                if(newAccount.Ocapi_Customer_ID__c!=NULL && newAccount.Ocapi_Customer_ID__c!=''){
                    if(oldAccount.Ocapi_Customer_ID__c != newAccount.Ocapi_Customer_ID__c ){
                        fieldMap.put('Ocapi_Customer_Id', newAccount.Ocapi_Customer_ID__c);
                    }
                }
                if(newAccount.UTM_Term__c!=NULL && newAccount.UTM_Term__c!=''){
                    if(oldAccount.UTM_Term__c != newAccount.UTM_Term__c ){
                        fieldMap.put('utm_term', newAccount.UTM_Term__c);
                    }
                }
                if(newAccount.UTM_Source__c!=NULL && newAccount.UTM_Source__c!=''){
                    if(oldAccount.UTM_Source__c != newAccount.UTM_Source__c ){
                        fieldMap.put('utm_source', newAccount.UTM_Source__c);
                    }
                }
                if(newAccount.UTM_Medium__c!=NULL && newAccount.UTM_Medium__c!=''){
                    if(oldAccount.UTM_Medium__c != newAccount.UTM_Medium__c ){
                        fieldMap.put('utm_medium', newAccount.UTM_Medium__c);
                    }
                }
                if(newAccount.UTM_Content__c!=NULL && newAccount.UTM_Content__c!=''){
                    if(oldAccount.UTM_Content__c != newAccount.UTM_Content__c ){
                        fieldMap.put('utm_content', newAccount.UTM_Content__c);
                    }
                }
                if(newAccount.UTM_Campaign__c!=NULL && newAccount.UTM_Campaign__c!=''){
                    if(oldAccount.UTM_Campaign__c != newAccount.UTM_Campaign__c ){
                        fieldMap.put('utm_campaign', newAccount.UTM_Campaign__c);
                    }
                }
                if(newAccount.Last_purchase_date__c!=NULL){
                    if(oldAccount.Last_purchase_date__c != newAccount.Last_purchase_date__c ){
                        string pchDate = string.valueOf(newAccount.Last_purchase_date__c);
                        fieldMap.put('Last_purchase_date', pchDate);
                    }
                }
                if(newAccount.VIP_Since_Date_MY__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_MY__c != newAccount.VIP_Since_Date_MY__c ){
                        string myDate = string.valueOf(newAccount.VIP_Since_Date_MY__c);
                        fieldMap.put('VIP_Since_Date_MY', myDate);
                    }
                }
                if(newAccount.VIP_Since_Date_MO__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_MO__c != newAccount.VIP_Since_Date_MO__c ){
                        string moDate = string.valueOf(newAccount.VIP_Since_Date_MO__c);
                        fieldMap.put('VIP_Since_Date_MO', moDate);
                    }
                }
                if(newAccount.VIP_Since_Date_KR__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_KR__c != newAccount.VIP_Since_Date_KR__c ){
                        string krDate = string.valueOf(newAccount.VIP_Since_Date_KR__c);
                        fieldMap.put('VIP_Since_Date_KR', krDate);
                    }
                }
                if(newAccount.VIP_Since_Date_HK__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_HK__c != newAccount.VIP_Since_Date_HK__c ){
                        string hkDate = string.valueOf(newAccount.VIP_Since_Date_HK__c);
                        fieldMap.put('VIP_Since_Date_HK', hkDate);
                    }
                }
                if(newAccount.VIP_Since_Date_GB__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_GB__c != newAccount.VIP_Since_Date_GB__c ){
                        string gbDate = string.valueOf(newAccount.VIP_Since_Date_GB__c);
                        fieldMap.put('VIP_Since_Date_GB', gbDate);
                    }
                }
                if(newAccount.VIP_Since_Date_CH__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_CH__c != newAccount.VIP_Since_Date_CH__c ){
                        string chDate = string.valueOf(newAccount.VIP_Since_Date_CH__c);
                        fieldMap.put('VIP_Since_Date_CH', chDate);
                    }
                }
                if(newAccount.VIP_Since_Date_EU__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_EU__c != newAccount.VIP_Since_Date_EU__c ){
                        string euDate = string.valueOf(newAccount.VIP_Since_Date_EU__c);
                        fieldMap.put('VIP_Since_Date_EU', euDate);
                    }
                }
                if(newAccount.VIP_Since_Date_CA__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_CA__c != newAccount.VIP_Since_Date_CA__c ){
                        string caDate = string.valueOf(newAccount.VIP_Since_Date_CA__c);
                        fieldMap.put('VIP_Since_Date_CA', caDate);
                    }
                }
                if(newAccount.VIP_Since_Date_AU__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_AU__c != newAccount.VIP_Since_Date_AU__c ){
                        string auDate = string.valueOf(newAccount.VIP_Since_Date_AU__c);
                        fieldMap.put('VIP_Since_Date_AU', auDate);
                    }
                }
                if(newAccount.VIP_Since_Date_AE__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_AE__c != newAccount.VIP_Since_Date_AE__c ){
                        string aeDate = string.valueOf(newAccount.VIP_Since_Date_AE__c);
                        fieldMap.put('VIP_Since_Date_AE', aeDate);
                    }
                }
                if(newAccount.VIP_Since_Date_MT__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_MT__c != newAccount.VIP_Since_Date_MT__c ){
                        string mtDate = string.valueOf(newAccount.VIP_Since_Date_MT__c);
                        fieldMap.put('VIP_Since_Date_MT', mtDate);
                        
                    }
                }
                if(newAccount.VIP_Since_Date_NO__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_NO__c != newAccount.VIP_Since_Date_NO__c ){
                        string noDate = string.valueOf(newAccount.VIP_Since_Date_NO__c);
                        fieldMap.put('VIP_Since_Date_NO', noDate);
                    }
                }
                if(newAccount.VIP_Since_Date_NZ__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_NZ__c != newAccount.VIP_Since_Date_NZ__c ){
                        string nzDate = string.valueOf(newAccount.VIP_Since_Date_NZ__c);
                        fieldMap.put('VIP_Since_Date_NZ', nzDate);
                    }
                }
                if(newAccount.VIP_Since_Date_UK__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_UK__c != newAccount.VIP_Since_Date_UK__c ){
                        string ukDate = string.valueOf(newAccount.VIP_Since_Date_UK__c);
                        fieldMap.put('VIP_Since_Date_UK', ukDate);
                    }
                }
                if(newAccount.VIP_Since_Date_KH__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_KH__c != newAccount.VIP_Since_Date_KH__c ){
                        string khDate = string.valueOf(newAccount.VIP_Since_Date_KH__c);
                        fieldMap.put('VIP_Since_Date_KH', khDate);
                    }
                }
                if(newAccount.Shoe_Size__c!=NULL){
                    if(oldAccount.Shoe_Size__c != newAccount.Shoe_Size__c ){
                        string shoe = string.valueOf(newAccount.Shoe_Size__c);
                        fieldMap.put('Shoe_Size', shoe);
                    }
                }
                if(newAccount.First_Date_Of_Purchase__c!=NULL ){
                    if(oldAccount.First_Date_Of_Purchase__c != newAccount.First_Date_Of_Purchase__c ){
                        string firstDate = string.valueOf(newAccount.First_Date_Of_Purchase__c);
                        fieldMap.put('First_Date_Of_Purchase', firstDate);
                    }
                }
                if(newAccount.VIP_Since_Date_US__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_US__c != newAccount.VIP_Since_Date_US__c ){
                        string usDate = string.valueOf(newAccount.VIP_Since_Date_US__c);
                        fieldMap.put('VIP_Since_Date_US', usDate);
                    }
                }
                if(newAccount.VIP_Since_Date_TW__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_TW__c != newAccount.VIP_Since_Date_TW__c ){
                        string twDate = string.valueOf(newAccount.VIP_Since_Date_TW__c);
                        fieldMap.put('VIP_Since_Date_TW', twDate);
                    }
                }
                if(newAccount.VIP_Since_Date_SG__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_SG__c != newAccount.VIP_Since_Date_SG__c ){
                        string sgDate = string.valueOf(newAccount.VIP_Since_Date_SG__c);
                        fieldMap.put('VIP_Since_Date_SG', sgDate);
                    }
                }
                if(newAccount.Reseller_Flag__c!=NULL){
                    string value = newAccount.Reseller_Flag__c == true ? 'True':'False';
                    if(oldAccount.Reseller_Flag__c != newAccount.Reseller_Flag__c ){
                        fieldMap.put('Reseller_Flag', value);
                    }
                }
                if(newAccount.VIP_Since_Date_PAK__c!=NULL ){
                    if(oldAccount.VIP_Since_Date_PAK__c != newAccount.VIP_Since_Date_PAK__c ){
                        string pakDate = string.valueOf(newAccount.VIP_Since_Date_PAK__c);
                        fieldMap.put('VIP_Since_Date_PAK', pakDate);
                    }
                }
                if(newAccount.Last_Login_Date__c!=NULL ){
                    if(oldAccount.Last_Login_Date__c != newAccount.Last_Login_Date__c ){
                        string loginDate = string.valueOf(newAccount.Last_Login_Date__c);
                        fieldMap.put('Last_Login_Date', loginDate);
                    }
                }
                if(newAccount.Retail_Store__c!=NULL ){
                    if(oldAccount.Retail_Store__c != newAccount.Retail_Store__c ){
                        string retailStore = string.valueOf(newAccount.Retail_Store__c);
                        fieldMap.put('Registered_Retail_Store', retailStore);
                    }
                }
                if(newAccount.Last_purchase_Channel__c!=NULL ){
                    if(oldAccount.Last_purchase_Channel__c != newAccount.Last_purchase_Channel__c ){
                        string lastPurChannel = string.valueOf(newAccount.Last_purchase_Channel__c);
                        fieldMap.put('Last_Purchase_Channel', lastPurChannel);
                    }
                }
                If(recordType!=null && recordType.endsWithIgnoreCase('PD') && newAccount.Subscribed_Content_Gender__c!=null){
                    if(oldAccount.Subscribed_Content_Gender__c != newAccount.Subscribed_Content_Gender__c){
                        fieldMap.put('subscribed_content_gender', newAccount.Subscribed_Content_Gender__c);
                    } 
                }
                
                if((newAccount.TotalOrderAmt_SGD__c!=NULL && newAccount.TotalOrderAmt_SGD__c > 0) || (newAccount.TotalRefundAmt_SGD__c!=NULL && newAccount.TotalRefundAmt_SGD__c >0) ){
                    if((oldAccount.TotalOrderAmt_SGD__c != newAccount.TotalOrderAmt_SGD__c) || 
                       (oldAccount.TotalRefundAmt_SGD__c != newAccount.TotalRefundAmt_SGD__c) ){
                           Decimal TotalOrderAmt = newAccount.TotalOrderAmt_SGD__c != null? newAccount.TotalOrderAmt_SGD__c:0;
                           Decimal TotalRefundAmt = newAccount.TotalRefundAmt_SGD__c != null? newAccount.TotalRefundAmt_SGD__c:0;
                           Decimal Total_LTV_Value = TotalOrderAmt - TotalRefundAmt;                            
                           string Total_LTV_Value_SGD = string.valueOf(Total_LTV_Value);
                           fieldMap.put('Total_LTV_Value_In_SGD', Total_LTV_Value_SGD);
                       }
                }
                if(newAccount.Total_Value_spends_within_Last_12_months__c != NULL){
                    if(oldAccount.Total_Value_spends_within_Last_12_months__c != newAccount.Total_Value_spends_within_Last_12_months__c ){
                        string total12monthValue = string.valueOf(newAccount.Total_Value_spends_within_Last_12_months__c);
                        fieldMap.put('Global_L12M_Spend_In_SGD', total12monthValue);
                    }
                }
                if(newAccount.Lifetime_Value__c != NULL){
                    if(oldAccount.Lifetime_Value__c != newAccount.Lifetime_Value__c ){
                        string ltvValue = string.valueOf(newAccount.Lifetime_Value__c);
                        fieldMap.put('Global_LTV_In_SGD', ltvValue);
                    }
                }
                  if(newAccount.Social_Account_Provider_ID__c!=NULL && newAccount.Social_Account_Provider_ID__c!=''){
                    if(oldAccount.Social_Account_Provider_ID__c != newAccount.Social_Account_Provider_ID__c ){
                        fieldMap.put('Social_Account_Provider_ID', newAccount.Social_Account_Provider_ID__c);
                    }
                }
                
                 if(newAccount.Last_Purchased_Store__c!=NULL && newAccount.Last_Purchased_Store__c!=''){
                    if(oldAccount.Last_Purchased_Store__c != newAccount.Last_Purchased_Store__c ){
                        fieldMap.put('Last_Purchased_Store', newAccount.Last_Purchased_Store__c);
                    }
                }
                if(newAccount.Subscribed_Whatsapp__c!=NULL){
                    string value = newAccount.Subscribed_Whatsapp__c == true ? 'True':'False';
                    if(oldAccount.Subscribed_Whatsapp__c != newAccount.Subscribed_Whatsapp__c ){
                        fieldMap.put('Subscribed_Mobile_Messaging', value);
                    }
                }
                
                 if(newAccount.Subscribed_Country_Whatsapp__c!=NULL && newAccount.Subscribed_Country_Whatsapp__c!=''){
                    if(oldAccount.Subscribed_Country_Whatsapp__c != newAccount.Subscribed_Country_Whatsapp__c ){
                        fieldMap.put('Subscribed_Country_Mobile_Messaging', newAccount.Subscribed_Country_Whatsapp__c);
                    }
                }
                 
                system.debug('fieldMap:: '+fieldMap);
                if(fieldMap.size() > 1){
                    fieldMapList.add(fieldMap);
                    AccountIds.add(AccId);
                }
            }
            
            if(fieldMapList.size()>0){
                JSONGenerator gen = json.createGenerator(true);
                gen.writeStartObject();
                gen.writeObjectField('attributes', fieldMapList);
                gen.writeEndObject();
                
                string request = gen.getAsString();
                system.debug('request--'+request);
                system.debug('fieldMapList.size()--'+fieldMapList.size());
                
                UpdateAccountDetailsToBrazeCallOut(request,recordType,AccountIds);
            }
            
        }catch(Exception e){
            
            CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage()+' Account IDs:: '+AccountIds+' inputnewAccount :: '+inputnewAccount,'','','','Trigger','Backend Process Error');     
            
        }
    }
    
    @future (callout = true)
    public static void UpdateAccountDetailsToBrazeCallOut(string Request,String recordType,Set<id> accIds){
        AccountDetailsToBrazeCallOut(Request,recordType,accIds);
    }
    
    //method to make callout 
    public static void AccountDetailsToBrazeCallOut(string Request,String recordType,Set<id> accIds){
    
        try{
            ZBraze_API_Master__c Apilist = ZBraze_API_Master__c.getvalues(recordType);//recordType
            List<Account> AccLst = new List<Account>();
            if(Request != null){
                HttpResponse response = CustomAttributeAPICallout(Request,Apilist);
                system.debug('response:: '+response);
                
                if(response.getStatusCode() >= 200 && response.getStatusCode() <= 299){
                    ResponseBody resbody=(ResponseBody)JSON.deserialize(response.getbody(), ResponseBody.class);
                    system.debug(' response.response.getbody()--'+ response.getbody());
                    if(resbody.attributes_processed == accIds.size() && resbody.message =='success'){
                        AccLst=updateIFStatus(accIds,'Completed');
                    }else{
                        if(!system.isBatch()){
                            AccLst = RetryCallOutToBraze(Request,Apilist,accIds);
                        }else{
                            AccLst = updateRetryCntIFStatusBatch(accIds,Integer.valueof(Apilist.Retry_Count__c));
                            
                            CreateErrorLog('Message :: '+response.getStatusCode()+' :: '+resbody.message+'  Account ID :: '+accIds,Apilist.Endpoint_Url__c,Request,String.valueOf(response.getbody()),'Batch','Integration Error');  
                        }
                    }
                }else{
                    if(!system.isBatch()){
                        AccLst=RetryCallOutToBraze(Request,Apilist,accIds);
                    }else{
                        AccLst = updateRetryCntIFStatusBatch(accIds,Integer.valueof(Apilist.Retry_Count__c));
                        
                        CreateErrorLog('Message :: '+response.getStatusCode()+' ::  Account ID :: '+accIds,Apilist.Endpoint_Url__c,Request,String.valueOf(response.getbody()),'Batch','Integration Error');
                    }
                }
            }
            if(AccLst.size()>0){
                ICAccountTriggerHandler.suspendTrigger = true;
                update AccLst;
            }
        }catch(Exception e){
            CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage()+' Request :: '+Request +' Account ID:: '+accIds,'','','','Trigger','Backend Process Error');     
            
        }
    }
    //method to update retry count and if status from batch
    public static List<Account> updateRetryCntIFStatusBatch(Set<Id> accId,Integer retryCnt){
        List<Account> accLst = new List<Account>();
        Decimal cnt=0;
        try{
            for(Account a:[Select id,Braze_Retry_Count__c from Account where id in :accId]){
                cnt=a.Braze_Retry_Count__c==null ? 1 : a.Braze_Retry_Count__c + 1;
                if(cnt == retryCnt){
                    a.IF_Status__c = 'Failed';
                    a.Braze_Retry_Count__c= 0;
                }else{
                    a.IF_Status__c = 'Pending';
                    a.Braze_Retry_Count__c= cnt;
                }
                
                accLst.add(a);
            }
            
        }catch(Exception e){
            CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage()+' Account ID :: '+accId,'','','','Trigger','Backend Process Error');     
            
        }
        return accLst;
    }
    //method to make retry callout for both trigger and batch
    public static List<Account> RetryCallOutToBraze(string Request,ZBraze_API_Master__c Apilist,Set<id> accIds){
        system.debug('Retry entry');
        List<Account> accLst = new List<Account>();
        try{
            HttpResponse retryResponse = CustomAttributeAPICallout(Request,Apilist);
            system.debug('retryResponse:: '+retryResponse);
            
            if(retryResponse.getStatusCode() >= 200 && retryResponse.getStatusCode() <= 299){
                ResponseBody retryResbody=(ResponseBody)JSON.deserialize(retryResponse.getbody(), ResponseBody.class);
                if(retryResbody.attributes_processed == accIds.size() && retryResbody.message =='success'){
                    accLst=updateIFStatus(accIds,'Completed');
                }else{
                    
                    CreateErrorLog('Message :: '+retryResponse.getStatusCode()+' :: '+retryResbody.message+'  Account ID :: '+accIds,Apilist.Endpoint_Url__c,Request,String.valueOf(retryResponse.getbody()),'Trigger','Integration Error');   
                    
                    accLst=updateIFStatus(accIds,'Pending');
                }
            }else{
                
                CreateErrorLog('Message :: '+retryResponse.getStatusCode()+' ::   Account ID :: '+accIds,Apilist.Endpoint_Url__c,Request,String.valueOf(retryResponse.getbody()),'Trigger','Integration Error');
                
                accLst=updateIFStatus(accIds,'Pending');
            }
        }catch(Exception e){
            CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage() +' Request:: '+Request+' Account ID :: '+accIds,'','','','Trigger','Backend Process Error');     
            
        }
        
        return accLst;
    }
    
    Private static HttpResponse CustomAttributeAPICallout(string Request,ZBraze_API_Master__c Apilist){
        
        HttpResponse Response =ZBraze_HTTPConnector.performHTTPCallout(Request,Apilist.Endpoint_Url__c,Apilist.Method__c,Apilist.Header__c,Apilist.Access_Token__c,36000,
                                                                       'ZBraze_Account_Callout','CustomAttributeAPICallout');
        return Response;
    }
    
    //method to update retry count and if status from trigger
    public static List<Account> updateIFStatus(set<Id> accIds,String status){
        List<Account> AccLst = new List<Account>();
        try{
            for(Id accId:accIds){
                Account a = new Account();
                a.id=accId;
                a.IF_Status__c=status;
                if(status=='Pending'){
                    a.Braze_Retry_Count__c = 1;
                }if(status=='Completed'){
                    a.Braze_Retry_Count__c = 0;
                }
                AccLst.add(a);
            }
        }catch(Exception e){
            CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage()+' Account ID :: '+accIds+' status :: '+status,'','','','Trigger','Backend Process Error');     
        }
        return AccLst;
    }
    
    //method to create error log record
    public static void CreateErrorLog(String discription,String endpoint,String request,String response,String source,String errorType){
        try{
            ErrorLog__c errorLog = new ErrorLog__c();
            
            errorLog.Error_Description__c =discription;
            errorLog.Error_Endpoint_URL__c =endpoint;                           
            errorLog.Error_Request__c=request;
            errorLog.Error_Response__c=response;
            errorLog.Error_Source__c=source;
            errorLog.Error_Type__c=errorType;
            
            insert errorLog;
        }catch(Exception e){
            CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage(),'','','','Trigger','Backend Process Error');     
        }
        
    }
    
    public class UpdateAliaswithExtIdWrapper{
        public list<UpdateAliaswithExtId> aliases_to_identify;
        public string merge_behavior;
        
    }
    
    public class UpdateAliaswithExtId{
        public string external_id;
        public UserAliases user_alias;
    }    
    
    public class UserAliasWrapper{
        public list<UserAliases> user_aliases;
        public list<string> fields_to_export;
    }
    
    public class UserAliases{
        public string alias_name;
        public string alias_label;
    }
    public class ExportUsers{
        public List<user> users{get;set;}
        public String message{get;set;}
        public List<String> invalid_user_ids{get;set;}
        public list<UserAliases> invalid_aliases{get;set;}
    }
    
    public class user  {
        public String external_id{get;set;}
        public List<UserAliases> user_aliases {get;set;}
        
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