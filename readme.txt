To run the file, open the project in vscode, make sure the validation_dv.py file is open, then click the run in debug mode option. This will automatically open and run it in the docker using the command 

powershell -ExecutionPolicy Bypass -File \"${workspaceFolder}\\.vscode\\run-in-docker.ps1\

The constants are all listed at the top of the validation file. There are no specific commands for each test, it is designed to be run in one giant batch. Each test should say passed when it runs, where it will also print out some of the debug statements. 


To run tcp tests, run tcpValidation.py using standard commands, which will run the full test suite. Run.py also has the three commands that can be run using command line, or by using run_test.py and changing parameters in that file. The topology used is just validation_line.topo, and we do not use noise for testing, instead manually dropping packets via removed connections to ensure retransmits are needed. The sequence number range is technically only 255, however, it loops to allow sending far more data at once since the buffer has a max of 128, meaning it can only get up to 128 out of sync. The timer and storage constants are SOCKET_BUFFER_SIZE = 128, SOCKET_RESEND = 10000, SOCKET_MAX_ATTEMPTS = 5, DATA_SIZE = 13, and BUFFER_SIZE = 2048. Each test can be run seperately using arguments:
            "baseline"
            "data-loss"
            "ack-loss"
            "flow-control"
            "control-loss-syn"
            "control-loss-syn-ack"
            "control-loss-final-ack"
            "close-loss"
            "cleanup"
or run all at once by just running tcpValidation.py. There is also a constant at the top of the file called verbose, which enables expanded logging even on pass to ensure all behavior is expected.

Results summary with verbose set to false: 
Creating Topo!
Number of Motes 4
  1   2   -54.0
  2   1   -54.0
  2   3   -54.0
  3   2   -54.0
  3   4   -54.0
  4   3   -54.0
Creating noise model for  1
Creating noise model for  2
Creating noise model for  3
Creating noise model for  4
('Adding Channel', 'command')
('Adding Channel', 'general')
('Adding Channel', 'general')
('Adding Channel', 'routing')
('Adding Channel', 'transport')
('Adding Channel', 'transport')
('Adding Channel', 'dbgtrans')
Running command
PASS baseline: 1-2-3-4, 1030 bytes, final segment 3 bytes, graceful close
Creating Topo!
Number of Motes 4
  1   2   -54.0
  2   1   -54.0
  2   3   -54.0
  3   2   -54.0
  3   4   -54.0
  4   3   -54.0
Creating noise model for  1
Creating noise model for  2
Creating noise model for  3
Creating noise model for  4
('Adding Channel', 'command')
('Adding Channel', 'general')
('Adding Channel', 'general')
('Adding Channel', 'routing')
('Adding Channel', 'transport')
('Adding Channel', 'transport')
('Adding Channel', 'dbgtrans')
Running command
PASS data-loss: selected gap ACK/retransmission/recovery logged
Creating Topo!
Number of Motes 4
  1   2   -54.0
  2   1   -54.0
  2   3   -54.0
  3   2   -54.0
  3   4   -54.0
  4   3   -54.0
Creating noise model for  1
Creating noise model for  2
Creating noise model for  3
Creating noise model for  4
('Adding Channel', 'command')
('Adding Channel', 'general')
('Adding Channel', 'general')
('Adding Channel', 'routing')
('Adding Channel', 'transport')
('Adding Channel', 'transport')
('Adding Channel', 'dbgtrans')
Running command
PASS ack-loss: later cumulative ACK/recovery and duplicate suppression logged
Creating Topo!
Number of Motes 4
  1   2   -54.0
  2   1   -54.0
  2   3   -54.0
  3   2   -54.0
  3   4   -54.0
  4   3   -54.0
Creating noise model for  1
Creating noise model for  2
Creating noise model for  3
Creating noise model for  4
('Adding Channel', 'command')
('Adding Channel', 'general')
('Adding Channel', 'general')
('Adding Channel', 'routing')
('Adding Channel', 'transport')
('Adding Channel', 'transport')
('Adding Channel', 'dbgtrans')
Running command
PASS flow-control: 128-byte receiver fill, pause/window log, consumption, completion
Creating Topo!
Number of Motes 4
  1   2   -54.0
  2   1   -54.0
  2   3   -54.0
  3   2   -54.0
  3   4   -54.0
  4   3   -54.0
Creating noise model for  1
Creating noise model for  2
Creating noise model for  3
Creating noise model for  4
('Adding Channel', 'command')
('Adding Channel', 'general')
('Adding Channel', 'general')
('Adding Channel', 'routing')
('Adding Channel', 'transport')
('Adding Channel', 'transport')
('Adding Channel', 'dbgtrans')
Running command
PASS control-loss syn: bounded repeatable retry/duplicate handling run
Creating Topo!
Number of Motes 4
  1   2   -54.0
  2   1   -54.0
  2   3   -54.0
  3   2   -54.0
  3   4   -54.0
  4   3   -54.0
Creating noise model for  1
Creating noise model for  2
Creating noise model for  3
Creating noise model for  4
('Adding Channel', 'command')
('Adding Channel', 'general')
('Adding Channel', 'general')
('Adding Channel', 'routing')
('Adding Channel', 'transport')
('Adding Channel', 'transport')
('Adding Channel', 'dbgtrans')
Running command
PASS control-loss syn-ack: bounded repeatable retry/duplicate handling run
Creating Topo!
Number of Motes 4
  1   2   -54.0
  2   1   -54.0
  2   3   -54.0
  3   2   -54.0
  3   4   -54.0
  4   3   -54.0
Creating noise model for  1
Creating noise model for  2
Creating noise model for  3
Creating noise model for  4
('Adding Channel', 'command')
('Adding Channel', 'general')
('Adding Channel', 'general')
('Adding Channel', 'routing')
('Adding Channel', 'transport')
('Adding Channel', 'transport')
('Adding Channel', 'dbgtrans')
Running command
PASS control-loss final-ack: bounded repeatable retry/duplicate handling run
Creating Topo!
Number of Motes 4
  1   2   -54.0
  2   1   -54.0
  2   3   -54.0
  3   2   -54.0
  3   4   -54.0
  4   3   -54.0
Creating noise model for  1
Creating noise model for  2
Creating noise model for  3
Creating noise model for  4
('Adding Channel', 'command')
('Adding Channel', 'general')
('Adding Channel', 'general')
('Adding Channel', 'routing')
('Adding Channel', 'transport')
('Adding Channel', 'transport')
('Adding Channel', 'dbgtrans')
Running command
PASS close-loss: close retries and bounded cleanup/release
Creating Topo!
Number of Motes 4
  1   2   -54.0
  2   1   -54.0
  2   3   -54.0
  3   2   -54.0
  3   4   -54.0
  4   3   -54.0
Creating noise model for  1
Creating noise model for  2
Creating noise model for  3
Creating noise model for  4
('Adding Channel', 'command')
('Adding Channel', 'general')
('Adding Channel', 'general')
('Adding Channel', 'routing')
('Adding Channel', 'transport')
('Adding Channel', 'transport')
('Adding Channel', 'dbgtrans')
Running command
PASS cleanup: unreachable peer retry, failure report, socket release