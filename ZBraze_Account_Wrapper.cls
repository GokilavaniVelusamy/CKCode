/********************************************************************************************************
* (C) Copyright 2023 Charles & Keith. All rights reserved.
* This code is property of Charles & Keith. Use, duplication and
* disclosure in any form without permission of copyright holder is prohibited.
* 
******************************************************************************************************* 
* @author Asha SP
* @version 1.0
* @created 25/01/2023
* @description 
* 
*
* @test class name - 
*
*  Change History:
*  MM/DD/YYYY			Developer Name			Comments
*  
* 
*/
public class ZBraze_Account_Wrapper {
    public List<Attributes> attributes;

    public class Attributes {
        public String external_id {get; set;} 
        public String last_name {get; set;}
        public String first_name {get; set;}
        public String email {get; set;}
        public String country {get; set;}
        public Date dob {get; set;}
        public String gender {get; set;}
        public String home_city {get; set;}
        public String language {get; set;}
        public String phone {get; set;}
        public String email_subscribe {get; set;}
       // public String push_subscribe {get; set;}
        public String Customer_Type {get; set;}
      //  public Double Days_Since_Last_Login {get; set;}
      //  public Double Days_since_last_purchase {get; set;}
        public Datetime Last_Login_Date {get; set;}
        public Datetime Last_purchase_date {get; set;}
        public Double Favored_Medium_Of_Purchase {get; set;}
        public Date First_Date_Of_Purchase {get; set;}
        public String Loyalty_Tier_AE {get; set;}
        public String Loyalty_Tier_AU {get; set;}
        public String Loyalty_Tier_CA {get; set;}
        public String Loyalty_Tier_CH {get; set;}
        public String Loyalty_Tier_EU {get; set;}
        public String Loyalty_Tier_GB {get; set;}
        public String Loyalty_Tier_HK {get; set;}
        public String Loyalty_Tier_KH {get; set;}
        public String Loyalty_Tier_KR {get; set;}
        public String Loyalty_Tier_MO {get; set;}
        public String Loyalty_Tier_MT {get; set;}
        public String Loyalty_Tier_MY {get; set;}
        public String Loyalty_Tier_NO {get; set;}
        public String Loyalty_Tier_NZ {get; set;}
        public String Loyalty_Tier_PAK {get; set;}
        public String Loyalty_Tier_SG {get; set;}
        public String Loyalty_Tier_TW {get; set;}
        public String Loyalty_Tier_UK {get; set;}
        public String Loyalty_Tier_US {get; set;}
        public String Mode_of_registration {get; set;}
        public String Most_Purchased_Category {get; set;}
        public String Most_Purchased_Color {get; set;}
        public Datetime Registration_Date {get; set;}
        public String School_University_Name {get; set;}
        public Double Shoe_Size {get; set;}
        public String subscribed_content_gender {get; set;}
        public Datetime VIP_Since_Date_AE {get; set;}
        public Datetime VIP_Since_Date_AU {get; set;}
        public Datetime VIP_Since_Date_CA {get; set;}
        public Datetime VIP_Since_Date_CH {get; set;}
        public Datetime VIP_Since_Date_EU {get; set;}
        public Datetime VIP_Since_Date_GB {get; set;}
        public Datetime VIP_Since_Date_HK {get; set;}
        public Datetime VIP_Since_Date_KR {get; set;}
        public Datetime VIP_Since_Date_MO {get; set;}
        public Datetime VIP_Since_Date_MT {get; set;}
        public Datetime VIP_Since_Date_NO {get; set;}
        public Datetime VIP_Since_Date_NZ {get; set;}
        public Datetime VIP_Since_Date_PAK {get; set;}
        public Datetime VIP_Since_Date_SG {get; set;}
        public Datetime VIP_Since_Date_TW {get; set;}
        public Datetime VIP_Since_Date_UK {get; set;}
        public Datetime VIP_Since_Date_US {get; set;}
        public Datetime VIP_Since_Date_KH {get; set;}
        public Datetime VIP_Since_Date_MY {get; set;}
        public String Source {get; set;}
        public String sms_subscribed {get; set;}
        public String sms_mobile_subscribed {get; set;}
        public String Ocapi_Customer_Id {get; set;}
        public String Site_URL {get; set;}
        public String utm_campaign {get; set;}
        public String utm_content {get; set;}
        public String utm_medium {get; set;}
        public String utm_source {get; set;}
        public String utm_term {get; set;}
        public String Reseller_Flag {get; set;}
        
        
        
    }
    public class ResponseBody {
        public  Decimal attributes_processed;
        public  String message;
        
    }
    
   
    
}