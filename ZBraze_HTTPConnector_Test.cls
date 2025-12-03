/********************************************************************************************************
* (C) Copyright 2023 Charles & Keith. All rights reserved.
* This code is property of Charles & Keith. Use, duplication and
* disclosure in any form without permission of copyright holder is prohibited.
* 
******************************************************************************************************* 
* @author Asha SP,Gokilavani V
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
@isTest
public class ZBraze_HTTPConnector_Test {
    @isTest static void Test(){
        Test.setMock(HttpCalloutMock.class, new ZBraze_Order_MockCallout());
        ZBraze_HTTPConnector.performCallout('requestBody', 'endpoint', 'POST', 
                                            'application/json', 'jdhsjdhjsa9898989mndmns', 
                                            3600, 'className', 'classMethodName');
        ZBraze_HTTPConnector.performHTTPCallout('requestBody', 'endpoint', 'POST', 
                                            'application/json', 'jdhsjdhjsa9898989mndmns', 
                                            3600, 'className', 'classMethodName');
        ZBraze_HTTPConnector.performSFTPCallout('endpoint', 'POST', 3600, 'contentType', 
                                                'userName', 'password', 'port', 'ftpHost', 'ftpType', 
                                                'folderPath', 'className', 'classMethodName');
    }
}