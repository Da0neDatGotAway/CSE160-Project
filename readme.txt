To run the file, open the project in vscode, make sure the validation_dv.py file is open, then click the run in debug mode option. This will automatically open and run it in the docker using the command 

powershell -ExecutionPolicy Bypass -File \"${workspaceFolder}\\.vscode\\run-in-docker.ps1\

The constants are all listed at the top of the validation file. There are no specific commands for each test, it is designed to be run in one giant batch. Each test should say passed when it runs, where it will also print out some of the debug statements. 