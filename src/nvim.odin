package main

/*
 spawn nvim --embed with stdin/stdout pipes using 
 core:os/os2 process_start. It also needs a reader 
 thread and request/notification framing. Requests
  are [0, msgid, method, params], responses are 
  [1, msgid, error, result]
  and notifications are [2, method, params].
*/
