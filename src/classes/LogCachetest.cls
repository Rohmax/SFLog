@isTest
private class LogCachetest {
	
	@isTest
	static void testAddLogInfoWithoutAdditionalInfo() {
		LogCache logCache = new LogCache();
		//Add a single Log without any attachment or additional info
		logCache.addLogInfo(new SystemLog__c(), null);
		System.assert(logCache.logInfoList.size() == 1);
		System.assert(logCache.logInfoList[0].logRecord != null);
		System.assert(logCache.logInfoList[0].fileRecord == null);
		//Add second Log without any attachment or additional info
		logCache.addLogInfo(new SystemLog__c(), null);
		System.assert(logCache.logInfoList.size() == 2);
	}

	@isTest
	static void testAddLogInfo() {
		//Add a single Log with additional info
		LogCache logCache = new LogCache();
		logCache.addLogInfo(new SystemLog__c(), '{"key" : "value"}');
		System.assert(logCache.logInfoList.size() == 1);
		System.assert(logCache.logInfoList[0].logRecord != null);
		System.assert(logCache.logInfoList[0].fileRecord != null);
		System.assertEquals('"{\\"key\\" : \\"value\\"}"', logCache.logInfoList[0].fileRecord.versionData.toString());

	}

	@isTest
	static void testCommitLogs() {
		LogCache logCache = new LogCache();
		//Trying to execute commit without any logs in the memory
		logCache.commitAndFlushLogs();
		System.assert([SELECT Id FROM SystemLog__c].size() == 0);
		//Now add some logs and additional info to the memory
		for(Integer testCount = 0; testCount<5; testCount++) {
			if(Math.mod(testCount, 2) == 0) {
				logCache.addLogInfo(new SystemLog__c(), '{"key" : "value"}');
			}
			else {
				logCache.addLogInfo(new SystemLog__c(), null);
			}
		}
		//Commiting now with both logs and content in memory
		logCache.commitAndFlushLogs();
		List<SystemLog__c> logsList = [SELECT Id FROM SystemLog__c];
		System.assert(logsList.size() == 5);
		List<ContentVersion> cvList = [SELECT Id, log__c FROM ContentVersion];
		System.assert(cvList.size() == 3);
		System.assert(cvList[0].log__c == logsList[0].Id);
		System.assert(cvList[1].log__c == logsList[2].Id);
		System.assert(cvList[2].log__c == logsList[4].Id);
	}
}