/* A class to cache logs Some change, some changes*/
public class LogCache {

	// A list of all the log info list which is basically a wrapper of log and related file records.
    @testVisible
    private List<LogInfo> logInfoList; 

    //Constructor to make a new empty lists 
	public LogCache() {
		this.logInfoList = new List<LogInfo>();
	}

	
	/** Adds a single loginfo to the list
	*
	* @param log A log
	*/
	public void addLogInfo(SystemLog__c log, Object obj) {
		if(obj != null) {
			logInfoList.add(new LogInfo(log, new ContentVersion(
    	    	versionData = Blob.valueOf(JSON.serializePretty(obj))
    		)));
		}
		else {
			logInfoList.add(new LogInfo(log));
		}
		
	}

	//Commits all of the logs and files to the SF database and then Flushes/Clears them from memory
	public String commitAndFlushLogs() {
		if (this.logInfoList.isEmpty()) {
			return '';
		}
		List<SystemLog__c> logs = new List<SystemLog__c>();
		List<ContentVersion> contentVersionRecords = new List<ContentVersion>();
		for(LogInfo logInfoInstance : logInfoList) {
			logs.add(logInfoInstance.logRecord);
			
		}
		List<Database.SaveResult> saveResults = Database.insert(logs, false);
		for(Integer resultCount=0; resultCount<saveResults.size(); resultCount++) {
			if(saveResults[resultCount].isSuccess() && this.logInfoList[resultCount].fileRecord != null) {
				this.logInfoList[resultCount].fileRecord.log__c = saveResults[resultCount].getId();
	        	this.logInfoList[resultCount].fileRecord.title = this.logInfoList[resultCount].logRecord.Name; 
	        	this.logInfoList[resultCount].fileRecord.pathOnClient = '/' + this.logInfoList[resultCount].logRecord.Name+'.txt';
	        	contentVersionRecords.add(logInfoList[resultCount].fileRecord);
			}
        }
        Database.insert(contentVersionRecords, false);
        this.logInfoList.clear();
        return saveResults[0].getId(); 
    }

	public class LogInfo {
    	public SystemLog__c logRecord;
    	public ContentVersion fileRecord;

    	public LogInfo(SystemLog__c logRecord) {
    		this.logRecord = logRecord;
    	}

    	public LogInfo(SystemLog__c logRecord, ContentVersion fileRecord) {
    		this.logRecord = logRecord;
    		this.fileRecord = fileRecord;
    	}
    }
}