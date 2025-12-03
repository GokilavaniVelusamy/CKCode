/********************************************************************************************************
* (C) Copyright 2023 Charles & Keith. All rights reserved.
* This code is property of Charles & Keith. Use, duplication and
* disclosure in any form without permission of copyright holder is prohibited.
* 
******************************************************************************************************* 
* @author  NagaRaju K
* @version 1.0
* @created 13/04/2023
* @description 
* This class is used for different API calls as a Helper
*
* @test class name - ZBraze_Batch_Account_Test
*
*  Change History:
*  MM/DD/YYYY			Developer Name			Comments
*  
* 
*/
public class ZBraze_Account_APIHelper {
  
    //─────────────────────────────────────────────────────────────────────────────────────────┐
    //This method is used to export the user details from Braze by Alias name as account email 
    //endpoint: https://rest.iad-05.braze.com/users/export/ids
    //@params: 
    //	recordType - CK or PD
    //	accId - set of account Ids
    //─────────────────────────────────────────────────────────────────────────────────────────┘

    public static void exportUserDetailsByAlias(string recordType,set<Id> accId){
        
        //VC JP Update
        String newrecordtype;
        if ((recordType == 'CK') || (recordType == 'JP')){
            newrecordtype = 'CK';
        }else if(recordType == 'PD'){
            newrecordtype = 'PD';
        }        
        
        system.debug('start time:'+system.now());
        List<Account> AccLst = new List<Account>();
        map<string,id> accIdEmailMap = new map<string,id>(); // key - email and values accid
        UserAliasWrapper wrapper = new UserAliasWrapper(); //main wrapper
        list<UserAliases> UserAliasesList = new list<UserAliases>(); //stores alias details
        
        //VC JP Update
        ZBraze_API_Master__c exportApiDetials = ZBraze_API_Master__c.getvalues(newrecordtype);
        ZBraze_Syn_Activation__c activationDetail = ZBraze_Syn_Activation__c.getvalues(newrecordtype);
        
        ZBraze_CustomAttribute_Export_Wrapper userResponse = new ZBraze_CustomAttribute_Export_Wrapper();
        
        map<string, ZBraze_CustomAttribute_Export_Wrapper.user> extIdWithAttributeMap = new map<string, ZBraze_CustomAttribute_Export_Wrapper.user>();
        list<string> extIdWithoutAttributeList = new list<string>();
        map<string, ZBraze_CustomAttribute_Export_Wrapper.user> aliasWithAttributeMap = new map<string, ZBraze_CustomAttribute_Export_Wrapper.user>();
        list<string> aliasWithoutAttributeList = new list<string>();
        map<string, string> nonExtIdMap = new map<string, string>(); //key - accid && values = email
        list<string> invalidAliasList = new list<string>(); //list of emails
        
        try{
                if(!accId.isEmpty()){
                    for(account acc: [select id, personEmail from Account where Id =:accId]){
                        accIdEmailMap.put(acc.personEmail, acc.id);
                        
                        UserAliases userAlias = new UserAliases();
                        userAlias.alias_name = acc.personEmail;
                        userAlias.alias_label = 'Identifier';
                        UserAliasesList.add(userAlias);
                    }
                    wrapper.User_Aliases = UserAliasesList;
                    wrapper.fields_to_export = new list<string>{
                        'external_id',
                            'user_aliases', 
                            'custom_attributes',
                            'first_name',
                            'last_name',
                            'email',
                            'dob',
                            'country',
                            'home_city',
                            'gender',
                            'email_subscribe',
                            'language',
                            'phone'
                            };
                                }
                
                string ExportRequest = JSON.serialize(wrapper);
                system.debug('ExportRequest:: '+ExportRequest);
                HttpResponse ExportResponse =ZBraze_HTTPConnector.performHTTPCallout(ExportRequest,exportApiDetials.ExportIds__c,exportApiDetials.Method__c,exportApiDetials.Header__c,exportApiDetials.Access_Token__c,36000,
                                                                           'ZBraze_Account_APIHelper','exportUserDetailsByAlias');
                
                system.debug('ExportResponse:: '+ExportResponse);
            
            if(ExportResponse != null && ExportResponse.getStatusCode() >=200 && ExportResponse.getStatusCode()<=299){
                //Check Response
                 userResponse=(ZBraze_CustomAttribute_Export_Wrapper)JSON.deserialize(ExportResponse.getbody(), ZBraze_CustomAttribute_Export_Wrapper.class);
                system.debug('userResponse--'+userResponse);
                if(userResponse != null && userResponse.users != null){
                    for(ZBraze_CustomAttribute_Export_Wrapper.user user: userResponse.users){
                        //get if external_id exist
                        if(user.external_id != null){
                            //check for custom_attributes
                            if(user.custom_attributes != null){
                                extIdWithAttributeMap.put(user.external_id, user);
                            }else if(user.custom_attributes == null){
                                extIdWithoutAttributeList.add(user.user_aliases[0].alias_name);
                            }
                            
                        }
                        //check if external_id not exist
                        if(user.external_id == null){
                            string email = user.user_aliases[0].alias_name;
                            string extId = accIdEmailMap.get(email);
                            nonExtIdMap.put(extId,email);
                            //check for custom_attributes
                            if(user.custom_attributes != null){
                                aliasWithAttributeMap.put(user.user_aliases[0].alias_name, user);
                            }else if(user.custom_attributes == null){
                                aliasWithoutAttributeList.add(user.user_aliases[0].alias_name);
                            }
                            
                        }
                    }
                }
                // get invalid_aliases
                if(userResponse != null && userResponse.invalid_aliases != null){
                    for(ZBraze_CustomAttribute_Export_Wrapper.Aliases invalid: userResponse.invalid_aliases){
                        invalidAliasList.add(invalid.alias_name);
                    }
                }
                
                //key - extId and value - braze user details
                map<string, ZBraze_CustomAttribute_Export_Wrapper.user> updateAttributeMap = new map<string, ZBraze_CustomAttribute_Export_Wrapper.user>();
                list<string> createAttributeList = new list<string>(); //alias names as emails
                
                //update external_Id into the Braze with alias name
                //VC JP Update
                if(!nonExtIdMap.isEmpty()){
                    Zbraze_Account_Callout.updateBrazeExternalIdUsingAlias(newrecordtype, nonExtIdMap);
                }
                
                //Create attributes starts
                if(!extIdWithoutAttributeList.isEmpty()){
                    createAttributeList.addAll(extIdWithoutAttributeList);
                }
                if(!aliasWithoutAttributeList.isEmpty()){
                    createAttributeList.addAll(aliasWithoutAttributeList);
                }
                if(!createAttributeList.isEmpty()){
                    ZBraze_Account_Callout.createAccountInBraze(recordType, createAttributeList);
                }
                //Create attributes end
                
                //update attributes starts
                if(!extIdWithAttributeMap.isEmpty()){
                    updateAttributeMap.putAll(extIdWithAttributeMap);
                }
                if(!aliasWithAttributeMap.isEmpty()){
                    for(string alias: aliasWithAttributeMap.keyset()){
                        string extId = accIdEmailMap.get(alias);
                        updateAttributeMap.put(extId, aliasWithAttributeMap.get(alias));
                    }
                }
                if(!updateAttributeMap.isEmpty()){
                    ZBraze_Account_APIHandler.updateAccountInBraze(recordType, updateAttributeMap);
                }
                //update attributes end
                
                //Invalid Alias starts
                if(!invalidAliasList.isEmpty()){
                    InvalidAliasBrazeSync(recordType, invalidAliasList);
                }
            }else{
                AccLst=zbraze_account_callout.updateRetryCntIFStatusBatch(accId,Integer.valueof(exportApiDetials.Retry_Count__c));
                zbraze_account_callout.CreateErrorLog('Message :: '+ExportResponse.getStatusCode() +' ::   Account ID :: '+accId,exportApiDetials.Endpoint_Url__c,ExportRequest,String.valueOf(ExportResponse.getbody()),'Batch','Integration Error');
            }
            if(AccLst.size()>0){
                ICAccountTriggerHandler.suspendTrigger = true;
                update AccLst;
            }
            }catch(Exception e){
            ZBraze_Account_Callout.CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage(),'','','','Batch','Backend Process Error');
        }  
        
        
    }
    
    public class UserAliasWrapper{
        public list<UserAliases> user_aliases;
        public list<string> fields_to_export;
    }
    
    public class UserAliases{
        public string alias_name;
        public string alias_label;
    }
    
    //──────────────────────────────────────────────────────────────────────────────────────────────┐
    //This method is used to create/update the customer attributes into the Braze for Invalid Alias 
    //endpoint: https://rest.iad-05.braze.com/users/export/ids
    //@params: 
    //	recordType - CK or PD
    //	accId - list of customer emails
    //──────────────────────────────────────────────────────────────────────────────────────────────┘
    public static void InvalidAliasBrazeSync(string recordType, list<string> invalidList){
        List<Account> AccLst = new List<Account>();
        ID RecordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        ZBraze_API_Master__c exportApiDetials = ZBraze_API_Master__c.getvalues(recordType);
        invalisAliasWrapper wrapper = new invalisAliasWrapper();
        map<string, string> extIdEmailMap = new map<string, string>();
        list<string> extIdList = new list<string>();
        set<id> accIds = new Set<id>();
        ZBraze_CustomAttribute_Export_Wrapper userResponse = new ZBraze_CustomAttribute_Export_Wrapper();
        try{
            if(!invalidList.isEmpty()){
                for(account acc: [select id, PersonEmail from account where personEmail =:invalidList AND RecordTypeId=:RecordTypeId]){
                    extIdEmailMap.put(acc.id, acc.PersonEmail);
                    extIdList.add(acc.id);
                    accIds.add(acc.id);
                }
                wrapper.external_ids = extIdList;
                wrapper.fields_to_export = new list<string>{
                    'external_id',
                        'user_aliases', 
                        'custom_attributes',
                        'first_name',
                        'last_name',
                        'email',
                        'dob',
                        'country',
                        'home_city',
                        'gender',
                        'email_subscribe',
                        'language',
                        'phone'
                        };
                            
                            string request = JSON.serialize(wrapper);
                system.debug('InvalidAliasBrazeSync request:: '+request);
                HttpResponse response =ZBraze_HTTPConnector.performHTTPCallout(request,exportApiDetials.ExportIds__c,exportApiDetials.Method__c,exportApiDetials.Header__c,exportApiDetials.Access_Token__c,36000,
                                                                               'ZBraze_Account_APIHelper','exportUserDetailsByAlias');
                
                system.debug('InvalidAliasBrazeSync Response:: '+response);
                
                if(response != null && response.getStatusCode() >=200 && response.getStatusCode()<=299){
                    system.debug('userResponse:: '+userResponse);
                    userResponse=(ZBraze_CustomAttribute_Export_Wrapper)JSON.deserialize(response.getbody(), ZBraze_CustomAttribute_Export_Wrapper.class);
                    map<string, ZBraze_CustomAttribute_Export_Wrapper.user> updateAttributeMap = new map<string, ZBraze_CustomAttribute_Export_Wrapper.user>();
                    list<string> createAttributeList = new list<string>(); //emails
                    map<string, string> updateAliasMap = new map<string, string>(); // accid and email pair 
                    list<string> invalidIdsList = new list<string>(); //stores invalid ids
                    if(userResponse != null && userResponse.users != null){
                        for(ZBraze_CustomAttribute_Export_Wrapper.user user: userResponse.users){
                            //check for customer attributes
                            if(user.custom_attributes != null){
                                updateAttributeMap.put(user.external_id, user);
                            }else if(user.custom_attributes == null){
                                string email = extIdEmailMap.get(user.external_id);
                                createAttributeList.add(email); 
                            }
                        }
                    }
                    if(userResponse.invalid_user_ids != null){
                        invalidIdsList.addAll(userResponse.invalid_user_ids);
                    }
                    if(invalidIdsList != null){
                        for(string inid: invalidIdsList){
                            string email = extIdEmailMap.get(inid);
                            createAttributeList.add(email);
                        }
                    }
                    system.debug('invalid updateAttributeMap:: '+updateAttributeMap);
                    system.debug('invalid createAttributeList:: '+createAttributeList);
                    system.debug('invalid updateAliasMap:: '+updateAliasMap);
                    system.debug('invalid invalidIdsList:: '+invalidIdsList);
                    system.debug('extIdEmailMap--'+extIdEmailMap);
                    //create attributes
                    if(!createAttributeList.isEmpty() && createAttributeList.size()>0){
                        ZBraze_Account_Callout.createAccountInBraze(recordType, createAttributeList);
                    }
                    //update attributes
                    if(!updateAttributeMap.isEmpty() && updateAttributeMap.size()>0){
                        ZBraze_Account_APIHandler.updateAccountInBraze(recordType, updateAttributeMap);
                    }
                    
                }else{
                    AccLst=zbraze_account_callout.updateRetryCntIFStatusBatch(accIds,Integer.valueof(exportApiDetials.Retry_Count__c));
                    zbraze_account_callout.CreateErrorLog('Message :: '+response.getStatusCode()+' ::   Account ID :: '+accIds,exportApiDetials.Endpoint_Url__c,request,String.valueOf(response.getbody()),'Trigger','Integration Error');
                }
            }
            if(AccLst.size()>0){
                ICAccountTriggerHandler.suspendTrigger = true;
                update AccLst;
            }
            
        }catch(Exception e){
            ZBraze_Account_Callout.CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage(),'','','','Trigger','Backend Process Error');
        }
    }
    
    public class invalisAliasWrapper{
        public list<string> external_ids;
        public list<string> fields_to_export;
    }
  
}