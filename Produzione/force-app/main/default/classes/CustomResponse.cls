public class CustomResponse {
    
    private Integer statusCode;
    private Object body;
    private Map<String, String> headers;
    private RestResponse response;
    
    public CustomResponse(RestResponse response){
        
        this.headers = new Map<String, String>();
        
        this.headers.put('Content-Type', 'application/json');
        
        this.statusCode = 200;
        this.response = response;
        
    }
    
    public void setStatusCode(Integer statusCode){
        
        this.statusCode = statusCode;
        
    }
    
    public void setBody(Object body){
        
        this.body = body;
        
    }
    
    public void send(){
        
        for(String key : this.headers.keySet()){
        
        	this.response.addHeader(key, this.headers.get(key));
            
        }
        
        this.response.statusCode = this.statusCode;
        this.response.responseBody = Blob.valueOf(JSON.serialize(this.body));
        
    }

}