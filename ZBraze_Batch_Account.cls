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
* This batch class is used to send custom attributes to Braze from SFDC by batch process
*
* @test class name - ZBraze_Batch_Account_Test
*
*  Change History:
*  MM/DD/YYYY			Developer Name			Comments
*  
* 
*/
global with sharing  class ZBraze_Batch_Account implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.stateful {
    Integer interval = 0;
    List<String> accLst;
    
    public static ID ckRecordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('CK').getRecordTypeId();
    public static ID pdRecordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('PD').getRecordTypeId();
    
    //VC JP Update
    public static ID jpRecordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('JP').getRecordTypeId();
    
    global ZBraze_Batch_Account(Integer interval, List<String> accLst) {
        this.interval = interval;
        
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
         String sql = '';
         sql = 'Select Id,IF_Status__c From Account Where IF_Status__c =\'Pending\''+
            +' AND RecordtypeId in (:jpRecordTypeId,:ckRecordTypeId,:pdRecordTypeId) Order by RecordtypeId';//0010l00001dU5MfAAK
        system.debug('sql--'+sql);
        return Database.getQueryLocator(sql);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        system.debug('ZBraze_Batch_Account.execute(), start.');
        
      //  Savepoint sp ;
        
        set<Id> accountid = new set<Id>();
        set<Id> updateAccId=new set<Id>();
        List<Account> accountFlag = new  List<Account>();
        List<Account> accountLst = (List<Account>)scope;
        try{
            if(!accountLst.isempty()){
                for(Account account : accountLst){
                    accountid.add(account.Id);
                }
                if(!accountid.isEmpty()){
                    ZBraze_Account_APIHandler.createUpdateAccountDetails(accountid);
                }
            }

        }catch(Exception e){
              ZBraze_Account_Callout.CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage(),'','','','Batch','Backend Process Error');
        }
    }
    global void finish(Database.BatchableContext BC){
       
        system.debug('ZBraze_Batch_Account.finish(), start, interval: '+this.interval);
        Datetime nw  = Datetime.now().addHours(this.interval);
         
        //parse to a cron expression
        String hour =  String.valueOf(nw.hour());
        String min =  String.valueOf(nw.minute());
        String ss =  String.valueOf(nw.second());
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
         //Create an Instance of your Schedule Class
        ZBraze_Scheduler_Account s = new ZBraze_Scheduler_Account (this.interval);
       	System.schedule('ZBraze_Batch_Account ' + String.valueOf(Datetime.now()), nextFireTime, s);
        system.debug('ZBraze_Batch_Account.finish(), end, nextFireTime: '+nextFireTime);   
    }
}