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
            LogType logType, Object data) {
        log(sourceClass, sourceMethod, functionalArea,
            '', logType, data);
    }

    public void log(String sourceClass, String sourceMethod, String functionalArea, 
        String message, LogType logType) {
        log(sourceClass, sourceMethod, functionalArea,
            message, logType, null);
    }

    public void log(String sourceClass, String sourceMethod, String functionalArea,
            LogType logType) {
        log(sourceClass, sourceMethod, functionalArea,
            '', logType, null);
    }

    public void log(String sourceClass, String sourceMethod, String functionalArea, 
        String message, LogType logType, Object data) {
        if(logTypes.contains(logType.name())) {
            logCache.addLogInfo(new SystemLog__c(SourceClassName__c = sourceClass,
            SourceMethodName__c = sourceMethod,
            FunctionalArea__c = functionalArea,
            Message__c = message,
            LogLevel__c = logType.name(),
            SessionId__c = UserInfo.getSessionId(),
            LoggedDateTime__c = System.now()), data);
        }
    }

    
    public String logException(Exception excptn, String sourceClass, String sourceMethod, String functionalArea, 
        Boolean useErrCtlg) {
        if(logTypes.contains(LogType.Error.name())) {
            logCache.addLogInfo(new SystemLog__c(SourceClassName__c = sourceClass,
                SourceMethodName__c = sourceMethod,
                FunctionalArea__c = functionalArea,
                Message__c = excptn.getMessage(),
                LogLevel__c = LogType.Error.name(),
                ExceptionType__c = excptn.getTypeName(),
                SessionId__c = UserInfo.getSessionId(),
                LoggedDateTime__c = System.now()), excptn.getStackTraceString());
            Id logId = logCache.commitAndFlushLogs();
            if(useErrCtlg) {
                ErrorsCatalogue__mdt errorCatalogueItem = getErrorsCatalogueData(excptn, sourceClass);
                LogCache.ErrorInfo errInfo = new LogCache.ErrorInfo(errorCatalogueItem.EndUserMessage__c, logId,
                        errorCatalogueItem.TechnicalContact__c, errorCatalogueItem.BusinessContact__c,
                        errorCatalogueItem.EndUserMessageGenerator__c, errorCatalogueItem.Severity__c);
                return errInfo.userFriendlyMsg;
            }
            return logId;
        }
        else {
            return '';
        }
    }

	public void commitLogs() {
		logCache.commitAndFlushLogs();
	}

	public void commitLogsAsync() {
        AsyncLoggingService asyncLogingJob = new AsyncLoggingService(logCache);
        System.enqueueJob(asyncLogingJob);
	}

    @testVisible
	private ErrorsCatalogue__mdt getErrorsCatalogueData(Exception excptn, String sourceClass) {
		//Language Based Error Catalogue Logic still needs to be added/developed
        List<ErrorsCatalogue__mdt> errorCatalogueItemsList = (List<ErrorsCatalogue__mdt>)queryErrorsCatalogue(excptn.getTypeName());
        if(errorCatalogueItemsList.isEmpty()) {
            errorCatalogueItemsList = (List<ErrorsCatalogue__mdt>)queryErrorsCatalogue(FALLBACK_EXCEPTION);
        }
        return errorCatalogueItemsList[0];
	}

    @testVisible
    private List<ErrorsCatalogue__mdt> queryErrorsCatalogue(String excptnCode) {
        return [SELECT
            BusinessContact__c,
            DeveloperName,
            EndUserMessage__c,
            EndUserMessageGenerator__c,
            ExceptionCode__c,
            FunctionalArea__c,
            Id,
            Label,
            Language,
            Language__c,
            MasterLabel,
            NamespacePrefix,
            QualifiedApiName,
            Severity__c,
            TechnicalContact__c
            FROM ErrorsCatalogue__mdt WHERE ExceptionCode__c =: excptnCode];
    }

    public class AsyncLoggingService implements Queueable {
        LogCache localLogCache;
        public AsyncLoggingService(LogCache logCacheInstance) {
            System.debug('logCacheInstance: '+logCacheInstance);
            this.localLogCache = logCacheInstance;
        }

        public void execute(QueueableContext context) {
            this.localLogCache.commitAndFlushLogs();
        }
    }
}