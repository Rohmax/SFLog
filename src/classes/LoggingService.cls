/*Service Class to perform logging*/
public class LoggingService {

    private final String FALLBACK_EXCEPTION = 'FallbackException';
    private final String FIELD_FOR_CONDITION = 'ExceptionCode__c';
    
    @testVisible
    private static LogCache logCache;
    @testVisible
    private static Set<String> logTypes;

    public LoggingService() {
        logCache = new LogCache();
        logTypes = new Set<String>();
        for(SFLoggingSettings__mdt logSetting : [Select LogLevel__c FROM SFLoggingSettings__mdt WHERE IsActive__c = TRUE]) {
            logTypes.add(logSetting.LogLevel__c);
        }
        
    }
    
    public void log(String sourceClass, String sourceMethod, String functionalArea, 
         String logType, Object data) {
        log(sourceClass, sourceMethod, functionalArea,
            '', logType, data);
    }

    public void log(String sourceClass, String sourceMethod, String functionalArea, 
        String message, String logType) {
        log(sourceClass, sourceMethod, functionalArea,
            message, logType, null);
    }

    public void log(String sourceClass, String sourceMethod, String functionalArea, 
         String logType) {
        log(sourceClass, sourceMethod, functionalArea,
            '', logType, null);
    }

    public void log(String sourceClass, String sourceMethod, String functionalArea, 
        String message, String logType, Object data) {
        if(logTypes.contains(logType)) {
            logCache.addLogInfo(new SystemLog__c(SourceClassName__c = sourceClass,
            SourceMethodName__c = sourceMethod,
            FunctionalArea__c = functionalArea,
            Message__c = message,
            LogLevel__c = logType,
            SessionId__c = UserInfo.getSessionId(),
            LoggedDateTime__c = System.now()), data);
        }
    }

    
    public String logException(Exception excptn, String sourceClass, String sourceMethod, String functionalArea, 
        Boolean useErrCtlg) {
        if(logTypes.contains('Error')) {
            logCache.addLogInfo(new SystemLog__c(SourceClassName__c = sourceClass,
                SourceMethodName__c = sourceMethod,
                FunctionalArea__c = functionalArea,
                Message__c = excptn.getMessage(),
                LogLevel__c = 'Error',
                ExceptionType__c = excptn.getTypeName(),
                SessionId__c = UserInfo.getSessionId(),
                LoggedDateTime__c = System.now()), excptn.getStackTraceString());
            Id logId = logCache.commitAndFlushLogs();
            return logId;
        }
        else {
            return '';
        }
    }

    public void commitLogs() {
        logCache.commitAndFlushLogs();
    }
     
}