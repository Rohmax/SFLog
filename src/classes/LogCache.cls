/* A class to cache logs */
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
			/*Content is not supported for Community Licenses and hence this framework can not be used in
			logging from community, that's why using attachments only, still keeping the content related code
			so that it can be used in future if possible*/
			/*logInfoList.add(new LogInfo(log, new ContentVersion(
    	    	versionData = Blob.valueOf(JSON.serializePretty(obj))
    		)));*/
			logInfoList.add(new LogInfo(log, new Attachment(
					body = Blob.valueOf(JSON.serializePretty(obj)),
					name ='Log_' + System.now().format('yyyy_MM_dd_hh_mm_ss') + '.txt'
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
		/*Content is not supported for Community Licenses and hence this framework can not be used in
		logging from community, that's why using attachments only, still keeping the content related code
		so that it can be used in future if possible*/
		//List<ContentVersion> contentVersionRecords = new List<ContentVersion>();
		List<Attachment> attchmntList = new List<Attachment>();
		for(LogInfo logInfoInstance : logInfoList) {
			logs.add(logInfoInstance.logRecord);
			
		}
		List<Database.SaveResult> saveResults = Database.insert(logs, false);
		for(Integer resultCount=0; resultCount<saveResults.size(); resultCount++) {
			if(saveResults[resultCount].isSuccess() && this.logInfoList[resultCount].fileRecord != null) {
				this.logInfoList[resultCount].fileRecord.parentId = saveResults[resultCount].getId();
				attchmntList.add(logInfoList[resultCount].fileRecord);
				/*Content is not supported for Community Licenses and hence this framework can not be used in
				logging from community, that's why using attachments only, still keeping the content related code
				so that it can be used in future if possible*/
				//this.logInfoList[resultCount].fileRecord.log__c = saveResults[resultCount].getId();
				//this.logInfoList[resultCount].fileRecord.title = this.logInfoList[resultCount].logRecord.Name;
				//this.logInfoList[resultCount].fileRecord.pathOnClient = this.logInfoList[resultCount].logRecord.Name+'.txt';
				//contentVersionRecords.add(logInfoList[resultCount].fileRecord);
			}
		}
		Database.insert(attchmntList, false);
		//Database.insert(contentVersionRecords, false);
		this.logInfoList.clear();
		return saveResults[0].getId();
	}


	//The inner wrapper class that contains the info and used to
	//communicate back this info to the client class as per the
	//Error Handling Framework defined by Shell
	public class ErrorInfo {
		@AuraEnabled
		public Boolean isError = true;
		@AuraEnabled
		public String userFriendlyMsg = '';
		@AuraEnabled
		public String errorReferenceId = '';
		@AuraEnabled
		public String technicalConInfo = '';
		@AuraEnabled
		public String businessConInfo = '';
		@AuraEnabled
		public String severity = '';

		public ErrorInfo(String userFriendlyMsg, String errorReferenceId,
				String technicalConInfo, String businessConInfo, String className, String severity) {

			if(className == '' || className == null) {
				this.userFriendlyMsg = '';
			}
			else {
				Type t = Type.forName(className);
				if(t == null) {
					t = Type.forName('CommonErrMsgGenerator');
				}
				EndUserExcptnMsgGnrtnInterface endUserExcptnMsgGnrtnInterfaceRec = (EndUserExcptnMsgGnrtnInterface)t.newInstance();
				Map<String, String> errorInfoAttributesToValuesMap = new Map<String, String>{'userFriendlyMsg'=>userFriendlyMsg,
				'errorReferenceId'=>errorReferenceId,
				'technicalConInfo'=>technicalConInfo,
				'businessConInfo'=>businessConInfo,
				'className'=>className,
				'severity'=>severity};
				this.userFriendlyMsg = endUserExcptnMsgGnrtnInterfaceRec.generateMessage(errorInfoAttributesToValuesMap);
			}
			this.errorReferenceId = errorReferenceId;
			this.technicalConInfo = technicalConInfo;
			this.businessConInfo = businessConInfo;
			this.severity = severity;
		}
	}

	public class LogInfo {
    	public SystemLog__c logRecord;
    	public Attachment fileRecord;

    	public LogInfo(SystemLog__c logRecord) {
    		this.logRecord = logRecord;
    	}

    	public LogInfo(SystemLog__c logRecord, Attachment fileRecord) {
    		this.logRecord = logRecord;
    		this.fileRecord = fileRecord;
    	}
    }
}