@isTest
public class ZBraze_LTVCalculation_Test {
    
    
    @TestSetup
    static void setupTestData(){
        
        id ckRecordTypeId = Schema.SObjectType.IC_Order__c.getRecordTypeInfosByName().get('CK Order').getRecordTypeId();                
        id ckCancelRecordTypeId = Schema.SObjectType.IC_Order__c.getRecordTypeInfosByName().get('CK Cancelled Orders').getRecordTypeId();
        id ckCommerce = Schema.SObjectType.IC_Refund__c.getRecordTypeInfosByName().get('CK Ecommerce').getRecordTypeId();
        id ckStore = Schema.SObjectType.IC_Refund__c.getRecordTypeInfosByName().get('CK Store').getRecordTypeId();
        
        id pdRecordTypeId= Schema.SObjectType.IC_Order__c.getRecordTypeInfosByName().get('PD Orders').getRecordTypeId();
        id pdCancelRecordTypeId= Schema.SObjectType.IC_Order__c.getRecordTypeInfosByName().get('PD Cancelled Orders').getRecordTypeId();
        id pdCommerce= Schema.SObjectType.IC_Refund__c.getRecordTypeInfosByName().get('PD Ecommerce').getRecordTypeId();
        id pdStore= Schema.SObjectType.IC_Refund__c.getRecordTypeInfosByName().get('PD Store').getRecordTypeId();
        
        ZBraze_API_Master__c CustSettingCK = ZBraze_Test_Data_Factory.createCKCustomSetting();
        ZBraze_API_Master__c CustSettingPD = ZBraze_Test_Data_Factory.createPDCustomSetting();        
        ZBraze_Syn_Activation__c CustSetting_CK = ZBraze_Test_Data_Factory.createBrazeActivationCustomSetting('CK');
        ZBraze_Syn_Activation__c CustSetting_PD = ZBraze_Test_Data_Factory.createBrazeActivationCustomSetting('PD');
        
        list<Account> accCK = ZBraze_Test_Data_Factory.createAccountCK(1); 
        list<Account> accPD = ZBraze_Test_Data_Factory.createAccountPD(1);
        
        list<IC_order__c> giftcardord_CK =ZBraze_Test_Data_Factory.createOrderCK(1 ,accCK[0].id,'Complete'); 
        list<IC_order__c> PurchaseeventordCK =ZBraze_Test_Data_Factory.createOrderCK(1 ,accCK[0].id,'In Progress');      
        list<IC_order__c> cancelOrderCK =ZBraze_Test_Data_Factory.createCancelOrderCK(1 ,accCK[0].id,giftcardord_CK[0]); 
        list<IC_order_product__c> orderprodCK = ZBraze_Test_Data_Factory.orderProductData(1,giftcardord_CK[0].id); 
        list<IC_order_product__c> PurEventorderprodlCK = ZBraze_Test_Data_Factory.orderProductData(1,PurchaseeventordCK[0].id); 
        list<IC_order_product__c> cancelOrderprodCK = ZBraze_Test_Data_Factory.orderProductData(1,cancelOrderCK[0].id);
        list<IC_Refund__c> refundCK = ZBraze_Test_Data_Factory.createRefundDataCK(2,giftcardord_CK[0].id,accCK[0].id); 
        
        list<IC_order__c> giftcardord_PD =ZBraze_Test_Data_Factory.createOrderPD(1 ,accPD[0].id,'Complete');              
        list<IC_order__c> PurchaseeventordPD =ZBraze_Test_Data_Factory.createOrderPD(1 ,accPD[0].id,'In Progress');       
        list<IC_order__c> cancelOrderPD =ZBraze_Test_Data_Factory.createCancelOrderPD(1 ,accPD[0].id,giftcardord_PD[0]);       
        list<IC_order_product__c> orderprodPD = ZBraze_Test_Data_Factory.orderProductData(1,giftcardord_PD[0].id);     
        list<IC_order_product__c> PurEventorderprodPD = ZBraze_Test_Data_Factory.orderProductData(1,PurchaseeventordPD[0].id);         
       list<IC_order_product__c> cancelOrderprodPD = ZBraze_Test_Data_Factory.orderProductData(1,cancelOrderPD[0].id);     
        list<IC_Refund__c> refundPD = ZBraze_Test_Data_Factory.createRefundDataPD(2,giftcardord_PD[0].id,accPD[0].id); 
        
    }
    @isTest static void testCKLTV() {          
        String requestbody=ZBraze_Test_Data_Factory.LTV_Requestbody(1,'CK','0test123@gmail.com');
       
        // Set up the mock request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/ltvCalculation/';
        request.httpMethod = 'POST';
        request.requestBody= Blob.valueOf(requestbody);
        RestContext.request = request;
          System.debug('ltvtestrequest---'+ request);
        // Call the REST service
        Test.startTest();
        Decimal response = ZBraze_LTVCalculation.getdetails();           
        System.debug('responseLtvCalculation---'+ response);
        Test.stopTest();
        
        
    }
    
    @isTest static void testPDLTV() {     
        String requestbody=ZBraze_Test_Data_Factory.LTV_Requestbody(1,'PD','0test123@gmail.com');
        
        // Set up the mock request
        RestRequest request = new RestRequest();
        request.requestUri = '/services/apexrest/ltvCalculation/';
        request.httpMethod = 'POST';
        request.requestBody= Blob.valueOf(requestbody);
        RestContext.request = request;
        
        // Call the REST service
        Test.startTest();
        Decimal response = ZBraze_LTVCalculation.getdetails();           
        System.debug('responseLtvCalculation---'+ response);
        Test.stopTest();
        
        
    }
    
    
}