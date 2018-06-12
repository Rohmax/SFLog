@isTest
private class LoggingServicetest {

	class TestException extends Exception{}

	class NonRegisteredException extends Exception{}

	@isTest
	static void testLoggingForSingleLogs() {
		LoggingService logService = new LoggingService();
		LoggingService.logTypes = new Set<String>{'Info', 'Warning', 'Error'};
		
		//Test for logging without any extra info and message
		logService.log('TestClass', 'TestMethod', 'Testing1', LogType.Info);
		logService.commitLogs();
		List<SystemLog__c> systemLogRecords = [SELECT LogLevel__c FROM SystemLog__c];
		System.assert(systemLogRecords.size() == 1);
		System.assertEquals('Info', systemLogRecords[0].LogLevel__c, 'Not the expected log level');
        
        //Test for logging with extra info, but without any message
        Object testExtraInfoData = '{"key": "value"}';
		logService.log('TestClass', 'TestMethod', 'Testing2', LogType.Warning, testExtraInfoData);
		System.assertEquals(1, LoggingService.logCache.logInfoList.size());
		logService.commitLogs();
		systemLogRecords = [SELECT SourceClassName__c,
		 (SELECT Id, ParentId FROM Attachments) FROM SystemLog__c WHERE LogLevel__c = 'Warning' and
		 FunctionalArea__c = 'Testing2'];
		System.assertEquals(1, systemLogRecords.size());
		System.assertEquals('TestClass', systemLogRecords[0].SourceClassName__c);
		System.assert(systemLogRecords[0].Attachments.size() == 1);
        
        //Test for logging with message, but without any extra info
		logService.log('TestClass', 'TestMethod', 'Testing3', 'Test Message', LogType.Info);
		logService.commitLogs();
		systemLogRecords = [SELECT SourceMethodName__c
		 FROM SystemLog__c WHERE LogLevel__c = 'Info' AND FunctionalArea__c = 'Testing3'];
		System.assertEquals(1, systemLogRecords.size());
		System.assertEquals('TestMethod', systemLogRecords[0].SourceMethodName__c);
        
        //Test for logging with both message and extra info
        testExtraInfoData = '{"key": "value"}';
		logService.log('TestClass', 'TestMethod', 'Testing4', 'Test Message', LogType.Info, testExtraInfoData);
		logService.commitLogs();
		systemLogRecords = new List<SystemLog__c>();
		systemLogRecords = [SELECT FunctionalArea__c,
		 (SELECT Id, ParentId FROM Attachments) FROM SystemLog__c WHERE LogLevel__c = 'Info'
		 AND FunctionalArea__c = 'Testing4'];
		System.assertEquals(1, systemLogRecords.size());
		System.assertEquals('Testing4', systemLogRecords[0].FunctionalArea__c);
		System.assert(systemLogRecords[0].Attachments.size() == 1);
		

		//Test for logging an exception using error catalogue
        String errorMessage = logService.logException(new TestException(), 'TestClass', 'TestMethod', 'Testing', true);
        ErrorsCatalogue__mdt errorCatlgRecord = logService.getErrorsCatalogueData(new TestException(),
        	'Test Class');
        System.assertEquals('Something went wrong. Please connect with your Admin or '+errorCatlgRecord.BusinessContact__c+'.', errorMessage);

        //Test for logging an exception without using error catalogue
        String logId = logService.logException(new TestException(), 'TestClass', 'TestMethod', 'Testing without Catalogue', false);
        System.assertEquals([SELECT SourceMethodName__c
		 FROM SystemLog__c WHERE LogLevel__c = 'Error' AND FunctionalArea__c = 'Testing without Catalogue' LIMIT 1].Id,
		  logId);
        
        //Test for logging an exception using error catalogue but an exception not registered in error catalogue
        errorMessage = logService.logException(new NonRegisteredException(), 'TestClass', 'TestMethod', 'Testing',
        	true);
        errorCatlgRecord = logService.getErrorsCatalogueData(new NonRegisteredException(),
        	'Test Class');
        System.assertEquals('Something went wrong. Please connect with your Admin or '+errorCatlgRecord.BusinessContact__c+'.', errorMessage);

        //Test for logging exception, when error logging is switched off
	    LoggingService.logTypes = new Set<String>{'Info', 'Warning'};
	    errorMessage = logService.logException(new NonRegisteredException(), 'TestClass', 'TestMethod', 'Testing', 
        	true);
	    System.assertEquals('', errorMessage);
	}

    @isTest
    static void testAsyncLogging() {
        LoggingService logService = new LoggingService();
        LoggingService.logTypes = new Set<String>{'Info', 'Warning', 'Error'};
        logService.log('TestClass', 'TestMethod', 'Logging Async', LogType.Info);
        Test.startTest();
        logService.commitLogsAsync();
        Test.stopTest();
		List<SystemLog__c> systemLogRecords = [SELECT FunctionalArea__c,
		(SELECT Id, ParentId FROM Attachments) FROM SystemLog__c WHERE LogLevel__c = 'Info'
		AND FunctionalArea__c = 'Logging Async'];
		System.assertEquals(1, systemLogRecords.size());
	}

	@isTest
	static void bulkTestLoggingService() {
		//Initializing the logging service
		LoggingService logService = new LoggingService();
		LoggingService.logTypes = new Set<String>{'Info', 'Warning', 'Error'};
		//Logging in bulk
		for(Integer logCount =0; logCount<200; logCount++) {
			//Also logging extra info for half of the records
			if(Math.mod(logCount, 2) == 0) {
				logService.log('TestClass', 'TestMethod', 'Testing', 'Test Message', LogType.Info, '{"key": "value"}');
			}
			else {
				logService.log('TestClass', 'TestMethod', 'Testing', LogType.Info);
			}
		}

		logService.commitLogs();
		System.assertEquals(200, [SELECT Id, (SELECT Id, ParentId FROM Attachments) FROM SystemLog__c].size());
        
        //Calculating the number of attachment records stored as Content Version against a log
		Integer logAttachmentsCount = 0;
		for(SystemLog__c testLog : [SELECT Id, (SELECT Id, ParentId FROM Attachments) FROM SystemLog__c]) {
			if(!testLog.Attachments.isEmpty()) {
				logAttachmentsCount++;
			}
		}
		//Should be half the number of log records, i.e. 100
		System.assertEquals(100, logAttachmentsCount);

	}
}
