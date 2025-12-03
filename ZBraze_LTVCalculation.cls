/********************************************************************************************************
* (C) Copyright 2023 Charles & Keith. All rights reserved.
* This code is property of Charles & Keith. Use, duplication and
* disclosure in any form without permission of copyright holder is prohibited.
* 
******************************************************************************************************* 
* @author Gokilavani V,Vinitha
* @version 1.0
* @created 19/09/2023
* @description 
* This class is used to SGD LTV value to Braze from SFDC
*
* @test class name - 
*
*  Change History:
*  MM/DD/YYYY			Developer Name			Comments
*  
* 
*/
@RestResource(urlMapping='/ltvCalculation/*')
global  class ZBraze_LTVCalculation {
    
    @HttpPost   
    global static Decimal getdetails() {
        
        Decimal response;
        RestRequest request = RestContext.request;
        string s=request.requestURI;        
         List<OrderLst> orderValues= new  List<OrderLst>();
        try {
             orderValues = (List<OrderLst>) JSON.deserialize(RestContext.request.requestBody.toString(), List<OrderLst>.class);
            system.debug('Requestbody---'+orderValues);
            response = LTVCalculations(orderValues);
        } catch(Exception e) {
            ZBraze_UtilityClass.CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage()+'  '+orderValues,'','','','LTV Calculation','Backend Process Error');   
        }
        
        system.debug('response--'+response);
        return response;
    }
    
    public static Decimal LTVCalculations(List<OrderLst> orderList) {
        
        Decimal Response=0.0;        
        id ckRecordTypeId = Schema.SObjectType.IC_Order__c.getRecordTypeInfosByName().get('CK Order').getRecordTypeId();                
        id ckCancelRecordTypeId = Schema.SObjectType.IC_Order__c.getRecordTypeInfosByName().get('CK Cancelled Orders').getRecordTypeId();
        id ckCommerce = Schema.SObjectType.IC_Refund__c.getRecordTypeInfosByName().get('CK Ecommerce').getRecordTypeId();
        id ckStore = Schema.SObjectType.IC_Refund__c.getRecordTypeInfosByName().get('CK Store').getRecordTypeId();
        
        id pdRecordTypeId= Schema.SObjectType.IC_Order__c.getRecordTypeInfosByName().get('PD Orders').getRecordTypeId();
        id pdCancelRecordTypeId= Schema.SObjectType.IC_Order__c.getRecordTypeInfosByName().get('PD Cancelled Orders').getRecordTypeId();
        id pdCommerce= Schema.SObjectType.IC_Refund__c.getRecordTypeInfosByName().get('PD Ecommerce').getRecordTypeId();
        id pdStore= Schema.SObjectType.IC_Refund__c.getRecordTypeInfosByName().get('PD Store').getRecordTypeId();
        try{
            ZBraze_API_Master__c CkCustomevent = ZBraze_API_Master__c.getvalues('CK');        
            Date CK_FromDate = Date.today().addMonths(-Integer.valueOf(CkCustomevent.LTV_Months__c));
            system.debug('ckfromdate---'+CK_FromDate);
            ZBraze_API_Master__c PDCustomevent = ZBraze_API_Master__c.getvalues('PD');        
            Date PD_FromDate = Date.today().addMonths(-Integer.valueOf(PDCustomevent.LTV_Months__c));
            
            
            Set<ID> odrRectypeid=new Set<ID>();
            Set<ID> refundRectypeid=new Set<ID>();
            for (OrderLst order : orderList) {
                if(order.Brand!=null && order.Brand.equalsIgnoreCase('CK')){
                    odrRectypeid.add(ckRecordTypeId);
                    odrRectypeid.add(ckCancelRecordTypeId);
                    refundRectypeid.add(ckCommerce);
                    refundRectypeid.add(ckStore);
                    Response=LTVOrder_Refund(odrRectypeid,refundRectypeid,CK_FromDate,order);                
                }
                if(order.Brand!=null && order.Brand.equalsIgnoreCase('PD')){
                    odrRectypeid.add(pdRecordTypeId);
                    odrRectypeid.add(pdCancelRecordTypeId);
                    refundRectypeid.add(pdCommerce);
                    refundRectypeid.add(pdStore);
                    Response=LTVOrder_Refund(odrRectypeid,refundRectypeid,PD_FromDate,order);                
                }
            }
        }catch(Exception e){
            ZBraze_UtilityClass.CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage()+'  '+orderList,'','','','LTV Calculation','Backend Process Error');    
        }
        
        
        return Response;
    }
    
    
    public static Decimal LTVOrder_Refund(set<id> OrdRectype,set<id> refundRectype,Date fromDate,OrderLst Ordlist){
        Decimal result = 0.0;
        Decimal orderSum = 0.0;
        Decimal refundSum = 0.0;
        system.debug('orderlist---'+Ordlist);
        try{
            AggregateResult[] results_order = [
                SELECT SUM(Grand_Total__c) orderTotal
                FROM IC_Order__c WHERE CreatedDate >= :fromDate and Customer_Email__c =:Ordlist.Personemail and Account_ID__c!=null
                and RecordTypeId=:OrdRectype and CurrencyIsoCode='SGD'];
            system.debug('results_order---'+results_order);
            
            if (results_order.size() > 0 && results_order[0].get('orderTotal') != null) {
                system.debug('orderTotal---'+results_order[0].get('orderTotal'));
                orderSum = (Decimal)results_order[0].get('orderTotal');
                system.debug('orderSum---'+orderSum);         
            }
            
            AggregateResult[] results_refund = [
                SELECT SUM(Refund_Amount__c) refundTotal
                FROM IC_Refund__c WHERE CreatedDate >= :fromDate and Related_Account__c!=null
                and Customer_Email__c=:Ordlist.Personemail and RecordTypeId=:refundRectype and CurrencyIsoCode='SGD' and Refund_Status__c='Completed-Refunded' and Refund_Option__c != 'MCTO'];
            system.debug('results_refund---'+results_refund);
            
            if (results_refund.size() > 0 && results_refund[0].get('refundTotal') != null) {
                refundSum = (Decimal)results_refund[0].get('refundTotal');
                system.debug('refundSum---'+refundSum);
            } 
            
            result = orderSum - refundSum; 
        }catch(Exception e){
            ZBraze_UtilityClass.CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage()+ ' OrdRectype:: '+OrdRectype+' refundRectype:'+refundRectype+ ' Ordlist'+Ordlist,'','','','LTV Calculation','Backend Process Error');     
        }
        return result;
        
    }
    
    
    
    public class OrderLst {
        public String Personemail { get; set; }
        public String Brand { get; set; }
    }
}