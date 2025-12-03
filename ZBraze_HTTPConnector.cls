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
public class ZBraze_HTTPConnector {
    public Static String performCallout(String requestBody,String endpoint,String methodType,
                                        String headers,String accessToken,
                                        Integer timeout,String className, String classMethodName){
                                            system.debug('endpoint--'+endpoint + '-methodType--'+methodType+'-headers--'+headers+'-className--'+className+'--classMethodName--'+classMethodName);
                                            system.debug('requestBody--'+requestBody +'endpoint--'+endpoint + '-methodType--'+methodType+'-headers--'+headers+'-accessToken--'+accessToken+'--timeout--'+timeout);
                                            String responseString;
                                            String requestSent;
                                            Http http = new Http();
                                            HttpRequest request = new HttpRequest(); 
                                            request.setEndpoint(endpoint);
                                            request.setMethod(methodType); 
                                            if(null != timeout){
                                                request.setTimeout(timeout);
                                            }                                  
                                            if(string.isnotblank(headers)){
                                                request.setHeader('Content-Type', headers);
                                            } 
                                            if(String.isNotEmpty(accessToken)) 
                                                request.setHeader('Authorization', 'Bearer ' + accessToken);
                                            if(requestBody != null){
                                                request.setBody(requestBody);
                                                requestSent = requestBody;
                                            }                                 
                                            try{
                                                system.debug('request--'+request);
                                                HttpResponse response = http.send(request);
                                                system.debug('response.getStatusCode(): '+response.getStatusCode());
                                                system.debug('response.getbody(): '+response.getbody());
                                               // if(response.getStatusCode() == 201 && response.getbody() != null)
                                                    responseString = response.getbody();
                                            }catch(Exception e){
                                                responseString=null;
                                                ZBraze_UtilityClass.CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage()+'Class: '+className+'; Method: '+classMethodName,'','','','ZBraze_HTTPConnector','Backend Process Error');     
                                             }
                                            return responseString;
                                        }
    
     public Static HttpResponse performHTTPCallout(String requestBody,String endpoint,String methodType,
                                        String headers,String accessToken,
                                        Integer timeout,String className, String classMethodName){
                                            system.debug('endpoint--'+endpoint + '-methodType--'+methodType+'-headers--'+headers+'-className--'+className+'--classMethodName--'+classMethodName);
                                            system.debug('requestBody--'+requestBody +'endpoint--'+endpoint + '-methodType--'+methodType+'-headers--'+headers+'-accessToken--'+accessToken+'--timeout--'+timeout);
                                            String responseString;
                                            String requestSent;
                                             HttpResponse response;
                                            Http http = new Http();
                                            HttpRequest request = new HttpRequest(); 
                                            request.setEndpoint(endpoint);
                                            request.setMethod(methodType); 
                                            if(null != timeout){
                                                request.setTimeout(timeout);
                                            }                                  
                                            if(string.isnotblank(headers)){
                                                request.setHeader('Content-Type', headers);
                                            } 
                                            if(String.isNotEmpty(accessToken)) 
                                                request.setHeader('Authorization', 'Bearer ' + accessToken);
                                            if(requestBody != null){
                                                request.setBody(requestBody);
                                                requestSent = requestBody;
                                            }                                 
                                            try{
                                                system.debug('request--'+request);
                                                 response = http.send(request);
                                                system.debug('response.getStatusCode(): '+response.getStatusCode());
                                                system.debug('response.getbody(): '+response.getbody());
                                            }catch(Exception e){
                                                ZBraze_UtilityClass.CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage()+'Class: '+className+'; Method: '+classMethodName,'','','','ZBraze_HTTPConnector','Backend Process Error');     
                                            }
                                            return response;
                                        }
    
    public Static HttpResponse performSFTPCallout(String endpoint,String methodType,Integer timeout,String contentType,String userName,String password,String port,
                                            String ftpHost,String ftpType,String folderPath,
                                            String className, String classMethodName){
                                                 system.debug('endpoint--'+endpoint + '-className--'+className+'--classMethodName--'+classMethodName);
                                               // String responseString;
                                                String requestSent;
                                                 HttpResponse response ;
                                                Http http = new Http();
                                                HttpRequest request = new HttpRequest(); 
                                                request.setEndpoint(endpoint);
                                                request.setMethod(methodType); 
                                                if(null != timeout){
                                                    request.setTimeout(timeout);
                                                }                                  
                                                if(string.isnotblank(contentType)){
                                                    request.setHeader('Content-Type', contentType);
                                                } 
                                                if(string.isnotblank(userName)){
                                                    request.setHeader('username', userName);
                                                }
                                                if(string.isnotblank(password)){
                                                    request.setHeader('password', password);
                                                }
                                                if(string.isnotblank(port)){
                                                    request.setHeader('port', port);
                                                }
                                                if(string.isnotblank(ftpHost)){
                                                    request.setHeader('ftp-host', ftpHost);
                                                }
                                                if(string.isnotblank(ftptype)){
                                                    request.setHeader('ftp-type', ftptype);
                                                }
                                                if(string.isnotblank(folderPath)){
                                                    request.setHeader('path', folderPath);
                                                }
                                                
                                                try{
                                                     response = http.send(request);
                                                   /* if(response.getStatusCode() == 200 && response.getbody() != null)
                                                        responseString = response.getbody();*/
                                                }catch(Exception e){
                                                   ZBraze_UtilityClass.CreateErrorLog('getLineNumber: '+e.getLineNumber()+ ' getStackTraceString: '+e.getStackTraceString()+' getMessage: '+e.getMessage()+'Class: '+className+'; Method: '+classMethodName,'','','','ZBraze_HTTPConnector','Backend Process Error');     
                                                }
                                                return response;
                                            }
}