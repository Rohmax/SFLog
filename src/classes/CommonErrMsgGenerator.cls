/**
 * Created by Rohan.Gore on 9/26/2017.
 */

public with sharing class CommonErrMsgGenerator implements EndUserExcptnMsgGnrtnInterface {
    public String generateMessage(Object obj) {
        Map<String, String> errorInfo = (Map<String, String>)obj;
        return 'Something went wrong. Please connect with your Admin or '+errorInfo.get('businessConInfo')+'.';
    }
}