@RestResource(urlmapping='/getLTV/*')
Global class ZBraze_Last12Month_LTV {
    @HttpPost   
    global static void getdetails(){
        String response;
        RestRequest request = RestContext.request;
        RequestWrapper wrapper = (RequestWrapper)JSON.deserializeUntyped(RestContext.request.requestBody.toString());
        system.debug('wrapper.email--'+wrapper);
    }
    
    
    public class RequestWrapper{
        String email;
        String brand;
        Date fromDate;
    }
}